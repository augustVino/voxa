// MARK: - PermissionManagerTests
// Phase 1 基础骨架 — PermissionManager 单元测试

import XCTest
@testable import Voxa

// MARK: - Mock

/// 用于测试的 Mock PermissionChecking 实现
final class MockPermissionManager: PermissionChecking, @unchecked Sendable {
    var accessibilityGranted = false
    var microphoneGranted = false
    var openSystemPreferencesCalled = false

    func checkAccessibility(prompt: Bool) -> Bool {
        accessibilityGranted
    }

    func requestMicrophoneAccess() async -> Bool {
        microphoneGranted
    }

    func checkAllPermissions() async -> [PermissionStatus] {
        let accessibilityStatus = PermissionStatus(type: .accessibility, isGranted: accessibilityGranted)
        let microphoneStatus = PermissionStatus(type: .microphone, isGranted: microphoneGranted)
        return [accessibilityStatus, microphoneStatus]
    }

    func openSystemPreferences() {
        openSystemPreferencesCalled = true
    }
}

// MARK: - Tests

final class PermissionManagerTests: XCTestCase {

    // MARK: - Protocol Contract Tests

    func testCheckAllPermissions_allDenied() async {
        let mock = MockPermissionManager()
        mock.accessibilityGranted = false
        mock.microphoneGranted = false

        let statuses = await mock.checkAllPermissions()

        XCTAssertEqual(statuses.count, 2)

        let accessibilityStatus = statuses.first(where: { $0.type == .accessibility })
        XCTAssertNotNil(accessibilityStatus)
        XCTAssertFalse(accessibilityStatus!.isGranted)

        let microphoneStatus = statuses.first(where: { $0.type == .microphone })
        XCTAssertNotNil(microphoneStatus)
        XCTAssertFalse(microphoneStatus!.isGranted)
    }

    func testCheckAllPermissions_allGranted() async {
        let mock = MockPermissionManager()
        mock.accessibilityGranted = true
        mock.microphoneGranted = true

        let statuses = await mock.checkAllPermissions()

        XCTAssertEqual(statuses.count, 2)

        for status in statuses {
            XCTAssertTrue(status.isGranted, "\(status.type) should be granted")
        }
    }

    func testCheckAllPermissions_partiallyGranted() async {
        let mock = MockPermissionManager()
        mock.accessibilityGranted = true
        mock.microphoneGranted = false

        let statuses = await mock.checkAllPermissions()

        let accessibilityStatus = statuses.first(where: { $0.type == .accessibility })
        XCTAssertTrue(accessibilityStatus!.isGranted)

        let microphoneStatus = statuses.first(where: { $0.type == .microphone })
        XCTAssertFalse(microphoneStatus!.isGranted)
    }

    func testCheckAccessibility_noPrompt() {
        let mock = MockPermissionManager()
        mock.accessibilityGranted = false

        XCTAssertFalse(mock.checkAccessibility(prompt: false))

        mock.accessibilityGranted = true
        XCTAssertTrue(mock.checkAccessibility(prompt: true))
    }

    func testRequestMicrophoneAccess() async {
        let mock = MockPermissionManager()
        mock.microphoneGranted = false

        let denied = await mock.requestMicrophoneAccess()
        XCTAssertFalse(denied)

        mock.microphoneGranted = true
        let granted = await mock.requestMicrophoneAccess()
        XCTAssertTrue(granted)
    }

    func testOpenSystemPreferences() {
        let mock = MockPermissionManager()
        XCTAssertFalse(mock.openSystemPreferencesCalled)

        mock.openSystemPreferences()
        XCTAssertTrue(mock.openSystemPreferencesCalled)
    }

    // MARK: - Type Tests

    func testPermissionType_caseIterable() {
        let allCases = PermissionType.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.accessibility))
        XCTAssertTrue(allCases.contains(.microphone))
    }

    func testPermissionStatus_equatable() {
        let status1 = PermissionStatus(type: .accessibility, isGranted: true)
        let status2 = PermissionStatus(type: .accessibility, isGranted: true)
        let status3 = PermissionStatus(type: .accessibility, isGranted: false)

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)
    }
}
