//
//  TextProcessingError.swift
//  Voxa
//
//  Phase 3: 文本处理错误类型
//

import Foundation

/// 文本处理相关错误
enum TextProcessingError: Error, Sendable {
    /// 未找到指定人设
    case personaNotFound(String)
    /// LLM 服务不可用（网络/超时/业务错误）
    case llmUnavailable(String)
    /// 其他业务错误
    case other(String)
}

extension TextProcessingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .personaNotFound(let id):
            return "未找到人设: \(id)"
        case .llmUnavailable(let message):
            return "润色服务不可用: \(message)"
        case .other(let message):
            return message
        }
    }
}
