//
//  RecordingOverlayView.swift
//  Voxa
//
//  录音状态浮窗内容 - 状态文字 + 波形 + 可选部分识别结果
//

import SwiftUI

/// 录音浮窗内容视图
/// 展示状态文字、实时波形、流式模式下的部分识别结果
struct RecordingOverlayView: View {
    @Bindable var state: OverlayState
    
    var body: some View {
        VStack(spacing: 12) {
            // 状态文字
            Text(state.statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            
            // 波形
            WaveformView(levels: state.levels)
            
            // 流式部分结果
            if !state.partialResult.isEmpty {
                Text(state.partialResult)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

/// 浮窗可观测状态 (供 OverlayPanel 与 SwiftUI 共享)
@Observable
final class OverlayState {
    var statusText: String = "正在聆听..."
    /// 最近 16 帧音量 (0.0~1.0), 用于波形条
    var levels: [Float] = Array(repeating: 0, count: OverlayState.barCountForOverlay)
    var partialResult: String = ""
    
    static let barCountForOverlay = 16
}

#Preview {
    let state = OverlayState()
    state.statusText = "正在聆听..."
    state.levels = (0..<16).map { _ in Float.random(in: 0.2...0.9) }
    return RecordingOverlayView(state: state)
        .padding()
        .background(Color.black.opacity(0.3))
}
