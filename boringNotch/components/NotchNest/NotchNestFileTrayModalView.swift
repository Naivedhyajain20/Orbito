//
//  NotchNestFileTrayModalView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import AppKit

struct NotchNestFileTrayModalView: View {
    @StateObject private var tvm = ShelfStateViewModel.shared
    @EnvironmentObject var vm: BoringViewModel
    @State private var isDropTargeted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "tray.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 11))
                    Text("File Tray & AirDrop")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(tvm.items.count) ITEMS")
                        .font(.system(size: 7.5, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.25)))
                        .foregroundColor(.green)
                }

                Spacer()

                if !tvm.items.isEmpty {
                    // Drag all files handle
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("Drag All (\(tvm.items.count))")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.20))
                            .overlay(Capsule().stroke(Color.green.opacity(0.50), lineWidth: 0.8))
                    )
                    .foregroundColor(.green)
                    .onDrag {
                        if let first = tvm.items.first, let url = first.fileURL ?? first.URL {
                            let provider = NSItemProvider(object: url as NSURL)
                            provider.suggestedName = first.displayName
                            return provider
                        }
                        return NSItemProvider()
                    }
                    .help("Drag all files to Finder, Desktop, or other apps")

                    // Clear all button
                    Button(action: {
                        for item in tvm.items {
                            tvm.remove(item)
                        }
                    }) {
                        Text("Clear All")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 1-Click AirDrop Button
                Button(action: {
                    shareWithAirDrop()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "airdrop")
                            .font(.system(size: 10, weight: .bold))
                        Text("AirDrop")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.35))
                            .overlay(Capsule().stroke(Color.blue.opacity(0.6), lineWidth: 0.8))
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Share files via AirDrop")
            }
            .padding(.horizontal, 10)

            // Drop zone area / horizontal item list
            ZStack {
                if tvm.items.isEmpty {
                    VStack(spacing: 4) {
                        Spacer()
                        Image(systemName: isDropTargeted ? "arrow.down.circle.fill" : "arrow.down.doc.fill")
                            .font(.system(size: isDropTargeted ? 24 : 18))
                            .foregroundColor(isDropTargeted ? .green : .white.opacity(0.35))
                            .animation(.spring(response: 0.25), value: isDropTargeted)

                        Text(isDropTargeted ? "Drop Files Here!" : "Drag files, videos or photos here")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(isDropTargeted ? .green : .white.opacity(0.7))

                        Text("Instant temporary stash & drag anywhere or AirDrop")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.45))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isDropTargeted ? Color.green : Color.white.opacity(0.18),
                                style: StrokeStyle(lineWidth: isDropTargeted ? 1.8 : 1, dash: isDropTargeted ? [] : [4])
                            )
                            .background(isDropTargeted ? Color.green.opacity(0.08) : Color.clear)
                    )
                    .padding(4)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tvm.items) { item in
                                VStack(spacing: 3) {
                                    ZStack(alignment: .topTrailing) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.12))
                                                .frame(width: 52, height: 52)
                                                .overlay(
                                                    Group {
                                                        if item.icon.isValid {
                                                            Image(nsImage: item.icon)
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 28, height: 28)
                                                        } else {
                                                            Image(systemName: "doc.fill")
                                                                .font(.system(size: 22))
                                                                .foregroundColor(.cyan)
                                                        }
                                                    }
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                                                )
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            openItem(item)
                                        }
                                        .onDrag {
                                            if let url = item.fileURL ?? item.URL {
                                                let provider = NSItemProvider(object: url as NSURL)
                                                provider.suggestedName = item.displayName
                                                return provider
                                            }
                                            return NSItemProvider(object: item.displayName as NSString)
                                        }
                                        .help("Drag to move/copy to Finder or other apps, or click to open \(item.displayName)")

                                        // Remove button
                                        Button(action: {
                                            tvm.remove(item)
                                        }) {
                                            Circle()
                                                .fill(Color.black.opacity(0.85))
                                                .frame(width: 15, height: 15)
                                                .overlay(
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 6.5, weight: .heavy))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .offset(x: 4, y: -4)
                                    }

                                    Text(item.displayName.isEmpty ? "File" : item.displayName)
                                        .font(.system(size: 8.5, weight: .medium))
                                        .foregroundColor(.white.opacity(0.90))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(width: 58)
                                }
                            }
                        }
                        .padding(6)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isDropTargeted ? Color.green : Color.white.opacity(0.12),
                                lineWidth: isDropTargeted ? 1.8 : 0.8
                            )
                            .background(isDropTargeted ? Color.green.opacity(0.08) : Color.clear)
                    )
                    .padding(4)
                }
            }
        }
        .padding(6)
        .frame(height: 110)
        .onDrop(of: [.fileURL, .url, .utf8PlainText, .plainText, .data], isTargeted: $isDropTargeted) { providers in
            vm.dropEvent = true
            tvm.load(providers)
            return true
        }
    }

    private func openItem(_ item: ShelfItem) {
        if let url = item.fileURL ?? item.URL {
            NSWorkspace.shared.open(url)
        }
    }

    private func shareWithAirDrop() {
        let urls = tvm.items.compactMap { $0.fileURL ?? $0.URL }
        if !urls.isEmpty {
            let picker = NSSharingServicePicker(items: urls)
            if let window = NSApplication.shared.keyWindow, let contentView = window.contentView {
                picker.show(relativeTo: NSRect.zero, of: contentView, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}
