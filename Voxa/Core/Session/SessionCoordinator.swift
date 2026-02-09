//
//  SessionCoordinator.swift
//  Voxa
//
//  会话状态机 - 协调录音、STT 和 UI 的完整流程
//

import Foundation

/// 会话状态
enum SessionState: Equatable, Sendable {
    /// 空闲状态
    case idle

    /// 录音中
    case recording

    /// 识别中
    case transcribing

    /// 处理中（热词/润色）
    case processing

    /// 注入中
    case injecting

    /// 错误状态
    case error(String)
}

/// 会话协调器
/// 负责协调 KeyMonitor、AudioPipeline、STTProvider 和 OverlayPanel
@Observable
final class SessionCoordinator: @unchecked Sendable {
    // MARK: - Dependencies

    private let keyMonitor: KeyMonitoring
    private let audioPipeline: AudioCapturing
    private var sttProvider: STTProvider
    private let settings: AppSettings
    private var overlay: (any OverlayPresenting)?
    private let textProcessor: TextProcessor
    private let textInjector: TextInjector
    /// 在文本处理前刷新热词（由调用方在 MainActor 上执行，可捕获 ModelContainer）
    private let reloadHotwords: () async -> Void
    /// Phase 4: 会话成功后保存历史记录（rawText, processedText, duration）；内部可做 30 天清理
    private let saveHistory: ((String, String, TimeInterval) async -> Void)?

    // MARK: - State

    private(set) var state: SessionState = .idle
    private(set) var lastTranscribedText: String = ""

    /// 事件消费任务
    private var eventTask: Task<Void, Never>?
    /// Phase 4: 热词刷新通知观察（设置页增删改热词后发送）
    private var reloadHotwordsObserver: Any?

    // MARK: - Initialization

    init(
        keyMonitor: KeyMonitoring,
        audioPipeline: AudioCapturing,
        sttProvider: STTProvider,
        settings: AppSettings,
        overlay: (any OverlayPresenting)? = nil,
        textProcessor: TextProcessor,
        textInjector: TextInjector,
        reloadHotwords: @escaping () async -> Void,
        saveHistory: ((String, String, TimeInterval) async -> Void)? = nil
    ) {
        self.keyMonitor = keyMonitor
        self.audioPipeline = audioPipeline
        self.sttProvider = sttProvider
        self.settings = settings
        self.overlay = overlay
        self.textProcessor = textProcessor
        self.textInjector = textInjector
        self.reloadHotwords = reloadHotwords
        self.saveHistory = saveHistory
    }

    // MARK: - Lifecycle

