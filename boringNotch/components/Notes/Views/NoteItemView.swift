//
//  NoteItemView.swift
//  boringNotch
//
//  Created by Claude on 05/09/2026.
//

import SwiftUI

struct NoteItemView: View {
    let note: Note
    let onAction: (NoteAction) -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(note.preview)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(timeAgo(from: note.updatedAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Actions
            HStack(spacing: 8) {
                // Pin button
                Button {
                    onAction(.togglePin)
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(note.isPinned ? .yellow : .gray)
                }
                .buttonStyle(PlainButtonStyle())

                // Copy button
                Button {
                    onAction(.copy)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())

                // Delete button
                Button {
                    onAction(.delete)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .opacity(isHovering ? 1 : 0)
        }
        .padding(12)
        .background(Color.white.opacity(isHovering ? 0.15 : 0.1))
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onAction(.edit)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        let minutes = Int(seconds / 60)
        let hours = Int(seconds / 3600)
        let days = Int(seconds / 86400)

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}
