# Voxa Phase 2 设置指南

## ✅ 编译状态: 成功

Phase 2 所有文件已正确添加到 Xcode 项目,编译成功!

## 快速开始

### 1. 打开 Xcode 项目

```bash
cd /Users/liepin/Documents/github/voxa
open Voxa.xcodeproj
```

### 2. 验证项目结构

在 Xcode 项目导航器中,确认以下文件已正确添加:

```
Voxa/
├── Core/
│   ├── Audio/
│   │   ├── AudioFormat.swift
│   │   ├── AudioError.swift
│   │   ├── AudioCapturing.swift
│   │   ├── AudioEncoder.swift
│   │   ├── AudioLevelProvider.swift
│   │   └── AudioPipeline.swift
│   ├── STT/
│   │   ├── STTError.swift
│   │   ├── STTProvider.swift
│   │   ├── MultipartFormData.swift
│   │   └── ZhipuSTTProvider.swift
│   ├── Session/
│   │   └── SessionCoordinator.swift
│   ├── KeyMonitor/
│   └── Permissions/
├── Services/
│   └── AppSettings.swift
├── UI/
│   ├── MenuBar/
│   └── Overlay/
│       └── OverlayPresenting.swift
└── VoxaApp.swift
```

### 3. 编译项目

1. 在 Xcode 中按 `Cmd+B` 编译项目
2. ✅ 应该显示 "Build Succeeded"
3. 按 `Cmd+R` 运行项目

### 如果遇到编译错误

如果编译失败,尝试:

1. **清理构建**: `Product` → `Clean Build Folder` (或 `Cmd+Shift+K`)
2. **删除 DerivedData**: 
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Voxa-*
   ```
3. **重新打开项目**: 关闭 Xcode 并重新打开项目

### 4. 配置 API Key

编译成功后,配置智谱 API Key:

```bash
./scripts/configure-api-key.sh YOUR_API_KEY
```

### 5. 测试功能

1. 运行应用
2. 点击菜单栏的 Voxa 图标
3. 确认显示 "状态: 就绪"
4. 按住 Fn 键说话
5. 松开 Fn 键
6. 查看控制台输出识别文本

## 故障排查

### 问题: "No such module 'AVFoundation'"

**原因**: 缺少系统框架

**解决方案**: 
1. 选择项目根节点
2. 选择 "Voxa" target
3. 切换到 "Build Phases" 标签
4. 展开 "Link Binary With Libraries"
5. 点击 "+" 添加 `AVFoundation.framework`

### 问题: 编译时出现 Swift 6 并发错误

**原因**: 代码使用了 Swift 6 的并发特性

**解决方案**: 确保 Xcode 版本 ≥ 15.0,并且项目设置中 Swift Language Version 为 6.0

## 下一步

参考 [quickstart.md](./specs/002-audio-stt/quickstart.md) 了解如何使用和测试 Phase 2 功能。
