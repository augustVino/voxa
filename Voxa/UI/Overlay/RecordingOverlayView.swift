//
//  RecordingOverlayView.swift
//  Voxa
//
//  录音状态浮窗内容 - 简约胶囊样式，自适应亮暗主题
//

import SwiftUI

/// 录音浮窗内容视图
/// 简约胶囊样式: 录音红点 + 波形 + 状态文字
struct RecordingOverlayView: View {
    @Bindable var state: OverlayState
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            // 录音红点 (带呼吸动画)
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .symbolEffect(.pulse, options: .repeating.speed(0.7))

            // 波形
            WaveformView(levels: state.levels, color: waveformColor)

            // 状态文字
            Text(state.statusText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(backgroundView)
        .clipShape(.capsule)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
    }

    // MARK: - Theme Colors

    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.114, green: 0.114, blue: 0.122)
    }

    private var waveformColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.114, green: 0.114, blue: 0.122)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if colorScheme == .dark {
            Color.black.opacity(0.75)
        } else {
            Color.white.opacity(0.95)
        }
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? .black.opacity(0.4)
            : .black.opacity(0.15)
    }

    private var shadowRadius: CGFloat {
        colorScheme == .dark ? 20 : 24
    }
}

/// 浮窗可观测状态 (供 OverlayPanel 与 SwiftUI 共享)
@Observable
final class OverlayState {
    var statusText: String = "聆听中..."
    /// 最近 N 帧音量 (0.0~1.0), 用于波形条
    var levels: [Float] = Array(repeating: 0, count: OverlayState.barCountForOverlay)
    var partialResult: String = ""

    static let barCountForOverlay = 12
}

#Preview("Dark Mode") {
    let state = OverlayState()
    state.statusText = "聆听中..."
    state.levels = (0..<12).map { _ in Float.random(in: 0.2...0.9) }
    return ZStack {
        Color.gray.opacity(0.3)
        RecordingOverlayView(state: state)
    }
    .frame(width: 300, height: 100)
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    let state = OverlayState()
    state.statusText = "聆听中..."
    state.levels = (0..<12).map { _ in Float.random(in: 0.2...0.9) }
    return ZStack {
        Color.gray.opacity(0.1)
        RecordingOverlayView(state: state)
    }
    .frame(width: 300, height: 100)
    .preferredColorScheme(.light)
}
