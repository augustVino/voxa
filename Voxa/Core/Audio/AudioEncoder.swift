//
//  AudioEncoder.swift
//  Voxa
//
//  音频编码器 - PCM 转 WAV 格式
//

import Foundation
@preconcurrency import AVFoundation

/// 音频编码器
/// 负责将 PCM 音频数据转换为 WAV 格式
actor AudioEncoder {
    /// 将 PCM 音频数据编码为 WAV 格式
    /// - Parameters:
    ///   - pcmData: PCM 原始音频数据
    ///   - sampleRate: 采样率 (Hz)
    ///   - channelCount: 声道数
    ///   - bitDepth: 位深度
    /// - Returns: WAV 格式音频数据
    /// - Throws: AudioError.encodingFailed
    func encode(
        pcmData: Data,
        sampleRate: Double,
        channelCount: Int,
        bitDepth: Int
    ) throws -> Data {
        guard bitDepth == 16 else {
            throw AudioError.encodingFailed("仅支持 16-bit PCM")
        }
        
        let dataSize = UInt32(pcmData.count)
        let byteRate = UInt32(sampleRate) * UInt32(channelCount) * UInt32(bitDepth / 8)
        let blockAlign = UInt16(channelCount * bitDepth / 8)
        
        var wavData = Data()
        
        // RIFF chunk descriptor
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(UInt32(36 + dataSize).littleEndianBytes)
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt sub-chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(UInt32(16).littleEndianBytes) // Subchunk1Size (16 for PCM)
        wavData.append(UInt16(1).littleEndianBytes)  // AudioFormat (1 = PCM)
        wavData.append(UInt16(channelCount).littleEndianBytes)
        wavData.append(UInt32(sampleRate).littleEndianBytes)
        wavData.append(byteRate.littleEndianBytes)
        wavData.append(blockAlign.littleEndianBytes)
        wavData.append(UInt16(bitDepth).littleEndianBytes)
        
        // data sub-chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(dataSize.littleEndianBytes)
        wavData.append(pcmData)
        
        return wavData
    }
    
    /// 重采样音频数据到目标采样率
    /// - Parameters:
    ///   - buffer: 原始音频 buffer
    ///   - targetSampleRate: 目标采样率
    /// - Returns: 重采样后的 PCM 数据
    nonisolated func resample(
        buffer: AVAudioPCMBuffer,
        to targetSampleRate: Double
    ) throws -> Data {
        let sourceFormat = buffer.format
        let sourceSampleRate = sourceFormat.sampleRate
        
        // 如果采样率已经匹配,直接转换
        if sourceSampleRate == targetSampleRate {
            return try convertBufferToData(buffer)
        }
        
        // 创建目标格式 (16kHz, 单声道, 16-bit PCM)
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioError.encodingFailed("无法创建目标音频格式")
        }
        
        // 创建转换器
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw AudioError.encodingFailed("无法创建音频转换器")
        }
        
        // 计算目标 buffer 容量
        let ratio = targetSampleRate / sourceSampleRate
        let targetFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        
        guard let targetBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: targetFrameCapacity
        ) else {
            throw AudioError.encodingFailed("无法创建目标 buffer")
        }
        
        // 执行转换
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        converter.convert(to: targetBuffer, error: &error, withInputFrom: inputBlock)
        
        if let error = error {
            throw AudioError.encodingFailed("音频转换失败: \(error.localizedDescription)")
        }
        
        return try convertBufferToData(targetBuffer)
    }
    
    /// 将 AVAudioPCMBuffer 转换为 Data
    nonisolated private func convertBufferToData(_ buffer: AVAudioPCMBuffer) throws -> Data {
        guard let channelData = buffer.int16ChannelData else {
            throw AudioError.encodingFailed("无法获取音频数据")
        }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        let bytesPerSample = 2 // 16-bit = 2 bytes
        
        var data = Data(capacity: frameLength * channelCount * bytesPerSample)
        
        for frame in 0..<frameLength {
            for channel in 0..<channelCount {
                let sample = channelData[channel][frame]
                withUnsafeBytes(of: sample.littleEndian) { bytes in
                    data.append(contentsOf: bytes)
                }
            }
        }
        
        return data
    }
}

// MARK: - Helper Extensions

private extension UInt32 {
    var littleEndianBytes: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}

private extension UInt16 {
    var littleEndianBytes: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
    }
}
