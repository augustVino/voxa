//
//  OverlayPanel.swift
//  Voxa
//
//  录音状态浮窗 - NSPanel 实现,不抢夺焦点
//

import AppKit
import SwiftUI

/// 录音状态浮窗面板
/// 使用 NSPanel + .nonactivatingPanel 确保不抢夺当前应用焦点
@MainActor
final class OverlayPanel: NSPanel, @unchecked Sendable {

    // MARK: - UI

    private let overlayState = OverlayState()
    private var levelStreamTask: Task<Void, Never>?

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
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false  // 自定义阴影在 SwiftUI 中处理
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false

        let hostingView = NSHostingView(rootView: RecordingOverlayView(state: overlayState))
        contentView = hostingView
    }

    // MARK: - Position

    /// 根据位置枚举计算浮窗原点 (多显示器: 使用主屏)
    private func frameOrigin(for position: OverlayPosition) -> NSPoint {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen = screen else {
            return NSPoint(x: 100, y: 20)
        }
        let visible = screen.visibleFrame
        let margin: CGFloat = 24

        switch position {
        case .bottomLeft:
            return NSPoint(x: visible.minX + margin, y: visible.minY + margin)
        case .bottomCenter:
            return NSPoint(
                x: visible.midX - frame.width / 2,
                y: visible.minY + margin
            )
        case .bottomRight:
            return NSPoint(
                x: visible.maxX - frame.width - margin,
                y: visible.minY + margin
            )
        }
    }
}

// MARK: - OverlayPresenting

extension OverlayPanel: OverlayPresenting {

    func show(at position: OverlayPosition, animated: Bool) async {
        await MainActor.run {
            overlayState.statusText = "聆听中..."
            overlayState.levels = Array(repeating: 0, count: OverlayState.barCountForOverlay)
            overlayState.partialResult = ""

            setFrameOrigin(frameOrigin(for: position))
            orderFrontRegardless()
        }
    }

    func hide(animated: Bool) async {
        await MainActor.run {
            levelStreamTask?.cancel()
            levelStreamTask = nil
            orderOut(nil)
        }
    }

    func updateStatus(_ text: String) async {
        await MainActor.run {
            overlayState.statusText = text
        }
    }

    func updatePartialResult(_ partialText: String) async {
        await MainActor.run {
            overlayState.partialResult = partialText
        }
    }

    func setLevelStream(_ stream: AsyncStream<Float>) async {
        await MainActor.run {
            levelStreamTask?.cancel()
            levelStreamTask = Task { [weak self, overlayState] in
                guard let self = self else { return }
                for await level in stream {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        var next = overlayState.levels
                        if next.count >= OverlayState.barCountForOverlay {
                            next = Array(next.dropFirst())
                        }
                        next.append(level)
                        overlayState.levels = next
                    }
                }
            }
        }
    }
}
