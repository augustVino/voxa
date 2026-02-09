//
//  HotwordCorrector.swift
//  Voxa
//
//  Phase 3: 从 SwiftData 加载热词，按优先级降序、不区分大小写替换 STT 原始文本
//

import Foundation
import SwiftData

/// 热词校正器：从 ModelContext 加载热词，对文本按优先级不区分大小写替换
final class HotwordCorrector: @unchecked Sendable {
    private let queue = DispatchQueue(label: "voxa.hotword.cache")
    private var cachedList: [(pattern: String, replacement: String, priority: Int)] = []

    init() {}

    /// 从 ModelContext 重新加载热词列表（供 Session/TextProcessor 在需要时刷新）
    func reload(from context: ModelContext) {
        let descriptor = FetchDescriptor<Hotword>(
            sortBy: [SortDescriptor(\.priority, order: .reverse)]
        )
        let list = (try? context.fetch(descriptor)) ?? []
        queue.sync {
            cachedList = list.map { (pattern: $0.pattern, replacement: $0.replacement, priority: $0.priority) }
        }
    }

    /// 对文本进行热词校正：按优先级降序、不区分大小写替换；空文本返回空，无热词时原样返回。
    /// 多热词策略：按 priority 降序逐条应用，每条用 replacingOccurrences 一次替换全部匹配，同一匹配只替换一次，避免循环替换。
    func correct(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        let list = queue.sync { cachedList }
        if list.isEmpty { return text }

        var result = text
        for item in list {
            guard !item.pattern.isEmpty else { continue }
            result = result.replacingOccurrences(
                of: item.pattern,
                with: item.replacement,
                options: .caseInsensitive,
                range: nil
            )
        }
        return result
    }
}
