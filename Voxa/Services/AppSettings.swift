//
//  AppSettings.swift
//  Voxa
//
//  应用配置管理 - 使用 @AppStorage 持久化配置
//

import Foundation
import SwiftUI

/// 应用配置管理
/// Phase 2 使用 UserDefaults 存储 API Key (临时方案)
/// Phase 4 迁移到 Keychain 加密存储
@Observable
@MainActor
final class AppSettings {
    // MARK: - STT 配置

    /// STT API Key (智谱 API)
    /// ⚠️ Phase 2 临时方案:使用 UserDefaults 明文存储
    /// Phase 4 改进:迁移到 Keychain
    @ObservationIgnored
    @AppStorage("sttApiKey")
    var sttApiKey: String = ""

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

    /// LLM API Key（智谱等）
    @ObservationIgnored
    @AppStorage("llmApiKey")
    var llmApiKey: String = ""

    /// LLM Base URL（智谱 GLM-4 对话）
    @ObservationIgnored
    @AppStorage("llmBaseURL")
    var llmBaseURL: String = "https://open.bigmodel.cn/api/paas/v4/chat/completions"

    /// LLM 模型名称
    @ObservationIgnored
    @AppStorage("llmModel")
    var llmModel: String = "glm-4"

    /// 当前人设 ID，空表示不润色
    @ObservationIgnored
    @AppStorage("activePersonaId")
    var activePersonaId: String = ""

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
        !llmApiKey.isEmpty && !llmBaseURL.isEmpty && !llmModel.isEmpty
    }

    // MARK: - Singleton

    static let shared = AppSettings()

    init() {}
}
