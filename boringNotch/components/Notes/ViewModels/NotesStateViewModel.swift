//
//  NotesStateViewModel.swift
//  boringNotch
//
//  Created by Claude on 05/09/2026.
//

import Foundation
import SwiftUI

@MainActor
final class NotesStateViewModel: ObservableObject {
    static let shared = NotesStateViewModel()

    @Published private(set) var notes: [Note] = [] {
        didSet {
            NotesPersistenceService.shared.save(notes)
        }
    }

    @Published var searchText: String = ""

    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return sortedNotes
        }
        return sortedNotes.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    private var sortedNotes: [Note] {
        notes.sorted { note1, note2 in
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            return note1.updatedAt > note2.updatedAt
        }
    }

    private init() {
        notes = NotesPersistenceService.shared.load()
    }

    func add(_ note: Note) {
        notes.append(note)
    }

    func update(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
        }
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
    }

    func togglePin(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            notes[index].updatedAt = Date()
        }
    }

    func copyToClipboard(_ note: Note) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note.content, forType: .string)
    }
}
