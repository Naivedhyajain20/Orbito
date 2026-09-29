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
        if image != nil { return "[Image]" }
        return text?.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120).description ?? "[Image]"
    }

    var itemType: ClipboardItemType {
        if image != nil { return .image }
        if let t = text {
            if URL(string: t) != nil && (t.hasPrefix("http://") || t.hasPrefix("https://")) { return .url }
            if t.contains("\n") || t.count > 100 { return .multiline }
            // Check if it's a file path pointing to an image
            if fileImagePreview != nil { return .image }
        }
        return .text
    }

    /// Attempts to load an image preview from the text if it's a file path to an image
    var fileImagePreview: NSImage? {
        guard let path = text else { return nil }
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip file:// scheme if present
        let filePath: String
        if trimmed.hasPrefix("file://") {
            filePath = URL(string: trimmed)?.path ?? trimmed
        } else if trimmed.hasPrefix("/") {
            filePath = trimmed
        } else {
            return nil
        }
        let ext = (filePath as NSString).pathExtension.lowercased()
        let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "ico"]
        guard imageExtensions.contains(ext) else { return nil }
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }
        return NSImage(contentsOfFile: filePath)
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

// MARK: - Category Filter (LaunchMe-style tabs)

enum ClipboardCategory: String, CaseIterable {
    case recent    = "Recent"
    case images    = "Images"
    case colors    = "Colors"
    case text      = "Text"
    case files     = "Files"
    case favorites = "Favorites"

    func matches(_ item: ClipboardItem) -> Bool {
        switch self {
        case .recent:    return true
        case .images:    return item.itemType == .image
        case .colors:    return item.text?.isHexColor == true
        case .text:      return item.itemType == .text || item.itemType == .multiline || item.itemType == .url
        case .files:     return item.text?.hasPrefix("file://") == true || item.text?.hasPrefix("/") == true
        case .favorites: return item.isPinned
        }
    }
}

// MARK: - Hex Color Helpers

extension ClipboardItem {
    var colorSwatch: Color? {
        guard let hex = text, hex.isHexColor else { return nil }
        return Color(hex: hex)
    }
}

extension String {
    var isHexColor: Bool {
        let h = trimmingCharacters(in: .whitespacesAndNewlines)
        guard h.hasPrefix("#") else { return false }
        let digits = h.dropFirst()
        guard digits.count == 3 || digits.count == 6 else { return false }
        return digits.allSatisfy { $0.isHexDigit }
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

        // Try to get image data first (from screenshot, browser copy, etc.)
        if let imageData = pb.data(forType: .tiff) ?? pb.data(forType: .png),
           let image = NSImage(data: imageData) {
            // Check if there's also a file URL — if so, store the path alongside the image
            if let fileURLData = pb.data(forType: .fileURL),
               let fileURL = URL(dataRepresentation: fileURLData, relativeTo: nil) {
                let item = ClipboardItem(text: fileURL.path, image: image, source: sourceApp)
                addItem(item)
            } else {
                let item = ClipboardItem(text: nil, image: image, source: sourceApp)
                addItem(item)
            }
            return
        }

        // Check for file URLs (copied files from Finder)
        if let fileURLData = pb.data(forType: .fileURL),
           let fileURL = URL(dataRepresentation: fileURLData, relativeTo: nil) {
            let path = fileURL.path
            let ext = fileURL.pathExtension.lowercased()
            let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "ico"]

            // If it's an image file, capture its thumbnail
            if imageExtensions.contains(ext), let image = NSImage(contentsOfFile: path) {
                let item = ClipboardItem(text: path, image: image, source: sourceApp)
                addItem(item)
            } else {
                // Non-image file — store the path as text
                if let last = items.first(where: { !$0.isPinned }), last.text == path { return }
                let item = ClipboardItem(text: path, source: sourceApp)
                addItem(item)
            }
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
