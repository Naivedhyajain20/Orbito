//
//  MacNotchDashboardView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Defaults

struct MacNotchDashboardView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    @ObservedObject var timerManager = TimerManager.shared
    @ObservedObject var sysManager = SystemInfoManager.shared
    @ObservedObject var focusManager = FocusModeManager.shared
    @ObservedObject var volumeManager = VolumeManager.shared
    @EnvironmentObject var vm: BoringViewModel

    @State private var launcherPage: Int = 0

    // App launcher sets (Real macOS Applications)
    private let appsSet1: [(name: String, icon: String, bundleId: String)] = [
        ("Finder", "folder.fill", "com.apple.finder"),
        ("Safari", "safari.fill", "com.apple.Safari"),
        ("Terminal", "terminal.fill", "com.apple.Terminal"),
        ("Xcode", "hammer.fill", "com.apple.dt.Xcode"),
        ("Notes", "note.text", "com.apple.Notes"),
        ("Slack", "bubble.left.and.bubble.right.fill", "com.tinyspeck.slackmacgap"),
        ("Music", "music.note", "com.apple.Music"),
        ("Code", "chevron.left.forwardslash.chevron.right", "com.microsoft.VSCode")
    ]

    private let appsSet2: [(name: String, icon: String, bundleId: String)] = [
        ("Mail", "envelope.fill", "com.apple.mail"),
        ("Calendar", "calendar", "com.apple.iCal"),
        ("Reminders", "checklist", "com.apple.reminders"),
        ("Settings", "gearshape.fill", "com.apple.systempreferences"),
        ("Messages", "message.fill", "com.apple.MobileSMS"),
        ("Photos", "photo.fill", "com.apple.Photos"),
        ("Podcasts", "antenna.radiowaves.left.and.right", "com.apple.podcasts"),
        ("Activity", "waveform.path.ecg", "com.apple.ActivityMonitor")
    ]

    private var currentApps: [(name: String, icon: String, bundleId: String)] {
        launcherPage == 0 ? appsSet1 : appsSet2
    }

    var body: some View {
        VStack(spacing: 10) {
            // Row 1: Agenda, App Launcher, Pomodoro Dial
            HStack(spacing: 8) {
                agendaCard
                appLauncherCard
                pomodoroCard
            }
            .frame(maxHeight: .infinity)

            // Row 2: Live System Resources (CPU, RAM, SSD), Day Progress, Quick Toggles
            HStack(spacing: 8) {
                systemMonitorCard
                dayProgressCard
                quickTogglesCard
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .onAppear {
            sysManager.startPolling()
        }
    }

    // MARK: - Card 1: Agenda & Calendar (Real Data)
    private var agendaCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                Text("Agenda")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            if calendarManager.events.isEmpty {
                VStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No upcoming events")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Button(action: {
                        NSWorkspace.shared.launchApplication("Calendar")
                    }) {
                        Text("Open Calendar")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(calendarManager.events.prefix(2))) { event in
                        HStack(spacing: 5) {
                            Circle().fill(Color.orange).frame(width: 5, height: 5)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text("\(event.start.formatted(date: .omitted, time: .shortened))" + (event.location != nil ? " • \(event.location!)" : ""))
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let url = event.url {
                                NSWorkspace.shared.open(url)
                            } else {
                                NSWorkspace.shared.launchApplication("Calendar")
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Card 2: Real App Launcher
    private var appLauncherCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yellow)
                Text("Quick Launch")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                // Page indicator dots
                HStack(spacing: 3) {
                    Circle()
                        .fill(launcherPage == 0 ? Color.white : Color.white.opacity(0.2))
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(launcherPage == 1 ? Color.white : Color.white.opacity(0.2))
                        .frame(width: 4, height: 4)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        launcherPage = (launcherPage == 0 ? 1 : 0)
                    }
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                ForEach(currentApps, id: \.name) { app in
                    Button(action: {
                        launchApp(bundleId: app.bundleId, name: app.name)
                    }) {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: app.icon)
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            Text(app.name)
                                .font(.system(size: 7, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Open \(app.name)")
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Card 3: Real Pomodoro / Timers
    private var pomodoroCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(timerManager.pomodoroPhase.color)
                Text("Pomodoro")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("Cycle \(timerManager.pomodoroCycles)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 12) {
                // Circular Progress Dial
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 3)
                        .frame(width: 38, height: 38)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(timerManager.pomodoroProgress, 0.02), 1.0)))
                        .stroke(
                            timerManager.pomodoroPhase.color,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 38, height: 38)

                    Button(action: {
                        timerManager.togglePomodoro()
                    }) {
                        Image(systemName: timerManager.pomodoroRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timerManager.pomodoroString)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Text(timerManager.pomodoroPhase.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(timerManager.pomodoroPhase.color)

                        Button(action: {
                            timerManager.resetPomodoro()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 7))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .cardStyle()
    }

    // MARK: - Card 4: Real System Resources (CPU, RAM, SSD, Network, Wi-Fi)
    private var systemMonitorCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
                Text("System Monitor")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "wifi")
                        .font(.system(size: 7))
                    Text(sysManager.wifiSSID)
                        .font(.system(size: 8, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 6) {
                // CPU Gauge
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: min(max(CGFloat(sysManager.cpuUsage / 100.0), 0.04), 1.0))
                            .stroke(
                                LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", sysManager.cpuUsage))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    Text("CPU")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                // RAM Gauge
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: min(max(CGFloat(sysManager.ramPercent / 100.0), 0.04), 1.0))
                            .stroke(
                                LinearGradient(colors: [Color.purple, Color.pink], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", sysManager.ramPercent))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    Text("RAM")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                // SSD Storage Gauge
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: min(max(CGFloat(sysManager.diskUsedPercent / 100.0), 0.04), 1.0))
                            .stroke(
                                LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", sysManager.diskUsedPercent))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    Text("SSD")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer(minLength: 2)

                // Network Speeds Column
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.green)
                        Text(sysManager.formatSpeed(sysManager.downloadSpeed))
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.cyan)
                        Text(sysManager.formatSpeed(sysManager.uploadSpeed))
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Text(String(format: "%.0fGB free", sysManager.diskFreeGB))
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Card 5: Real Day Progress
    private var dayProgressCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "hourglass")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.blue)
                Text("Day Progress")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(calculateDayProgress() * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 4)
                        Capsule()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(calculateDayProgress()), height: 4)
                    }
                }
                .frame(height: 6)

                Text(hoursRemainingString())
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)

                Text("\"Deep work happens one focused moment at a time.\"")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(1)
                    .italic()
            }
        }
        .cardStyle()
    }

    // MARK: - Card 6: Real Quick Toggles
    private var quickTogglesCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                Text("Quick Toggles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                toggleButton(
                    icon: "moon.fill",
                    label: "DND",
                    active: focusManager.isFocusActive
                ) {
                    focusManager.toggleFocus()
                }

                toggleButton(
                    icon: volumeManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    label: "Mute",
                    active: volumeManager.isMuted
                ) {
                    volumeManager.toggleMuteAction()
                }

                toggleButton(
                    icon: "web.camera",
                    label: "Mirror",
                    active: vm.isCameraExpanded
                ) {
                    vm.toggleCameraPreview()
                }

                toggleButton(
                    icon: "wifi",
                    label: "Wi-Fi",
                    active: sysManager.wifiSSID != "—"
                ) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.network") {
                        NSWorkspace.shared.open(url)
                    }
                }

                toggleButton(
                    icon: "lock.fill",
                    label: "Lock",
                    active: false
                ) {
                    lockScreen()
                }

                toggleButton(
                    icon: "gearshape.fill",
                    label: "Settings",
                    active: false
                ) {
                    DispatchQueue.main.async {
                        SettingsWindowController.shared.showWindow()
                    }
                }
            }
        }
        .cardStyle()
    }

    private func toggleButton(icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(active ? .cyan : .white.opacity(0.65))
                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(active ? .white : .white.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(active ? Color.cyan.opacity(0.25) : Color(white: 0.16).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(active ? Color.cyan.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func calculateDayProgress() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let startMinutes = 9 * 60   // 9:00 AM
        let endMinutes = 18 * 60    // 6:00 PM

        if currentMinutes < startMinutes { return 0.1 }
        if currentMinutes > endMinutes { return 1.0 }
        return Double(currentMinutes - startMinutes) / Double(endMinutes - startMinutes)
    }

    private func hoursRemainingString() -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let currentMinutes = hour * 60 + minute
        let endMinutes = 18 * 60
        let remainingMinutes = max(0, endMinutes - currentMinutes)
        let h = remainingMinutes / 60
        let m = remainingMinutes % 60
        if remainingMinutes <= 0 {
            return "Workday complete • Rest time"
        } else {
            return "\(h)h \(m)m remaining in workday"
        }
    }

    private func launchApp(bundleId: String, name: String) {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.launchApplication(name)
        }
    }

    private func lockScreen() {
        let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        if let libHandle = libHandle {
            let sym = dlsym(libHandle, "SACLockScreenImmediate")
            if let sym = sym {
                typealias SACLockScreenImmediateFunc = @convention(c) () -> Void
                let lockFunc = unsafeBitCast(sym, to: SACLockScreenImmediateFunc.self)
                lockFunc()
            }
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.11).opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.16), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
            )
    }
}
