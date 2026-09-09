//
//  NotesView.swift
//  boringNotch
//
//  Created by Claude on 05/09/2026.
//

import SwiftUI
import Defaults

struct NotesView: View {
    @ObservedObject var notesViewModel = NotesStateViewModel.shared
    @State private var isShowingEditor = false
    @State private var editingNote: Note?

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search notes...", text: $notesViewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)

                if !notesViewModel.searchText.isEmpty {
                    Button {
                        notesViewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Notes list
            if notesViewModel.filteredNotes.isEmpty {
                EmptyNotesView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(notesViewModel.filteredNotes) { note in
                            NoteItemView(note: note) { action in
                                handleNoteAction(action, for: note)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            // New note button
            Button {
                editingNote = nil
                isShowingEditor = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Note")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .sheet(isPresented: $isShowingEditor) {
            NoteEditorView(note: editingNote) { savedNote in
                if let existing = editingNote {
                    var updated = existing
                    updated.content = savedNote.content
                    notesViewModel.update(updated)
                } else {
                    notesViewModel.add(savedNote)
                }
                isShowingEditor = false
            }
        }
    }

    private func handleNoteAction(_ action: NoteAction, for note: Note) {
        switch action {
        case .edit:
            editingNote = note
            isShowingEditor = true
        case .copy:
            notesViewModel.copyToClipboard(note)
        case .togglePin:
            notesViewModel.togglePin(note)
        case .delete:
            notesViewModel.delete(note)
        }
    }
}

struct EmptyNotesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No notes yet")
                .font(.headline)
                .foregroundColor(.white)
            Text("Create your first note to get started")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

enum NoteAction {
    case edit
    case copy
    case togglePin
    case delete
}
