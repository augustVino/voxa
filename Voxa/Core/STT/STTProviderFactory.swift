//
//  STTProviderFactory.swift
//  Voxa
//
//  STT 提供商工厂
//

import Foundation

/// STT 提供商工厂
enum STTProviderFactory {
    /// 创建 STT 提供商实例
    static func createProvider(
        type: STTProviderType,
        apiKey: String,
        baseURL: String? = nil,
        model: String? = nil
    ) -> STTProvider {
        switch type {
        case .zhipu:
            return ZhipuSTTProvider(
                apiKey: apiKey,
                baseURL: baseURL ?? "https://open.bigmodel.cn/api/paas/v4/audio/transcriptions",
                model: model ?? "glm-asr-2512"
            )
        case .openai:
            return OpenAIWhisperProvider(
                apiKey: apiKey,
                baseURL: baseURL ?? "https://api.openai.com/v1/audio/transcriptions",
                model: model ?? "whisper-1"
            )
        }
    }
}
