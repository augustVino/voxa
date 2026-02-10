//
//  ModelSettingsView.swift
//  Voxa
//
//  Phase 4: 模型设置页 — STT/LLM API Key、Base URL、模型名（脱敏）
//

import SwiftUI

/// 模型设置：STT 与 LLM 的 API Key、Base URL、模型名称；API Key 脱敏显示
struct ModelSettingsView: View {
    @State private var settings = AppSettings.shared
    @FocusState private var focusedField: Field?

    // 本地状态变量，避免直接绑定导致的 ViewBridge 警告
    @State private var sttApiKey: String = ""
    @State private var sttBaseURL: String = ""
    @State private var sttModel: String = ""
    @State private var llmApiKey: String = ""
    @State private var llmBaseURL: String = ""
    @State private var llmModel: String = ""

    enum Field: Hashable {
        case sttApiKey, sttBaseURL, sttModel
        case llmApiKey, llmBaseURL, llmModel
    }

    var body: some View {
        Form {
            Section {
                Text("未配置 API Key 将导致识别/润色失败。请在下方填写并保存。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("STT（语音识别）") {
                SecureField("API Key", text: $sttApiKey)
                    .focused($focusedField, equals: .sttApiKey)
                    .onSubmit { saveField(.sttApiKey) }
                TextField("endpoint", text: $sttBaseURL, prompt: Text("https://api.example.com/v1/audio/transcriptions"))
                    .focused($focusedField, equals: .sttBaseURL)
                    .onSubmit { saveField(.sttBaseURL) }
                TextField("模型名称", text: $sttModel)
                    .focused($focusedField, equals: .sttModel)
                    .onSubmit { saveField(.sttModel) }
            }
            Section("LLM（润色）") {
                SecureField("API Key", text: $llmApiKey)
                    .focused($focusedField, equals: .llmApiKey)
                    .onSubmit { saveField(.llmApiKey) }
                TextField("Base URL", text: $llmBaseURL, prompt: Text("https://api.openai.com/v1"))
                    .focused($focusedField, equals: .llmBaseURL)
                    .onSubmit { saveField(.llmBaseURL) }
                TextField("模型名称", text: $llmModel)
                    .focused($focusedField, equals: .llmModel)
                    .onSubmit { saveField(.llmModel) }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            // 从 settings 初始化本地状态
            sttApiKey = settings.sttApiKey
            sttBaseURL = settings.sttBaseURL
            sttModel = settings.sttModel
            llmApiKey = settings.llmApiKey
            llmBaseURL = settings.llmBaseURL
            llmModel = settings.llmModel
        }
    }

    /// 保存指定字段到 settings
    private func saveField(_ field: Field) {
        switch field {
        case .sttApiKey:
            settings.sttApiKey = sttApiKey
        case .sttBaseURL:
            settings.sttBaseURL = sttBaseURL
        case .sttModel:
            settings.sttModel = sttModel
        case .llmApiKey:
            settings.llmApiKey = llmApiKey
        case .llmBaseURL:
            settings.llmBaseURL = llmBaseURL
        case .llmModel:
            settings.llmModel = llmModel
        }
        focusedField = nil
    }
}

#Preview {
    ModelSettingsView()
}
