//
//  WaveformView.swift
//  Voxa
//
//  实时波形动效 - 条形样式,基于音量数据流
//

import SwiftUI

/// 波形条数量
private let barCount = 16

/// 实时波形视图
/// 显示一组条形,高度随音量变化 (约 30 FPS 更新)
struct WaveformView: View {
    /// 最近 N 帧的音量值 (0.0 ~ 1.0), 从左到右为从旧到新
    let levels: [Float]
    
    /// 条形宽度
    private let barWidth: CGFloat = 4
    /// 条形间距
    private let barSpacing: CGFloat = 3
    /// 最大条形高度
    private let maxBarHeight: CGFloat = 24
    
    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.9))
                    .frame(width: barWidth, height: barHeight(at: index))
                    .animation(.easeOut(duration: 0.05), value: levels)
            }
        }
        .frame(height: maxBarHeight)
    }
    
    private func barHeight(at index: Int) -> CGFloat {
        let count = levels.count
        guard index < count else { return 4 }
        let level = CGFloat(levels[index])
        let height = max(4, level * maxBarHeight)
        return min(height, maxBarHeight)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
        WaveformView(levels: [0.2, 0.5, 0.8, 0.6, 0.4, 0.7, 0.9, 0.5, 0.3, 0.6, 0.8, 0.4, 0.5, 0.7, 0.6, 0.3])
            .padding()
    }
    .frame(width: 200, height: 80)
}
