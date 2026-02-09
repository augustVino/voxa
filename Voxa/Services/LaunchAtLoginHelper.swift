//
//  LaunchAtLoginHelper.swift
//  Voxa
//
//  Phase 4: 开机自启动 — 使用 SMAppService (macOS 13+) 注册/注销登录项
//

import Foundation
import ServiceManagement

/// 开机自启动：根据 AppSettings.launchAtLogin 与 SMAppService 同步
enum LaunchAtLoginHelper {

    /// 将当前系统登录项状态同步到 AppSettings.launchAtLogin（建议在应用启动时调用一次）
    @MainActor
    static func syncToSettings() {
        let status = SMAppService.mainApp.status
        let enabled: Bool
        switch status {
        case .enabled:
            enabled = true
        case .notRegistered, .notFound, .requiresApproval:
            enabled = false
        @unknown default:
            enabled = false
        }
        AppSettings.shared.launchAtLogin = enabled
    }

    /// 根据 enable 注册或注销登录项（异步操作）
    @MainActor
    static func apply(enable: Bool) async -> Bool {
        do {
            if enable {
                try await SMAppService.mainApp.register()
                print("[LaunchAtLoginHelper] ✅ 登录项注册成功")
            } else {
                try await SMAppService.mainApp.unregister()
                print("[LaunchAtLoginHelper] ✅ 登录项注销成功")
            }
            // 操作成功后同步状态
            syncToSettings()
            return true
        } catch {
            print("[LaunchAtLoginHelper] ❌ 登录项操作失败: \(error.localizedDescription)")
            // 失败时也同步状态，确保 UI 与系统状态一致
            syncToSettings()
            return false
        }
    }
}
