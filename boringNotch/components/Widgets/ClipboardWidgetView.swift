//
//  ClipboardWidgetView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

/// Compact glass widget showing the most recent clipboard snippet with 1-tap copy.
struct ClipboardWidgetView: View {
    @StateObject private var manager = ClipboardManager.shared
    @State private var copied = false

    var body: some View {
        HStack(spacing: 8) {
            if let latest = manager.items.first {
                Image(systemName: latest.itemType.icon)
                    .font(.system(size: 11))
                    .foregroundColor(latest.itemType.color)

                Text(latest.preview)
                    .font(.system(size: 10, design: latest.itemType == .url ? .monospaced : .default))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                    .frame(maxWidth: 120, alignment: .leading)

                Button {
                    manager.copy(latest)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9))
                        .foregroundColor(copied ? .green : .white)
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Image(systemName: "clipboard")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Clipboard empty")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
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
}
