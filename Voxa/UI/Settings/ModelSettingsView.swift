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
    @State private var sttProviderType: STTProviderType = .zhipu
    @State private var sttApiKey: String = ""
    @State private var sttBaseURL: String = ""
    @State private var sttModel: String = ""
    @State private var openaiSttBaseURL: String = ""
    @State private var openaiSttModel: String = ""
    @State private var llmApiKey: String = ""
    @State private var llmBaseURL: String = ""
    @State private var llmModel: String = ""
    @State private var polishingEnabled: Bool = false

    enum Field: Hashable {
        case sttApiKey, sttBaseURL, sttModel
        case openaiSttBaseURL, openaiSttModel
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
                Picker("提供商", selection: $sttProviderType) {
                    ForEach(STTProviderType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: sttProviderType) { oldValue, newValue in
                    // 切换提供商前先保存当前配置
                    if oldValue == .zhipu {
                        if !sttApiKey.isEmpty { settings.sttApiKey = sttApiKey }
                        if !sttBaseURL.isEmpty { settings.sttBaseURL = sttBaseURL }
                        if !sttModel.isEmpty { settings.sttModel = sttModel }
                    } else if oldValue == .openai {
                        if !sttApiKey.isEmpty { settings.openaiSttApiKey = sttApiKey }
                        if !openaiSttBaseURL.isEmpty { settings.openaiSttBaseURL = openaiSttBaseURL }
                        if !openaiSttModel.isEmpty { settings.openaiSttModel = openaiSttModel }
                    }

                    settings.sttProviderType = newValue
                    loadSTTConfig()
                }

                SecureField("API Key", text: $sttApiKey)
                    .focused($focusedField, equals: .sttApiKey)
                    .onSubmit { saveField(.sttApiKey) }

                if sttProviderType == .zhipu {
                    TextField("endpoint", text: $sttBaseURL, prompt: Text("https://open.bigmodel.cn/api/paas/v4/audio/transcriptions"))
                        .focused($focusedField, equals: .sttBaseURL)
                        .onSubmit { saveField(.sttBaseURL) }
                    TextField("模型名称", text: $sttModel)
                        .focused($focusedField, equals: .sttModel)
                        .onSubmit { saveField(.sttModel) }
                }

                if sttProviderType == .openai {
                    TextField("endpoint", text: $openaiSttBaseURL, prompt: Text("https://api.openai.com/v1/audio/transcriptions"))
                        .focused($focusedField, equals: .openaiSttBaseURL)
                        .onSubmit { saveField(.openaiSttBaseURL) }
                    TextField("模型名称", text: $openaiSttModel)
                        .focused($focusedField, equals: .openaiSttModel)
                        .onSubmit { saveField(.openaiSttModel) }
                }
            }
            Section("LLM（润色）") {
                Toggle("启用润色", isOn: $polishingEnabled)
                    .onChange(of: polishingEnabled) { _, _ in
                        settings.polishingEnabled = polishingEnabled
                    }

                if polishingEnabled {
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

            Section {
                Button(action: { saveAll() }) {
                    Text("保存配置")
                        .frame(maxWidth: .infinity)
                        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadSTTConfig()
            loadLLMConfig()
            polishingEnabled = settings.polishingEnabled
        }
    }

    /// 加载 STT 配置
    private func loadSTTConfig() {
        sttProviderType = settings.sttProviderType
        switch sttProviderType {
        case .zhipu:
            sttApiKey = settings.sttApiKey
            sttBaseURL = settings.sttBaseURL
            sttModel = settings.sttModel
        case .openai:
            sttApiKey = settings.openaiSttApiKey
            openaiSttBaseURL = settings.openaiSttBaseURL
            openaiSttModel = settings.openaiSttModel
        }
    }

    /// 加载 LLM 配置
    private func loadLLMConfig() {
        llmApiKey = settings.llmApiKey
        llmBaseURL = settings.llmBaseURL
        llmModel = settings.llmModel
    }

    /// 保存指定字段到 settings
    private func saveField(_ field: Field) {
        switch field {
        case .sttApiKey:
            switch sttProviderType {
            case .zhipu: settings.sttApiKey = sttApiKey
            case .openai: settings.openaiSttApiKey = sttApiKey
            }
        case .sttBaseURL:
            settings.sttBaseURL = sttBaseURL
        case .sttModel:
            settings.sttModel = sttModel
        case .openaiSttBaseURL:
            settings.openaiSttBaseURL = openaiSttBaseURL
        case .openaiSttModel:
            settings.openaiSttModel = openaiSttModel
        case .llmApiKey:
            settings.llmApiKey = llmApiKey
        case .llmBaseURL:
            settings.llmBaseURL = llmBaseURL
        case .llmModel:
            settings.llmModel = llmModel
        }
        focusedField = nil
    }

    /// 保存所有字段到 settings
    private func saveAll() {
        switch sttProviderType {
        case .zhipu:
            settings.sttApiKey = sttApiKey
            settings.sttBaseURL = sttBaseURL
            settings.sttModel = sttModel
        case .openai:
            settings.openaiSttApiKey = sttApiKey
            settings.openaiSttBaseURL = openaiSttBaseURL
            settings.openaiSttModel = openaiSttModel
        }
        settings.llmApiKey = llmApiKey
        settings.llmBaseURL = llmBaseURL
        settings.llmModel = llmModel
        focusedField = nil
    }
}

#Preview {
    ModelSettingsView()
}
