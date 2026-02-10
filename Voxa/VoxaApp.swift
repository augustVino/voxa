// MARK: - VoxaApp
// Phase 1 基础骨架 — App 入口 + 生命周期状态管理
// Phase 3: ModelContainer 注入 (Persona, InputHistory)

import SwiftUI
import SwiftData

// MARK: - State

/// 应用全局运行状态
///
/// Phase 1 状态流转：
/// launching → permissionRequired / ready
/// permissionRequired → ready
/// ready → error
/// error → permissionRequired
enum AppState: Sendable, Equatable {
    /// 应用正在初始化
    case launching

    /// 缺少必要权限，携带缺失权限类型列表
    case permissionRequired([PermissionType])

    /// 所有权限就绪，KeyMonitor 已启动，应用处于工作状态
    case ready

    /// 发生运行时错误
    case error(String)
}

// MARK: - Protocol

/// 应用生命周期协调器协议
///
/// 实现者负责：
/// 1. 管理应用启动流程（权限检测 → KeyMonitor 启动）
/// 2. 维护全局 AppState 状态
/// 3. 协调权限变更时的状态转换
///
/// 约束：
/// - 状态变更必须遵循定义的状态转换图
/// - 状态必须通过 Observation 框架可观测（@Observable）
/// - 启动流程不得阻塞主线程
@MainActor
protocol AppLifecycleCoordinating: AnyObject {

    /// 当前应用状态（可观测）
    var appState: AppState { get }

    /// 执行应用启动流程
    func initialize() async

    /// 重新检测权限并尝试恢复到 ready 状态
    func retryPermissions() async
}

// MARK: - AppLifecycleCoordinator

/// 应用生命周期协调器
///
/// 管理启动流程：权限检测 → KeyMonitor 启动 → 事件消费
/// 使用 @Observable 提供状态可观测性
@MainActor
@Observable
final class AppLifecycleCoordinator: AppLifecycleCoordinating {

    // MARK: - Properties

    /// 当前应用状态
    var appState: AppState = .launching

    /// 权限管理器
    private let permissionManager: PermissionChecking

    /// 键盘事件监听器
    private let keyMonitor: KeyMonitoring

    /// 事件消费 Task
    private var eventConsumptionTask: Task<Void, Never>?

    /// 权限轮询 Task
    private var permissionPollingTask: Task<Void, Never>?

    // MARK: - Init

    init(permissionManager: PermissionChecking, keyMonitor: KeyMonitoring) {
        self.permissionManager = permissionManager
        self.keyMonitor = keyMonitor
    }

    // MARK: - AppLifecycleCoordinating

    /// 执行应用启动流程
    ///
    /// 1. 检测所有必要权限
    /// 2. 权限就绪则启动 KeyMonitor
    /// 3. 权限缺失则进入 permissionRequired 状态，并启动自动轮询
    func initialize() async {
        let statuses = await permissionManager.checkAllPermissions()
        let missingPermissions = statuses
            .filter { !$0.isGranted }
            .map(\.type)

        if !missingPermissions.isEmpty {
            appState = .permissionRequired(missingPermissions)

            // 如果缺少 Accessibility 权限，弹出系统提示
            if missingPermissions.contains(.accessibility) {
                _ = permissionManager.checkAccessibility(prompt: true)
            }

            // 启动权限变化自动轮询
            startPermissionPolling()
            return
        }

        // 权限就绪，停止轮询并启动监听
        stopPermissionPolling()
        await startKeyMonitoring()
    }

    /// 重新检测权限并尝试恢复到 ready 状态
    func retryPermissions() async {
        appState = .launching
        await initialize()
    }

    // MARK: - Permission Polling

    /// 启动权限变化轮询
    ///
    /// 每 2 秒检测一次权限状态，当权限全部就绪时自动启动 KeyMonitor。
    /// macOS 不提供 Accessibility 权限变更通知，轮询是唯一可靠的检测方式。
    private func startPermissionPolling() {
        guard permissionPollingTask == nil else { return }

        permissionPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))

                guard !Task.isCancelled, let self else { return }

                let shouldPoll: Bool
                switch self.appState {
                case .permissionRequired, .error:
                    shouldPoll = true
                case .ready, .launching:
                    shouldPoll = false
                }
                guard shouldPoll else { return }

                let statuses = await self.permissionManager.checkAllPermissions()
                let allGranted = statuses.allSatisfy(\.isGranted)

                if allGranted {
                    self.stopPermissionPolling()
                    await self.startKeyMonitoring()
                    return
                }
            }
        }
    }

    /// 停止权限轮询
    private func stopPermissionPolling() {
        permissionPollingTask?.cancel()
        permissionPollingTask = nil
    }

    // MARK: - Key Monitoring

    /// 启动 KeyMonitor 并开始消费事件
    private func startKeyMonitoring() async {
        do {
            try keyMonitor.startMonitoring()
            // Phase 2: 事件消费由 SessionCoordinator 接管
            appState = .ready
        } catch let error as KeyMonitorError {
            switch error {
            case .monitorCreationFailed:
                appState = .error("Fn 键监听启动失败，请检查辅助功能权限")
                _ = permissionManager.checkAccessibility(prompt: true)
                startPermissionPolling()
            case .alreadyMonitoring:
                break
            }
        } catch {
            appState = .error(error.localizedDescription)
        }
    }

    nonisolated deinit {
        // Tasks 会在 coordinator 释放时自然取消
    }
}

