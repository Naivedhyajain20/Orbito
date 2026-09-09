//
//  ClipboardView.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import SwiftUI

struct ClipboardView: View {
    @StateObject private var manager = ClipboardManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Search + clear
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("Search clipboard…", text: $manager.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.caption)
                    .foregroundColor(.white)

                if !manager.items.isEmpty {
                    Button {
                        manager.clearUnpinned()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Clear unpinned items")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Divider().opacity(0.25).padding(.top, 8)

            if manager.filteredItems.isEmpty {
                ClipboardEmptyState()
            } else {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(manager.filteredItems) { item in
                            ClipboardItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct ClipboardItemView: View {
    @StateObject private var manager = ClipboardManager.shared
    let item: ClipboardItem
    @State private var hovering = false
    @State private var copied = false

    var body: some View {
        HStack(spacing: 8) {
            // Type icon
            Image(systemName: item.isPinned ? "pin.fill" : item.itemType.icon)
                .font(.system(size: 11))
                .foregroundColor(item.isPinned ? .yellow : item.itemType.color)
                .frame(width: 16)

            // Content
            Group {
                if let image = item.image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 80, maxHeight: 40)
                        .cornerRadius(4)
                } else {
                    Text(item.preview)
                        .font(.system(size: 11, design: item.itemType == .url ? .monospaced : .default))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)

            if !hovering {
                Text(item.timeAgo)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }

            // Action buttons (show on hover)
            if hovering {
                HStack(spacing: 4) {
                    // Open link if URL
                    if item.itemType == .url, let urlStr = item.text, let url = URL(string: urlStr) {
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                                .frame(width: 22, height: 22)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Open in browser")
                    }

                    // Copy
                    Button {
                        manager.copy(item)
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundColor(copied ? .green : .white)
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Pin
                    Button {
                        manager.togglePin(item)
                    } label: {
                        Image(systemName: item.isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 10))
                            .foregroundColor(item.isPinned ? .yellow : .gray)
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Delete
                    Button {
                        manager.delete(item)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(hovering ? 0.12 : item.isPinned ? 0.1 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(item.isPinned ? Color.yellow.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        )
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovering)
        .onTapGesture {
            manager.copy(item)
            withAnimation { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { copied = false }
            }
        }
    }
}

struct ClipboardEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "clipboard")
                .font(.system(size: 36))
                .foregroundColor(.gray.opacity(0.4))
            Text("Clipboard is empty")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Copy anything to start tracking")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
