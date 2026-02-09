//
//  InputHistoryCleanup.swift
//  Voxa
//
//  Phase 4: 历史记录仅保留最近 30 天，超期自动删除
//

import Foundation
import SwiftData

/// 历史记录 30 天清理
enum InputHistoryCleanup {
    static let retentionDays = 30

    /// 删除 createdAt 早于 (当前 − retentionDays) 的记录
    static func run(context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<InputHistory>(
            predicate: #Predicate<InputHistory> { $0.createdAt < cutoff }
        )
        guard let toDelete = try? context.fetch(descriptor) else { return }
        for record in toDelete {
            context.delete(record)
        }
        if !toDelete.isEmpty {
            try? context.save()
        }
    }
}
