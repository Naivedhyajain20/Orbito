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
import Defaults
import AppKit

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

    // Alarm Sound State
    @Published var isAlarmRinging: Bool = false
    @Published var alarmTimerLabel: String = ""
    private var alarmTimerTask: Task<Void, Never>?

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

    func startQuickTimer(label: String = "Timer", duration: TimeInterval, color: String = "#FF9F0A") {
        for idx in timers.indices {
            timers[idx].isRunning = false
        }
        var timer = BoringTimer(label: label, duration: duration, color: color)
        timer.isRunning = true
        timers.insert(timer, at: 0)
        startTickIfNeeded()
    }

    func stopAllTimers() {
        for idx in timers.indices {
            timers[idx].isRunning = false
        }
        timerTask?.cancel()
        timerTask = nil
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
                await MainActor.run {
                    self.tickTimers()
                }
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
                triggerTimerAlarm(label: timers[idx].label)
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
        let completed = pomodoroPhase
        triggerTimerAlarm(label: completed == .work ? "Focus session complete" : "Break complete")
        sendPomodoroNotification(completedPhase: completed)
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

    // MARK: - Alarm System

    func triggerTimerAlarm(label: String) {
        alarmTimerLabel = label
        sendTimerNotification(label: label)

        guard Defaults[.enableTimerAlarm] else { return }

        isAlarmRinging = true
        let soundName = Defaults[.timerAlarmSoundName]
        let volume = Float(Defaults[.timerAlarmVolume])

        alarmTimerTask?.cancel()
        alarmTimerTask = Task { [weak self] in
            // Ring alarm in repeated pulses (up to 8 times or until stopped)
            for _ in 0..<8 {
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self?.playAlarmSoundOnce(soundName: soundName, volume: volume)
                }
                try? await Task.sleep(for: .milliseconds(900))
            }
            await MainActor.run {
                self?.isAlarmRinging = false
            }
        }
    }

    func playAlarmSoundOnce(soundName: String, volume: Float) {
        let sound: NSSound? = {
            switch soundName {
            case "Radar": return NSSound(named: "Submarine") ?? NSSound(named: "Ping")
            case "Chime": return NSSound(named: "Hero") ?? NSSound(named: "Blow")
            case "Ping": return NSSound(named: "Ping")
            case "Glass": return NSSound(named: "Glass")
            case "Hero": return NSSound(named: "Hero")
            default: return NSSound(named: "Glass") ?? NSSound(named: "Ping")
            }
        }()
        if let sound = sound {
            sound.volume = max(0.1, min(1.0, volume))
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    func stopAlarm() {
        alarmTimerTask?.cancel()
        alarmTimerTask = nil
        isAlarmRinging = false
    }

    func testAlarmSound() {
        let soundName = Defaults[.timerAlarmSoundName]
        let volume = Float(Defaults[.timerAlarmVolume])
        playAlarmSoundOnce(soundName: soundName, volume: volume)
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
