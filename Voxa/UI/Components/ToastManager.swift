//
//  ToastManager.swift
//  Voxa
//
//  全局 Toast 管理器 - 单例模式，可在应用任何地方调用
//

import Foundation

/// 全局 Toast 管理器
/// 使用单例模式，可在应用任何地方调用显示 Toast
@MainActor
@Observable
public final class ToastManager {

    // MARK: - Singleton

    public static let shared = ToastManager()

    // MARK: - Properties

    private var panel: ToastPanel?

    // MARK: - Init

    private init() {
        panel = ToastPanel()
    }

    // MARK: - Public API

    /// 显示 Toast
    /// - Parameters:
    ///   - message: 消息内容
    ///   - type: 消息类型
    ///   - duration: 显示时长（秒），默认 3 秒
    public func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        Task {
            await panel?.show(message, type: type, duration: duration)
        }
    }

    /// 显示错误 Toast
    /// - Parameters:
    ///   - message: 错误消息
    ///   - duration: 显示时长（秒），默认 3 秒
    public func show(error message: String, duration: TimeInterval = 3.0) {
        show(message, type: .error, duration: duration)
    }

    /// 显示警告 Toast
    /// - Parameters:
    ///   - message: 警告消息
    ///   - duration: 显示时长（秒），默认 3 秒
    public func show(warning message: String, duration: TimeInterval = 3.0) {
        show(message, type: .warning, duration: duration)
    }

    /// 显示成功 Toast
    /// - Parameters:
    ///   - message: 成功消息
    ///   - duration: 显示时长（秒），默认 2 秒
    public func show(success message: String, duration: TimeInterval = 2.0) {
        show(message, type: .success, duration: duration)
    }

    /// 隐藏当前显示的 Toast
    public func hide() {
        Task {
            await panel?.hide()
        }
    }
}

// MARK: - Convenience Global API

/// 全局 Toast 便捷函数
public func Toast(
    _ message: String,
    type: ToastType = .info,
    duration: TimeInterval = 3.0
) {
    Task { @MainActor in
        ToastManager.shared.show(message, type: type, duration: duration)
    }
}

/// 全局 Toast 错误便捷函数
public func ToastError(_ message: String, duration: TimeInterval = 3.0) {
    Task { @MainActor in
        ToastManager.shared.show(error: message, duration: duration)
    }
}

/// 全局 Toast 警告便捷函数
public func ToastWarning(_ message: String, duration: TimeInterval = 3.0) {
    Task { @MainActor in
        ToastManager.shared.show(warning: message, duration: duration)
    }
}

/// 全局 Toast 成功便捷函数
public func ToastSuccess(_ message: String, duration: TimeInterval = 2.0) {
    Task { @MainActor in
        ToastManager.shared.show(success: message, duration: duration)
    }
}
