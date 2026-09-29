//
//  QuickTimerRulerView.swift
//  boringNotch
//
//  LaunchMe-style scrollable ruler timer with smooth interaction.
//  Timer auto-starts and shows as live activity when notch minimizes.
//

import SwiftUI
import UserNotifications

// MARK: - Ruler constants

private let tickSpacing: CGFloat = 12.0     // pts per minute
private let majorTickEvery = 5              // major tick every 5 min
private let rulerRange = 0...120            // 0–120 minutes

// MARK: - Main View (exact LaunchMe ruler timer)

struct QuickTimerRulerView: View {
    @StateObject private var manager = TimerManager.shared

    /// Selected minutes (double for smooth drag)
    @State private var selectedMinutes: Double = 5
    /// Track cumulative drag for gesture
    @State private var baseMinutes: Double = 5
    @State private var isRunning = false
    @State private var remainingSeconds: Int = 300
    @State private var totalStartSeconds: Int = 300
    @State private var countdownTask: Task<Void, Never>? = nil

    // Derived
    private var totalSeconds: Int { Int(selectedMinutes) * 60 }
    private var displaySeconds: Int { isRunning ? remainingSeconds : totalSeconds }
    private var progress: Double {
        guard totalStartSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalStartSeconds))
    }

    private let presets: [(String, Int)] = [
        ("1 min", 1), ("5 min", 5), ("10 min", 10), ("15 min", 15), ("25 min", 25), ("60 min", 60)
    ]

    var body: some View {
        VStack(spacing: 0) {
            if manager.isAlarmRinging {
                alarmBanner
            }

            // ── Ruler ──────────────────────────────────────────────────
            rulerSection
                .frame(height: 50)
                .clipped()

            // ── Bottom bar ─────────────────────────────────────────────
            HStack(alignment: .center, spacing: 0) {
                // Progress ring + time display
                ZStack {
                    // Circular progress ring
                    Circle()
                        .stroke(Color.orange.opacity(0.15), lineWidth: 3)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: isRunning ? progress : 0)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progress)

                    // Big time display inside ring
                    Text(formattedTime(displaySeconds))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isRunning ? .orange : .white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: displaySeconds)
                }

                Spacer(minLength: 8)

                // Preset pills — scrollable
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(presets, id: \.1) { label, minutes in
                            presetPill(label: label, minutes: minutes)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 8)

                // Start / Stop button
                Button {
                    toggleTimer()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(isRunning ? "Stop" : "Start")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isRunning ? Color.red.opacity(0.9) : Color.orange)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isRunning)
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .background(Color.clear)
    }

    // MARK: - Ruler Section

    private var rulerSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Scrollable tick marks using Canvas
                rulerTrack(totalWidth: geo.size.width)
                    .frame(height: 38)
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                guard !isRunning else { return }
                                let delta = -value.translation.width / tickSpacing
                                let newVal = (baseMinutes + delta).clamped(to: 0...120)
                                selectedMinutes = newVal
                            }
                            .onEnded { _ in
                                selectedMinutes = selectedMinutes.rounded()
                                baseMinutes = selectedMinutes
                                if !isRunning { remainingSeconds = totalSeconds }
                            }
                    )
                    .contentShape(Rectangle())

                // Center indicator arrow
                VStack(spacing: 0) {
                    Spacer()
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 2, height: 4)
                }
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Ruler Track Canvas

    private func rulerTrack(totalWidth: CGFloat) -> some View {
        Canvas { ctx, size in
            let centerX = size.width / 2
            // Offset so "selectedMinutes" tick aligns to center
            let offsetX = centerX - CGFloat(selectedMinutes) * tickSpacing

            for minute in rulerRange {
                let x = offsetX + CGFloat(minute) * tickSpacing
                guard x >= -tickSpacing && x <= size.width + tickSpacing else { continue }

                let isMajor = minute % majorTickEvery == 0
                let tickH: CGFloat = isMajor ? 14 : 7
                let tickY: CGFloat = 0

                // Tick line
                var path = Path()
                path.move(to: CGPoint(x: x, y: tickY))
                path.addLine(to: CGPoint(x: x, y: tickY + tickH))

                // Highlight ticks near center (fade out towards edges)
                let distance = abs(x - centerX)
                let alpha = Double(max(0.2, 1 - distance / (size.width * 0.45)))

                ctx.stroke(
                    path,
                    with: .color(.white.opacity(isMajor ? alpha : alpha * 0.45)),
                    lineWidth: isMajor ? 1.5 : 0.75
                )

                // Labels on major ticks
                if isMajor {
                    let label = "\(minute)"
                    let resolved = ctx.resolve(
                        Text(label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(alpha * 0.85))
                    )
                    let textSize = resolved.measure(in: CGSize(width: 40, height: 14))
                    ctx.draw(resolved, in: CGRect(
                        x: x - textSize.width / 2,
                        y: tickY + tickH + 3,
                        width: textSize.width,
                        height: textSize.height
                    ))
                }
            }
        }
        .frame(width: totalWidth)
    }

    // MARK: - Preset Pill

    private func presetPill(label: String, minutes: Int) -> some View {
        Button {
            guard !isRunning else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedMinutes = Double(minutes)
                baseMinutes = selectedMinutes
                remainingSeconds = minutes * 60
            }
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(Int(selectedMinutes) == minutes ? .black : .white.opacity(0.75))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Int(selectedMinutes) == minutes
                              ? Color.orange
                              : Color.white.opacity(0.12))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: Int(selectedMinutes))
    }

    // MARK: - Timer Logic

    private func toggleTimer() {
        if isRunning {
            // Stop
            countdownTask?.cancel()
            countdownTask = nil
            isRunning = false
            remainingSeconds = totalSeconds
            // Remove from TimerManager live activity
            if let quickTimer = manager.timers.first(where: { $0.label == "⏱ Quick Timer" }) {
                manager.removeTimer(quickTimer)
            }
        } else {
            guard totalSeconds > 0 else { return }
            remainingSeconds = totalSeconds
            totalStartSeconds = totalSeconds
            isRunning = true

            // Add to TimerManager so it shows as live activity when notch minimizes
            // Remove any existing quick timer first
            if let existing = manager.timers.first(where: { $0.label == "⏱ Quick Timer" }) {
                manager.removeTimer(existing)
            }
            manager.addTimer(label: "⏱ Quick Timer", duration: TimeInterval(totalSeconds), color: "#FF9500")
            if let added = manager.timers.first(where: { $0.label == "⏱ Quick Timer" }) {
                manager.toggleTimer(added)
            }

            countdownTask = Task {
                while remainingSeconds > 0 && !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    if !Task.isCancelled {
                        await MainActor.run { remainingSeconds -= 1 }
                    }
                }
                if !Task.isCancelled {
                    await MainActor.run {
                        isRunning = false
                        manager.triggerTimerAlarm(label: "Quick Timer (\(formattedTime(totalStartSeconds)))")
                    }
                }
            }
        }
    }

    private var alarmBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.badge.fill")
                .foregroundColor(.white)
            Text("⏰ TIME'S UP!")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Button(action: {
                manager.stopAlarm()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "stop.fill")
                    Text("Stop Alarm")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.25)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color.red.opacity(0.9))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func formattedTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Clamped Utility

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
