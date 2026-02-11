# Code Style Guidelines

## Dependency Injection

**No singletons except `AppSettings`**. All core dependencies use protocol-based injection:

```swift
// Define Sendable protocol
protocol AudioCapturing: Sendable {
    func startCapture() async throws
    func stopCapture() async throws -> Data
}

// Inject through initializer
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

**Why**: Enables testing, prevents hidden dependencies, ensures thread-safe boundaries.

## Swift 6 Concurrency

### Actor Isolation

Core components handling mutable state use `actor`:

```swift
actor AudioPipeline: AudioCapturing {
    private var engine: AVAudioEngine?
    // ...
}
```

### Main Actor Isolation

UI components and settings use `@MainActor`:

```swift
@Observable @MainActor final class AppSettings {
    // ...
}

struct MenuBarView: View {
    @MainActor var body: some View { /* ... */ }
}
```

### AsyncStream for Events

Event-driven components use `AsyncStream`:

```swift
protocol KeyMonitoring: Sendable {
    var events: AsyncStream<KeyEvent> { get }
}
```

## Naming Conventions

- **Protocols**: Gerund form ending with `-ing` (`AudioCapturing`, `KeyMonitoring`, `TextInjecting`)
- **Coordinators**: Named with domain + `Coordinator` (`SessionCoordinator`, `AppLifecycleCoordinator`)
- **Models**: Singular nouns (`Persona`, `InputHistory`)
- **Views**: Purpose + `View` (`MenuBarView`, `SettingsView`)

## File Organization

```
Voxa/
├── VoxaApp.swift          # @main entry point
├── Core/                   # Engine components (protocol-based)
│   ├── Audio/
│   ├── KeyMonitor/
│   ├── Session/
│   └── ...
├── Models/                 # SwiftData @Model classes
├── Services/               # AppSettings, KeychainService
└── UI/                     # SwiftUI views
```

## Comments

Use `// MARK: -` for logical sections:

```swift
// MARK: - Properties

// MARK: - Init

// MARK: - Public

// MARK: - Private
```

**No inline comments for obvious code**. Comments should explain **why**, not **what**.
