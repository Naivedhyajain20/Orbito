//
//  NotchNestBookmarksModalView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import AppKit

struct BookmarkItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var target: String // URL or Mac App Path
    var isApp: Bool = false
}

struct NotchNestBookmarksModalView: View {
    @State private var bookmarks: [BookmarkItem] = []
    @State private var isAdding: Bool = false
    @State private var newName: String = ""
    @State private var newTarget: String = ""
    @State private var isAppType: Bool = false
    @State private var hoveredId: UUID? = nil

    private let storageKey = "Orbito_SavedBookmarks_v2"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Bar
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 11))
                    Text("Quick Launch & Bookmarks")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("AUTO-LOGO")
                        .font(.system(size: 7, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.25)))
                        .foregroundColor(.blue)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        isAdding.toggle()
                        if !isAdding {
                            newName = ""
                            newTarget = ""
                        }
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: isAdding ? "xmark" : "plus")
                            .font(.system(size: 8, weight: .bold))
                        Text(isAdding ? "Close" : "Add Shortcut")
                            .font(.system(size: 8.5, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(isAdding ? Color.red.opacity(0.2) : Color.blue.opacity(0.25)))
                    .foregroundColor(isAdding ? .red : .white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 10)
            .padding(.top, 4)

            // Add Shortcut Drawer
            if isAdding {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        // Website vs App Toggle
                        Button(action: { isAppType = false }) {
                            HStack(spacing: 3) {
                                Image(systemName: "globe")
                                Text("Website")
                            }
                            .font(.system(size: 8.5, weight: isAppType ? .regular : .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(isAppType ? Color.white.opacity(0.06) : Color.blue.opacity(0.35))
                            .clipShape(Capsule())
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            isAppType = true
                            openAppPicker()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "macwindow")
                                Text("Mac App")
                            }
                            .font(.system(size: 8.5, weight: isAppType ? .bold : .regular))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(isAppType ? Color.blue.opacity(0.35) : Color.white.opacity(0.06))
                            .clipShape(Capsule())
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)

                        if isAppType {
                            Button("📂 Browse...") {
                                openAppPicker()
                            }
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(.cyan)
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }

                    HStack(spacing: 6) {
                        TextField(isAppType ? "App Name (e.g. Slack)" : "Name (e.g. ChatGPT)", text: $newName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
                            .foregroundColor(.white)
                            .frame(maxWidth: 140)

                        TextField(isAppType ? "App Path (/Applications/...)" : "URL (e.g. chatgpt.com)", text: $newTarget)
                            .textFieldStyle(.plain)
                            .font(.system(size: 9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
                            .foregroundColor(.white)
                            .onChange(of: newTarget) { _, val in
                                if !isAppType && newName.isEmpty {
                                    newName = autoExtractName(from: val)
                                }
                            }

                        Button("Save") {
                            saveNewShortcut()
                        }
                        .font(.system(size: 9.5, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .buttonStyle(.plain)
                        .disabled(newTarget.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.35)))
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Shortcuts Grid / Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(bookmarks) { item in
                        Button(action: {
                            launch(item: item)
                        }) {
                            VStack(spacing: 3) {
                                ZStack(alignment: .topTrailing) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .fill(Color(white: 0.15).opacity(0.85))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                                    .stroke(Color.white.opacity(hoveredId == item.id ? 0.25 : 0.08), lineWidth: 1)
                                            )

                                        ShortcutIconView(item: item)
                                            .frame(width: 26, height: 26)
                                    }

                                    // Delete Button on Hover
                                    if hoveredId == item.id {
                                        Button(action: {
                                            delete(item: item)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.black))
                                        }
                                        .buttonStyle(.plain)
                                        .offset(x: 4, y: -4)
                                    }
                                }

                                Text(item.name)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                                    .frame(maxWidth: 52)
                            }
                            .frame(width: 52)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { isHovered in
                            hoveredId = isHovered ? item.id : nil
                        }
                        .contextMenu {
                            Button("Open") {
                                launch(item: item)
                            }
                            Button("Delete", role: .destructive) {
                                delete(item: item)
                            }
                        }
                        .help(item.target)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
            }
        }
        .padding(.vertical, 4)
        .frame(height: isAdding ? 140 : 96)
        .onAppear {
            loadBookmarks()
        }
    }

    // MARK: - Actions
    private func saveNewShortcut() {
        var cleanTarget = newTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTarget.isEmpty else { return }

        var finalName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalName.isEmpty {
            finalName = isAppType ? (cleanTarget as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "") : autoExtractName(from: cleanTarget)
        }

        if !isAppType && !cleanTarget.hasPrefix("http://") && !cleanTarget.hasPrefix("https://") {
            cleanTarget = "https://" + cleanTarget
        }

        let newItem = BookmarkItem(name: finalName, target: cleanTarget, isApp: isAppType || cleanTarget.hasSuffix(".app"))
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            bookmarks.append(newItem)
            saveBookmarks()
            newName = ""
            newTarget = ""
            isAdding = false
        }
    }

    private func delete(item: BookmarkItem) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            bookmarks.removeAll { $0.id == item.id }
            saveBookmarks()
        }
    }

    private func launch(item: BookmarkItem) {
        if item.isApp || item.target.hasPrefix("/") || item.target.hasSuffix(".app") {
            if FileManager.default.fileExists(atPath: item.target) {
                NSWorkspace.shared.open(URL(fileURLWithPath: item.target))
            } else if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.target) {
                NSWorkspace.shared.open(appUrl)
            } else {
                let candidate = "/Applications/\(item.target).app"
                if FileManager.default.fileExists(atPath: candidate) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: candidate))
                }
            }
        } else if let u = URL(string: item.target) {
            NSWorkspace.shared.open(u)
        }
    }

    private func openAppPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        if panel.runModal() == .OK, let url = panel.url {
            let appPath = url.path
            let appName = url.deletingPathExtension().lastPathComponent
            newTarget = appPath
            newName = appName
            isAppType = true
        }
    }

    private func autoExtractName(from urlString: String) -> String {
        var clean = urlString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "www.", with: "")
        if let firstSlash = clean.firstIndex(of: "/") {
            clean = String(clean[..<firstSlash])
        }
        let parts = clean.split(separator: ".")
        if let domainName = parts.first {
            return domainName.capitalized
        }
        return "Website"
    }

    // MARK: - Persistence
    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([BookmarkItem].self, from: data),
           !saved.isEmpty {
            self.bookmarks = saved
        } else {
            // Default Starters with Auto-Logos
            self.bookmarks = [
                BookmarkItem(name: "ChatGPT", target: "https://chatgpt.com", isApp: false),
                BookmarkItem(name: "GitHub", target: "https://github.com", isApp: false),
                BookmarkItem(name: "Claude", target: "https://claude.ai", isApp: false),
                BookmarkItem(name: "YouTube", target: "https://youtube.com", isApp: false),
                BookmarkItem(name: "Figma", target: "https://figma.com", isApp: false),
                BookmarkItem(name: "X (Twitter)", target: "https://x.com", isApp: false),
                BookmarkItem(name: "Finder", target: "/System/Library/CoreServices/Finder.app", isApp: true),
                BookmarkItem(name: "Terminal", target: "/System/Applications/Utilities/Terminal.app", isApp: true)
            ]
            saveBookmarks()
        }
    }

    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

// MARK: - Smart Shortcut Icon View
struct ShortcutIconView: View {
    let item: BookmarkItem

    var body: some View {
        SmartShortcutIconView(
            name: item.name,
            target: item.target,
            type: item.isApp ? .app : .url,
            fallbackIcon: item.isApp ? "app.badge.fill" : "globe",
            size: 24
        )
    }
}

