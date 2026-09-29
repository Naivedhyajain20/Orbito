//
//  SpacesSyncManager.swift
//  boringNotch
//
//  Detects macOS Space switches and supports per-Space background theming.
//

import AppKit
import Defaults
import Foundation
import SwiftUI

// MARK: - Private CGS declarations (same pattern as existing CGSSpace usage)

private typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSGetActiveSpace")
private func CGSGetActiveSpace(_ cid: CGSConnectionID) -> Int

// MARK: - Background Style Enum

enum NotchBackground: String, CaseIterable, Codable, Defaults.Serializable {
    case black       = "Black"
    case glass       = "Glass"
    case blackGlass  = "Black Glass"
    case image       = "Image"

    var icon: String {
        switch self {
        case .black:      return "rectangle.fill"
        case .glass:      return "sparkles"
        case .blackGlass: return "rectangle.fill.on.rectangle.fill"
        case .image:      return "photo"
        }
    }
}

// MARK: - Spaces Sync Manager

@MainActor
final class SpacesSyncManager: ObservableObject {
    static let shared = SpacesSyncManager()

    /// The numeric ID of the current Space (changes on Space switch)
    @Published private(set) var currentSpaceID: Int = 0

    private init() {
        currentSpaceID = CGSGetActiveSpace(CGSMainConnectionID())
        observeSpaceChanges()
    }

    private func observeSpaceChanges() {
        // NSWorkspace posts this on every Space switch (reliable since macOS 10.9)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                let newSpaceID = CGSGetActiveSpace(CGSMainConnectionID())
                self?.currentSpaceID = newSpaceID
            }
        }
    }

    /// Get the background style for the current space
    var currentBackground: NotchBackground {
        let key = String(currentSpaceID)
        let raw = Defaults[.spaceBackgrounds][key] ?? NotchBackground.black.rawValue
        return NotchBackground(rawValue: raw) ?? .black
    }

    /// Set background for the current space
    func setBackground(_ style: NotchBackground) {
        let key = String(currentSpaceID)
        var map = Defaults[.spaceBackgrounds]
        map[key] = style.rawValue
        Defaults[.spaceBackgrounds] = map
    }

    /// Get wallpaper image path for current space
    var currentWallpaperPath: String? {
        let key = String(currentSpaceID)
        return Defaults[.spaceWallpaperPaths][key]
    }

    /// Set wallpaper image path for current space
    func setWallpaperPath(_ path: String?) {
        let key = String(currentSpaceID)
        var map = Defaults[.spaceWallpaperPaths]
        if let path = path {
            map[key] = path
        } else {
            map.removeValue(forKey: key)
        }
        Defaults[.spaceWallpaperPaths] = map
        objectWillChange.send()
    }

    /// Load wallpaper NSImage for current space (cached)
    var currentWallpaperImage: NSImage? {
        guard let path = currentWallpaperPath, !path.isEmpty else { return nil }
        // Use cached version if available
        let cacheKey = "wallpaper:\(path)" as NSString
        if let cached = wallpaperCache.object(forKey: cacheKey) { return cached }
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        wallpaperCache.setObject(image, forKey: cacheKey)
        return image
    }

    private let wallpaperCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 10
        return cache
    }()
}
