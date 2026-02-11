# CLAUDE.md

Voxa - AI-powered macOS menu bar voice input application (macOS 14+, Swift 6)

Users press and hold the Fn key to record voice, which is transcribed via Zhipu AI's GLM-ASR service, optionally polished by an LLM, and injected into the active application.

## Commands

```bash
# Build
xcodebuild -project Voxa.xcodeproj -scheme Voxa build

# Release build (no code signing)
xcodebuild build -project Voxa.xcodeproj -scheme Voxa -configuration Release \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO

# Test
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS'

# Specific test
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS' \
  -only-testing:VoxaTests/SessionCoordinatorTests

# Clean
xcodebuild -project Voxa.xcodeproj -scheme Voxa clean
```

**Alternative**: Use Xcode GUI (Voxa.xcodeproj)

## Release

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

See [Release Guide](.claude/release.md) for details.

## Guidelines

- [Architecture](.claude/architecture.md) - Project structure, state machines, protocols
- [Swift Concurrency](.claude/swift-concurrency.md) - Swift 6 strict concurrency patterns
- [Code Style](.claude/code-style.md) - Dependency injection, naming, conventions
- [Development](.claude/development.md) - Permissions, debugging, platform constraints
- [Testing](.claude/testing.md) - Test patterns, running tests
