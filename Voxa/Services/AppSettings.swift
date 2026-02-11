//
//  AppSettings.swift
//  Voxa
//
//  应用配置管理 - 使用 @AppStorage 持久化配置
//

import Foundation
import SwiftUI

/// 应用配置管理
/// Phase 4 T019: API Key 存 Keychain，其余配置 UserDefaults
@Observable
@MainActor
final class AppSettings {

    // MARK: - 常量

    /// 内置默认人设的固定 ID
    static let builtinDefaultPersonaID = "builtin-default"

    /// 内置默认人设的名称
    static let builtinDefaultPersonaName = "默认风格"

    /// 内置默认人设的 Prompt
    static let builtinDefaultPersonaPrompt = "让文本保持自然、清晰、口语化的语气，同时更精炼易读，要把句尾的句号去掉。"
    // MARK: - STT 配置

    /// STT API Key (智谱 API)，存 Keychain
    private var _sttApiKeyCache: String = ""
    var sttApiKey: String {
        get {
            if _sttApiKeyCache.isEmpty, let k = KeychainService.get(key: .sttApiKey) {
                _sttApiKeyCache = k
            }
            return _sttApiKeyCache
        }
        set {
            KeychainService.set(key: .sttApiKey, value: newValue)
            _sttApiKeyCache = newValue
        }
    }

    /// STT 服务 Base URL
    @ObservationIgnored
    @AppStorage("sttBaseURL")
    var sttBaseURL: String = "https://open.bigmodel.cn/api/paas/v4/audio/transcriptions"

    /// STT 模型名称
    @ObservationIgnored
    @AppStorage("sttModel")
    var sttModel: String = "glm-asr-2512"

    /// 是否启用流式识别
    @ObservationIgnored
    @AppStorage("streamingEnabled")
    var streamingEnabled: Bool = true

    // MARK: - LLM 配置 (Phase 3 润色)

    /// LLM API Key（智谱等），存 Keychain
    private var _llmApiKeyCache: String = ""
    var llmApiKey: String {
        get {
            if _llmApiKeyCache.isEmpty, let k = KeychainService.get(key: .llmApiKey) {
                _llmApiKeyCache = k
            }
            return _llmApiKeyCache
        }
        set {
            KeychainService.set(key: .llmApiKey, value: newValue)
            _llmApiKeyCache = newValue
        }
    }

    /// LLM Base URL（OpenAI 协议兼容，系统自动拼接 /chat/completions）
    @ObservationIgnored
    @AppStorage("llmBaseURL")
    var llmBaseURL: String = "https://api.openai.com/v1"

    /// LLM 模型名称
    @ObservationIgnored
    @AppStorage("llmModel")
    var llmModel: String = "glm-4"

    /// 润色功能开关（默认关闭）
    @ObservationIgnored
    @AppStorage("polishingEnabled")
    var polishingEnabled: Bool = false

    /// 当前人设 ID，空表示不润色
    @ObservationIgnored
    @AppStorage("activePersonaId")
    var activePersonaId: String = ""

    // MARK: - 通用设置 (Phase 4)

    /// 是否启用 Fn 单键触发录音
    @ObservationIgnored
    @AppStorage("fnKeyEnabled")
    var fnKeyEnabled: Bool = true

    /// 备用快捷键（与 KeyboardShortcuts 一致格式，如 "⌃⌥Space"）
    @ObservationIgnored
    @AppStorage("customShortcut")
    var customShortcut: String = ""

    /// 开机自启动
    @ObservationIgnored
    @AppStorage("launchAtLogin")
    var launchAtLogin: Bool = false

    /// 显示 Dock 图标
    @ObservationIgnored
    @AppStorage("showDockIcon")
    var showDockIcon: Bool = false

    // MARK: - 浮窗配置

    /// 浮窗位置
    @ObservationIgnored
    @AppStorage("overlayPosition")
    private var overlayPositionRaw: String = "bottomCenter"

    var overlayPosition: OverlayPosition {
        get {
            OverlayPosition(rawValue: overlayPositionRaw) ?? .bottomCenter
        }
        set {
            overlayPositionRaw = newValue.rawValue
        }
    }

    // MARK: - 音频配置

    /// 录音最大时长 (秒)
    @ObservationIgnored
    @AppStorage("maxRecordingDuration")
    var maxRecordingDuration: Int = 30

    // MARK: - Validation

    /// 检查 STT 配置是否完整
    var isSTTConfigured: Bool {
        !sttApiKey.isEmpty && !sttBaseURL.isEmpty && !sttModel.isEmpty
    }

    /// 检查 LLM 配置是否完整（润色用）
    var isLLMConfigured: Bool {
        polishingEnabled && !llmApiKey.isEmpty && !llmBaseURL.isEmpty && !llmModel.isEmpty
    }

    // MARK: - Singleton

    static let shared = AppSettings()

    init() {
        KeychainService.migrateFromUserDefaultsIfNeeded()
        _sttApiKeyCache = KeychainService.get(key: .sttApiKey) ?? ""
        _llmApiKeyCache = KeychainService.get(key: .llmApiKey) ?? ""
    }
}
