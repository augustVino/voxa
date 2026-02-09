//
//  AudioError.swift
//  Voxa
//
//  音频相关错误类型定义
//

import Foundation

/// 音频采集和处理相关错误
enum AudioError: Error, LocalizedError {
    /// 音频引擎启动失败
    case engineStartFailed(underlying: Error)
    
    /// 音频引擎已在运行
    case engineAlreadyRunning
    
    /// 音频输入节点不可用
    case inputNodeUnavailable
    
    /// 音频格式不支持
    case unsupportedFormat(String)
    
    /// 音频数据编码失败
    case encodingFailed(String)
    
    /// 录音时长超限 (最大 30 秒)
    case durationExceeded(maxSeconds: Int)
    
    /// 文件大小超限 (最大 25 MB)
    case fileSizeExceeded(maxMB: Int)
    
    /// 音频设备不可用
    case deviceUnavailable
    
    /// 音频权限被拒绝
    case permissionDenied
    
    /// 音频质量过低
    case lowQuality(reason: String)
    
    /// 未知错误
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .engineStartFailed(let error):
            return "音频引擎启动失败: \(error.localizedDescription)"
        case .engineAlreadyRunning:
            return "音频引擎已在运行"
        case .inputNodeUnavailable:
            return "音频输入设备不可用"
        case .unsupportedFormat(let format):
            return "不支持的音频格式: \(format)"
        case .encodingFailed(let reason):
            return "音频编码失败: \(reason)"
        case .durationExceeded(let maxSeconds):
            return "录音时长超过限制 (\(maxSeconds) 秒)"
        case .fileSizeExceeded(let maxMB):
            return "音频文件大小超过限制 (\(maxMB) MB)"
        case .deviceUnavailable:
            return "音频设备不可用"
        case .permissionDenied:
            return "麦克风权限被拒绝"
        case .lowQuality(let reason):
            return "音频质量过低: \(reason)"
        case .unknown(let error):
            return "未知音频错误: \(error.localizedDescription)"
        }
    }
}
