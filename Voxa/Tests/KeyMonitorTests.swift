// MARK: - KeyMonitorTests
// Phase 1 基础骨架 — KeyMonitor 单元测试

import XCTest
@testable import Voxa

final class KeyMonitorTests: XCTestCase {

    // MARK: - KeyEvent Tests

    func testKeyEvent_equatable() {
        XCTAssertEqual(KeyEvent.fnDown, KeyEvent.fnDown)
        XCTAssertEqual(KeyEvent.fnUp, KeyEvent.fnUp)
        XCTAssertNotEqual(KeyEvent.fnDown, KeyEvent.fnUp)
    }

    func testKeyEvent_shortcutTriggered_equatable() {
        XCTAssertEqual(
            KeyEvent.shortcutTriggered(id: "test"),
            KeyEvent.shortcutTriggered(id: "test")
        )
        XCTAssertNotEqual(
            KeyEvent.shortcutTriggered(id: "test1"),
            KeyEvent.shortcutTriggered(id: "test2")
        )
    }

    // MARK: - KeyMonitorError Tests

    func testKeyMonitorError_types() {
        let monitorError: KeyMonitorError = .monitorCreationFailed
        let alreadyError: KeyMonitorError = .alreadyMonitoring

        // 验证 Error 协议遵从
        XCTAssertNotNil(monitorError as Error)
        XCTAssertNotNil(alreadyError as Error)
    }

    // MARK: - KeyMonitor Protocol Conformance

    func testKeyMonitor_conformsToKeyMonitoring() {
        let monitor = KeyMonitor()
        XCTAssertTrue(monitor is KeyMonitoring)
    }

    func testKeyMonitor_hasEventsStream() {
        let monitor = KeyMonitor()
        let _: AsyncStream<KeyEvent> = monitor.events
    }

    // MARK: - Idempotency Tests

    func testKeyMonitor_startAlreadyMonitoring_throwsError() {
        // 注意：此测试在没有 Accessibility 权限的 CI 环境中可能会因为
        // monitorCreationFailed 而无法测试 alreadyMonitoring 逻辑。
        let monitor = KeyMonitor()

        do {
            try monitor.startMonitoring()
            // 如果成功了，第二次 start 应该抛出 alreadyMonitoring
            XCTAssertThrowsError(try monitor.startMonitoring()) { error in
                XCTAssertEqual(error as? KeyMonitorError, .alreadyMonitoring)
            }
            monitor.stopMonitoring()
        } catch {
            // monitorCreationFailed 是预期行为（无 Accessibility 权限时）
            XCTAssertEqual(error as? KeyMonitorError, .monitorCreationFailed)
        }
    }

    func testKeyMonitor_stopWhenNotMonitoring_noOp() {
        let monitor = KeyMonitor()
        // 未启动时调用 stop 不应崩溃
        monitor.stopMonitoring()
        monitor.stopMonitoring() // 多次调用也不应崩溃
    }

    // MARK: - AsyncStream Lifecycle

    func testKeyMonitor_stopFinishesStream() async {
        let monitor = KeyMonitor()

        let expectation = XCTestExpectation(description: "Stream should finish after stop")

        let consumeTask = Task {
            for await _ in monitor.events {
                // 消费事件
            }
            expectation.fulfill()
        }

        try? await Task.sleep(for: .milliseconds(50))

        monitor.stopMonitoring()

        await fulfillment(of: [expectation], timeout: 2.0)
        consumeTask.cancel()
    }

    // MARK: - AppState Tests

    func testAppState_equatable() {
        XCTAssertEqual(AppState.launching, AppState.launching)
        XCTAssertEqual(AppState.ready, AppState.ready)
        XCTAssertNotEqual(AppState.launching, AppState.ready)
    }

    func testAppState_permissionRequired_equatable() {
        XCTAssertEqual(
            AppState.permissionRequired([.accessibility]),
            AppState.permissionRequired([.accessibility])
        )
        XCTAssertNotEqual(
            AppState.permissionRequired([.accessibility]),
            AppState.permissionRequired([.microphone])
        )
    }

    func testAppState_error_equatable() {
        XCTAssertEqual(
            AppState.error("test"),
            AppState.error("test")
        )
        XCTAssertNotEqual(
            AppState.error("error1"),
            AppState.error("error2")
        )
    }
}
