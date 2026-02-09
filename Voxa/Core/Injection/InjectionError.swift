//
//  InjectionError.swift
//  Voxa
//
//  Phase 3: 文本注入错误类型（可选，用于注入失败原因）
//

import Foundation

/// 文本注入相关错误
enum InjectionError: Error, Sendable {
    /// 无法获取当前焦点元素
    case noFocusedElement
    /// AX 写入失败
    case axWriteFailed(String)
    /// 剪贴板兜底也失败
    case fallbackPasteFailed(String)
    /// 其他
    case other(String)
}

extension InjectionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noFocusedElement:
            return "无法获取当前焦点"
        case .axWriteFailed(let msg):
            return "AX 写入失败: \(msg)"
        case .fallbackPasteFailed(let msg):
            return "粘贴兜底失败: \(msg)"
        case .other(let msg):
            return msg
        }
    }
}
