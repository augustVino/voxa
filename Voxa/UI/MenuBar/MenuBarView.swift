// MARK: - MenuBarView
// Phase 1 基础骨架 — Menu Bar 下拉菜单视图

import SwiftUI

/// Menu Bar 下拉菜单视图
///
/// 显示当前应用状态和基本操作选项。
/// Phase 1 仅包含状态显示、权限重试和退出按钮。
struct MenuBarView: View {
    let coordinator: AppLifecycleCoordinator

    var body: some View {
        Text(statusText)

        // 权限缺失状态 — 自动轮询中，用户也可手动操作
        if case .permissionRequired = coordinator.appState {
            Text("正在自动检测权限变化...")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("打开系统设置") {
                PermissionManager().openSystemPreferences()
            }
            Divider()
            Button("立即检测") {
                Task {
                    await coordinator.retryPermissions()
                }
            }
        }

        // 错误状态
        if case .error = coordinator.appState {
            Button("重试") {
                Task {
                    await coordinator.retryPermissions()
                }
            }
            Button("重启 Voxa") {
                relaunchApp()
            }
        }

        Divider()
        Button("退出 Voxa") {
            NSApplication.shared.terminate(nil)
        }
    }

    /// 根据 AppState 返回对应的状态文本
    private var statusText: String {
        switch coordinator.appState {
        case .launching:
            return "状态: 启动中"
        case .permissionRequired(let types):
            let names = types.map { type -> String in
                switch type {
                case .accessibility: return "辅助功能"
                case .microphone: return "麦克风"
                }
            }
            return "状态: 需要权限 (\(names.joined(separator: "、")))"
        case .ready:
            return "状态: 就绪"
        case .error(let message):
            return "状态: 错误 - \(message)"
        }
    }

    /// 重启应用
    ///
    /// 通过 NSWorkspace 重新打开自身 Bundle，然后终止当前进程。
    /// macOS Accessibility 权限变更后往往需要进程重启才能生效。
    private func relaunchApp() {
        let bundleURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true

        NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, _ in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
