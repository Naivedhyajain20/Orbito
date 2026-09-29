import SwiftUI
import Defaults
import LaunchAtLogin
import KeyboardShortcuts
import UniformTypeIdentifiers

enum NotchNestSettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case widgets = "Widgets"
    case wallpaper = "Wallpaper"
    case style = "Style"
    case player = "Player"
    case calendar = "Calendar"
    case pomodoro = "Pomodoro"
    case camera = "Camera"
    case coding = "Developer"
    case clipboard = "Clipboard"
    case toggle = "Toggle"
    case game = "Game"
    case tray = "Tray"
    case support = "Support"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .widgets: return "square.grid.2x2.fill"
        case .wallpaper: return "photo.fill"
        case .style: return "eye.fill"
        case .player: return "play.fill"
        case .calendar: return "calendar"
        case .pomodoro: return "timer"
        case .camera: return "camera.fill"
        case .coding: return "chevron.left.forwardslash.chevron.right"
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

    // Notch Customization & Wallpaper State
    @Default(.globalNotchBackground) private var globalNotchBackground
    @Default(.globalWallpaperPath) private var globalWallpaperPath
    @Default(.enableSpaceBackgrounds) private var enableSpaceBackgrounds
    @Default(.widgetSpacing) private var widgetSpacing
    @Default(.widgetCornerRadius) private var widgetCornerRadius
    @Default(.customOpenHeight) private var customOpenHeight
    @Default(.compactPlayerMode) private var compactPlayerMode
    @Default(.customCompanionPath) private var customCompanionPath
    @Default(.customCompanionType) private var customCompanionType
    @Default(.showCompanionText) private var showCompanionText
    @Default(.customCompanionText) private var customCompanionText
    @Default(.companionContentMode) private var companionContentMode
    @Default(.companionMediaSize) private var companionMediaSize
    @Default(.showDynamicIslandMusicAnimation) private var showDynamicIslandMusicAnimation
    @Default(.enableTimerAlarm) private var enableTimerAlarm
    @Default(.timerAlarmSoundName) private var timerAlarmSoundName
    @Default(.timerAlarmVolume) private var timerAlarmVolume

    // General Toggles (Connected directly to real Defaults)
    @Default(.showNestPlayer) private var enablePlayer
    @Default(.showNestCamera) private var enableCamera
    @Default(.showNestBookmarks) private var enableBookmarks
    @Default(.showNestCalendar) private var enableCalendar
    @Default(.showNestTimer) private var enableTimer
    @Default(.showNestNotes) private var enableNotes
    @Default(.showNestClipboard) private var enableClipboard
    @Default(.showNestWeather) private var enableWeather
    @Default(.showNestPet) private var enablePet
    @Default(.fullCoverPlayerStyle) private var fullCoverPlayer

    // System features
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @Default(.showOnLockScreen) private var showOnLockScreen
    @Default(.enableFaceIDUnlockAnimation) private var enableFaceIDUnlockAnimation
    @Default(.faceIDHaptics) private var faceIDHaptics
    @Default(.faceIDSound) private var faceIDSound
    @Default(.hideFromScreenRecording) private var hideFromScreenRecording
    @Default(.showOnAllDisplays) private var showOnAllDisplays
    @State private var selectedDisplay: String = "Built-in Retina Display (Built-in)"
    @Default(.nestComponentOrder) private var componentOrder
    @State private var draggedComponent: String? = nil

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
    @AppStorage("musicLiveActivityEnabled") private var musicLiveActivity: Bool = true

    // Pomodoro tab states
    @State private var focusDuration: Double = 25
    @State private var restDuration: Double = 5
    @State private var sprintCount: Double = 4
    @State private var playTimerSound: Bool = true
    @State private var timerSoundName: String = "Marimba"
    @State private var pomodoroLiveActivity: Bool = true
    @ObservedObject private var timerManager = TimerManager.shared

    // Camera tab states
    @Default(.mirrorShape) private var mirrorShape
    @Default(.mirrorRecordAudio) private var mirrorRecordAudio
    @State private var cameraSource: String = "Automatic"
    @State private var mirrorFlip: Bool = true

    // Developer / Coding Activity states
    @Default(.githubUsername) private var githubUsername
    @Default(.githubToken) private var githubToken
    @Default(.leetcodeUsername) private var leetcodeUsername
    @Default(.showCodingActivityInNotch) private var showCodingActivityInNotch
    @Default(.codingAutoRefreshMinutes) private var codingAutoRefreshMinutes
    @ObservedObject private var codingManager = CodingActivityManager.shared

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

    // Crop preview state
    @State private var showWallpaperCropSheet: Bool = false
    @State private var showCompanionCropSheet: Bool = false
    @State private var pendingCropImage: NSImage? = nil
    @State private var pendingImageSourcePath: String = ""
    @State private var pendingImageIsForWallpaper: Bool = true
    @State private var pendingCompanionType: String = "image"

    var body: some View {
        VStack(spacing: 0) {
            // TOP TOOLBAR
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
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
                            .frame(width: 50)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
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
                    case .widgets:
                        widgetsSection
                    case .wallpaper:
                        wallpaperSection
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
                    case .coding:
                        codingSection
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
        .sheet(isPresented: $showWallpaperCropSheet) {
            if let img = pendingCropImage {
                let notchAspect = max(1.5, openNotchSize.width / max(1, openNotchSize.height))
                ImageCropPreviewSheet(
                    sourceImage: img,
                    targetAspectRatio: notchAspect,
                    title: "Notch Wallpaper Preview & Crop",
                    onConfirm: { croppedImage in
                        if let savedPath = saveCroppedImageToAppSupport(croppedImage, originalPath: pendingImageSourcePath, subfolder: "wallpapers") {
                            globalWallpaperPath = savedPath
                        } else {
                            globalWallpaperPath = pendingImageSourcePath
                        }
                        globalNotchBackground = .image
                        enableLiquidGlass = false
                        showWallpaperCropSheet = false
                        pendingCropImage = nil
                    },
                    onCancel: {
                        showWallpaperCropSheet = false
                        pendingCropImage = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showCompanionCropSheet) {
            if let img = pendingCropImage {
                ImageCropPreviewSheet(
                    sourceImage: img,
                    targetAspectRatio: 1.0,  // pet widget is square
                    title: "Companion Widget Preview & Crop",
                    onConfirm: { croppedImage in
                        if let savedPath = saveCroppedImageToAppSupport(croppedImage, originalPath: pendingImageSourcePath, subfolder: "companion") {
                            customCompanionType = "image"
                            customCompanionPath = savedPath
                        } else {
                            customCompanionType = "image"
                            customCompanionPath = pendingImageSourcePath
                        }
                        showCompanionCropSheet = false
                        pendingCropImage = nil
                    },
                    onCancel: {
                        showCompanionCropSheet = false
                        pendingCropImage = nil
                    }
                )
            }
        }
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
                    toggleCard(title: "Weather", percent: "18%", isOn: $enableWeather)
                    toggleCard(title: "Clipboard", percent: "15%", isOn: $enableClipboard)
                    toggleCard(title: "Timer", percent: "15%", isOn: $enableTimer)
                    toggleCard(title: "Pet & Quote", percent: "15%", isOn: $enablePet)
                    toggleCard(title: "Camera", percent: "10%", isOn: $enableCamera)
                }

                HStack {
                    Toggle("Full-Cover Animated Album Art Style", isOn: $fullCoverPlayer)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 4)

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
                            let spaceUsed = computeSpaceUsed()
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 100, height: 6)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(spaceUsed > 90 ? Color.red : spaceUsed > 70 ? Color.orange : Color.green)
                                        .frame(width: CGFloat(spaceUsed), height: 6)
                                }

                            Text("Space: \(Int(spaceUsed))%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // Draggable order cards — only enabled components
                    let activeOrder = componentOrder.filter { isNestComponentEnabled($0) }
                    if activeOrder.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                            Text("No components enabled. Enable components above to arrange them.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else {
                        HStack(spacing: 6) {
                            ForEach(Array(activeOrder.enumerated()), id: \.element) { index, comp in
                                draggableOrderCard(title: comp, icon: nestComponentIcon(comp), index: index, total: activeOrder.count)

                                if index < activeOrder.count - 1 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                        }
                    }

                    // Reset button
                    HStack {
                        Spacer()
                        Button(action: {
                            componentOrder = allNestComponents
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset Order")
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
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
                        Text("Show on Lock Screen")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $showOnLockScreen)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }

                    Divider().background(Color.white.opacity(0.06))

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Face ID Unlock Animation")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Shows animated glyph when unlocking Mac")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Toggle("", isOn: $enableFaceIDUnlockAnimation)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }

                    if enableFaceIDUnlockAnimation {
                        Divider().background(Color.white.opacity(0.06))

                        HStack {
                            Text("Apple Pay Unlock Sound")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $faceIDSound)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }

                        Divider().background(Color.white.opacity(0.06))

                        HStack {
                            Text("Haptic Feedback on Unlock")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $faceIDHaptics)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }

                        Divider().background(Color.white.opacity(0.06))

                        Button {
                            FaceIDManager.shared.testUnlockSequence()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "faceid")
                                Text("Test Face ID Animation")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().background(Color.white.opacity(0.06))

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hide from Screenshots & Recordings")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Keeps Orbito hidden during screen recordings and screenshots")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Toggle("", isOn: $hideFromScreenRecording)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
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

    // MARK: - Widgets Section
    private var widgetsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Widgets & Notch Customization")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Control widget spacing, notch height, corner radius, and enable or disable individual widgets.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))
            }

            // Dimensions & Spacing Sliders Card
            VStack(alignment: .leading, spacing: 14) {
                Text("DIMENSIONS & SPACING CONTROLS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white.opacity(0.5))

                // Widget Spacing
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                        Text("Widget Spacing (Gap between widgets)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(widgetSpacing)) pt")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    Slider(value: $widgetSpacing, in: 4...24, step: 1)
                        .accentColor(.blue)
                }

                Divider().background(Color.white.opacity(0.06))

                // Corner Radius
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "square.dashed")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                        Text("Widget Corner Radius (Roundness)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(widgetCornerRadius)) pt")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    Slider(value: $widgetCornerRadius, in: 6...22, step: 1)
                        .accentColor(.blue)
                }

                Divider().background(Color.white.opacity(0.06))

                // Notch Expanded Height
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                        Text("Expanded Notch Height")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(customOpenHeight)) pt")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    Slider(value: $customOpenHeight, in: 140...220, step: 2)
                        .accentColor(.blue)
                }

                Divider().background(Color.white.opacity(0.06))

                // Compact Player Mode Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compact Music Player Layout")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Reduces player width so more widgets fit comfortably across your screen")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $compactPlayerMode)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                // Dynamic Island Music Animation Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamic Island Music Waveform")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Animated dynamic soundbars in the notch ear when music is playing")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $showDynamicIslandMusicAnimation)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            .padding(14)
            .background(cardBackground)

            // Modular Widgets Grid
            VStack(alignment: .leading, spacing: 12) {
                Text("ENABLED WIDGETS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white.opacity(0.5))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 10) {
                    toggleCard(title: "Music Player", percent: "Compact / Full", isOn: $enablePlayer)
                    toggleCard(title: "Calendar & Shortcuts", percent: "Events & Folders", isOn: $enableCalendar)
                    toggleCard(title: "Quick Notes Card", percent: "Add & View Notes", isOn: $enableNotes)
                    toggleCard(title: "Live Weather Card", percent: "Conditions & Temp", isOn: $enableWeather)
                    toggleCard(title: "Clipboard History", percent: "Text & Image Previews", isOn: $enableClipboard)
                    toggleCard(title: "Quick Timer & Stopwatch", percent: "Ruler & Ear Pill", isOn: $enableTimer)
                    toggleCard(title: "Pet & Quote", percent: "Companions", isOn: $enablePet)
                    toggleCard(title: "Mirror Camera", percent: "Video Mirror", isOn: $enableCamera)
                }
            }
            .padding(14)
            .background(cardBackground)

            // Reorder Widgets
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("COMPONENT ARRANGEMENT")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Button(action: {
                        componentOrder = allNestComponents
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                let activeOrder = componentOrder.filter { isNestComponentEnabled($0) }
                HStack(spacing: 6) {
                    ForEach(Array(activeOrder.enumerated()), id: \.element) { index, comp in
                        draggableOrderCard(title: comp, icon: nestComponentIcon(comp), index: index, total: activeOrder.count)
                        if index < activeOrder.count - 1 {
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
    }

    // MARK: - Wallpaper & Background Section
    private var wallpaperSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notch Background & Wallpaper")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Choose your notch style: Solid Black, Liquid Glass, Black Glass, or set your own custom wallpaper background.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))
            }

            // Global Background Style Card
            VStack(alignment: .leading, spacing: 14) {
                Text("GLOBAL NOTCH BACKGROUND")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white.opacity(0.5))

                HStack(spacing: 10) {
                    ForEach(NotchBackground.allCases, id: \.self) { bg in
                        Button(action: {
                            globalNotchBackground = bg
                            if bg == .glass {
                                enableLiquidGlass = true
                            } else {
                                enableLiquidGlass = false
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: bg.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(bg.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(globalNotchBackground == bg ? Color.blue.opacity(0.25) : Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9)
                                            .stroke(globalNotchBackground == bg ? Color.blue : Color.white.opacity(0.12), lineWidth: 1.2)
                                    )
                            )
                            .foregroundColor(globalNotchBackground == bg ? .white : .white.opacity(0.75))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // If Custom Image selected or available
                if globalNotchBackground == .image {
                    Divider().background(Color.white.opacity(0.08))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("CUSTOM WALLPAPER IMAGE")
                            .font(.system(size: 9.5, weight: .heavy))
                            .foregroundColor(.white.opacity(0.5))

                        HStack(spacing: 14) {
                            // Thumbnail Preview
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(white: 0.08))
                                    .frame(width: 80, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )

                                if let path = globalWallpaperPath, !path.isEmpty, FileManager.default.fileExists(atPath: path) {
                                    CustomCompanionMediaView(filePath: path, isFill: true)
                                        .frame(width: 80, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    VStack(spacing: 2) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 14))
                                        Text("No Image")
                                            .font(.system(size: 8))
                                    }
                                    .foregroundColor(.white.opacity(0.4))
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Button(action: {
                                        chooseCustomWallpaper()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "square.and.arrow.down")
                                            Text("Choose Image, GIF or Video...")
                                        }
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if globalWallpaperPath != nil && !(globalWallpaperPath?.isEmpty ?? true) {
                                        Button(action: {
                                            globalWallpaperPath = nil
                                        }) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "trash")
                                                Text("Remove")
                                            }
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.red.opacity(0.85))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.12)))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }

                                if let path = globalWallpaperPath, !path.isEmpty {
                                    Text(URL(fileURLWithPath: path).lastPathComponent)
                                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                } else {
                                    Text("Supports PNG, JPG, GIF, MP4, MOV. Static images can be cropped to fit the notch perfectly.")
                                        .font(.system(size: 9.5))
                                        .foregroundColor(.white.opacity(0.45))
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(cardBackground)

            // Spaces Sync Section
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "macwindow.on.rectangle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.blue)
                            Text("Sync with macOS Spaces (Desktops)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Automatically apply different backgrounds or wallpaper images to each macOS Space/Desktop.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    Spacer()
                    Toggle("", isOn: $enableSpaceBackgrounds)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                if enableSpaceBackgrounds {
                    Divider().background(Color.white.opacity(0.08))

                    // Embed SpaceBackgroundPickerView
                    SpaceBackgroundPickerView()
                }
            }
            .padding(14)
            .background(cardBackground)

            // Glass & Blur Tuning (Active when Glass or Black Glass is chosen)
            if globalNotchBackground == .glass || globalNotchBackground == .blackGlass {
                VStack(alignment: .leading, spacing: 14) {
                    Text("LIQUID GLASS CONTROLS")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white.opacity(0.5))

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Frosted Window Blur")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Blurs desktop wallpaper and windows beneath the notch")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Toggle("", isOn: $frostedBackground)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }

                    Divider().background(Color.white.opacity(0.06))

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Specular Rim Highlight")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Apple-style subtle specular rim lighting along the notch curved edges")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Toggle("", isOn: $lightingEffect)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }

                    Divider().background(Color.white.opacity(0.06))

                    HStack {
                        Text("Glass Tint")
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
                            Text("Glass Opacity")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(glassOpacity * 100))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Slider(value: $glassOpacity, in: 0.15...1.0)
                            .accentColor(.blue)
                    }
                }
                .padding(14)
                .background(cardBackground)
            }

            // MARK: - Companion Widget Media Slot (Pet / GIF / Video)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles.tv")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.pink)
                            Text("Companion Widget Media (Pet Slot)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Customize the animation widget in your notch (shown in Image 2): keep the animated Pixel Pet, or set your own custom Image, animated GIF, or looping Video (MP4 / MOV).")
                            .font(.system(size: 10.5))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    Spacer()
                }

                HStack(spacing: 16) {
                    // Preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.08))
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )

                        CustomCompanionMediaView(
                            customPath: customCompanionPath,
                            customType: customCompanionType,
                            size: 64
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Button(action: {
                                chooseCompanionMedia()
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "photo.badge.plus")
                                    Text("Choose Image, GIF or Video...")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
                            }
                            .buttonStyle(PlainButtonStyle())

                            if customCompanionPath != nil {
                                Button(action: {
                                    customCompanionPath = nil
                                    customCompanionType = "pet"
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Reset to Pixel Pet")
                                    }
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        if let path = customCompanionPath, !path.isEmpty {
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(.green.opacity(0.9))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("Currently showing default Pixel Pet animation.")
                                .font(.system(size: 9.5))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Text("Supports: GIF, MP4, MOV, PNG, JPG, WebP. Videos loop automatically with muted sound.")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Divider().background(Color.white.opacity(0.06))

                // Display Mode: Fit Centered vs Fill Card
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Display Style")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Fit centered with adjustable size, or fill the entire widget card")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Picker("", selection: $companionContentMode) {
                        Text("Fit Centered").tag("fit")
                        Text("Fill Card").tag("fill")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 180)
                }

                if companionContentMode == "fit" {
                    Divider().background(Color.white.opacity(0.06))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Media Display Size")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(companionMediaSize)) pt")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Slider(value: $companionMediaSize, in: 36...96, step: 2)
                            .accentColor(.pink)
                    }
                }

                Divider().background(Color.white.opacity(0.06))

                // Caption Text controls
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Caption Text")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Display text below the media (e.g. \"YOU ARE PERFECT JUST KEEP GOING\")")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $showCompanionText)
                        .toggleStyle(SwitchToggleStyle(tint: .pink))
                }

                if showCompanionText {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Caption Message")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 8) {
                            TextField("Motivational message...", text: $customCompanionText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))

                            Button("Reset") {
                                customCompanionText = "YOU ARE PERFECT JUST KEEP GOING"
                            }
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    private func chooseCustomWallpaper() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            .image, .png, .jpeg, .gif, .movie, .quickTimeMovie, .mpeg4Movie
        ]
        if panel.runModal() == .OK, let url = panel.url {
            let ext = url.pathExtension.lowercased()
            if ext == "gif" || ["mp4", "mov", "m4v"].contains(ext) {
                // Animated GIF or Video: copy to App Support wallpapers directory for guaranteed sandbox access
                if let savedPath = copyMediaToAppSupport(sourceURL: url, subfolder: "wallpapers") {
                    globalWallpaperPath = savedPath
                } else {
                    globalWallpaperPath = url.path
                }
                globalNotchBackground = .image
                enableLiquidGlass = false
            } else if let image = NSImage(contentsOfFile: url.path) {
                // Static image: show crop preview sheet
                pendingImageSourcePath = url.path
                pendingImageIsForWallpaper = true
                pendingCropImage = image
                showWallpaperCropSheet = true
            } else {
                if let savedPath = copyMediaToAppSupport(sourceURL: url, subfolder: "wallpapers") {
                    globalWallpaperPath = savedPath
                } else {
                    globalWallpaperPath = url.path
                }
                globalNotchBackground = .image
                enableLiquidGlass = false
            }
        }
    }

    private func chooseCompanionMedia() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            .image, .png, .jpeg, .gif, .movie, .quickTimeMovie, .mpeg4Movie
        ]
        if panel.runModal() == .OK, let url = panel.url {
            let ext = url.pathExtension.lowercased()
            if ext == "gif" {
                // GIFs: copy to App Support and apply directly
                if let savedPath = copyMediaToAppSupport(sourceURL: url, subfolder: "companion") {
                    customCompanionType = "gif"
                    customCompanionPath = savedPath
                } else {
                    customCompanionType = "gif"
                    customCompanionPath = url.path
                }
            } else if ["mp4", "mov", "m4v"].contains(ext) {
                // Videos: copy to App Support and apply directly
                if let savedPath = copyMediaToAppSupport(sourceURL: url, subfolder: "companion") {
                    customCompanionType = "video"
                    customCompanionPath = savedPath
                } else {
                    customCompanionType = "video"
                    customCompanionPath = url.path
                }
            } else {
                // Static images: show crop preview
                if let image = NSImage(contentsOfFile: url.path) {
                    pendingImageSourcePath = url.path
                    pendingCompanionType = "image"
                    pendingImageIsForWallpaper = false
                    pendingCropImage = image
                    showCompanionCropSheet = true
                } else {
                    if let savedPath = copyMediaToAppSupport(sourceURL: url, subfolder: "companion") {
                        customCompanionType = "image"
                        customCompanionPath = savedPath
                    } else {
                        customCompanionType = "image"
                        customCompanionPath = url.path
                    }
                }
            }
        }
    }

    // MARK: - 2. Style Section
    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Visual Style & Effects")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Customize drop shadow, notch header battery capsule, and visual polish.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))
            }

            // Quick link card informing user that Liquid Glass & Background are in Wallpaper tab
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(.cyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Liquid Glass & Wallpaper Background")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Liquid Glass, Black Glass, Custom Wallpaper, and Pet media slot are configured together in the Wallpaper tab.")
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Button(action: {
                    selectedTab = .wallpaper
                }) {
                    Text("Go to Wallpaper →")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.blue.opacity(0.15)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(14)
            .background(cardBackground)

            // Notch Appearance & Polish
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Window drop shadow")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Adds subtle elevation shadow behind the expanded notch")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $enableShadow)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Battery capsule in notch header")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Displays battery percentage and charging state in the top header")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
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

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamic Island sound wave animation")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Smooth animated audio visualizer bars when music is playing in the notch")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $showDynamicIslandMusicAnimation)
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Audible Timer & Pomodoro Alarm")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Rings an audible alarm sound when countdown or focus session completes")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $enableTimerAlarm)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }

                if enableTimerAlarm {
                    Divider().background(Color.white.opacity(0.06))

                    HStack {
                        Text("Alarm Sound")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $timerAlarmSoundName) {
                            Text("Alarm").tag("Alarm")
                            Text("Bell").tag("Bell")
                            Text("Ping").tag("Ping")
                            Text("Marimba").tag("Marimba")
                            Text("Digital").tag("Digital")
                            Text("Breeze").tag("Breeze")
                            Text("SOS").tag("SOS")
                        }
                        .frame(width: 130)

                        Button(action: {
                            timerManager.testAlarmSound()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2.fill")
                                Text("Test")
                            }
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.25)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Divider().background(Color.white.opacity(0.06))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Alarm Volume")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(timerAlarmVolume * 100))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Slider(value: $timerAlarmVolume, in: 0.1...1.0)
                            .accentColor(.green)
                    }

                    if timerManager.isAlarmRinging {
                        Divider().background(Color.white.opacity(0.06))

                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.red)
                                Text("Alarm is currently ringing!")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            Spacer()
                            Button(action: {
                                timerManager.stopAlarm()
                            }) {
                                Text("Stop Alarm")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.red))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
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

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Record Microphone Audio")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Include voice audio when using the mirror record button.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $mirrorRecordAudio)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recordings Folder")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("~/Movies/Orbito Recordings")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Button(action: {
                        let movies = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
                        if let folder = movies?.appendingPathComponent("Orbito Recordings", isDirectory: true) {
                            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                            NSWorkspace.shared.open(folder)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 9))
                            Text("Open in Finder")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    // MARK: - 7. Developer & Coding Activity Section (GitHub & LeetCode)
    private var codingSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Developer Profiles (GitHub & LeetCode)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Monitor your real-time GitHub commit graphs, LeetCode problem solving, and streaks right from the notch.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }

            // MARK: GitHub Account Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .foregroundColor(Color(red: 57/255, green: 211/255, blue: 83/255))
                            .font(.system(size: 13, weight: .bold))
                        Text("GitHub Profile")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if let gh = codingManager.githubData {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("Connected as @\(gh.username)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                    } else {
                        Text("Not Linked")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                // Username input row
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Username")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        TextField("e.g. torvalds, octocat", text: $githubUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Personal Token (Optional)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        SecureField("ghp_... (for private commits)", text: $githubToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    Button(action: {
                        codingManager.refreshGitHub()
                    }) {
                        HStack(spacing: 3) {
                            if codingManager.isLoadingGitHub {
                                ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            Text("Verify & Link")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .disabled(githubUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || codingManager.isLoadingGitHub)
                    .padding(.top, 16)
                }

                if let err = codingManager.githubError {
                    Text(err)
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }

                // Live Profile & Heatmap Preview
                if let gh = codingManager.githubData {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider().background(Color.white.opacity(0.08))

                        HStack(spacing: 12) {
                            if let avatar = gh.avatarUrl, let url = URL(string: avatar) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    default:
                                        Image(systemName: "person.circle").foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(red: 57/255, green: 211/255, blue: 83/255), lineWidth: 1.2))
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(gh.name ?? gh.username)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                Text("@\(gh.username) • \(gh.publicRepos) public repos • \(gh.followers) followers")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("\(gh.totalContributionsYear)")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(Color(red: 57/255, green: 211/255, blue: 83/255))
                                    Text("Past Year Commits")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("🔥 \(gh.currentStreak)d")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.15))
                                    Text("Current Streak")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }

                        // Mini Contribution Graph Preview
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 2) {
                                ForEach(gh.weeks) { week in
                                    VStack(spacing: 2) {
                                        ForEach(week.days) { day in
                                            RoundedRectangle(cornerRadius: 1.5)
                                                .fill(miniGithubColor(day.level))
                                                .frame(width: 7, height: 7)
                                        }
                                    }
                                }
                            }
                            .padding(4)
                        }
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.4)))
                    }
                }
            }
            .padding(14)
            .background(cardBackground)

            // MARK: LeetCode Account Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "curlybraces")
                            .foregroundColor(Color(red: 255/255, green: 161/255, blue: 22/255))
                            .font(.system(size: 13, weight: .bold))
                        Text("LeetCode Profile")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if let lc = codingManager.leetcodeData {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("Connected as @\(lc.username)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                    } else {
                        Text("Not Linked")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                // Username input row
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LeetCode Username")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        TextField("e.g. your_handle", text: $leetcodeUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    Button(action: {
                        codingManager.refreshLeetCode()
                    }) {
                        HStack(spacing: 3) {
                            if codingManager.isLoadingLeetCode {
                                ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            Text("Verify & Link")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .disabled(leetcodeUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || codingManager.isLoadingLeetCode)
                    .padding(.top, 16)
                }

                if let err = codingManager.leetcodeError {
                    Text(err)
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }

                // Live Stats Preview
                if let lc = codingManager.leetcodeData {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider().background(Color.white.opacity(0.08))

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(lc.realName ?? lc.username)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                Text(lc.ranking > 0 ? "Global Rank #\(lc.ranking)" : "@\(lc.username)")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(Color(red: 255/255, green: 161/255, blue: 22/255))
                            }

                            Spacer()

                            HStack(spacing: 6) {
                                HStack(spacing: 2) {
                                    Text("Easy:").font(.system(size: 9, weight: .medium)).foregroundColor(.white.opacity(0.6))
                                    Text("\(lc.easySolved)").font(.system(size: 10, weight: .heavy)).foregroundColor(Color(red: 0/255, green: 184/255, blue: 163/255))
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color.white.opacity(0.06)))

                                HStack(spacing: 2) {
                                    Text("Med:").font(.system(size: 9, weight: .medium)).foregroundColor(.white.opacity(0.6))
                                    Text("\(lc.mediumSolved)").font(.system(size: 10, weight: .heavy)).foregroundColor(Color(red: 255/255, green: 192/255, blue: 30/255))
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color.white.opacity(0.06)))

                                HStack(spacing: 2) {
                                    Text("Hard:").font(.system(size: 9, weight: .medium)).foregroundColor(.white.opacity(0.6))
                                    Text("\(lc.hardSolved)").font(.system(size: 10, weight: .heavy)).foregroundColor(Color(red: 255/255, green: 55/255, blue: 95/255))
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color.white.opacity(0.06)))

                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("\(lc.totalSolved)")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Total Solved")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(cardBackground)

            // MARK: Display Preferences Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Notch Preferences")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Developer Icon in Notch Bar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Displays the code symbol in the notch header for 1-click access to your heatmaps.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Toggle("", isOn: $showCodingActivityInNotch)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-Refresh Interval")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Frequency of automatic background syncs from GitHub and LeetCode.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Picker("", selection: $codingAutoRefreshMinutes) {
                        Text("Every 15 minutes").tag(15)
                        Text("Every 30 minutes").tag(30)
                        Text("Every 1 hour").tag(60)
                        Text("Every 2 hours").tag(120)
                    }
                    .frame(width: 170)
                    .onChange(of: codingAutoRefreshMinutes) { _, _ in
                        codingManager.setupAutoRefresh()
                    }
                }
            }
            .padding(14)
            .background(cardBackground)
        }
    }

    private func miniGithubColor(_ level: Int) -> Color {
        switch level {
        case 1: return Color(red: 14/255, green: 68/255, blue: 41/255)
        case 2: return Color(red: 0/255, green: 109/255, blue: 50/255)
        case 3: return Color(red: 38/255, green: 166/255, blue: 65/255)
        case 4: return Color(red: 57/255, green: 211/255, blue: 83/255)
        default: return Color(red: 22/255, green: 27/255, blue: 34/255)
        }
    }

    // MARK: - 8. Clipboard Section
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

    /// Draggable order card with left/right arrow buttons for reordering
    private func draggableOrderCard(title: String, icon: String, index: Int, total: Int) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            // Move arrows
            HStack(spacing: 8) {
                Button(action: { moveComponent(title, direction: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(index == 0 ? .white.opacity(0.15) : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .disabled(index == 0)

                Button(action: { moveComponent(title, direction: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(index == total - 1 ? .white.opacity(0.15) : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .disabled(index == total - 1)
            }
        }
        .frame(width: 68, height: 58)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(draggedComponent == title ? Color.blue.opacity(0.3) : Color(white: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(draggedComponent == title ? Color.blue.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 0.8)
                )
        )
        .onDrag {
            draggedComponent = title
            return NSItemProvider(object: title as NSString)
        }
        .onDrop(of: [.text], delegate: ComponentDropDelegate(
            item: title,
            componentOrder: $componentOrder,
            draggedItem: $draggedComponent
        ))
    }

    /// Compute space used as percentage (based on active component widths vs max notch width)
    private func computeSpaceUsed() -> Double {
        let maxWidth: Double = 1060.0
        let activeOrder = componentOrder.filter { isNestComponentEnabled($0) }
        var totalWidth: Double = 16 // base padding
        for (index, comp) in activeOrder.enumerated() {
            totalWidth += Double(nestComponentWidths[comp] ?? 0)
            if index < activeOrder.count - 1 {
                totalWidth += 9
            }
        }
        return min((totalWidth / maxWidth) * 100.0, 100.0)
    }

    /// Move a component left (-1) or right (+1) in the order
    private func moveComponent(_ name: String, direction: Int) {
        guard let currentIndex = componentOrder.firstIndex(of: name) else { return }
        
        // Find the next/prev enabled component in componentOrder
        let enabledInOrder = componentOrder.filter { isNestComponentEnabled($0) }
        guard let enabledIndex = enabledInOrder.firstIndex(of: name) else { return }
        let targetEnabledIndex = enabledIndex + direction
        guard targetEnabledIndex >= 0, targetEnabledIndex < enabledInOrder.count else { return }
        let targetName = enabledInOrder[targetEnabledIndex]
        guard let targetIndex = componentOrder.firstIndex(of: targetName) else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            componentOrder.swapAt(currentIndex, targetIndex)
        }
    }

    private func iconForComponent(_ name: String) -> String {
        return nestComponentIcon(name)
    }
}

// MARK: - Drop Delegate for Component Reorder
struct ComponentDropDelegate: DropDelegate {
    let item: String
    @Binding var componentOrder: [String]
    @Binding var draggedItem: String?

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedItem,
              dragged != item,
              let fromIndex = componentOrder.firstIndex(of: dragged),
              let toIndex = componentOrder.firstIndex(of: item)
        else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            componentOrder.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
