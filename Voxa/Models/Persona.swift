//
//  Persona.swift
//  Voxa
//
//  Phase 3: SwiftData 人设模型 - 用于 LLM 润色时的 system prompt
//

import Foundation
import SwiftData

/// 人设模型：名称、润色 prompt、描述与排序
@Model
final class Persona {
    @Attribute(.unique) var id: String
    var name: String
    var prompt: String
    var descriptionText: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        prompt: String,
        descriptionText: String = "",
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.descriptionText = descriptionText
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
