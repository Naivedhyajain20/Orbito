//
//  NotchModeManager.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import Combine
import Defaults
import SwiftUI

/// Manages the active NotchMode and applies behavioral side-effects.
@MainActor
final class NotchModeManager: ObservableObject {
    static let shared = NotchModeManager()

    @Published var currentMode: NotchMode = Defaults[.notchMode] {
        didSet {
            Defaults[.notchMode] = currentMode
            applyMode(currentMode)
        }
    }

    @Published var currentTheme: NotchTheme = Defaults[.notchTheme] {
        didSet { Defaults[.notchTheme] = currentTheme }
    }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        applyMode(currentMode)
    }

    // MARK: - Mode Cycling (for keyboard shortcut)

    func cycleMode() {
        let all = NotchMode.allCases
        let idx = all.firstIndex(of: currentMode) ?? 0
        currentMode = all[(idx + 1) % all.count]
        showModeChangeHUD()
    }

    // MARK: - Apply Mode

    private func applyMode(_ mode: NotchMode) {
        let coordinator = BoringViewCoordinator.shared

        switch mode {
        case .normal:
            // Restore defaults
            coordinator.musicLiveActivityEnabled = true
            coordinator.alwaysShowTabs = true

        case .minimal:
            // Hide tabs, suppress music live activity
            coordinator.alwaysShowTabs = false
            coordinator.musicLiveActivityEnabled = false

        case .productivity:
            // Always show tabs, enable calendar
            coordinator.alwaysShowTabs = true
            coordinator.musicLiveActivityEnabled = false
            Defaults[.showCalendar] = true

        case .music:
            // Music live activity always on, tabs still visible
            coordinator.musicLiveActivityEnabled = true
            coordinator.alwaysShowTabs = true
            // Switch to home if not already there
            if coordinator.currentView != .home {
                coordinator.currentView = .home
            }

        case .work:
            // Focus mode active, hide music live activity
            coordinator.musicLiveActivityEnabled = false
            coordinator.alwaysShowTabs = true
            // Auto-start focus if not already running
            if !FocusModeManager.shared.isFocusActive {
                FocusModeManager.shared.startFocus()
            }
        }
    }

    // MARK: - HUD notification

    private func showModeChangeHUD() {
        // Post a brief notification so user sees the mode change
        let coordinator = BoringViewCoordinator.shared
        // Reuse the sneak peek system with a custom icon
        coordinator.toggleSneakPeek(
            status: true,
            type: .music,    // closest neutral type
            duration: 2.0
        )
    }
}
