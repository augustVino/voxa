//
//  STTProviderType.swift
//  Voxa
//
//  STT 服务提供商类型枚举
//

import Foundation

/// STT 服务提供商类型
enum STTProviderType: String, CaseIterable, Identifiable, Codable {
    case zhipu = "zhipu"
    case openai = "openai"

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .zhipu: return "智谱 AI"
        case .openai: return "OpenAI Whisper"
        }
    }

    /// 默认 Base URL
    var defaultBaseURL: String {
        switch self {
        case .zhipu: return "https://open.bigmodel.cn/api/paas/v4/audio/transcriptions"
        case .openai: return "https://api.openai.com/v1/audio/transcriptions"
        }
    }

    /// 默认模型名称
    var defaultModel: String {
        switch self {
        case .zhipu: return "glm-asr-2512"
        case .openai: return "whisper-1"
        }
    }

    /// 是否支持流式识别
    var supportsStreaming: Bool {
        switch self {
        case .zhipu: return true
        case .openai: return false  // Whisper API 不支持流式
        }
    }
}

