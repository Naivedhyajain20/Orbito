//
//  generic.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Foundation
import Defaults

public enum Style {
    case notch
    case floating
}

public enum ContentType: Int, Codable, Hashable, Equatable {
    case normal
    case menu
    case settings
}

public enum NotchState {
    case closed
    case open
}

public enum NotchViews {
    case home
    case shelf
    case notes
    case timers
    case worldClock
    case clipboard
    case calculator
    case systemInfo
    case aiActions
}

enum SettingsEnum {
    case general
    case about
    case charge
    case download
    case mediaPlayback
    case hud
    case shelf
    case extensions
}

// MARK: - Notch Mode
enum NotchMode: String, CaseIterable, Defaults.Serializable, Identifiable {
    case normal       = "Normal"
    case minimal      = "Minimal"
    case productivity = "Productivity"
    case music        = "Music"
    case work         = "Work"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .normal:       return "rectangle.topthird.inset.filled"
        case .minimal:      return "minus.circle"
        case .productivity: return "briefcase"
        case .music:        return "music.note"
        case .work:         return "brain.head.profile"
        }
    }

    var description: String {
        switch self {
        case .normal:       return "Default behavior"
        case .minimal:      return "Only battery & time — minimal distractions"
        case .productivity: return "Tabs always visible, calendar priority"
        case .music:        return "Music controls always on top"
        case .work:         return "Focus + Pomodoro priority, no music"
        }
    }
}

// MARK: - Notch Theme
enum NotchTheme: String, CaseIterable, Defaults.Serializable, Identifiable {
    case glass       = "Glass"
    case darkSolid   = "Dark Solid"
    case transparent = "Transparent"
    case minimal     = "Minimal"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .glass:       return "square.on.square.dashed"
        case .darkSolid:   return "square.fill"
        case .transparent: return "square.dotted"
        case .minimal:     return "squareshape"
        }
    }

    /// Background blur radius
    var blurRadius: CGFloat {
        switch self {
        case .glass:       return 20
        case .darkSolid:   return 0
        case .transparent: return 8
        case .minimal:     return 0
        }
    }

    /// Background fill opacity (over black)
    var bgOpacity: CGFloat {
        switch self {
        case .glass:       return 0.6
        case .darkSolid:   return 1.0
        case .transparent: return 0.35
        case .minimal:     return 0.85
        }
    }

    /// Content (icons/text) opacity
    var contentOpacity: CGFloat {
        switch self {
        case .minimal: return 0.7
        default:       return 1.0
        }
    }
}

enum DownloadIndicatorStyle: String, Defaults.Serializable {
    case progress = "Progress"
    case percentage = "Percentage"
}

enum DownloadIconStyle: String, Defaults.Serializable {
    case onlyAppIcon = "Only app icon"
    case onlyIcon = "Only download icon"
    case iconAndAppIcon = "Icon and app icon"
}

enum MirrorShapeEnum: String, Defaults.Serializable {
    case rectangle = "Rectangular"
    case circle = "Circular"
}

enum WindowHeightMode: String, Defaults.Serializable {
    case matchMenuBar = "Match menubar height"
    case matchRealNotchSize = "Match real notch height"
    case custom = "Custom height"
}

enum SliderColorEnum: String, CaseIterable, Defaults.Serializable {
    case white = "White"
    case albumArt = "Match album art"
    case accent = "Accent color"
}
