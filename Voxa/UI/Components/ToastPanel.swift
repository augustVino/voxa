//
//  ToastPanel.swift
//  Voxa
//
//  Toast 通知面板 - NSPanel 实现，不抢夺焦点
//

import AppKit
import SwiftUI

/// Toast 通知面板
/// 使用 NSPanel + .nonactivatingPanel 确保不抢夺当前应用焦点
@MainActor
final class ToastPanel: NSPanel, @unchecked Sendable {

    // MARK: - Properties

    private var hideTask: Task<Void, Never>?

    // MARK: - Init

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
    }

    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 50),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
    }

    // MARK: - Position

    /// 计算 Toast 居中显示在屏幕顶部的位置
    private func centerOrigin(for size: NSSize) -> NSPoint {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen = screen else {
            return NSPoint(x: 100, y: 100)
        }
        let visible = screen.visibleFrame
        let topMargin: CGFloat = 100

        return NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.maxY - topMargin - size.height
        )
    }
}

// MARK: - ToastPresenting

extension ToastPanel: ToastPresenting {

    func show(_ message: String, type: ToastType, duration: TimeInterval) async {
        // 取消之前的隐藏任务
        hideTask?.cancel()

        // 创建新的 Toast 视图
        let toastView = ToastView(message: message, type: type)

        let hostingView = NSHostingView(rootView: toastView)

        // 清除旧内容
        contentView?.removeFromSuperview()

        // 设置新内容
        contentView = hostingView

        // 使用 NSHostingView 的 fittingSize 计算大小
        hostingView.layoutSubtreeIfNeeded()
        let size = hostingView.fittingSize

        setContentSize(size)
        setFrameOrigin(centerOrigin(for: size))

        // 显示窗口
        orderFrontRegardless()

        // 设置自动隐藏
        hideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            await self?.hide()
        }
    }

    func hide() async {
        hideTask?.cancel()
        hideTask = nil
        orderOut(nil)
    }
}
