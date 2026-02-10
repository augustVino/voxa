//
//  TextProcessorTests.swift
//  Voxa
//
//  Phase 3: 文本处理管道单元测试 — 无 Persona 跳过、润色失败降级、空输入
//

import XCTest
@testable import Voxa

/// Mock 润色器：可配置返回或抛错
private struct MockPromptProcessor: PromptProcessing, Sendable {
    var result: Result<String, Error> = .success("polished")

    func process(text: String, systemPrompt: String) async throws -> String {
        switch result {
        case .success(let s): return s
        case .failure(let e): throw e
        }
    }
}

final class TextProcessorTests: XCTestCase {

    // MARK: - 无 Persona 或 activePersonaId 为空时跳过润色

    func testProcess_noPersonaReturnsOriginalText() async throws {
        let processor = TextProcessor(
            promptProcessor: MockPromptProcessor(result: .success("polished")),
            getCurrentPrompt: { nil }
        )
        let out = try await processor.process(rawText: "hello")
        XCTAssertEqual(out, "hello")
    }

    func testProcess_emptyPromptSkipsPolish() async throws {
        let processor = TextProcessor(
            promptProcessor: MockPromptProcessor(result: .success("polished")),
            getCurrentPrompt: { "" }
        )
        let out = try await processor.process(rawText: "hello")
        XCTAssertEqual(out, "hello")
    }

    // MARK: - 润色失败/超时/空响应时降级为原文

    func testProcess_polishFailureFallsBackToOriginal() async throws {
        let processor = TextProcessor(
            promptProcessor: MockPromptProcessor(result: .failure(TextProcessingError.llmUnavailable("timeout"))),
            getCurrentPrompt: { "sys" }
        )
        let out = try await processor.process(rawText: "hello")
        XCTAssertEqual(out, "hello")
    }

    // MARK: - rawText 为空时返回空字符串

    func testProcess_emptyRawTextNoInject_returnsEmpty() async throws {
        let processor = TextProcessor(
            promptProcessor: MockPromptProcessor(),
            getCurrentPrompt: { "sys" }
        )
        let out1 = try await processor.process(rawText: "")
        let out2 = try await processor.process(rawText: "   \n\t")
        XCTAssertEqual(out1, "")
        XCTAssertEqual(out2, "")
    }

    // MARK: - 润色成功返回润色结果

    func testProcess_polishSuccessReturnsPolished() async throws {
        let processor = TextProcessor(
            promptProcessor: MockPromptProcessor(result: .success("polished text")),
            getCurrentPrompt: { "sys" }
        )
        let out = try await processor.process(rawText: "original")
        XCTAssertEqual(out, "polished text")
    }
}
