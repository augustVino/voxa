# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Voxa - AI-powered macOS menu bar voice input application (macOS 14+, Swift 6)

Users press and hold the Fn key to record voice, which is transcribed via Zhipu AI's GLM-ASR service, optionally polished by an LLM, and injected into the active application.

## Commands

```bash
# Build the project
xcodebuild -project Voxa.xcodeproj -scheme Voxa build

# Run tests
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS'

# Clean build
xcodebuild -project Voxa.xcodeproj -scheme Voxa clean
```

**Alternative**: Use Xcode GUI for development (Voxa.xcodeproj)

## Key Technologies

- **Swift 6** strict concurrency (actor, @MainActor, AsyncStream, Sendable)
- **SwiftUI** for all UI layers
- **SwiftData** for persistence
- **Keychain** for secure API key storage
- **NSEvent** for global Fn key monitoring

## Documentation

- [Architecture & Project Structure](.claude/architecture.md)
- [Swift 6 Concurrency](.claude/swift-concurrency.md)
- [Development Guide](.claude/development.md)
- [Testing](.claude/testing.md)
