//
//  ClipboardManager.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import AppKit
import Combine
import SwiftUI

// MARK: - Model

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let text: String?
    let image: NSImage?
    let source: String? // App bundle ID
    let createdAt: Date
    var isPinned: Bool

    init(text: String?, image: NSImage? = nil, source: String? = nil) {
        self.id = UUID()
        self.text = text
        self.image = image
        self.source = source
        self.createdAt = Date()
        self.isPinned = false
    }

    var preview: String {
        text?.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120).description ?? "[Image]"
    }

    var itemType: ClipboardItemType {
        if image != nil { return .image }
        if let t = text {
            if URL(string: t) != nil && (t.hasPrefix("http://") || t.hasPrefix("https://")) { return .url }
            if t.contains("\n") || t.count > 100 { return .multiline }
        }
        return .text
    }

    var timeAgo: String {
        let diff = Date().timeIntervalSince(createdAt)
        if diff < 60 { return "\(max(1, Int(diff))) sec ago" }
        if diff < 3600 { return "\(max(1, Int(diff / 60))) min ago" }
        if diff < 86400 { return "\(max(1, Int(diff / 3600))) hr ago" }
        return "\(max(1, Int(diff / 86400))) d ago"
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool { lhs.id == rhs.id }
}

enum ClipboardItemType {
    case text, url, multiline, image

    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .url: return "link"
        case .multiline: return "text.alignleft"
        case .image: return "photo"
        }
    }

    var color: Color {
        switch self {
        case .text: return .white
        case .url: return .blue
        case .multiline: return .purple
        case .image: return .green
        }
    }
}

// MARK: - Manager

@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""

    private var lastChangeCount: Int = 0
    private var pollingTask: Task<Void, Never>?
    private let maxItems = 20

    // Bundle IDs to ignore (password managers, etc.)
    private let blocklist: Set<String> = [
        "com.agilebits.onepassword7",
        "com.agilebits.onepassword-osx",
        "com.dashlane.Dashlane",
        "com.lastpass.LastPassDesktop",
        "com.bitwarden.desktop",
        "io.keybase.Keybase"
    ]

    var filteredItems: [ClipboardItem] {
        let sorted = items.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.createdAt > b.createdAt
        }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { ($0.text ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startPolling()
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self = self else { return }
                await self.checkClipboard()
            }
        }
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        purgeExpired()

        // Check source app — skip blocklisted apps
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontApp.bundleIdentifier,
           blocklist.contains(bundleId) {
            return
        }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        // Try to get image first
        if let imageData = pb.data(forType: .tiff) ?? pb.data(forType: .png),
           let image = NSImage(data: imageData) {
            let item = ClipboardItem(text: nil, image: image, source: sourceApp)
            addItem(item)
            return
        }

        // Get text
        if let text = pb.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Avoid re-adding the exact same text twice in a row
            if let last = items.first(where: { !$0.isPinned }), last.text == text { return }
            let item = ClipboardItem(text: text, source: sourceApp)
            addItem(item)
        }
    }

    private func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        // Keep max unpinned items
        let unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxItems {
            if let oldest = unpinned.last, let idx = items.firstIndex(where: { $0.id == oldest.id }) {
                items.remove(at: idx)
            }
        }
    }

    func copy(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if let text = item.text {
            pb.setString(text, forType: .string)
        } else if let image = item.image, let tiff = image.tiffRepresentation {
            pb.setData(tiff, forType: .tiff)
        }
        lastChangeCount = pb.changeCount // Prevent re-adding
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearAll() {
        items.removeAll()
    }

    func clearUnpinned() {
        items.removeAll { !$0.isPinned }
    }

    func purgeExpired() {
        let cutoff = Date().addingTimeInterval(-48 * 3600)
        items.removeAll { !$0.isPinned && $0.createdAt < cutoff }
    }
}
