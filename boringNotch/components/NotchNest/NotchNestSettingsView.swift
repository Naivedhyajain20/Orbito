import SwiftUI
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

enum NotchNestSettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case style = "Style"
    case player = "Player"
    case calendar = "Calendar"
    case pomodoro = "Pomodoro"
    case camera = "Camera"
    case clipboard = "Clipboard"
    case toggle = "Toggle"
    case game = "Game"
    case tray = "Tray"
    case support = "Support"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .style: return "eye.fill"
        case .player: return "play.fill"
        case .calendar: return "calendar"
        case .pomodoro: return "timer"
        case .camera: return "camera.fill"
        case .clipboard: return "doc.on.clipboard.fill"
        case .toggle: return "keyboard"
        case .game: return "gamecontroller.fill"
        case .tray: return "tray.fill"
        case .support: return "bubble.left.fill"
        }
    }
}

struct NotchNestSettingsView: View {
    @State private var selectedTab: NotchNestSettingsTab = .general

    // General Toggles (Connected directly to real Defaults)
    @Default(.showNestPlayer) private var enablePlayer
    @Default(.showNestCamera) private var enableCamera
    @Default(.showNestBookmarks) private var enableBookmarks
    @Default(.showNestCalendar) private var enableCalendar
    @Default(.showNestTimer) private var enableTimer
    @Default(.showNestNotes) private var enableNotes
    @Default(.showNestClipboard) private var enableClipboard

    // System features
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @Default(.showOnAllDisplays) private var showOnAllDisplays
    @State private var selectedDisplay: String = "Built-in Retina Display (Built-in)"
    @State private var componentOrder: [String] = ["Player", "Calendar", "Notes", "Timer", "Camera"]

    // Style tab states (Connected directly to real Defaults)
    @Default(.lightingEffect) private var lightingEffect
    @Default(.enableShadow) private var enableShadow
    @Default(.showBatteryIndicator) private var showBatteryIndicator
    @Default(.enableLiquidGlass) private var enableLiquidGlass
    @Default(.backgroundTint) private var backgroundTint
    @Default(.glassOpacity) private var glassOpacity
    @Default(.frostedBackground) private var frostedBackground
    @Default(.hideCompletedReminders) private var hideCompletedReminders
    @State private var darkness: Double = 0.95
    @State private var componentSeparators: Bool = true

    // Player tab states
    @State private var selectedPlayer: String = "Spotify"
    @Default(.playerColorTinting) private var playerColorTinting
    @Default(.useMusicVisualizer) private var useMusicVisualizer
    @State private var musicLiveActivity: Bool = true

    // Pomodoro tab states
    @State private var focusDuration: Double = 25
    @State private var restDuration: Double = 5
    @State private var sprintCount: Double = 4
    @State private var playTimerSound: Bool = true
    @State private var timerSoundName: String = "Marimba"
    @State private var pomodoroLiveActivity: Bool = true

    // Camera tab states
    @Default(.mirrorShape) private var mirrorShape
    @State private var cameraSource: String = "Automatic"
    @State private var mirrorFlip: Bool = true

    // Clipboard tab states
    @Default(.showClipboard) private var showClipboard
    @State private var clipboardNotifications: Bool = true
    @State private var onDeviceAI: Bool = true
    @State private var clipboardClearedAlert: Bool = false

    // Game tab states
    @State private var showGameTab: Bool = true
    @State private var gameSpeed: String = "Normal"

    // Tray tab states
    @State private var enableDropZone: Bool = true
    @State private var autoOpenOnDrag: Bool = true
    @State private var trayRetention: String = "1 Day"

    var body: some View {
        VStack(spacing: 0) {
            // TOP TOOLBAR
            HStack(spacing: 8) {
                ForEach(NotchNestSettingsTab.allCases) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                if selectedTab == tab {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 28, height: 28)
                                }

                                Image(systemName: tab.icon)
                                    .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                            }

                            Text(tab.rawValue)
                                .font(.system(size: 8.5, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                        }
                        .frame(width: 48)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.12))

            Divider()
                .background(Color.white.opacity(0.1))

