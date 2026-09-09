//
//  NotchNestBookmarksModalView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import AppKit

struct BookmarkItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var url: String
    var icon: String
}

struct NotchNestBookmarksModalView: View {
    @State private var bookmarks: [BookmarkItem] = [
        BookmarkItem(name: "ChatGPT", url: "https://chatgpt.com", icon: "brain.head.profile"),
        BookmarkItem(name: "GitHub", url: "https://github.com", icon: "chevron.left.forwardslash.chevron.right"),
        BookmarkItem(name: "YouTube", url: "https://youtube.com", icon: "play.rectangle.fill"),
        BookmarkItem(name: "Notion", url: "https://notion.so", icon: "doc.text.fill"),
        BookmarkItem(name: "Figma", url: "https://figma.com", icon: "paintpalette.fill"),
        BookmarkItem(name: "X (Twitter)", url: "https://x.com", icon: "bubble.left.fill"),
        BookmarkItem(name: "Gmail", url: "https://mail.google.com", icon: "envelope.fill")
    ]

    @State private var isAdding: Bool = false
    @State private var newName: String = ""
    @State private var newUrl: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 11))
                    Text("Instant Bookmarks")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("UNLIMITED")
                        .font(.system(size: 7, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.25)))
                        .foregroundColor(.blue)
                }

                Spacer()

                Button(action: {
                    isAdding.toggle()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: isAdding ? "xmark" : "plus")
                            .font(.system(size: 8, weight: .bold))
                        Text(isAdding ? "Cancel" : "Add Bookmark")
                            .font(.system(size: 8.5, weight: .semibold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.blue.opacity(0.25)))
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)

            if isAdding {
                HStack(spacing: 6) {
                    TextField("Name (e.g. Claude)", text: $newName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 9))
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
                        .foregroundColor(.white)

                    TextField("URL (e.g. https://claude.ai)", text: $newUrl)
                        .textFieldStyle(.plain)
                        .font(.system(size: 9))
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
                        .foregroundColor(.white)

                    Button("Save") {
                        if !newName.isEmpty && !newUrl.isEmpty {
                            let formattedUrl = newUrl.hasPrefix("http") ? newUrl : "https://" + newUrl
                            bookmarks.append(BookmarkItem(name: newName, url: formattedUrl, icon: "safari.fill"))
                            newName = ""
                            newUrl = ""
                            isAdding = false
                        }
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.cyan)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(bookmarks) { b in
                        Button(action: {
                            if let u = URL(string: b.url) {
                                NSWorkspace.shared.open(u)
                            }
                        }) {
                            VStack(spacing: 3) {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: b.icon)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white)
                                    )
                                Text(b.name)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                            }
                            .frame(width: 52)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(b.url)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .padding(8)
        .frame(height: 105)
    }
}
