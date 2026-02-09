# Voxa Architecture

## Project Type

Voxa is a **native macOS menu bar application** (macOS 14+) that provides AI-powered voice input. Users press and hold the Fn key to record voice, which is transcribed via Zhipu AI's GLM-ASR service, optionally polished by an LLM, and injected into the active application.

**Key Characteristics**:
- Menu bar app (LSUIElement = true, no dock icon by default)
- Global Fn key monitoring via NSEvent
- Swift 6 strict concurrency throughout
- SwiftUI for all UI layers
- SwiftData for persistence
- Keychain for secure API key storage

## Layered Architecture

```
┌─────────────────────────────────────────┐
│  Presentation Layer (SwiftUI Views)     │
│  - MenuBarView, SettingsView, Overlay   │
├─────────────────────────────────────────┤
│  Application Layer (Coordinators)       │
│  - AppLifecycleCoordinator              │
│  - SessionCoordinator                   │
├─────────────────────────────────────────┤
│  Domain Layer (Services & Models)       │
│  - AppSettings, KeychainService         │
│  - SwiftData Models (Persona, Hotword)  │
├─────────────────────────────────────────┤
│  Core Layer (Engine Components)         │
│  - KeyMonitor, AudioPipeline, STT       │
│  - TextProcessor, TextInjector          │
└─────────────────────────────────────────┘
```

## State Machines

### AppState (AppLifecycleCoordinator)

```
launching → permissionRequired → ready → error
```

- **launching**: Initial state during app startup
- **permissionRequired**: Waiting for Accessibility/Microphone permissions
- **ready**: All permissions granted, app fully functional
- **error**: Critical failure during initialization

### SessionState (SessionCoordinator)

```
idle → recording → transcribing → processing → injecting → error
```

- **idle**: Waiting for user input (Fn key press)
- **recording**: Audio capture in progress
- **transcribing**: Sending audio to STT service
- **processing**: Hotword correction + optional LLM polishing
- **injecting**: Inserting text into active application
- **error**: Recoverable error with auto-retry

## Project Structure

```
Voxa/
├── VoxaApp.swift              # @main entry point
├── Info.plist                 # Microphone permission, LSUIElement
├── Voxa.entitlements          # Audio input, Apple Events
├── Core/
│   ├── Audio/                 # AudioPipeline (actor), AVAudioEngine wrapper
│   ├── Injection/             # TextInjector (AX API + clipboard fallback)
│   ├── KeyMonitor/            # Fn/Globe key detection via NSEvent
│   ├── Permissions/           # PermissionManager (Accessibility + Microphone)
│   ├── Session/               # SessionCoordinator (main state machine)
│   ├── STT/                   # ZhipuSTTProvider (GLM-ASR-2512)
│   └── TextProcessing/        # HotwordCorrector, PromptProcessor, TextProcessor
├── Models/
│   ├── InputHistory.swift     # @Model for SwiftData
│   ├── Hotword.swift          # @Model for SwiftData
│   └── Persona.swift          # @Model for SwiftData
├── Services/
│   ├── AppSettings.swift      # @Observable singleton with @AppStorage
│   ├── KeychainService.swift  # Secure API key storage
│   ├── LaunchAtLoginHelper.swift  # SMAppService wrapper
│   └── InputHistoryCleanup.swift  # 30-day retention cleanup
├── UI/
│   ├── MenuBar/               # MenuBarView
│   ├── Settings/              # 5 settings tabs
│   └── Overlay/               # RecordingOverlayView, WaveformView, OverlayPanel
└── Tests/
    └── Unit tests for core components
```

## Key Protocols

All core components use protocol-oriented design for testability:

| Protocol | Location | Purpose |
|----------|----------|---------|
| `KeyMonitoring` | `Core/KeyMonitor/KeyMonitoring.swift` | Fn key detection |
| `PermissionChecking` | `Core/Permissions/PermissionChecking.swift` | Permission validation |
| `AudioCapturing` | `Core/Audio/AudioCapturing.swift` | Audio capture interface |
| `STTProvider` | `Core/STT/STTProvider.swift` | Speech-to-text service |
| `OverlayPresenting` | `UI/Overlay/OverlayPresenting.swift` | Floating overlay control |

## Initialization Flow

**VoxaApp.swift** entry point sequence:

1. Create SwiftData ModelContainer (Persona, Hotword, InputHistory)
2. Initialize services (PermissionManager, KeyMonitor)
3. Create SessionCoordinator with all dependencies:
   - AudioPipeline
   - ZhipuSTTProvider
   - TextProcessor (HotwordCorrector + PromptProcessor)
   - TextInjector
4. Launch startup Task:
   - Check macOS version
   - Create OverlayPanel
   - Inject overlay into SessionCoordinator
   - Start SessionCoordinator
   - Initialize AppLifecycleCoordinator (permissions)
   - Sync launch-at-login status
   - Run 30-day history cleanup
5. Display MenuBarExtra + Settings Window

## Key Services

### AppSettings

`@Observable @MainActor final class` - Singleton with `@AppStorage` backing

**Responsibilities**:
- STT configuration (API Key in Keychain, base URL, model)
- LLM configuration (API Key in Keychain, base URL, model)
- Active persona ID
- General settings (Fn key enabled, custom shortcut, launch at login, show dock icon)
- Overlay position
- Audio configuration (max recording duration)

**Validation**: `isSTTConfigured`, `isLLMConfigured`

### SessionCoordinator

Central orchestrator for voice input sessions

**Responsibilities**:
- Listens to `KeyMonitor.events` for Fn key presses
- Coordinates recording → transcription → processing → injection flow
- Manages overlay display and status updates
- Handles errors with 2-second auto-retry logic

### TextProcessor

Two-stage text processing pipeline:

1. **HotwordCorrector**: Pattern-based replacement from SwiftData
2. **PromptProcessor**: Optional LLM-based polishing (if persona active)

## Data Models (SwiftData)

### Persona
`@Model` class with `@Attribute(.unique) id`
- Custom prompts for text polishing
- Fields: name, prompt, descriptionText, sortOrder, timestamps

### Hotword
`@Model` class with `@Attribute(.unique) id`
- Pattern-replacement pairs for correction
- Fields: pattern, replacement, priority, isAutoGenerated, createdAt

### InputHistory
`@Model` class
- 30-day retention with auto-cleanup
- Fields: rawText, processedText, personaName, duration, timestamps

All models use `@Attribute(.unique) id` for stable references.

## Voice Input Flow

```
User presses Fn key
  ↓
KeyMonitor.events yields .fnDown
  ↓
SessionCoordinator.handleFnDown()
  ├─ Show overlay at configured position
  └─ AudioPipeline.startCapture()
  ↓
User releases Fn key
  ↓
SessionCoordinator.handleFnUp()
  ├─ AudioPipeline.stopCapture() → WAV data
  ├─ ZhipuSTTProvider.transcribe() → text
  ├─ HotwordCorrector.correct() → corrected text
  ├─ PromptProcessor.process() → polished text (if persona active)
  ├─ TextInjector.inject() → AX API or clipboard fallback
  └─ Save to InputHistory (SwiftData)
  ↓
Hide overlay, return to idle
```
