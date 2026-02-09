//
//  AudioFormat.swift
//  Voxa
//
//  音频格式枚举定义
//

import Foundation

/// 支持的音频格式
enum AudioFormat {
    /// WAV 格式 (PCM 16-bit, 16kHz, 单声道)
    /// 这是智谱 GLM-ASR-2512 STT 服务要求的格式
    case wav
    
    /// 文件扩展名
    var fileExtension: String {
        switch self {
        case .wav:
            return "wav"
        }
    }
    
    /// MIME 类型
    var mimeType: String {
        switch self {
        case .wav:
            return "audio/wav"
        }
    }
    
    /// 采样率 (Hz)
    var sampleRate: Double {
        switch self {
        case .wav:
            return 16000.0 // 16kHz
        }
    }
    
    /// 声道数
    var channelCount: Int {
        switch self {
        case .wav:
            return 1 // 单声道
        }
    }
    
    /// 位深度
    var bitDepth: Int {
        switch self {
        case .wav:
            return 16 // 16-bit
        }
    }
}