// MARK: - macOS Version Check

/// 检测 macOS 版本是否满足最低要求（macOS 14 Sonoma）
@MainActor
private func checkMacOSVersion() -> Bool {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    return version.majorVersion >= 14
}

/// 显示 macOS 版本不兼容警告并退出
@MainActor
private func showVersionAlert() {
    let alert = NSAlert()
    alert.messageText = "系统版本不支持"
    alert.informativeText = "Voxa 需要 macOS 14 (Sonoma) 或更高版本。"
    alert.alertStyle = .critical
    alert.addButton(withTitle: "退出")
    alert.runModal()
    NSApplication.shared.terminate(nil)
}

// MARK: - App Entry Point

@main
struct VoxaApp: App {
    @State private var coordinator: AppLifecycleCoordinator
    @State private var sessionCoordinator: SessionCoordinator
    /// Phase 3: SwiftData 容器（人设、输入历史）
    private let modelContainer: ModelContainer

    init() {
        // Phase 3: 创建 ModelContainer，schema 包含 Persona, InputHistory
        do {
            let schema = Schema([Persona.self, InputHistory.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 初始化失败: \(error)")
        }
        let permissionManager = PermissionManager()
        let keyMonitor = KeyMonitor()
        let coord = AppLifecycleCoordinator(
            permissionManager: permissionManager,
            keyMonitor: keyMonitor
        )
        self._coordinator = State(initialValue: coord)

        // Phase 3: 文本处理与注入依赖
        let settings = AppSettings.shared
        let promptProcessor = PromptProcessor(
            apiKey: settings.llmApiKey,
            baseURL: settings.llmBaseURL,
            model: settings.llmModel
        )
        let getCurrentPrompt: () async -> String? = { [modelContainer] in
            await MainActor.run {
                let id = AppSettings.shared.activePersonaId
                guard !id.isEmpty else { return nil }
                let ctx = ModelContext(modelContainer)
                var descriptor = FetchDescriptor<Persona>()
                descriptor.predicate = #Predicate<Persona> { $0.id == id }
                let list = (try? ctx.fetch(descriptor)) ?? []
                return list.first?.prompt
            }
        }
        let textProcessor = TextProcessor(
            promptProcessor: promptProcessor,
            getCurrentPrompt: getCurrentPrompt
        )
        let textInjector = TextInjector()

        // Phase 4: 会话成功后保存历史并执行 30 天清理
        let saveHistory: (String, String, TimeInterval) async -> Void = { [modelContainer] rawText, processedText, duration in
            await MainActor.run {
                let ctx = ModelContext(modelContainer)
                let personaId = AppSettings.shared.activePersonaId
                var personaName: String?
                if !personaId.isEmpty {
                    var fd = FetchDescriptor<Persona>()
                    fd.predicate = #Predicate<Persona> { $0.id == personaId }
                    personaName = (try? ctx.fetch(fd).first)?.name
                }
                let record = InputHistory(
                    rawText: rawText,
                    processedText: processedText,
                    personaName: personaName,
                    duration: duration
                )
                ctx.insert(record)
                try? ctx.save()
                InputHistoryCleanup.run(context: ctx)
            }
        }

        // Phase 2 + 3: SessionCoordinator (浮窗在 MainActor Task 中注入)
        let audioPipeline = AudioPipeline()
        let placeholderProvider = ZhipuSTTProvider(apiKey: "")
        let sessionCoord = SessionCoordinator(
            keyMonitor: keyMonitor,
            audioPipeline: audioPipeline,
            sttProvider: placeholderProvider,
            settings: settings,
            overlay: nil,
            textProcessor: textProcessor,
            textInjector: textInjector,
            saveHistory: saveHistory
        )
        self._sessionCoordinator = State(initialValue: sessionCoord)

        // 应用启动时立即初始化（捕获局部变量避免 escaping closure 捕获 self）
        let containerForStartup = modelContainer
        Task { @MainActor in
            guard checkMacOSVersion() else {
                showVersionAlert()
                return
            }

            // Phase 5: 在 MainActor 上创建录音浮窗并注入
            let overlayPanel = OverlayPanel()
            sessionCoord.setOverlay(overlayPanel)

            sessionCoord.start()
            await coord.initialize()
            // Phase 4: 同步开机自启动实际状态到设置
            LaunchAtLoginHelper.syncToSettings()
            // Phase 4: 同步 Dock 图标显示状态（直接内联）
            NSApp.setActivationPolicy(AppSettings.shared.showDockIcon ? .regular : .accessory)
            // Phase 4: 启动时执行一次 30 天历史清理
            let ctx = ModelContext(containerForStartup)
            InputHistoryCleanup.run(context: ctx)
        }
    }

    var body: some Scene {
        MenuBarExtra("Voxa", systemImage: "mic.circle.fill") {
            MenuBarView(
                coordinator: coordinator,
                sessionCoordinator: sessionCoordinator
            )
            .modelContainer(modelContainer)
        }
        // Phase 4: 设置面板，约 600×450，菜单栏「设置…」可打开
        Settings {
            SettingsView()
                .frame(minWidth: 600, minHeight: 450)
                .modelContainer(modelContainer)
        }
    }
}
