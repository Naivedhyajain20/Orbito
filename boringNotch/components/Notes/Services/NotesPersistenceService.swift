//
//  NotesPersistenceService.swift
//  boringNotch
//
//  Created by Claude on 05/09/2026.
//

import Foundation

final class NotesPersistenceService {
    static let shared = NotesPersistenceService()

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let fm = FileManager.default
        let support = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = (support ?? fm.temporaryDirectory)
            .appendingPathComponent("boringNotch", isDirectory: true)
            .appendingPathComponent("Notes", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("notes.json")
        encoder.outputFormatting = [.prettyPrinted]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func load() -> [Note] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }

        if let notes = try? decoder.decode([Note].self, from: data) {
            return notes
        }

        print("⚠️ Failed to decode notes persistence file")
        return []
    }

    func save(_ notes: [Note]) {
        do {
            let data = try encoder.encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save notes: \(error.localizedDescription)")
        }
    }
}
