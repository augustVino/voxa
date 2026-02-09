//
//  TextInjector.swift
//  Voxa
//
//  Phase 3: 通过 AX API 将文本插入当前焦点；失败时剪贴板粘贴并恢复原剪贴板
//

import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

/// 文本注入器：AX 写入当前焦点，失败时 Cmd+V 兜底并恢复剪贴板
final class TextInjector: Sendable {

    init() {}

    /// 注入文本到当前焦点。空文本返回 true 且不执行任何操作。
    /// - Returns: 是否成功（AX 成功或兜底成功为 true，完全失败为 false）
    func inject(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }

        if injectViaAX(trimmed) {
            return true
        }
        fallbackPaste(trimmed)
        return true
    }

    /// AX 路径：获取前台应用的焦点元素，可写则设置 kAXValueAttribute
    private func injectViaAX(_ text: String) -> Bool {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return false }
        let app = AXUIElementCreateApplication(pid)

        var element: CFTypeRef?
        let resultEl = AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &element)
        guard resultEl == .success, let uiEl = element, CFGetTypeID(uiEl) == AXUIElementGetTypeID() else { return false }
        let focusElement = (uiEl as! AXUIElement)

        var settable = DarwinBoolean(false)
        AXUIElementIsAttributeSettable(focusElement, kAXValueAttribute as CFString, &settable)
        guard settable.boolValue else { return false }
        let setResult = AXUIElementSetAttributeValue(focusElement, kAXValueAttribute as CFString, text as CFTypeRef)
        return setResult == .success
    }

    /// 剪贴板兜底：保存当前内容 → 写入 text → 模拟 Cmd+V → 延迟后恢复原剪贴板
    func fallbackPaste(_ text: String) {
        let pasteboard = NSPasteboard.general
        let existing = pasteboard.string(forType: .string) ?? ""

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        postCmdV()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            pasteboard.clearContents()
            pasteboard.setString(existing, forType: .string)
        }
    }

    /// 模拟按下 Cmd+V
    private func postCmdV() {
        let src = CGEventSource(stateID: .hidSystemState)
        let keyCodeV: CGKeyCode = 9
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyCodeV, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyCodeV, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
