# Testing Guidelines

## Test Location

All unit tests are located in `/Voxa/Tests/` directory.

## Test Coverage

Tests cover the following core components:

| Component | Test File | Coverage Focus |
|-----------|-----------|----------------|
| PermissionManager | `PermissionManagerTests.swift` | Permission checking logic |
| KeyMonitor | `KeyMonitorTests.swift` | Fn key detection |
| SessionCoordinator | `SessionCoordinatorTests.swift` | State machine transitions |
| TextInjector | `TextInjectorTests.swift` | AX API and clipboard fallback |
| TextProcessor | `TextProcessorTests.swift` | LLM polishing pipeline |

## Running Tests

### Run All Tests

```bash
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS'
```

### Run Specific Test Class

```bash
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS' -only-testing:VoxaTests/SessionCoordinatorTests
```

### Run Specific Test Method

```bash
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS' -only-testing:VoxaTests/SessionCoordinatorTests/testRecordingFlow
```

## Testing Patterns

### Actor Testing

For `actor`-based components like `AudioPipeline`:

```swift
func testAudioCapture() async throws {
    let pipeline = AudioPipeline()
    try await pipeline.startCapture()
    // Test behavior
    let data = try await pipeline.stopCapture()
    XCTAssertFalse(data.isEmpty)
}
```

### MainActor Testing

For `@MainActor` components like `AppSettings`:

```swift
@MainActor
func testSettingsValidation() {
    let settings = AppSettings.shared
    XCTAssertFalse(settings.isSTTConfigured)
    // Configure and verify
}
```

### AsyncStream Testing

For event-driven components:

```swift
func testKeyMonitoring() async throws {
    let monitor = KeyMonitor()
    let eventReceived = expectation(description: "Event received")

    Task {
        for await event in monitor.events {
            if event == .fnDown {
                eventReceived.fulfill()
                break
            }
        }
    }

    // Trigger event
    // ...

    await fulfillment(of: [eventReceived], timeout: 1.0)
}
```

## Test Isolation

- Each test should be independent
- Use fresh instances for each test
- Clean up any side effects in `tearDown()`
- Mock external dependencies (network calls, system APIs)

## Mock Protocol Example

```swift
struct MockAudioCapturing: AudioCapturing {
    var startCallCount = 0
    var stopCallCount = 0
    var mockData = Data()

    func startCapture() async throws {
        startCallCount += 1
    }

    func stopCapture() async throws -> Data {
        stopCallCount += 1
        return mockData
    }
}
```

## CI/CD Integration

For automated testing in CI:

```bash
# Clean build
xcodebuild -project Voxa.xcodeproj -scheme Voxa clean

# Run tests with coverage
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS' -enableCodeCoverage YES

# Generate coverage report
xcrun llvm-cov report ...
```
