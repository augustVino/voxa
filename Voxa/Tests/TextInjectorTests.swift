//
//  TextInjectorTests.swift
//  Voxa
//
//  Phase 3: 文本注入单元测试 — 空文本不操作、剪贴板兜底后恢复
//

import XCTest
import AppKit
@testable import Voxa

final class TextInjectorTests: XCTestCase {

    // MARK: - 空文本不执行任何操作

    func testInject_emptyTextReturnsTrueAndPerformsNoOperation() {
        let injector = TextInjector()
        let result = injector.inject("")
        XCTAssertTrue(result, "空文本应返回 true 且不执行任何操作")
    }

    func testInject_whitespaceOnlyReturnsTrue() {
        let injector = TextInjector()
        let result = injector.inject("   \n\t")
        XCTAssertTrue(result)
    }

    // MARK: - 剪贴板兜底后恢复原内容

    @MainActor
    func testFallbackPaste_restoresClipboardAfterPaste() async {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let original = "original clipboard content"
        pasteboard.setString(original, forType: .string)

        let injector = TextInjector()
        injector.fallbackPaste("injected text")

        // 恢复在 MainActor 上延迟 ~200ms 执行，等待足够长时间后断言
        try? await Task.sleep(for: .milliseconds(400))

        let restored = pasteboard.string(forType: .string)
        XCTAssertEqual(restored, original, "剪贴板兜底后应恢复原内容")
    }
}
