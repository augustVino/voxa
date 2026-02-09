//
//  STTError.swift
//  Voxa
//
//  语音转文字相关错误类型定义
//

import Foundation

/// STT (Speech-to-Text) 服务相关错误
enum STTError: Error, LocalizedError {
    /// 网络请求失败
    case networkError(underlying: Error)
    
    /// 网络超时
    case timeout
    
    /// API 认证失败 (401)
    case unauthorized
    
    /// API 请求频率超限 (429)
    case rateLimitExceeded
    
    /// API 服务不可用 (5xx)
    case serviceUnavailable(statusCode: Int)
    
    /// 无效的 API 响应
    case invalidResponse(String)
    
    /// JSON 解析失败
    case decodingFailed(underlying: Error)
    
    /// 音频文件无效
    case invalidAudioFile(String)
    
    /// API Key 未配置
    case missingAPIKey
    
    /// 流式识别中断
    case streamingInterrupted(String)
    
    /// 未知错误
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "网络请求失败: \(error.localizedDescription)"
        case .timeout:
            return "请求超时,请检查网络连接"
        case .unauthorized:
            return "API Key 无效或已过期,请检查配置"
        case .rateLimitExceeded:
            return "API 请求频率超限,请稍后重试"
        case .serviceUnavailable(let statusCode):
            return "STT 服务暂时不可用 (HTTP \(statusCode))"
        case .invalidResponse(let reason):
            return "无效的 API 响应: \(reason)"
        case .decodingFailed(let error):
            return "响应解析失败: \(error.localizedDescription)"
        case .invalidAudioFile(let reason):
            return "音频文件无效: \(reason)"
        case .missingAPIKey:
            return "未配置 API Key,请先配置 STT 服务"
        case .streamingInterrupted(let reason):
            return "流式识别中断: \(reason)"
        case .unknown(let error):
            return "未知 STT 错误: \(error.localizedDescription)"
        }
    }
}
