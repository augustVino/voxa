//
//  TextProcessor.swift
//  Voxa
//
//  Phase 3: 管道「热词 → 可选 LLM 润色」；润色失败时降级为热词文本
//

import Foundation

/// 文本处理管道：热词校正 → 可选润色；空输入不调用润色，润色失败降级为热词结果
/// 持有 getCurrentPrompt 闭包（可捕获 ModelContainer），故使用 @unchecked Sendable
final class TextProcessor: @unchecked Sendable {
    private let hotwordCorrector: HotwordCorrector
    private let promptProcessor: any PromptProcessing
    /// 获取当前人设的 system prompt；返回 nil 或空表示不润色（可在 MainActor 上读取 SwiftData）
    private let getCurrentPrompt: () async -> String?

    init(
        hotwordCorrector: HotwordCorrector,
        promptProcessor: any PromptProcessing,
        getCurrentPrompt: @escaping () async -> String?
    ) {
        self.hotwordCorrector = hotwordCorrector
        self.promptProcessor = promptProcessor
        self.getCurrentPrompt = getCurrentPrompt
    }

    /// 处理原始文本：空/空白直接返回空；热词校正 → 若有人设则尝试润色，失败或空结果则用校正文本
    func process(rawText: String) async throws -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        let corrected = hotwordCorrector.correct(rawText)

        guard let systemPrompt = await getCurrentPrompt(), !systemPrompt.isEmpty else {
            return corrected
        }

        do {
            let polished = try await promptProcessor.process(text: corrected, systemPrompt: systemPrompt)
            return polished.isEmpty ? corrected : polished
        } catch {
            return corrected
        }
    }
}
