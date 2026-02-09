// MARK: - PermissionManager
// Phase 1 基础骨架 — 权限检测与引导模块

import Foundation
@preconcurrency import ApplicationServices
import AVFoundation
import AppKit

// MARK: - Types

/// 应用所需的系统权限类型
enum PermissionType: String, Sendable, CaseIterable, Equatable {
    /// 辅助功能权限（Accessibility）
    /// 用途：CGEventTap 全局键盘事件监听
    case accessibility

    /// 麦克风权限（Microphone）
    /// 用途：语音录制（Phase 2 启用，Phase 1 预检测）
    case microphone
}

/// 单项权限的状态
struct PermissionStatus: Sendable, Equatable {
    /// 权限类型
    let type: PermissionType
    /// 是否已授权
    let isGranted: Bool
}

// MARK: - Protocol

/// 权限检测与管理协议
///
/// 实现者负责：
/// 1. 检测各项系统权限的当前授权状态
/// 2. 触发系统标准授权流程
/// 3. 提供跳转到系统设置的能力
///
/// 约束：
/// - 权限状态必须实时从系统 API 获取，不可缓存
/// - 检测方法必须是幂等的
/// - Accessibility 权限无系统变更通知，需主动查询
protocol PermissionChecking: Sendable {

    /// 检测 Accessibility 权限状态
    /// - Parameter prompt: 是否在未授权时弹出系统提示引导用户前往设置
    /// - Returns: 当前授权状态
    func checkAccessibility(prompt: Bool) -> Bool

    /// 请求麦克风权限
    /// - Returns: 用户是否授权
    func requestMicrophoneAccess() async -> Bool

    /// 检测所有必要权限的当前状态
    /// - Returns: 各项权限的状态列表
    func checkAllPermissions() async -> [PermissionStatus]

    /// 打开系统偏好设置中的安全与隐私面板
    func openSystemPreferences()
}

// MARK: - Implementation

/// 权限管理器：检测和管理 Accessibility 与 Microphone 权限
final class PermissionManager: PermissionChecking, @unchecked Sendable {

    // MARK: - PermissionChecking

    /// 检测 Accessibility 权限状态
    /// - Parameter prompt: 为 true 时弹出系统提示引导用户前往系统设置
    /// - Returns: 是否已授权
    func checkAccessibility(prompt: Bool) -> Bool {
        // 先用无参数版本检测（更可靠，不受 options dict 影响）
        let simpleTrusted = AXIsProcessTrusted()

        if prompt && !simpleTrusted {
            // 仅在需要提示且未授权时使用带选项的版本触发系统弹窗
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            _ = AXIsProcessTrustedWithOptions(options)
        }

        return simpleTrusted
    }

    /// 请求麦克风权限
    /// - Returns: 用户是否授权
    func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// 检测所有必要权限的当前状态
    /// - Returns: 各项权限的状态列表
    func checkAllPermissions() async -> [PermissionStatus] {
        let accessibilityGranted = checkAccessibility(prompt: false)
        let microphoneGranted = await requestMicrophoneAccess()

        return [
            PermissionStatus(type: .accessibility, isGranted: accessibilityGranted),
            PermissionStatus(type: .microphone, isGranted: microphoneGranted),
        ]
    }

    /// 打开系统偏好设置中的辅助功能面板
    func openSystemPreferences() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
