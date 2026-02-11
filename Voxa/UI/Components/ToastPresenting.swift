//
//  ToastPresenting.swift
//  Voxa
//
//  Toast 展示协议定义
//

import Foundation

/// Toast 消息类型
public enum ToastType: Sendable {
    case error
    case warning
    case success
    case info
}

/// Toast 展示协议
/// 定义 Toast 通知的显示接口
public protocol ToastPresenting: Sendable {
    /// 显示 Toast
    /// - Parameters:
    ///   - message: 消息内容
    ///   - type: 消息类型
    ///   - duration: 显示时长（秒），默认 3 秒
    func show(_ message: String, type: ToastType, duration: TimeInterval) async

    /// 隐藏当前显示的 Toast
    func hide() async
}

// MARK: - Default Parameter Values

extension ToastPresenting {
    /// 显示 Toast（默认 3 秒，信息类型）
    func show(_ message: String) async {
        await show(message, type: .info, duration: 3.0)
    }

    /// 显示错误 Toast（默认 3 秒）
    func show(error message: String) async {
        await show(message, type: .error, duration: 3.0)
    }

    /// 显示警告 Toast（默认 3 秒）
    func show(warning message: String) async {
        await show(message, type: .warning, duration: 3.0)
    }

    /// 显示成功 Toast（默认 2 秒）
    func show(success message: String) async {
        await show(message, type: .success, duration: 2.0)
    }
}
