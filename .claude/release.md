# Release Guide

## Creating a Release

```bash
# Create and push tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## GitHub Actions Workflow

### Triggers

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Tags matching `v*.*.*` (e.g., `v1.0.0`)
- Manual workflow dispatch

### Build Job

Runs on every trigger:
1. Checks out repository
2. Selects Xcode
3. Resolves package dependencies
4. Builds app (Release configuration, no code signing)
5. Packages `Voxa.app` into `Voxa.zip`
6. Uploads build artifacts (30-day retention)
7. Generates release notes

### Release Job

Only runs on version tags (`v*.*.*`):
1. Downloads build artifacts
2. Creates GitHub Release with:
   - Version tag name
   - Auto-generated release notes from commits
   - `Voxa.zip` artifact

## Release Notes Format

Auto-generated notes include:
```
## Voxa {VERSION}

### 安装方法
1. 下载 Voxa.zip
2. 解压得到 Voxa.app
3. 将 Voxa.app 移动到应用程序文件夹

### 变更日志
- Commit message 1
- Commit message 2
...
```

## Local Testing

Before tagging:

```bash
# Test release build locally
xcodebuild build -project Voxa.xcodeproj -scheme Voxa -configuration Release \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO

# Verify app launches
open DerivedData/Build/Products/Release/Voxa.app
```
