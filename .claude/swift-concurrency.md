# Swift 6 Concurrency Guidelines

## Critical Requirement

**Swift 6 strict concurrency is enforced throughout the codebase.** All code must compile with strict concurrency enabled.

## Core Patterns

### Actor-Based Components

Core components that handle mutable state use `actor` for thread safety:

```swift
// AudioPipeline - handles audio capture and processing
actor AudioPipeline: AudioCapturing {
    // Audio capture logic here
}

// ZhipuSTTProvider - handles network requests
actor ZhipuSTTProvider: STTProvider {
    // STT service calls here
}
```

**Why**: Ensures serialized access to mutable state and prevents data races.

### Main Actor Isolation

UI-related components and settings use `@MainActor`:

```swift
@Observable @MainActor final class AppSettings {
    // UI-bound settings
}

struct MenuBarView: View {
    @MainActor var body: some View {
        // UI implementation
    }
}
```

**Why**: Guarantees UI updates happen on the main thread.

### AsyncStream for Events

Event-driven components use `AsyncStream` for sending events:

```swift
// KeyMonitor - Fn key events
var events: AsyncStream<KeyEvent>

// AudioPipeline - Audio level updates
var audioLevels: AsyncStream<AudioLevel>
```

**Why**: Provides structured, cancellable async event streams.

### Sendable Protocols

All public protocols conform to `Sendable` for safe cross-actor boundary passing:

```swift
protocol KeyMonitoring: Sendable {
    var events: AsyncStream<KeyEvent> { get }
}

protocol AudioCapturing: Sendable {
    func startCapture() async throws
    func stopCapture() async throws -> Data
}
```

**Why**: Ensures values can be safely passed across concurrency domains.

## Dependency Injection

**No singletons except `AppSettings`**. All dependencies are injected through initializers:

```swift
// GOOD: Dependency injection
final class SessionCoordinator {
    private let audioPipeline: AudioCapturing
    private let sttProvider: STTProvider
    private let textInjector: TextInjecting

    init(
        audioPipeline: AudioCapturing,
        sttProvider: STTProvider,
        textInjector: TextInjecting
    ) {
        self.audioPipeline = audioPipeline
        self.sttProvider = sttProvider
        self.textInjector = textInjector
    }
}
```

**Why**: Enables testing and prevents hidden dependencies.

## Common Patterns

### Calling Actor Methods

```swift
// From outside an actor
let result = await audioPipeline.stopCapture()

// From within an actor
let result = audioPipeline.stopCapture()  // No await needed on same actor
```

### MainActor from Background

```swift
// Update UI from background task
await MainActor.run {
    overlayViewModel.show()
}
```

### Task Cancellation

```swift
Task {
    // Cancellable work
    for await event in keyMonitor.events {
        // Handle event
        if Task.isCancelled { break }
    }
}
```

## Testing Considerations

- Use `@MainActor` for test cases that test UI-bound components
- Mock protocols with `actor` implementations where needed
- Test async code with `await` and `XCTAssertNoThrow`
