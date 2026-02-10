# GitHub Actions 指南

## 概述

本项目包含两个 GitHub Actions workflow：

1. **Build** (`.github/workflows/build.yml`) - 每次 push 时自动构建
2. **Release** (`.github/workflows/release.yml`) - 推送 tag 时创建 Release

## 工作流说明

### Build Workflow

触发条件：
- Push 到 `main` 或 `develop` 分支
- 创建 Pull Request
- 手动触发

构建步骤：
1. 解析 Swift Package 依赖
2. （可选）导入代码签名证书
3. 构建 Voxa.app
4. 打包并上传构建产物

### Release Workflow

触发条件：
- 推送格式为 `v*.*.*` 的 tag（如 `v1.0.0`）

功能：
- 生成 Release Notes
- 下载最新构建产物
- 创建 GitHub Release 并上传附件

## 代码签名配置（可选）

### 无签名构建

默认情况下，workflow 会进行无签名构建。生成的 `.app` 包可以在本地运行，但可能需要：
- 关闭 Gatekeeper：`sudo spctl --master-disable`
- 右键点击应用 → 打开

### 配置代码签名

如需分发签名版本，在 GitHub Repository Settings 中配置：

#### 1. 导出证书

```bash
# 从 Keychain 导出 .p12 证书
security find-identity -v -p codesigning

# 选择证书 ID 后导出
security export -t cert -f pkcs12 -o certificate.p12 <证书ID>
```

#### 2. Base64 编码证书

```bash
base64 -i certificate.p12 | pbcopy
```

#### 3. 配置 GitHub Secrets

在 Repository Settings → Secrets and variables → Actions：

| 名称 | 类型 | 说明 |
|------|------|------|
| `CERTIFICATE_PASSWORD` | Secret | .p12 证书的导出密码 |
| `KEYCHAIN_PASSWORD` | Secret | 临时 keychain 密码（任意字符串） |

在 Repository Settings → Secrets and variables → Variables：

| 名称 | 类型 | 说明 |
|------|------|------|
| `CERTIFICATE_BASE64` | Variable | Base64 编码的证书内容 |

## 使用方式

### 日常开发

```bash
git add .
git commit -m "feat: 新功能"
git push origin main
```

→ 自动触发构建，产物可在 Actions 页面下载

### 发布新版本

```bash
# 创建并推送 tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

→ 自动创建 Release 并上传构建产物

### 本地测试构建

```bash
# 运行与 CI 相同的构建命令
xcodebuild build \
  -project Voxa.xcodeproj \
  -scheme Voxa \
  -configuration Release \
  -derivedDataPath DerivedData
```

## 下载构建产物

1. 进入 GitHub Repository → Actions
2. 选择最近的 Workflow Run
3. 在 "Artifacts" 部分下载 `Voxa-macOS-<commit-sha>`

## 注意事项

- 构建产物保留 30 天
- 无签名版本仅用于个人测试
- 公开发布需要有效的 Apple Developer 账号和证书