            // TAB CONTENT
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    switch selectedTab {
                    case .general:
                        generalSection
                    case .style:
                        styleSection
                    case .player:
                        playerSection
                    case .calendar:
                        calendarSection
                    case .pomodoro:
                        pomodoroSection
                    case .camera:
                        cameraSection
                    case .clipboard:
                        clipboardSection
                    case .toggle:
                        toggleSection
                    case .game:
                        gameSection
                    case .tray:
                        traySection
                    case .support:
                        supportSection
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 800, height: 620)
        .background(Color(white: 0.10))
        .preferredColorScheme(.dark)
    }

    // MARK: - 1. General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enable Components
            VStack(alignment: .leading, spacing: 10) {
                Text("Enable Components")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 10) {
                    toggleCard(title: "Player", percent: "25%", isOn: $enablePlayer)
                    toggleCard(title: "Calendar", percent: "15%", isOn: $enableCalendar)
                    toggleCard(title: "Notes", percent: "20%", isOn: $enableNotes)
                    toggleCard(title: "Clipboard", percent: "15%", isOn: $enableClipboard)
                    toggleCard(title: "Timer", percent: "15%", isOn: $enableTimer)
                    toggleCard(title: "Camera", percent: "10%", isOn: $enableCamera)
                }

                Text("Enable or disable individual components. All modular components are customizable.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Component Order & Space Management
            VStack(alignment: .leading, spacing: 10) {
                Text("Component Order & Space Management")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 11, weight: .bold))
                            Text("Component Order")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)

                        Spacer()

                        HStack(spacing: 8) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 100, height: 6)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.green)
                                        .frame(width: 92.5, height: 6)
                                }

                            Text("Space Used: 92.5%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    HStack(spacing: 6) {
                        ForEach(Array(componentOrder.enumerated()), id: \.offset) { index, comp in
                            orderCard(title: comp, icon: iconForComponent(comp))

                            if index < componentOrder.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                }
                .padding(14)
                .background(cardBackground)
            }

            // System features
            VStack(alignment: .leading, spacing: 12) {
                Text("System features")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    HStack {
                        Text("Launch at Login")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .onChange(of: launchAtLogin) { _, val in
                                LaunchAtLogin.isEnabled = val
                            }
                    }

                    Divider().background(Color.white.opacity(0.06))

                    HStack {
                        Text("Show on all displays")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $showOnAllDisplays)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }

                    Divider().background(Color.white.opacity(0.06))

                    HStack {
                        Text("Show on a specific display")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $selectedDisplay) {
                            Text("Built-in Retina Display (Built-in)").tag("Built-in Retina Display (Built-in)")
                        }
                        .labelsHidden()
                        .frame(width: 220)
                    }
                }
                .padding(14)
                .background(cardBackground)
            }
        }
    }

    // MARK: - 2. Style Section
    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Liquid Glass & Visual Appearance")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Liquid Glass effect")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Applies Apple specular rim highlight and dynamic blur to notch edges")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $enableLiquidGlass)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Background Tint")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $backgroundTint) {
                        Text("Black").tag("Black")
                        Text("White").tag("White")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 140)
                }

                Divider().background(Color.white.opacity(0.06))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Opacity")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(glassOpacity * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Slider(value: $glassOpacity, in: 0.2...1.0)
                        .accentColor(.blue)
                }
            }
            .padding(14)
            .background(cardBackground)

            // Notch Background & Polish
            VStack(spacing: 14) {
                HStack {
                    Text("Frosted notch background")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $frostedBackground)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Glass rim specular highlight")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $lightingEffect)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Window drop shadow")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $enableShadow)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Battery capsule in notch header")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $showBatteryIndicator)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - 3. Player Section
    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Music Player Integration")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    Text("Default Music Player")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $selectedPlayer) {
                        Text("Spotify").tag("Spotify")
                        Text("Apple Music").tag("Apple Music")
                        Text("YouTube Music").tag("YouTube Music")
                    }
                    .frame(width: 160)
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Automation Permissions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Spotify")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Apple Music")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Music live activity in notch")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $musicLiveActivity)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Album artwork ambient color glow")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $playerColorTinting)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - 4. Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Calendar & Upcoming Events")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    Text("Calendar Selection")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("All System Calendars (Synced)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                HStack {
                    Text("Hide completed reminders")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $hideCompletedReminders)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - 5. Pomodoro Section
    private var pomodoroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Pomodoro & Focus Timer")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Focus Duration")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(focusDuration)) minutes")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Slider(value: $focusDuration, in: 10...60, step: 5)
                        .accentColor(.green)
                }

                Divider().background(Color.white.opacity(0.06))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Rest Duration")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(restDuration)) minutes")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Slider(value: $restDuration, in: 2...30, step: 1)
                        .accentColor(.green)
                }

                Divider().background(Color.white.opacity(0.06))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Number of Sprints")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(sprintCount)) sprints")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Slider(value: $sprintCount, in: 1...8, step: 1)
                        .accentColor(.green)
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Play completion sound")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $playTimerSound)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Timer Sound")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $timerSoundName) {
                        Text("Marimba").tag("Marimba")
                        Text("Bell").tag("Bell")
                        Text("Ping").tag("Ping")
                        Text("Digital").tag("Digital")
                    }
                    .frame(width: 140)
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - 6. Camera Section
    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Instant Camera Mirror")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    Text("Camera Access Status")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 7, height: 7)
                        Text("Authorized")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Mirror Shape")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $mirrorShape) {
                        Text("Circle").tag(MirrorShapeEnum.circle)
                        Text("Rounded Rectangle").tag(MirrorShapeEnum.rectangle)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 180)
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Camera Source")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $cameraSource) {
                        Text("Automatic").tag("Automatic")
                        Text("Built-in FaceTime HD Camera").tag("Built-in FaceTime HD Camera")
                    }
                    .frame(width: 200)
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - 7. Clipboard Section
    private var clipboardSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Smart AI Clipboard")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    Text("Enable Clipboard History")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $showClipboard)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Show copy notifications")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $clipboardNotifications)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("On-device AI search & classification")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $onDeviceAI)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("History Management")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Clear History") {
                        ClipboardManager.shared.clearUnpinned()
                        clipboardClearedAlert = true
                    }
                    .alert(isPresented: $clipboardClearedAlert) {
                        Alert(title: Text("Clipboard Cleared"), message: Text("All saved clipboard history items have been removed."), dismissButton: .default(Text("OK")))
                    }
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - 8. Toggle Section
    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Global Keyboard Shortcuts")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    Text("Toggle Notch Open/Close")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .toggleNotchOpen)
                }
                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Toggle Sneak Peek")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .toggleSneakPeek)
                }
                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Open Notes")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .toggleNotesPanel)
                }
                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Open Timers")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .openTimers)
                }
                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Open Clipboard")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .openClipboard)
                }
            }
            .padding(14)
            .background(cardBackground)

            Text("All shortcuts operate globally across macOS without needing to switch focus away from your active application.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - 9. Game Section
    private var gameSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Infinity Run Mini-Game")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    Text("Show Game Tab in Notch Header")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $showGameTab)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Game Progression Speed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $gameSpeed) {
                        Text("Normal").tag("Normal")
                        Text("Fast").tag("Fast")
                        Text("Sonic").tag("Sonic")
                    }
                    .frame(width: 140)
                }
            }
            .padding(14)
            .background(cardBackground)

            Text("Play the retro runner mini-game directly in the notch. Press the Spacebar or trackpad to jump over obstacles.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - 10. Tray Section
    private var traySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("File Tray & Temporary Drop Zone")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                HStack {
                    Text("Enable Drop Zone in Notch")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $enableDropZone)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Auto-open notch on file drag")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $autoOpenOnDrag)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("File Retention")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $trayRetention) {
                        Text("1 Hour").tag("1 Hour")
                        Text("1 Day").tag("1 Day")
                        Text("Until Closed").tag("Until Closed")
                    }
                    .frame(width: 140)
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - 11. Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("About Orbito")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                HStack {
                    Text("Version")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("1.2.0 (Unlocked Edition)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.blue)
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    Text("Status")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("All Features Active & Unlocked")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - Helpers & Styling
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: 0.14).opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func toggleCard(title: String, percent: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text(percent)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.14).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func orderCard(title: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(width: 68, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )
        )
    }

    private func iconForComponent(_ name: String) -> String {
        switch name {
        case "Player": return "play.circle"
        case "Calendar": return "calendar"
        case "Bookmarks": return "bookmark"
        case "Notes": return "note.text"
        case "Timer": return "timer"
        case "Camera": return "camera"
        default: return "app"
        }
    }
}

