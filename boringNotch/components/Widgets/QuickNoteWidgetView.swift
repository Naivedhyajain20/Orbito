//
//  QuickNoteWidgetView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

/// Compact glass widget for jotting down a quick thought from the Front Screen.
struct QuickNoteWidgetView: View {
    @ObservedObject var notesVM = NotesStateViewModel.shared
    @State private var quickText: String = ""
    @State private var added = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 11))
                .foregroundColor(.yellow)

            TextField("Quick note…", text: $quickText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 10))
                .foregroundColor(.white)
                .frame(maxWidth: 130)
                .onSubmit {
                    saveNote()
                }

            if !quickText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    saveNote()
                } label: {
                    Image(systemName: added ? "checkmark" : "plus.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(added ? .green : .yellow)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Button {
                BoringViewCoordinator.shared.currentView = .notes
            } label: {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Open Notes")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func saveNote() {
        let trimmed = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notesVM.add(Note(content: trimmed))
        quickText = ""
        withAnimation { added = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { added = false }
        }
    }
}
