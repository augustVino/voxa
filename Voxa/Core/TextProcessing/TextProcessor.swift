//
//  TextProcessor.swift
//  Voxa
//
//  文本处理管道：可选 LLM 润色；润色失败时返回原文
//

import Foundation

/// 文本处理管道：可选润色；空输入不调用润色，润色失败降级为原文
/// 持有 getCurrentPrompt 闭包（可捕获 ModelContainer），故使用 @unchecked Sendable
final class TextProcessor: @unchecked Sendable {
    private let settings: AppSettings
    /// 获取当前人设的 system prompt；返回 nil 或空表示不润色（可在 MainActor 上读取 SwiftData）
    private let getCurrentPrompt: () async -> String?

    init(
        settings: AppSettings,
        getCurrentPrompt: @escaping () async -> String?
    ) {
        self.settings = settings
        self.getCurrentPrompt = getCurrentPrompt
    }

    /// 创建使用最新配置的 PromptProcessor
    private func makePromptProcessor() async -> PromptProcessor {
        await MainActor.run {
            PromptProcessor(
                apiKey: settings.llmApiKey,
                baseURL: settings.llmBaseURL,
                model: settings.llmModel
            )
        }
    }

    /// 处理原始文本：空/空白直接返回空；若有人设则尝试润色，失败或空结果则返回原文
    func process(rawText: String) async throws -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        // 检查润色开关是否启用
        let polishingEnabled = await MainActor.run { settings.polishingEnabled }
        if !polishingEnabled {
            print("[TextProcessor] ⚠️ 润色功能已关闭，直接返回原文")
            return trimmed
        }

        guard let systemPrompt = await getCurrentPrompt(), !systemPrompt.isEmpty else {
            print("[TextProcessor] ⚠️ 无 systemPrompt，跳过润色，返回原文")
            return trimmed
        }

        print("[TextProcessor] ✅ 获取到 systemPrompt: \(systemPrompt.prefix(50))...")
        print("[TextProcessor] 🚀 开始调用 LLM 润色...")

        do {
            // 使用最新配置创建 PromptProcessor
            let processor = await makePromptProcessor()
            let polished = try await processor.process(text: trimmed, systemPrompt: systemPrompt)
            print("[TextProcessor] ✨ 润色成功: \(polished)")
            return polished.isEmpty ? trimmed : polished
        } catch {
            print("[TextProcessor] ❌ 润色失败: \(error.localizedDescription)")
            return trimmed
        }
    }
}
