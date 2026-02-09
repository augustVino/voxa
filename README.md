# Voxa

**AI 驱动的语音输入法 - macOS 原生应用**

Voxa 是一款基于 SwiftUI 的 macOS 原生语音输入法,通过按住 Fn 键即可快速进行语音输入和文本注入。

## ✨ 功能特性

### ✅ Phase 1: 基础骨架 (已完成)
- 🎯 全局 Fn 键监听 (基于 NSEvent)
- 🔐 权限管理 (辅助功能 + 麦克风)
- 📊 Menu Bar 应用架构
- 🔄 应用生命周期管理

### ✅ Phase 2: 录音与 STT (MVP 核心 - 已完成)
- 🎤 **音频录制**: 按住 Fn 键实时录音
- 🗣️ **语音识别**: 智谱 GLM-ASR-2512 STT 服务
- 📝 **实时反馈**: 控制台输出识别文本
- ⚡ **流式识别**: 支持流式和非流式两种模式
- 🎛️ **状态管理**: SessionCoordinator 状态机
- 📊 **MenuBar 显示**: 实时会话状态和识别结果

### ⏳ Phase 3-5: 高级功能 (规划中)
- 🎨 录音浮窗 UI + 波形动效
- 🔧 热词优化 + Prompt 润色
- ⌨️ 文本注入到活跃应用
- ⚙️ 设置面板 UI

## 🚀 快速开始

### 系统要求

- macOS 14 (Sonoma) 或更高版本
- Xcode 15+ (支持 Swift 6)
- 智谱 API Key ([获取地址](https://open.bigmodel.cn/))

### 安装步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/yourusername/voxa.git
   cd voxa
   ```

2. **配置 API Key**
   ```bash
   ./scripts/configure-api-key.sh YOUR_API_KEY
   ```

3. **构建运行**
   ```bash
   open Voxa.xcodeproj
   # 在 Xcode 中按 Cmd+R 运行
   ```

4. **授予权限**
   - 首次运行时授予 "辅助功能" 权限
   - 授予 "麦克风" 权限

### 基础使用

1. 点击菜单栏的 Voxa 图标
2. 确认状态显示 "就绪"
3. **按住 Fn 键** 开始录音
4. 清晰说出要识别的内容
5. **松开 Fn 键** 停止录音
6. 查看识别结果:
   - 控制台输出完整文本
   - 菜单栏显示最近识别内容

## 📖 文档

- [Quick Start Guide](./specs/002-audio-stt/quickstart.md) - 快速开始指南
- [Feature Specification](./specs/002-audio-stt/spec.md) - 功能规格说明
- [Implementation Plan](./specs/002-audio-stt/plan.md) - 技术实施计划
- [技术架构与实施指南](./docs/技术架构与实施指南.md) - 整体架构文档

## 🏗️ 项目结构

```
Voxa/
├── Core/                    # 核心引擎层
│   ├── KeyMonitor/          # Fn 键监听
│   ├── Permissions/         # 权限管理
│   ├── Audio/               # 音频采集 (Phase 2)
│   ├── STT/                 # 语音转文字 (Phase 2)
│   └── Session/             # 会话协调 (Phase 2)
├── Services/                # 服务层
│   └── AppSettings.swift    # 应用配置
├── UI/                      # SwiftUI 视图层
│   ├── MenuBar/             # 菜单栏视图
│   └── Overlay/             # 录音浮窗 (Phase 5)
└── Tests/                   # 单元测试
```

## 🔧 配置选项

### 识别模式

```bash
# 启用流式识别 (默认)
defaults write com.voxa.Voxa streamingEnabled -bool true

# 禁用流式识别
defaults write com.voxa.Voxa streamingEnabled -bool false
```

### 录音时长

```bash
# 设置最大录音时长 (默认 30 秒)
defaults write com.voxa.Voxa maxRecordingDuration -int 30
```

### 查看配置

```bash
defaults read com.voxa.Voxa
```

## 🐛 故障排查

### API Key 配置问题

```bash
# 检查 API Key
defaults read com.voxa.Voxa sttApiKey

# 重新配置
./scripts/configure-api-key.sh YOUR_NEW_API_KEY
```

### 权限问题

1. 系统设置 → 隐私与安全性 → 辅助功能
2. 确认 Voxa 已授权
3. 如需重置权限,删除应用后重新安装

### 查看日志

```bash
# 实时日志
log stream --predicate 'subsystem == "com.voxa.Voxa"' --level debug

# 或使用 Console.app
```

## 🎯 开发路线图

- [x] **Phase 1**: 基础骨架 (Fn 键监听 + 权限管理)
- [x] **Phase 2**: 录音与 STT (MVP 核心功能)
- [ ] **Phase 3**: 文本处理 (热词 + Prompt 润色)
- [ ] **Phase 4**: 文本注入 (自动输入到活跃应用)
- [ ] **Phase 5**: 设置面板 (UI 配置界面)

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request!

### 开发环境

1. Fork 本仓库
2. 创建特性分支: `git checkout -b feature/your-feature`
3. 提交更改: `git commit -m 'Add some feature'`
4. 推送分支: `git push origin feature/your-feature`
5. 提交 Pull Request

### 代码规范

- 遵循 Swift 官方代码风格
- 使用 Swift 6 strict concurrency 模式
- 添加必要的注释和文档
- 编写单元测试覆盖核心逻辑

## 📄 许可证

MIT License

## 🙏 致谢

- [智谱 AI](https://open.bigmodel.cn/) - GLM-ASR-2512 语音识别服务
- Apple - AVFoundation 音频框架
- SwiftUI - 现代化 UI 框架

## 📧 联系方式

- Issue Tracker: [GitHub Issues](https://github.com/yourusername/voxa/issues)
- Email: your.email@example.com

---

**注意**: 本项目目前处于 MVP 阶段,Phase 2 核心功能已完成,Phase 3-5 功能正在开发中。
