//
//  Note.swift
//  boringNotch
//
//  Created by Claude on 05/09/2026.
//

import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var isPinned: Bool
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), content: String, isPinned: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var preview: String {
        let lines = content.split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: true)
        if lines.isEmpty {
            return "Empty note"
        }
        return lines.prefix(2).joined(separator: "\n")
    }
}
