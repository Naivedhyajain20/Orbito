//
//  SpaceBackgroundPickerView.swift
//  boringNotch
//
//  Settings UI for configuring per-Space background styles and wallpaper images.
//

import Defaults
import SwiftUI
import AppKit

struct SpaceBackgroundPickerView: View {
    @ObservedObject var spacesManager = SpacesSyncManager.shared
    @Default(.spaceBackgrounds) var spaceBackgrounds

    private var activeStyle: NotchBackground {
        spacesManager.currentBackground
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Current Active Space", systemImage: "macwindow.on.rectangle")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("Space #\(spacesManager.currentSpaceID)")
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Style selector pills
            HStack(spacing: 8) {
                ForEach(NotchBackground.allCases, id: \.self) { style in
                    Button(action: {
                        spacesManager.setBackground(style)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: style.icon)
                                .font(.system(size: 11))
                            Text(style.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            activeStyle == style
                                ? Color.accentColor
                                : Color.white.opacity(0.08)
                        )
                        .foregroundColor(activeStyle == style ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Wallpaper image picker (only show when Image mode is active)
            if activeStyle == .image {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notch Wallpaper", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        // Preview thumbnail
                        if let wallpaperImage = spacesManager.currentWallpaperImage {
                            Image(nsImage: wallpaperImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 80, height: 48)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Button(action: chooseWallpaperFile) {
                                Label("Choose Image…", systemImage: "folder")
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.accentColor.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(PlainButtonStyle())

                            if spacesManager.currentWallpaperPath != nil {
                                Button(action: {
                                    spacesManager.setWallpaperPath(nil)
                                }) {
                                    Label("Remove", systemImage: "trash")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }

            Text("Switch between macOS Spaces to set different backgrounds for each desktop.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func chooseWallpaperFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.message = "Choose a wallpaper image for the notch background"
        if panel.runModal() == .OK, let url = panel.url {
            spacesManager.setWallpaperPath(url.path)
        }
    }
}
