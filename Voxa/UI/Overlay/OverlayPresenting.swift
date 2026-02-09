//
//  OverlayPresenting.swift
//  Voxa
//
//  浮窗展示协议定义
//

import Foundation

/// 浮窗位置枚举
enum OverlayPosition: String, Sendable {
    case bottomCenter
    case bottomLeft
    case bottomRight
}

/// 浮窗展示协议
/// 定义录音状态浮窗的显示和隐藏接口
protocol OverlayPresenting: Sendable {
    /// 显示浮窗
    /// - Parameters:
    ///   - position: 浮窗位置
    ///   - animated: 是否使用动画
    func show(at position: OverlayPosition, animated: Bool) async
    
    /// 隐藏浮窗
    /// - Parameter animated: 是否使用动画
    func hide(animated: Bool) async
    
    /// 更新浮窗状态文本
    /// - Parameter text: 状态文本 (如 "正在聆听..." / "识别中...")
    func updateStatus(_ text: String) async
    
    /// 更新流式识别部分结果
    /// - Parameter partialText: 部分识别文本
    func updatePartialResult(_ partialText: String) async
    
    /// 设置实时音量数据流 (录音开始时调用,用于波形动效)
    /// - Parameter stream: 归一化音量值流 (0.0 ~ 1.0)
    func setLevelStream(_ stream: AsyncStream<Float>) async
}

// MARK: - Default Parameter Values

extension OverlayPresenting {
    /// 显示浮窗 (默认使用动画)
    func show(at position: OverlayPosition) async {
        await show(at: position, animated: true)
    }
    
    /// 隐藏浮窗 (默认使用动画)
    func hide() async {
        await hide(animated: true)
    }
}
