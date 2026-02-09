//
//  InputHistory.swift
//  Voxa
//
//  Phase 3: SwiftData 输入历史模型（预留，Phase 3 可仅做最小持久化）
//

import Foundation
import SwiftData

/// 输入历史：原始文本、处理后文本、人设名、时长等（Phase 3 预留）
@Model
final class InputHistory {
    @Attribute(.unique) var id: String
    var rawText: String
    var processedText: String
    var personaName: String?
    var duration: TimeInterval
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        rawText: String,
        processedText: String,
        personaName: String? = nil,
        duration: TimeInterval = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.rawText = rawText
        self.processedText = processedText
        self.personaName = personaName
        self.duration = duration
        self.createdAt = createdAt
    }
}
