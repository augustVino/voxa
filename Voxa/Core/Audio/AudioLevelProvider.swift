//
//  AudioLevelProvider.swift
//  Voxa
//
//  实时音量数据提供者 - 用于波形动效
//

import Foundation
@preconcurrency import AVFoundation

/// 实时音量数据提供者
/// 负责计算和提供归一化的音量数据流,用于波形动画
actor AudioLevelProvider {
    /// 音量数据流
    private var continuation: AsyncStream<Float>.Continuation?
    
    /// 音量平滑系数 (0.0 ~ 1.0)
    /// 值越大,音量变化越平滑
    private let smoothingFactor: Float = 0.3
    
    /// 上一次的音量值 (用于平滑处理)
    private var previousLevel: Float = 0.0
    
    /// 创建音量数据流
    /// - Returns: 归一化音量值流 (0.0 ~ 1.0)
    func createStream() -> AsyncStream<Float> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { await self?.stopStream() }
            }
        }
    }
    
    /// 更新音量数据
    /// - Parameter buffer: 音频 buffer
    nonisolated func updateLevel(from buffer: AVAudioPCMBuffer) {
        let level = calculateRMS(from: buffer)
        Task {
            await self.yieldLevel(level)
        }
    }
    
    /// 发送音量数据到流
    private func yieldLevel(_ level: Float) {
        let smoothedLevel = smoothLevel(level)
        continuation?.yield(smoothedLevel)
    }
    
    /// 停止音量数据流
    func stopStream() {
        continuation?.finish()
        continuation = nil
        previousLevel = 0.0
    }
    
    /// 计算 RMS (Root Mean Square) 音量
    /// - Parameter buffer: 音频 buffer
    /// - Returns: RMS 值 (0.0 ~ 1.0)
    nonisolated private func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else {
            return 0.0
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        guard frameLength > 0 else {
            return 0.0
        }
        
        var sum: Float = 0.0
        
        // 计算所有声道的平均 RMS
        for channel in 0..<channelCount {
            let channelPointer = channelData[channel]
            
            for frame in 0..<frameLength {
                let sample = channelPointer[frame]
                sum += sample * sample
            }
        }
        
        let meanSquare = sum / Float(frameLength * channelCount)
        let rms = sqrt(meanSquare)
        
        // 归一化到 0.0 ~ 1.0
        // 使用对数刻度以获得更好的视觉效果
        let normalized = min(max(rms * 5.0, 0.0), 1.0)
        
        return normalized
    }
    
    /// 平滑音量值
    /// - Parameter level: 当前音量值
    /// - Returns: 平滑后的音量值
    private func smoothLevel(_ level: Float) -> Float {
        let smoothed = previousLevel * smoothingFactor + level * (1.0 - smoothingFactor)
        previousLevel = smoothed
        return smoothed
    }
}
