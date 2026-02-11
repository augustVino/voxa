//
//  ToastView.swift
//  Voxa
//
//  Toast 通知视图 - 简约胶囊样式，自适应亮暗主题
//

import SwiftUI

/// Toast 内容视图
struct ToastView: View {
    let message: String
    let type: ToastType
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            // 图标
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)

            // 消息文字
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(textColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundView)
        .clipShape(.capsule)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
        .frame(maxWidth: 360)
    }

    // MARK: - Theme & Type

    private var iconName: String {
        switch type {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.114, green: 0.114, blue: 0.122)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if colorScheme == .dark {
            Color.black.opacity(0.8)
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
        colorScheme == .dark ? 16 : 20
    }
}

// MARK: - Previews

#Preview("Error - Dark") {
    ZStack {
        Color.gray.opacity(0.3)
        ToastView(message: "网络连接失败，请检查网络设置", type: .error)
    }
    .frame(width: 400, height: 200)
    .preferredColorScheme(.dark)
}

#Preview("Warning - Light") {
    ZStack {
        Color.gray.opacity(0.1)
        ToastView(message: "录音时长过短", type: .warning)
    }
    .frame(width: 400, height: 200)
    .preferredColorScheme(.light)
}

#Preview("Success - Dark") {
    ZStack {
        Color.gray.opacity(0.3)
        ToastView(message: "语音识别完成", type: .success)
    }
    .frame(width: 400, height: 200)
    .preferredColorScheme(.dark)
}

#Preview("Info - Light") {
    ZStack {
        Color.gray.opacity(0.1)
        ToastView(message: "正在处理文本...", type: .info)
    }
    .frame(width: 400, height: 200)
    .preferredColorScheme(.light)
}
