//
//  FocusModeManager.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import SwiftUI
import Combine
import UserNotifications

@MainActor
final class FocusModeManager: ObservableObject {
    static let shared = FocusModeManager()

    @Published var isFocusActive: Bool = false
    @Published var focusEndTime: Date?
    @Published var remainingTime: String = ""

    var focusDuration: TimeInterval = 25 * 60 // default 25 min
    private var focusTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?

    private init() {}

    func startFocus(duration: TimeInterval? = nil) {
        let dur = duration ?? focusDuration
        isFocusActive = true
        focusEndTime = Date().addingTimeInterval(dur)
        startTicking()

        // Schedule end notification
        let content = UNMutableNotificationContent()
        content.title = "🎯 Focus Session Complete"
        content.body = "Great work! Take a break."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: dur, repeats: false)
        let request = UNNotificationRequest(identifier: "focus-end", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func stopFocus() {
        isFocusActive = false
        focusEndTime = nil
        remainingTime = ""
        focusTask?.cancel()
        tickTask?.cancel()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus-end"])
    }

    func toggleFocus(duration: TimeInterval? = nil) {
        if isFocusActive { stopFocus() } else { startFocus(duration: duration) }
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self = self else { return }
                if let end = await self.focusEndTime {
                    let remaining = end.timeIntervalSince(Date())
                    if remaining <= 0 {
                        await self.stopFocus()
                        return
                    }
                    let m = Int(remaining) / 60
                    let s = Int(remaining) % 60
                    await MainActor.run {
                        self.remainingTime = String(format: "%02d:%02d", m, s)
                    }
                }
            }
        }
    }
}
