//
//  TextProcessorTests.swift
//  Voxa
//
//  Phase 3: 文本处理管道单元测试 — 顺序、无 Persona 跳过、润色失败降级、空输入
//

import XCTest
import SwiftData
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

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([Hotword.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        context = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - 管道顺序（先热词后润色）

    func testProcess_appliesHotwordThenPolish() async throws {
        context.insert(Hotword(pattern: "foo", replacement: "bar", priority: 0))
        try context.save()

        let corrector = HotwordCorrector()
        corrector.reload(from: context)

        let processor = TextProcessor(
            hotwordCorrector: corrector,
            promptProcessor: MockPromptProcessor(result: .success("polished")),
            getCurrentPrompt: { "system" }
        )
        let out = try await processor.process(rawText: "foo")
        XCTAssertEqual(out, "polished")
    }

    // MARK: - 无 Persona 或 activePersonaId 为空时跳过润色

    func testProcess_noPersonaReturnsCorrectedOnly() async throws {
        context.insert(Hotword(pattern: "x", replacement: "y", priority: 0))
        try context.save()

        let corrector = HotwordCorrector()
        corrector.reload(from: context)

        let processor = TextProcessor(
            hotwordCorrector: corrector,
            promptProcessor: MockPromptProcessor(result: .success("polished")),
            getCurrentPrompt: { nil }
        )
        let out = try await processor.process(rawText: "x")
        XCTAssertEqual(out, "y")
    }

    func testProcess_emptyPromptSkipsPolish() async throws {
        let corrector = HotwordCorrector()
        corrector.reload(from: context)

        let processor = TextProcessor(
            hotwordCorrector: corrector,
            promptProcessor: MockPromptProcessor(result: .success("polished")),
            getCurrentPrompt: { "" }
        )
        let out = try await processor.process(rawText: "hello")
        XCTAssertEqual(out, "hello")
    }

    // MARK: - 润色失败/超时/空响应时降级为热词文本

    func testProcess_polishFailureFallsBackToCorrected() async throws {
        context.insert(Hotword(pattern: "a", replacement: "b", priority: 0))
        try context.save()

        let corrector = HotwordCorrector()
        corrector.reload(from: context)

        let processor = TextProcessor(
            hotwordCorrector: corrector,
            promptProcessor: MockPromptProcessor(result: .failure(TextProcessingError.llmUnavailable("timeout"))),
            getCurrentPrompt: { "sys" }
        )
        let out = try await processor.process(rawText: "a")
        XCTAssertEqual(out, "b")
    }

    // MARK: - rawText 为空时返回空字符串

    func testProcess_emptyRawTextNoInject_returnsEmpty() async throws {
        let corrector = HotwordCorrector()
        let processor = TextProcessor(
            hotwordCorrector: corrector,
            promptProcessor: MockPromptProcessor(),
            getCurrentPrompt: { "sys" }
        )
        let out1 = try await processor.process(rawText: "")
        let out2 = try await processor.process(rawText: "   \n\t")
        XCTAssertEqual(out1, "")
        XCTAssertEqual(out2, "")
    }
}
