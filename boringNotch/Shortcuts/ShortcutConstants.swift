//
//  Constants.swift
//  boringNotch
//
//  Created by Richard Kunkli on 16/08/2024.
//

import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let clipboardHistoryPanel = Self("clipboardHistoryPanel", default: .init(.c, modifiers: [.shift, .command]))
    static let toggleMicrophone = Self("toggleMicrophone", default: .init(.f5, modifiers: [.function]))
    static let decreaseBacklight = Self("decreaseBacklight", default: .init(.f1, modifiers: [.command]))
    static let increaseBacklight = Self("increaseBacklight", default: .init(.f2, modifiers: [.command]))
    static let toggleSneakPeek = Self("toggleSneakPeek", default: .init(.h, modifiers: [.command, .shift]))
    static let toggleNotchOpen = Self("toggleNotchOpen", default: .init(.i, modifiers: [.command, .shift]))
    static let toggleNotesPanel = Self("toggleNotesPanel", default: .init(.n, modifiers: [.command, .shift]))
    // New feature shortcuts
    static let openTimers    = Self("openTimers",    default: .init(.t, modifiers: [.command, .shift]))
    static let openCalculator = Self("openCalculator", default: .init(.k, modifiers: [.command, .shift]))
    static let openClipboard  = Self("openClipboard",  default: .init(.v, modifiers: [.command, .option]))
    static let openSystemInfo = Self("openSystemInfo", default: .init(.m, modifiers: [.command, .shift]))
    static let openAIActions  = Self("openAIActions",  default: .init(.a, modifiers: [.command, .shift]))
    static let toggleFocusMode = Self("toggleFocusMode", default: .init(.f, modifiers: [.command, .shift]))
    static let cycleNotchMode  = Self("cycleNotchMode",  default: .init(.d, modifiers: [.command, .shift]))
}