    /// 启动会话协调器
    func start() {
        print("[SessionCoordinator] 启动会话协调器")

        // 启动事件消费循环
        eventTask = Task {
            await consumeKeyEvents()
        }
        // Phase 4: 设置页热词增删改后刷新
        reloadHotwordsObserver = NotificationCenter.default.addObserver(
            forName: .voxaReloadHotwords,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.reloadHotwords() }
        }
    }

    /// 停止会话协调器
    func stop() {
        print("[SessionCoordinator] 停止会话协调器")

        eventTask?.cancel()
        eventTask = nil
        if let o = reloadHotwordsObserver {
            NotificationCenter.default.removeObserver(o)
            reloadHotwordsObserver = nil
        }

        // 清理状态
        state = .idle
        lastTranscribedText = ""
    }

    /// 设置录音浮窗 (需在 MainActor 上创建 OverlayPanel 后调用)
    func setOverlay(_ overlay: (any OverlayPresenting)?) {
        self.overlay = overlay
    }

    // MARK: - Private Methods

    /// 消费 KeyMonitor 事件
    private func consumeKeyEvents() async {
        for await event in keyMonitor.events {
            switch event {
            case .fnDown:
                await handleFnDown()
            case .fnUp:
                await handleFnUp()
            case .shortcutTriggered:
                // 自定义快捷键：切换录音状态（空闲时开始，录音中时停止）
                if state == .idle {
                    await handleFnDown()
                } else if state == .recording {
                    await handleFnUp()
                }
            }
        }
    }

    /// 处理 Fn 键按下
    private func handleFnDown() async {
        guard state == .idle else {
            print("[SessionCoordinator] ⚠️ 当前状态不是 idle,忽略 Fn Down")
            return
        }

        print("[SessionCoordinator] 🎤 Fn 键按下,开始录音")
        state = .recording

        // 先显示浮窗，再启动录音，避免首次 startCapture（AVAudioEngine 冷启动）过慢导致长时间无反馈
        if let overlay = overlay {
            let position = await MainActor.run { settings.overlayPosition }
            await overlay.show(at: position, animated: true)
        }

        do {
            try await audioPipeline.startCapture()

            if let overlay = overlay {
                let stream = await audioPipeline.audioLevelStream()
                await overlay.setLevelStream(stream)
            }
        } catch {
            print("[SessionCoordinator] ❌ 录音启动失败: \(error)")
            state = .error(error.localizedDescription)
            await overlay?.hide(animated: true)

            Task {
                try? await Task.sleep(for: .seconds(2))
                await recoverToIdle()
            }
        }
    }

    /// 处理 Fn 键释放
    private func handleFnUp() async {
        guard state == .recording else {
            print("[SessionCoordinator] ⚠️ 当前状态不是 recording,忽略 Fn Up")
            return
        }

        print("[SessionCoordinator] 🛑 Fn 键释放,停止录音")

        // 先更新浮窗状态为「识别中」
        await overlay?.updateStatus("识别中...")

        do {
            // 停止录音并获取音频数据 (会结束音量流)
            let audioData = try await audioPipeline.stopCapture()

            // 检查录音时长
            guard audioData.count > 1000 else {
                print("[SessionCoordinator] ⚠️ 录音时长过短,忽略")
                state = .idle
                await overlay?.hide(animated: true)
                return
            }

            // 开始识别 (识别完成后会隐藏浮窗)
            await performTranscription(audioData: audioData)

        } catch {
            print("[SessionCoordinator] ❌ 停止录音失败: \(error)")
            state = .error(error.localizedDescription)
            await overlay?.hide(animated: true)

            Task {
                try? await Task.sleep(for: .seconds(2))
                await recoverToIdle()
            }
        }
    }

    /// 执行语音识别
    private func performTranscription(audioData: Data) async {
        // 检查 STT 配置并更新 provider
        let isConfigured = await settings.isSTTConfigured
        guard isConfigured else {
            print("[SessionCoordinator] ❌ STT 未配置")
            state = .error("请先配置 STT API Key")
            await overlay?.hide(animated: true)
            Task {
                try? await Task.sleep(for: .seconds(2))
                await recoverToIdle()
            }
            return
        }

        // 使用最新的 API Key 创建 provider
        let apiKey = await settings.sttApiKey
        sttProvider = ZhipuSTTProvider(apiKey: apiKey)

        print("[SessionCoordinator] 🔄 开始语音识别...")
        state = .transcribing
        let sessionStart = Date()

        do {
            let streamingEnabled = await settings.streamingEnabled
            let text = try await sttProvider.transcribe(
                audioData: audioData,
                streaming: streamingEnabled,
                customWords: nil
            )

            print("[SessionCoordinator] ✅ 识别完成: \(text)")
            lastTranscribedText = text

            await reloadHotwords()
            state = .processing
            await overlay?.updateStatus("处理中...")

            let finalText: String
            do {
                finalText = try await textProcessor.process(rawText: text)
            } catch {
                print("[SessionCoordinator] ❌ 文本处理失败: \(error)")
                state = .error("处理失败")
                await overlay?.hide(animated: true)
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    await recoverToIdle()
                }
                return
            }

            if finalText.isEmpty {
                state = .idle
                await overlay?.hide(animated: true)
                return
            }

            state = .injecting
            await overlay?.updateStatus("注入中...")

            let injected = textInjector.inject(finalText)
            if !injected {
                state = .error("注入失败")
                await overlay?.hide(animated: true)
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    await recoverToIdle()
                }
                return
            }

            let duration = Date().timeIntervalSince(sessionStart)
            if let saveHistory = saveHistory {
                await saveHistory(text, finalText, duration)
            }
            state = .idle
            await overlay?.hide(animated: true)

        } catch let error as STTError {
            print("[SessionCoordinator] ❌ 识别失败: \(error)")

            switch error {
            case .unauthorized:
                state = .error("API Key 无效,请检查配置")
            case .timeout:
                state = .error("网络超时,请检查网络连接")
            case .networkError:
                state = .error("网络错误,请检查网络连接")
            case .serviceUnavailable:
                state = .error("STT 服务暂时不可用")
            default:
                state = .error(error.localizedDescription)
            }

            await overlay?.hide(animated: true)
            // 2 秒后自动恢复到 idle
            Task {
                try? await Task.sleep(for: .seconds(2))
                await recoverToIdle()
            }

        } catch {
            print("[SessionCoordinator] ❌ 未知错误: \(error)")
            state = .error(error.localizedDescription)
            await overlay?.hide(animated: true)

            // 2 秒后自动恢复到 idle
            Task {
                try? await Task.sleep(for: .seconds(2))
                await recoverToIdle()
            }
        }
    }

    /// 恢复到 idle 状态
    private func recoverToIdle() async {
        if case .error = state {
            print("[SessionCoordinator] 🔄 从错误状态恢复到 idle")
            state = .idle
        }
    }

    deinit {
        stop()
    }
}
