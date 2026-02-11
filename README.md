# Voxa

<div align="center">

**AI-powered macOS menu bar voice input application**

[![Build Status](https://github.com/augustVino/voxa/workflows/Build%20macOS%20Application/badge.svg)](https://github.com/augustVino/voxa/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

按住 Fn 键说话，松开即输入

</div>

---

## 项目简介

Voxa 是一款**系统级 AI 语音输入工具**，专为 macOS 设计。通过按住 Fn 键即可快速启动语音输入，自动将语音转录为文本并注入到当前光标位置，无需切换应用或窗口。

### 核心特性

- **极低唤起成本** - 按住 Fn 键即可开始录音，松开即完成输入
- **不中断工作流** - 无需切换应用，菜单栏常驻，不打扰当前操作
- **AI 文本润色** - 支持自定义人设（Persona），让输出文本更符合场景需求
- **完全隐私保护** - API Key 安全存储在系统 Keychain 中

---

## 系统要求

- **操作系统**: macOS 14.0 或更高版本
- **架构**: Apple Silicon (M1/M2/M3/M4) 或 Intel
- **权限**:
  - 辅助功能权限 (Accessibility) - 用于全局按键监听和文本注入
  - 麦克风权限 (Microphone) - 用于音频录制

---

## 快速开始

### 安装

1. 从 [Releases](https://github.com/augustVino/voxa/releases) 页面下载对应架构的版本
2. 解压得到 `Voxa.app`
3. 将 `Voxa.app` 移动到应用程序文件夹
4. 首次启动时授予必要的系统权限

> 如果提示文件已损坏，需要在终端等命令行工具中执行：xattr -cr /Applications/Voxa.app

### 架构选择

| 文件                     | 适用机型               |
| ------------------------ | ---------------------- |
| `Voxa-apple-silicon.zip` | M1/M2/M3/M4 芯片的 Mac |
| `Voxa-intel.zip`         | Intel 芯片的 Mac       |

不确定？点击菜单栏左上角 → 关于本机 → 查看"芯片"或"处理器"

### 基本使用

1. **首次配置**

   - 点击菜单栏 Voxa 图标
   - 进入「模型设置」，配置 STT 和 LLM 服务
   - 选择或创建一个「人设」

2. **语音输入**
   - 在任意应用中将光标置于输入位置
   - **按住 Fn 键**开始录音
   - 说话
   - **松开 Fn 键**，系统自动识别并注入文本

---

## 功能说明

### 快捷键配置

| 快捷键             | 说明                        |
| ------------------ | --------------------------- |
| **Fn 键**          | 主路径 - 按住录音，松开输入 |
| `Cmd + Option + V` | 备用快捷键（可自定义）      |

### 录音动画

录音时屏幕底部显示动画反馈，支持三种位置配置：

- `bottomLeft` - 左下角
- `bottomCenter` - 居中底部（默认）
- `bottomRight` - 右下角

### 人设系统

人设用于控制输出文本的语气、风格与结构：

| 内置人设     | 适用场景                             |
| ------------ | ------------------------------------ |
| **默认人设** | 去除语气词，保留技术术语，偏书面表达 |
| 产品经理     | 结构化表达，偏业务与方案描述         |
| 开发者       | 技术术语保留，代码风格化             |

### 历史记录

- 自动保存最近 30 天的输入记录
- 支持搜索、复制、删除操作
- 记录包含原始文本、处理后文本、使用人设等信息

---

## 技术架构

### 技术栈

- **语言**: Swift 6 (严格并发模式)
- **UI 框架**: SwiftUI
- **数据持久化**: SwiftData
- **安全存储**: Keychain Services
- **音频处理**: AVFoundation
- **网络**: URLSession

### 架构概览

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
│  - SwiftData Models (Persona)           │
├─────────────────────────────────────────┤
│  Core Layer (Engine Components)         │
│  - KeyMonitor, AudioPipeline, STT       │
│  - TextProcessor, TextInjector          │
└─────────────────────────────────────────┘
```

### 语音输入流程

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
  ├─ STTProvider.transcribe() → text
  ├─ PromptProcessor.process() → polished text
  ├─ TextInjector.inject() → AX API or clipboard
  └─ Save to InputHistory (SwiftData)
```

### 目录结构

```
Voxa/
├── VoxaApp.swift              # @main 入口
├── Info.plist                 # 权限声明
├── Voxa.entitlements          # 音频输入权限
├── Core/
│   ├── Audio/                 # 音频管道
│   ├── Injection/             # 文本注入器
│   ├── KeyMonitor/            # Fn 键监听
│   ├── Permissions/           # 权限管理
│   ├── Session/               # 会话协调器
│   ├── STT/                   # 语音转文本
│   └── TextProcessing/        # 文本处理
├── Models/
│   ├── InputHistory.swift     # 输入历史模型
│   └── Persona.swift          # 人设模型
├── Services/
│   ├── AppSettings.swift      # 应用设置
│   ├── KeychainService.swift  # 密钥存储服务
│   └── LaunchAtLoginHelper.swift  # 开机启动
└── UI/
    ├── MenuBar/               # 菜单栏界面
    ├── Settings/              # 设置界面
    └── Overlay/               # 录音浮窗
```

---

## 开发指南

### 环境要求

- Xcode 15.0 或更高版本
- macOS 14.0 或更高版本
- Swift 6.0

### 构建项目

```bash
# 克隆仓库
git clone https://github.com/augustVino/voxa.git
cd voxa

# 解析依赖
xcodebuild -resolvePackageDependencies -project Voxa.xcodeproj

# 构建
xcodebuild -project Voxa.xcodeproj -scheme Voxa build

# 清理
xcodebuild -project Voxa.xcodeproj -scheme Voxa clean
```

### 运行测试

```bash
# 运行所有测试
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS'

# 运行特定测试
xcodebuild test -project Voxa.xcodeproj -scheme Voxa -destination 'platform=macOS' \
  -only-testing:VoxaTests/SessionCoordinatorTests
```

### Release 构建

```bash
xcodebuild build -project Voxa.xcodeproj -scheme Voxa -configuration Release \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
```

### 开发文档

- [架构说明](.claude/architecture.md) - 项目结构、状态机、协议
- [Swift 并发](.claude/swift-concurrency.md) - Swift 6 严格并发模式
- [代码风格](.claude/code-style.md) - 依赖注入、命名规范
- [开发指南](.claude/development.md) - 权限、调试、平台限制
- [测试指南](.claude/testing.md) - 测试模式、运行测试

---

## 配置说明

### 模型配置

#### STT（语音识别）

**当前深度适配**: 智谱 AI GLM-ASR-2512 模型

Voxa 的 STT 组件目前针对智谱 AI 的 GLM-ASR-2512 模型进行了深度适配和充分测试，支持流式和非流式两种识别模式。

虽然理论上支持 OpenAI 兼容格式的 API，但其他 STT 服务商（如 OpenAI Whisper）并未经过深度测试，可能需要调整代码才能正常使用。

| 服务           | Base URL                                                    | 状态          |
| -------------- | ----------------------------------------------------------- | ------------- |
| 智谱 AI        | `https://open.bigmodel.cn/api/paas/v4/audio/transcriptions` | ✅ 深度适配   |
| OpenAI Whisper | `https://api.openai.com/v1/audio/transcriptions`            | ⚠️ 未深度测试 |

#### LLM（文本润色）

支持 OpenAI 兼容格式的 API：

| 服务         | Base URL                               | 状态        |
| ------------ | -------------------------------------- | ----------- |
| OpenAI       | `https://api.openai.com/v1`            | ✅ 支持     |
| 智谱 AI      | `https://open.bigmodel.cn/api/paas/v4` | ✅ 支持     |
| 其他兼容服务 | 自定义                                 | ✅ 理论支持 |

### 设置项

| 分类     | 配置项                                          |
| -------- | ----------------------------------------------- |
| **通用** | 快捷键、录音动画位置、开机自启动、Dock 图标显示 |
| **模型** | STT/LLM API Key、Base URL、模型名称             |
| **人设** | 创建、编辑、删除人设                            |
| **历史** | 查看历史记录、设置保留天数                      |

---

## 故障排除

### 权限问题

**问题**: Fn 键无响应

**解决方案**:

1. 打开「系统设置」→「隐私与安全性」→「辅助功能」
2. 确保 Voxa 已勾选
3. 重启应用

**问题**: 无法录音

**解决方案**:

1. 打开「系统设置」→「隐私与安全性」→「麦克风」
2. 确保 Voxa 已勾选

### 文本注入问题

**问题**: 文本未注入到目标应用

**解决方案**:

1. 确保已授予辅助功能权限
2. 某些应用可能不支持 AX API，应用会自动使用剪贴板方式
3. 检查目标应用是否支持文本输入

---

## 路线图

### v1.0 (MVP) - 当前版本

- [x] Fn 单键语音输入
- [x] 智谱 AI STT 深度适配
- [x] 基础人设系统
- [x] 自动文本注入

### v1.1 (计划中)

- [ ] 多 STT 服务商适配（OpenAI Whisper 等）
- [ ] 多人设快速切换
- [ ] 历史记录增强
- [ ] 自定义快捷键支持

### v2.0 (未来)

- [ ] 热词系统
- [ ] 上下文感知
- [ ] 多语言支持
- [ ] Prompt 插件化

---

## 贡献指南

欢迎提交 Issue 和 Pull Request！

### 提交 PR 前请确保:

1. 代码遵循项目的 [代码风格指南](.claude/code-style.md)
2. 添加必要的单元测试
3. 更新相关文档
4. 所有测试通过

### 开发工作流

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 致谢

- 智谱 AI GLM-ASR-2512 语音识别服务
- Swift 和 SwiftUI 社区
- 所有贡献者

---

## 联系方式

- 项目主页: [https://github.com/augustVino/voxa](https://github.com/augustVino/voxa)
- 问题反馈: [GitHub Issues](https://github.com/augustVino/voxa/issues)

---

<div align="center">

**Voxa** - 让语音输入如键盘般自然

</div>
