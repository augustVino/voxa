//
//  SettingsView.swift
//  Voxa
//
//  Phase 4: 设置面板容器 — 五 Tab：通用、模型、人设、热词、历史记录
//

import SwiftUI
import SwiftData

/// 设置面板主视图：TabView 包含五个分页
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("通用", systemImage: "gearshape") }
            ModelSettingsView()
                .tabItem { Label("模型", systemImage: "cpu") }
            PersonaSettingsView()
                .tabItem { Label("人设", systemImage: "person.crop.circle") }
            HotwordSettingsView()
                .tabItem { Label("热词", systemImage: "textformat") }
            HistorySettingsView()
                .tabItem { Label("历史记录", systemImage: "clock.arrow.circlepath") }
        }
        .frame(minWidth: 600, minHeight: 450)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Persona.self, Hotword.self, InputHistory.self], inMemory: true)
}
