//
//  TimerManager.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import Foundation
import UserNotifications
import Combine
import SwiftUI

// MARK: - Models

struct BoringTimer: Identifiable, Codable {
    let id: UUID
    var label: String
    var totalDuration: TimeInterval
    var remainingTime: TimeInterval
    var isRunning: Bool
    var isFinished: Bool
    var color: String // hex string for Codable compliance

    init(id: UUID = UUID(), label: String = "Timer", duration: TimeInterval, color: String = "#FF6B6B") {
        self.id = id
        self.label = label
        self.totalDuration = duration
        self.remainingTime = duration
        self.isRunning = false
        self.isFinished = false
        self.color = color
    }

    var progress: Double {
        guard totalDuration > 0 else { return 1 }
        return 1 - (remainingTime / totalDuration)
    }

    var timeString: String {
        let t = Int(max(remainingTime, 0))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

struct LapTime: Identifiable {
    let id = UUID()
    let lapNumber: Int
    let elapsed: TimeInterval
    let split: TimeInterval

    var lapString: String {
        let t = Int(elapsed)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var splitString: String {
        let t = Int(split)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 { return String(format: "+%d:%02d:%02d", h, m, s) }
        return String(format: "+%02d:%02d", m, s)
    }
}

// MARK: - Pomodoro

enum PomodoroPhase: String, Codable {
    case work = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var icon: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak: return "bed.double"
        }
    }

    var color: Color {
        switch self {
        case .work: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}

// MARK: - Manager

@MainActor
final class TimerManager: ObservableObject {
    static let shared = TimerManager()

    // Countdown timers
    @Published var timers: [BoringTimer] = []

    // Stopwatch
    @Published var stopwatchElapsed: TimeInterval = 0
    @Published var stopwatchRunning: Bool = false
    @Published var laps: [LapTime] = []

    // Pomodoro
    @Published var pomodoroActive: Bool = false
    @Published var pomodoroPhase: PomodoroPhase = .work
    @Published var pomodoroRemaining: TimeInterval = 25 * 60
    @Published var pomodoroCycles: Int = 0
    @Published var pomodoroRunning: Bool = false

    var pomodoroWorkDuration: TimeInterval = 25 * 60
    var pomodoroShortBreak: TimeInterval = 5 * 60
    var pomodoroLongBreak: TimeInterval = 15 * 60
    var pomodoroLongBreakAfter: Int = 4

    // Private
    private var timerTask: Task<Void, Never>?
    private var stopwatchTask: Task<Void, Never>?
    private var pomodoroTask: Task<Void, Never>?
    private var lastStopwatchLapElapsed: TimeInterval = 0

    private init() {
        requestNotificationPermission()
    }

    // MARK: - Live Activity Properties

    var hasActiveLiveActivity: Bool {
        timers.contains(where: { $0.isRunning }) || stopwatchRunning || pomodoroRunning
    }

    var liveActivityIcon: String {
        if pomodoroRunning {
            return pomodoroPhase.icon
        } else if stopwatchRunning {
            return "stopwatch"
        } else if timers.contains(where: { $0.isRunning }) {
            return "timer"
        }
        return "timer"
    }

    var liveActivityColor: Color {
        if pomodoroRunning {
            return pomodoroPhase.color
        } else if stopwatchRunning {
            return .cyan
        } else if let timer = timers.first(where: { $0.isRunning }) {
            return Color(hex: timer.color) ?? .orange
        }
        return .orange
    }

    var liveActivityTimeString: String {
        if pomodoroRunning {
            let t = Int(max(pomodoroRemaining, 0))
            let m = t / 60
            let s = t % 60
            return String(format: "%02d:%02d", m, s)
        } else if stopwatchRunning {
            let t = Int(stopwatchElapsed)
            let m = (t % 3600) / 60
            let s = t % 60
            return String(format: "%02d:%02d", m, s)
        } else if let timer = timers.first(where: { $0.isRunning }) {
            return timer.timeString
        }
        return "--:--"
    }

    // MARK: - Countdown Timers

    func addTimer(label: String, duration: TimeInterval, color: String = "#FF6B6B") {
        let timer = BoringTimer(label: label, duration: duration, color: color)
        timers.append(timer)
    }

    func removeTimer(_ timer: BoringTimer) {
        timers.removeAll { $0.id == timer.id }
    }

    func toggleTimer(_ timer: BoringTimer) {
        guard let idx = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        timers[idx].isRunning.toggle()
        startTickIfNeeded()
    }

    func resetTimer(_ timer: BoringTimer) {
        guard let idx = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        timers[idx].remainingTime = timers[idx].totalDuration
        timers[idx].isRunning = false
        timers[idx].isFinished = false
    }

    private func startTickIfNeeded() {
        guard timerTask == nil || timerTask!.isCancelled else { return }
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self = self else { return }
                await self.tickTimers()
            }
        }
    }

    private func tickTimers() {
        let hasRunning = timers.contains { $0.isRunning && !$0.isFinished }
        guard hasRunning else {
            timerTask?.cancel()
            timerTask = nil
            return
        }

        for idx in timers.indices {
            guard timers[idx].isRunning && !timers[idx].isFinished else { continue }
            timers[idx].remainingTime -= 0.1
            if timers[idx].remainingTime <= 0 {
                timers[idx].remainingTime = 0
                timers[idx].isRunning = false
                timers[idx].isFinished = true
                sendTimerNotification(label: timers[idx].label)
            }
        }
    }

    // MARK: - Stopwatch

    func startStopwatch() {
        stopwatchRunning = true
        stopwatchTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                guard let self = self else { return }
                if self.stopwatchRunning {
                    await MainActor.run { self.stopwatchElapsed += 0.05 }
                } else {
                    break
                }
            }
        }
    }

    func pauseStopwatch() {
        stopwatchRunning = false
        stopwatchTask?.cancel()
    }

    func resetStopwatch() {
        stopwatchRunning = false
        stopwatchTask?.cancel()
        stopwatchElapsed = 0
        laps = []
        lastStopwatchLapElapsed = 0
    }

    func recordLap() {
        guard stopwatchRunning else { return }
        let split = stopwatchElapsed - lastStopwatchLapElapsed
        let lap = LapTime(lapNumber: laps.count + 1, elapsed: stopwatchElapsed, split: split)
        laps.insert(lap, at: 0)
        lastStopwatchLapElapsed = stopwatchElapsed
    }

    var stopwatchString: String {
        let t = Int(stopwatchElapsed)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        let ms = Int((stopwatchElapsed.truncatingRemainder(dividingBy: 1)) * 100)
        if h > 0 { return String(format: "%d:%02d:%02d.%02d", h, m, s, ms) }
        return String(format: "%02d:%02d.%02d", m, s, ms)
    }

    // MARK: - Pomodoro

    func startPomodoro() {
        pomodoroActive = true
        pomodoroRunning = true
        pomodoroPhase = .work
        pomodoroRemaining = pomodoroWorkDuration
        pomodoroCycles = 0
        runPomodoro()
    }

    func togglePomodoro() {
        pomodoroRunning.toggle()
        if pomodoroRunning { runPomodoro() } else { pomodoroTask?.cancel() }
    }

    func resetPomodoro() {
        pomodoroTask?.cancel()
        pomodoroRunning = false
        pomodoroActive = false
        pomodoroPhase = .work
        pomodoroRemaining = pomodoroWorkDuration
        pomodoroCycles = 0
    }

    private func runPomodoro() {
        pomodoroTask?.cancel()
        pomodoroTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self = self else { return }
                guard self.pomodoroRunning else { break }
                await MainActor.run {
                    self.pomodoroRemaining -= 1
                    if self.pomodoroRemaining <= 0 {
                        self.advancePomodoroPhase()
                    }
                }
            }
        }
    }

    func skipPomodoroPhase() {
        advancePomodoroPhase()
    }

    private func advancePomodoroPhase() {
        sendPomodoroNotification(completedPhase: pomodoroPhase)
        switch pomodoroPhase {
        case .work:
            pomodoroCycles += 1
            if pomodoroCycles % pomodoroLongBreakAfter == 0 {
                pomodoroPhase = .longBreak
                pomodoroRemaining = pomodoroLongBreak
            } else {
                pomodoroPhase = .shortBreak
                pomodoroRemaining = pomodoroShortBreak
            }
        case .shortBreak, .longBreak:
            pomodoroPhase = .work
            pomodoroRemaining = pomodoroWorkDuration
        }
    }

    var pomodoroString: String {
        let t = Int(max(pomodoroRemaining, 0))
        let m = t / 60
        let s = t % 60
        return String(format: "%02d:%02d", m, s)
    }

    var pomodoroProgress: Double {
        let total: TimeInterval
        switch pomodoroPhase {
        case .work: total = pomodoroWorkDuration
        case .shortBreak: total = pomodoroShortBreak
        case .longBreak: total = pomodoroLongBreak
        }
        guard total > 0 else { return 0 }
        return 1 - (pomodoroRemaining / total)
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendTimerNotification(label: String) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Timer Finished"
        content.body = "\"\(label)\" has completed!"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendPomodoroNotification(completedPhase: PomodoroPhase) {
        let content = UNMutableNotificationContent()
        switch completedPhase {
        case .work:
            content.title = "🍅 Focus session done!"
            content.body = "Time for a break. You've earned it."
        case .shortBreak, .longBreak:
            content.title = "☕ Break over!"
            content.body = "Back to focus. You've got this!"
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
