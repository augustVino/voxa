//
//  HotwordCorrectorTests.swift
//  Voxa
//
//  Phase 3: 热词校正单元测试
//

import XCTest
import SwiftData
@testable import Voxa

final class HotwordCorrectorTests: XCTestCase {

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

    // MARK: - 热词按 priority 降序应用

    func testCorrect_appliesHotwordsInPriorityDescendingOrder() throws {
        context.insert(Hotword(pattern: "foo", replacement: "F1", priority: 1))
        context.insert(Hotword(pattern: "foo", replacement: "F2", priority: 2))
        try context.save()

        let corrector = HotwordCorrector()
        corrector.reload(from: context)

        // 高优先级 2 应先于 1 应用，所以应得到 F2
        XCTAssertEqual(corrector.correct("foo"), "F2")
    }

    // MARK: - 不区分大小写替换

    func testCorrect_caseInsensitiveReplacement() throws {
        context.insert(Hotword(pattern: "hello", replacement: "Hi", priority: 0))
        try context.save()

        let corrector = HotwordCorrector()
        corrector.reload(from: context)

        XCTAssertEqual(corrector.correct("HELLO world"), "Hi world")
        XCTAssertEqual(corrector.correct("Hello"), "Hi")
    }

    // MARK: - 空文本返回空

    func testCorrect_emptyTextReturnsEmpty() throws {
        context.insert(Hotword(pattern: "x", replacement: "y", priority: 0))
        try context.save()

        let corrector = HotwordCorrector()
        corrector.reload(from: context)

        XCTAssertEqual(corrector.correct(""), "")
        XCTAssertEqual(corrector.correct("   "), "")
        XCTAssertEqual(corrector.correct("\n\t"), "")
    }

    // MARK: - 无热词时原样返回

    func testCorrect_noHotwordsReturnsOriginal() throws {
        let corrector = HotwordCorrector()
        corrector.reload(from: context)

        let input = "unchanged text"
        XCTAssertEqual(corrector.correct(input), input)
    }

    func testCorrect_neverReloadedReturnsOriginal() throws {
        let corrector = HotwordCorrector()
        // 未调用 reload
        XCTAssertEqual(corrector.correct("anything"), "anything")
    }
}
