//
//  AudioEncoder.swift
//  Voxa
//
//  音频编码器 - PCM 转 WAV 格式
//

import Foundation

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
