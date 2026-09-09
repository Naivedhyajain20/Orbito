//
//  NoteEditorView.swift
//  boringNotch
//
//  Created by Claude on 05/09/2026.
//

import SwiftUI

struct NoteEditorView: View {
    let note: Note?
    let onSave: (Note) -> Void

    @State private var content: String
    @Environment(\.dismiss) private var dismiss

    init(note: Note?, onSave: @escaping (Note) -> Void) {
        self.note = note
        self.onSave = onSave
        _content = State(initialValue: note?.content ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(note == nil ? "New Note" : "Edit Note")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.gray)

                Button("Save") {
                    saveNote()
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.accentColor)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color.black.opacity(0.3))

            // Editor
            TextEditor(text: $content)
                .font(.body)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding()
        }
        .frame(width: 500, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func saveNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        let savedNote = Note(
            id: note?.id ?? UUID(),
            content: trimmedContent,
            isPinned: note?.isPinned ?? false,
            createdAt: note?.createdAt ?? Date(),
            updatedAt: Date()
        )

        onSave(savedNote)
        dismiss()
    }
}
