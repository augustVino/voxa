// MARK: - KeyMonitor
// Phase 1 基础骨架 — 基于 NSEvent 的全局 Fn 键监听
// Phase 4: 集成 KeyboardShortcuts 库支持自定义快捷键

import Foundation
import AppKit
import KeyboardShortcuts

// MARK: - Events

/// KeyMonitor 产出的事件类型
enum KeyEvent: Sendable, Equatable {
    /// Fn 键按下
    case fnDown
    /// Fn 键释放
    case fnUp
    /// 自定义快捷键触发
    case shortcutTriggered
}

// MARK: - Protocol

/// 键盘事件监听器协议
///
/// 实现者负责：
/// 1. 监听全局 Fn 键按下/释放事件
/// 2. 以 AsyncStream 方式异步产出事件
/// 3. 以只读方式监听（不拦截、不修改原始事件）
///
/// 约束：
/// - 必须在 Accessibility 权限已授予后才能启动
/// - 启动和停止操作必须幂等
/// - 事件流在 stopMonitoring() 后应正常终止
protocol KeyMonitoring: Sendable {

    /// 事件流，消费者通过 for-await-in 接收事件
    var events: AsyncStream<KeyEvent> { get }

    /// 启动全局键盘事件监听
    /// - Throws: `KeyMonitorError` 如果监听器创建失败
    func startMonitoring() throws

    /// 停止监听并释放系统资源
    func stopMonitoring()
}

// MARK: - Implementation

/// 基于 NSEvent 的全局 Fn 键监听器 + KeyboardShortcuts 集成
///
/// 通过 `NSEvent.addGlobalMonitorForEvents` + `addLocalMonitorForEvents`
/// 监听 `.flagsChanged` 事件，检测 Fn/Globe (🌐) 键的按下与释放。
///
/// 在搭载 Globe 键的 Mac 上，macOS 会在底层拦截 Fn 键事件（用于切换输入法、
/// 显示 Emoji 等），NSEvent 是能可靠接收这些事件的机制。
final class KeyMonitor: KeyMonitoring, @unchecked Sendable {

    // MARK: - Properties

    /// 事件流
    let events: AsyncStream<KeyEvent>

    /// 用于向 AsyncStream 推送事件的 continuation
    private var continuation: AsyncStream<KeyEvent>.Continuation?

    /// Fn 键当前是否处于按下状态
    private var isFnCurrentlyPressed = false

    /// NSEvent 全局监听器（监听其他 App 中的事件）
    private var globalEventMonitor: Any?

    /// NSEvent 本地监听器（监听当前 App 中的事件）
    private var localEventMonitor: Any?

    /// KeyboardShortcuts 监听任务
    private var shortcutListenerTask: Task<Void, Never>?

    /// 监听运行状态
    private var isMonitoring = false

    // MARK: - Init

    init() {
        let (stream, continuation) = AsyncStream<KeyEvent>.makeStream()
        self.events = stream
        self.continuation = continuation
    }

    // MARK: - KeyMonitoring

    /// 启动全局键盘事件监听
    /// - Throws: `KeyMonitorError.monitorCreationFailed` 如果 NSEvent 监听器创建失败
    func startMonitoring() throws {
        guard !isMonitoring else {
            throw KeyMonitorError.alreadyMonitoring
        }

        // 全局监听：当用户在其他 App 中按下 Fn 键
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        // 本地监听：当菜单栏下拉时按下 Fn 键
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        guard globalEventMonitor != nil else {
            throw KeyMonitorError.monitorCreationFailed
        }

        // 启动自定义快捷键监听
        startShortcutListener()

        isMonitoring = true
    }

    /// 停止监听并释放系统资源
    func stopMonitoring() {
        if isMonitoring {
            if let monitor = globalEventMonitor {
                NSEvent.removeMonitor(monitor)
                globalEventMonitor = nil
            }
            if let monitor = localEventMonitor {
                NSEvent.removeMonitor(monitor)
                localEventMonitor = nil
            }
            shortcutListenerTask?.cancel()
            shortcutListenerTask = nil
            isMonitoring = false
        }

        continuation?.finish()
        continuation = nil
    }

    /// 启动自定义快捷键监听
    private func startShortcutListener() {
        shortcutListenerTask = Task { [weak self] in
            for await event in KeyboardShortcuts.events(for: .recordAudio) {
                // 只监听 keyUp 事件（按键释放时触发）
                if event == .keyUp {
                    self?.continuation?.yield(.shortcutTriggered)
                }
            }
        }
    }

    // MARK: - Private

    /// 处理 flagsChanged 事件，检测 Fn 键状态变化
    private func handleFlagsChanged(_ event: NSEvent) {
        let fnPressed = event.modifierFlags.contains(.function)

        guard fnPressed != isFnCurrentlyPressed else { return }

        isFnCurrentlyPressed = fnPressed
        continuation?.yield(fnPressed ? .fnDown : .fnUp)
    }

    deinit {
        stopMonitoring()
    }
}
