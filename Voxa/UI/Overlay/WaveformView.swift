//
//  WaveformView.swift
//  Voxa
//
//  实时波形动效 - 简约胶囊样式
//

import SwiftUI

/// 实时波形视图
/// 简约胶囊样式: 12条细波形
struct WaveformView: View {
    /// 最近 N 帧的音量值 (0.0 ~ 1.0), 从左到右为从旧到新
    let levels: [Float]
    /// 波形条颜色
    var color: Color = .white

    /// 条形数量
    private let barCount = 12
    /// 条形宽度
    private let barWidth: CGFloat = 3
    /// 条形间距
    private let barSpacing: CGFloat = 2
    /// 最大条形高度
    private let maxBarHeight: CGFloat = 20
    /// 最小条形高度
    private let minBarHeight: CGFloat = 4

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: barWidth, height: barHeight(at: index))
                    .animation(.easeOut(duration: 0.05), value: levels)
            }
        }
        .frame(height: maxBarHeight)
    }

    private func barHeight(at index: Int) -> CGFloat {
        let count = levels.count
        guard index < count else { return minBarHeight }
        let level = CGFloat(levels[index])
        let height = max(minBarHeight, level * maxBarHeight)
        return min(height, maxBarHeight)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
        WaveformView(levels: [0.2, 0.5, 0.8, 0.6, 0.4, 0.7, 0.9, 0.5, 0.3, 0.6, 0.8, 0.4])
            .padding()
    }
    .frame(width: 160, height: 60)
}
