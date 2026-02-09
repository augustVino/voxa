//
//  AudioPipeline.swift
//  Voxa
//
//  音频采集管道 - 基于 AVAudioEngine
//

import Foundation
@preconcurrency import AVFoundation

/// 音频采集管道
/// 负责音频录制、实时音量监控和 WAV 编码
actor AudioPipeline: AudioCapturing {
    // MARK: - Constants
    
    /// 最大录音时长 (秒) - 智谱 GLM-ASR-2512 限制
    private let maxDurationSeconds: Int = 30
    
    /// 最大文件大小 (字节) - 智谱 GLM-ASR-2512 限制 25MB
    private let maxFileSizeBytes: Int = 25 * 1024 * 1024
    
    /// Ring Buffer 容量 (秒)
    private let ringBufferCapacitySeconds: Int = 35 // 略大于最大录音时长
    
    // MARK: - Dependencies
    
    private let audioEngine: AVAudioEngine
    private let encoder: AudioEncoder
    private let levelProvider: AudioLevelProvider
    
    // MARK: - State
    
    private(set) var isRecording = false
    private var recordingStartTime: Date?
    private var audioDataBuffer: Data = Data()
    
    /// 实际录音采样率 (由输入设备决定)
    private var inputSampleRate: Double = 16000.0
    /// 实际录音声道数
    private var inputChannelCount: Int = 1
    
    // MARK: - Initialization
    
    init(
        audioEngine: AVAudioEngine = AVAudioEngine(),
        encoder: AudioEncoder = AudioEncoder(),
        levelProvider: AudioLevelProvider = AudioLevelProvider()
    ) {
        self.audioEngine = audioEngine
        self.encoder = encoder
        self.levelProvider = levelProvider
    }
    
    // MARK: - AudioCapturing
    
    func startCapture() async throws {
        guard !isRecording else {
            throw AudioError.engineAlreadyRunning
        }
        
        print("[AudioPipeline] 开始录音...")
        
        // 重置状态
        audioDataBuffer.removeAll(keepingCapacity: true)
        recordingStartTime = Date()
        
        // 获取输入节点
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw AudioError.inputNodeUnavailable
        }
        
        // 记录实际输入格式，WAV 编码时使用
        inputSampleRate = inputFormat.sampleRate
        inputChannelCount = Int(inputFormat.channelCount)
        
        print("[AudioPipeline] 输入格式: \(inputFormat.sampleRate) Hz, \(inputFormat.channelCount) 声道")
        
        // 安装音频 Tap
        inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: inputFormat
        ) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        // 启动音频引擎
        do {
            try audioEngine.start()
            isRecording = true
            print("[AudioPipeline] 音频引擎已启动")
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioError.engineStartFailed(underlying: error)
        }
    }
    
    func stopCapture() async throws -> Data {
        guard isRecording else {
            return Data()
        }
        
        print("[AudioPipeline] 停止录音...")
        
        // 停止音频引擎
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        
        // 停止音量数据流
        await levelProvider.stopStream()
        
        // 计算录音时长
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        print("[AudioPipeline] 录音时长: \(String(format: "%.2f", duration)) 秒")
        
        // 检查时长限制
        if duration > Double(maxDurationSeconds) {
            throw AudioError.durationExceeded(maxSeconds: maxDurationSeconds)
        }
        
        // 检查录音数据
        guard !audioDataBuffer.isEmpty else {
            throw AudioError.encodingFailed("未捕获到音频数据")
        }
        
        print("[AudioPipeline] PCM 数据大小: \(audioDataBuffer.count) 字节")
        
        // 编码为 WAV 格式 (使用实际录音采样率，而非 AudioFormat 的目标采样率)
        let wavData = try await encoder.encode(
            pcmData: audioDataBuffer,
            sampleRate: inputSampleRate,
            channelCount: inputChannelCount,
            bitDepth: AudioFormat.wav.bitDepth
        )
        
        print("[AudioPipeline] WAV 数据大小: \(wavData.count) 字节 (\(wavData.count / 1024 / 1024) MB)")
        
        // 检查文件大小限制
        if wavData.count > maxFileSizeBytes {
            throw AudioError.fileSizeExceeded(maxMB: maxFileSizeBytes / 1024 / 1024)
        }
        
        // 清理缓冲区
        audioDataBuffer.removeAll()
        recordingStartTime = nil
        
        return wavData
    }
    
    func audioLevelStream() async -> AsyncStream<Float> {
        await levelProvider.createStream()
    }
    
    // MARK: - Private Methods
    
    /// 处理音频 buffer
    nonisolated private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // 更新音量数据 (用于波形动效)
        levelProvider.updateLevel(from: buffer)
        
        // 将 buffer 转换为 PCM 数据
        guard let channelData = buffer.floatChannelData else {
            return
        }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        var pcmData = Data(capacity: frameLength * channelCount * 2)
        
        // 转换为 Int16 PCM 数据
        for frame in 0..<frameLength {
            for channel in 0..<channelCount {
                let sample = channelData[channel][frame]
                
                // 归一化到 Int16 范围 (-32768 ~ 32767)
                let clampedSample = max(-1.0, min(1.0, sample))
                let int16Sample = Int16(clampedSample * 32767.0)
                
                withUnsafeBytes(of: int16Sample.littleEndian) { bytes in
                    pcmData.append(contentsOf: bytes)
                }
            }
        }
        
        // 异步追加数据到 buffer
        Task {
            await self.appendAudioData(pcmData)
        }
    }
    
    /// 追加音频数据到缓冲区
    private func appendAudioData(_ data: Data) {
        // 检查录音时长
        if let startTime = recordingStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            
            // 接近时长限制时自动停止
            if elapsed >= Double(maxDurationSeconds) {
                print("[AudioPipeline] ⚠️ 达到最大录音时长,自动停止")
                Task {
                    _ = try? await self.stopCapture()
                }
                return
            }
        }
        
        // 追加数据
        audioDataBuffer.append(data)
        
        // 检查文件大小
        if audioDataBuffer.count > maxFileSizeBytes {
            print("[AudioPipeline] ⚠️ 音频数据接近大小限制,自动停止")
            Task {
                _ = try? await self.stopCapture()
            }
        }
    }
}
