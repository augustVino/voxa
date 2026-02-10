//
//  GeneralSettingsView.swift
//  Voxa
//
//  Phase 4: 通用设置页 — 快捷键、动画位置、自启动、Dock
//

import SwiftUI
import AppKit
import KeyboardShortcuts

/// 通用设置：快捷键、录音动画位置、开机自启动、Dock 图标
struct GeneralSettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var isTogglingLaunchAtLogin = false

    var body: some View {
        Form {
            Section("快捷键") {
                Toggle("Fn 键触发录音", isOn: Binding(
                    get: { settings.fnKeyEnabled },
                    set: { settings.fnKeyEnabled = $0 }
                ))

                KeyboardShortcuts.Recorder("快捷键:", name: .recordAudio)

                Text("快捷键可与 Fn 键同时使用。打开设置时按 Fn 仍会触发录音。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("浮窗") {
                Picker("录音动画位置", selection: Binding(
                    get: { settings.overlayPosition },
                    set: { settings.overlayPosition = $0 }
                )) {
                    Text("左下").tag(OverlayPosition.bottomLeft)
                    Text("中下").tag(OverlayPosition.bottomCenter)
                    Text("右下").tag(OverlayPosition.bottomRight)
                }
                .pickerStyle(.segmented)
            }
            Section("启动与界面") {
                HStack {
                    Toggle("开机自启动", isOn: Binding(
                        get: { settings.launchAtLogin },
                        set: { newValue in
                            // 先乐观更新 UI
                            settings.launchAtLogin = newValue
                            // 异步应用设置
                            Task {
                                isTogglingLaunchAtLogin = true
                                let success = await LaunchAtLoginHelper.apply(enable: newValue)
                                isTogglingLaunchAtLogin = false
                                if !success {
                                    // 操作失败，恢复状态
                                    settings.launchAtLogin = !newValue
                                }
                            }
                        }
                    ))
                    .disabled(isTogglingLaunchAtLogin)
                    if isTogglingLaunchAtLogin {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                    }
                }
                Toggle("显示 Dock 图标", isOn: Binding(
                    get: { settings.showDockIcon },
                    set: { newValue in
                        settings.showDockIcon = newValue
                        // 直接设置 Dock 图标显示策略
                        NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                    }
                ))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    GeneralSettingsView()
}
