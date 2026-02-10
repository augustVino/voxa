# Development Guide

## Permission Handling

### Required Permissions

The app requires two system permissions:

| Permission | Purpose | Prompt Location |
|------------|---------|-----------------|
| **Accessibility** | Global key monitoring and text injection | `NSAppleEventsUsageDescription` in Info.plist |
| **Microphone** | Audio capture | `NSMicrophoneUsageDescription` in Info.plist |

### Permission Flow

```
App Launch
  ↓
AppLifecycleCoordinator.initialize()
  ├─ PermissionManager.checkAllPermissions()
  │  ├─ checkAccessibility(prompt: true) if missing
  │  └─ requestMicrophoneAccess()
  ↓
AppState.permissionRequired(types) (if missing)
  ↓
Start permission polling (2s interval)
  ↓
AppState.ready (when granted)
  ↓
AppLifecycleCoordinator.startKeyMonitoring()
```

**Key Points**:
- Permissions are checked on every launch
- Missing permissions trigger a polling state until granted
- User is prompted with system dialogs for missing permissions
- App requires both permissions to function

## Audio Constraints

GLM-ASR-2512 Service Limitations:

| Constraint | Value | Configurable |
|------------|-------|--------------|
| Max recording duration | 30 seconds | Yes (AppSettings) |
| Max file size | 25MB | No |
| Audio format | WAV (Int16 PCM) | No |

**Implementation**: `AudioPipeline` enforces these limits and throws errors when exceeded.

## Text Injection Strategy

### Primary Method: AX API

```swift
// Accessibility API for direct text insertion
AXUIElementSetAttributeValue(element, kAXFocusedAttribute, ...)
```

**Advantages**:
- Direct insertion without clipboard interference
- Preserves existing clipboard content
- More reliable for complex text fields

### Fallback Method: Clipboard Paste

```swift
// Cmd+V simulation when AX API fails
Copy to clipboard → Simulate Cmd+V → Restore original clipboard
```

**Why**: AX API may fail in some apps or due to system restrictions.

**Implementation**: `TextInjector` automatically falls back when AX API fails.

## Keychain Migration

API keys migrated from UserDefaults to Keychain for security:

```swift
// Legacy UserDefaults keys
"stt_api_key"  → KeychainService.key(.sttAPIKey)
"llm_api_key"  → KeychainService.key(.llmAPIKey)
```

**Migration Logic**: `KeychainService` automatically migrates existing keys on first access.

## Launch at Login

Uses `SMAppService` (macOS 13+) for login item management:

```swift
// Enable
SMAppService.loginItemIdentifier = "com.voxa.app"
try await SMAppService.loginItem.setLoginItemEnabled(true)

// Check status
let isEnabled = SMAppService.loginItem.status == .enabled
```

**Helper**: `LaunchAtLoginHelper` wraps this API and syncs with `AppSettings`.

## Input History Cleanup

30-day retention policy with automatic cleanup:

```swift
// Runs on app launch and after each session
InputHistoryCleanup.cleanup(modelContext: context, daysToKeep: 30)
```

**Implementation**: Deletes `InputHistory` records older than 30 days from SwiftData.

## Development Tips

### Debugging Key Monitoring

1. Check Accessibility permissions in System Settings
2. Verify `KeyMonitor` is started (check AppState)
3. Monitor `KeyMonitor.events` stream in debugger

### Debugging Audio Issues

1. Check Microphone permissions in System Settings
2. Verify `AudioPipeline` state in SessionCoordinator
3. Monitor `AudioPipeline.audioLevels` for real-time feedback
4. Check file size limits (25MB max)

### Debugging Injection Problems

1. Verify Accessibility permissions
2. Check target application compatibility
3. Monitor `TextInjector` logs for AX API failures
4. Verify clipboard content after fallback

### Debugging Permissions

1. Check Info.plist for permission descriptions
2. Verify entitlements in Voxa.entitlements
3. Monitor `AppState.permissionRequired` state
4. Check system permission dialogs in System Settings
