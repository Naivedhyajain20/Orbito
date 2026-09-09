//
//  TimersView.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import SwiftUI

// MARK: - Root Timers Tab

struct TimersView: View {
    @StateObject private var manager = TimerManager.shared
    @State private var selectedSegment: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Segment picker
            Picker("", selection: $selectedSegment) {
                Text("Timers").tag(0)
                Text("Stopwatch").tag(1)
                Text("Pomodoro").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider().opacity(0.3)

            switch selectedSegment {
            case 0: CountdownTimersPanel()
            case 1: StopwatchPanel()
            case 2: PomodoroPanel()
            default: EmptyView()
            }
        }
        .environmentObject(manager)
    }
}

// MARK: - Countdown Timers

struct CountdownTimersPanel: View {
    @EnvironmentObject var manager: TimerManager
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            if manager.timers.isEmpty {
                TimersEmptyState()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(manager.timers) { timer in
                            TimerCard(timer: timer)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            Button {
                showingAddSheet = true
            } label: {
                Label("New Timer", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTimerSheet { label, duration, color in
                manager.addTimer(label: label, duration: duration, color: color)
                showingAddSheet = false
            }
        }
    }
}

struct TimerCard: View {
    @EnvironmentObject var manager: TimerManager
    let timer: BoringTimer

    var timerColor: Color {
        Color(hex: timer.color) ?? .red
    }

    var body: some View {
        HStack(spacing: 10) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(timerColor.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timer.progress)
            }
            .frame(width: 36, height: 36)
            .overlay {
                if timer.isFinished {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(timerColor)
                }
            }

            // Label + time
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(timer.timeString)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(timer.isFinished ? timerColor : .white)
            }

            Spacer()

            // Controls
            HStack(spacing: 4) {
                if !timer.isFinished {
                    Button {
                        manager.toggleTimer(timer)
                    } label: {
                        Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(timerColor.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button {
                    manager.resetTimer(timer)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    manager.removeTimer(timer)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(timer.isFinished ? 0.12 : 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(timerColor.opacity(timer.isFinished ? 0.6 : 0.15), lineWidth: 1)
                )
        )
    }
}

struct TimersEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 36))
                .foregroundColor(.gray.opacity(0.5))
            Text("No timers")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Add a countdown timer below")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct AddTimerSheet: View {
    var onAdd: (String, TimeInterval, String) -> Void

    @State private var label = ""
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var selectedColor = "#FF6B6B"

    private let colorOptions = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD"]

    var duration: TimeInterval { TimeInterval(hours * 3600 + minutes * 60 + seconds) }

    var body: some View {
        VStack(spacing: 16) {
            Text("New Timer")
                .font(.headline)
                .padding(.top)

            TextField("Label (e.g. Tea, Meeting)", text: $label)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Duration pickers
            HStack(spacing: 0) {
                durationPicker(title: "h", value: $hours, range: 0...23)
                Text(":").foregroundColor(.secondary)
                durationPicker(title: "m", value: $minutes, range: 0...59)
                Text(":").foregroundColor(.secondary)
                durationPicker(title: "s", value: $seconds, range: 0...59)
            }

            // Color picker
            HStack(spacing: 8) {
                ForEach(colorOptions, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex) ?? .red)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == hex ? 2 : 0))
                        .onTapGesture { selectedColor = hex }
                }
            }

            HStack {
                Button("Cancel") { onAdd("", 0, "") }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.secondary)

                Spacer()

                Button("Add Timer") {
                    let finalLabel = label.isEmpty ? "Timer" : label
                    onAdd(finalLabel, duration, selectedColor)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(duration > 0 ? .accentColor : .gray)
                .disabled(duration <= 0)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 300)
    }

    @ViewBuilder
    func durationPicker(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 2) {
            Picker(title, selection: value) {
                ForEach(Array(range), id: \.self) { n in
                    Text(String(format: "%02d", n)).tag(n)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 70)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
    }
}

// MARK: - Stopwatch

struct StopwatchPanel: View {
    @EnvironmentObject var manager: TimerManager

    var body: some View {
        VStack(spacing: 12) {
            // Main display
            Text(manager.stopwatchString)
                .font(.system(size: 42, weight: .thin, design: .monospaced))
                .foregroundColor(.white)
                .padding(.top, 8)

            // Controls
            HStack(spacing: 16) {
                // Lap / Reset
                Button {
                    if manager.stopwatchRunning {
                        manager.recordLap()
                    } else {
                        manager.resetStopwatch()
                    }
                } label: {
                    Text(manager.stopwatchRunning ? "Lap" : "Reset")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 36)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(manager.stopwatchElapsed == 0 && !manager.stopwatchRunning ? 0.3 : 1)
                .disabled(manager.stopwatchElapsed == 0 && !manager.stopwatchRunning)

                // Start/Pause
                Button {
                    if manager.stopwatchRunning {
                        manager.pauseStopwatch()
                    } else {
                        manager.startStopwatch()
                    }
                } label: {
                    Image(systemName: manager.stopwatchRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 60, height: 36)
                        .background(manager.stopwatchRunning ? Color.yellow : Color.green)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Laps
            if !manager.laps.isEmpty {
                Divider().opacity(0.3)
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(manager.laps) { lap in
                            HStack {
                                Text("Lap \(lap.lapNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(lap.splitString)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(lap.lapString)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 72, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                        }
                    }
                }
                .frame(maxHeight: 100)
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Pomodoro

struct PomodoroPanel: View {
    @EnvironmentObject var manager: TimerManager

    var body: some View {
        VStack(spacing: 10) {
            // Phase indicator
            HStack(spacing: 6) {
                Image(systemName: manager.pomodoroPhase.icon)
                    .font(.system(size: 12))
                Text(manager.pomodoroPhase.rawValue)
                    .font(.caption.weight(.semibold))
                Text("• Cycle \(manager.pomodoroCycles + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(manager.pomodoroPhase.color)
            .padding(.top, 8)

            // Circular progress ring + time
            ZStack {
                Circle()
                    .stroke(manager.pomodoroPhase.color.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: manager.pomodoroProgress)
                    .stroke(
                        manager.pomodoroPhase.color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: manager.pomodoroProgress)

                Text(manager.pomodoroString)
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 110, height: 110)

            // Controls
            HStack(spacing: 12) {
                if manager.pomodoroActive {
                    Button {
                        manager.togglePomodoro()
                    } label: {
                        Image(systemName: manager.pomodoroRunning ? "pause.fill" : "play.fill")
                            .foregroundColor(.black)
                            .frame(width: 60, height: 32)
                            .background(manager.pomodoroPhase.color)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        manager.resetPomodoro()
                    } label: {
                        Text("Reset")
                            .foregroundColor(.white)
                            .frame(width: 60, height: 32)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button {
                        manager.startPomodoro()
                    } label: {
                        Label("Start Pomodoro", systemImage: "play.fill")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Cycle dots
            HStack(spacing: 6) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i < (manager.pomodoroCycles % 4) ? manager.pomodoroPhase.color : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&int) else { return nil }
        let r, g, b: Double
        switch h.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default: return nil
        }
        self.init(red: r, green: g, blue: b)
    }
}
