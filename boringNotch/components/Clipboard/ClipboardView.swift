//
//  ClipboardView.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//  Redesigned with LaunchMe-style categorized tabs + horizontal grids.
//

import SwiftUI

struct ClipboardView: View {
    @StateObject private var manager = ClipboardManager.shared
    @State private var category: ClipboardCategory = .recent

    var filtered: [ClipboardItem] {
        let base = manager.filteredItems
        return category == .recent ? base : base.filter { category.matches($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Category Tabs ───────────────────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ClipboardCategory.allCases, id: \.self) { cat in
                        categoryTab(cat)
                    }
                    Spacer()
                    if !manager.items.isEmpty {
                        Button {
                            manager.clearUnpinned()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Clear all")
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.red.opacity(0.12)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Divider().opacity(0.2)

            // ── Content Grid ────────────────────────────────────────────
            if filtered.isEmpty {
                ClipboardEmptyState()
            } else if category == .images {
                imageGrid
            } else if category == .colors {
                colorGrid
            } else {
                textGrid
            }
        }
    }

    // MARK: - Tab Pill
    private func categoryTab(_ cat: ClipboardCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                category = cat
            }
        } label: {
            Text(cat.rawValue)
                .font(.system(size: 11, weight: category == cat ? .semibold : .medium))
                .foregroundColor(category == cat ? .black : .white.opacity(0.65))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(category == cat ? Color.white : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Image Grid (LaunchMe style: large horizontal image cards)
    private var imageGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(filtered) { item in
                    if let img = item.image {
                        ZStack(alignment: .bottomLeading) {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Timestamp badge
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 7))
                                Text(item.timeAgo)
                                    .font(.system(size: 8, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color.black.opacity(0.6))
                            )
                            .padding(8)

                            // Pin / action buttons on hover (top right)
                            if item.isPinned {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.yellow)
                                            .padding(6)
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                    }
                                    Spacer()
                                }
                                .padding(6)
                            }
                        }
                        .onTapGesture { manager.copy(item) }
                        .contextMenu {
                            Button("Copy") { manager.copy(item) }
                            Button(item.isPinned ? "Unpin" : "Pin") { manager.togglePin(item) }
                            Button("Delete", role: .destructive) { manager.delete(item) }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Color Grid (hex swatch cards — exact LaunchMe match)
    private var colorGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(filtered) { item in
                    if let swatch = item.colorSwatch {
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(swatch)
                                .frame(width: 140, height: 120)

                            VStack(alignment: .leading, spacing: 3) {
                                Spacer()
                                Text(item.text ?? "")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)

                                HStack(spacing: 3) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 7))
                                    Text(item.timeAgo)
                                        .font(.system(size: 8, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(Color.black.opacity(0.35))
                                )
                            }
                            .padding(10)

                            // Pin badge
                            if item.isPinned {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.yellow)
                                            .padding(6)
                                            .background(Circle().fill(Color.black.opacity(0.4)))
                                    }
                                    Spacer()
                                }
                                .padding(6)
                            }
                        }
                        .onTapGesture { manager.copy(item) }
                        .contextMenu {
                            Button("Copy") { manager.copy(item) }
                            Button(item.isPinned ? "Unpin" : "Pin") { manager.togglePin(item) }
                            Button("Delete", role: .destructive) { manager.delete(item) }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Text Grid (horizontal cards like LaunchMe's text clipboard)
    private var textGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(filtered) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        // Type badge for pinned/URL items
                        if item.isPinned || item.itemType == .url {
                            HStack(spacing: 3) {
                                if item.isPinned {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(.yellow)
                                }
                                if item.itemType == .url {
                                    Image(systemName: "link")
                                        .font(.system(size: 7))
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        // Preview text
                        if let image = item.image {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 130, maxHeight: 60)
                                .cornerRadius(6)
                        } else {
                            Text(item.preview)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(5)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 0)

                        // Timestamp
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 7))
                            Text(item.timeAgo)
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color.white.opacity(0.08))
                        )
                    }
                    .padding(10)
                    .frame(width: 155, height: 120, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                    )
                    .onTapGesture { manager.copy(item) }
                    .contextMenu {
                        Button("Copy") { manager.copy(item) }
                        if item.itemType == .url, let urlStr = item.text, let url = URL(string: urlStr) {
                            Button("Open in Browser") { NSWorkspace.shared.open(url) }
                        }
                        Button(item.isPinned ? "Unpin" : "Pin") { manager.togglePin(item) }
                        Button("Delete", role: .destructive) { manager.delete(item) }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
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
