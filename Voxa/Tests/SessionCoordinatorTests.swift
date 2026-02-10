//
//  SessionCoordinatorTests.swift
//  Voxa
//
//  Phase 3: SessionCoordinator 状态与依赖集成测试
//

import XCTest
import SwiftData
@testable import Voxa

final class SessionCoordinatorTests: XCTestCase {

    // MARK: - SessionState 包含 processing、injecting

    func testSessionState_includesProcessingAndInjecting() {
        let processing: SessionState = .processing
        let injecting: SessionState = .injecting
        XCTAssertEqual(processing, .processing)
        XCTAssertEqual(injecting, .injecting)
    }

    // MARK: - Coordinator 可使用 Phase 3 依赖构造

    @MainActor
    func testSessionCoordinator_createsWithTextProcessorAndInjector() async throws {
        let schema = Schema([Persona.self, InputHistory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let keyMonitor = KeyMonitor()
        let audioPipeline = AudioPipeline()
        let sttProvider = ZhipuSTTProvider(apiKey: "")
        let settings = AppSettings.shared
        let promptProcessor = PromptProcessor(
            apiKey: "",
            baseURL: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
            model: "glm-4"
        )
        let getCurrentPrompt: () async -> String? = { nil }
        let textProcessor = TextProcessor(
            promptProcessor: promptProcessor,
            getCurrentPrompt: getCurrentPrompt
        )
        let textInjector = TextInjector()

        let coordinator = SessionCoordinator(
            keyMonitor: keyMonitor,
            audioPipeline: audioPipeline,
            sttProvider: sttProvider,
            settings: settings,
            overlay: nil,
            textProcessor: textProcessor,
            textInjector: textInjector
        )

        XCTAssertEqual(coordinator.state, .idle)
    }
}
