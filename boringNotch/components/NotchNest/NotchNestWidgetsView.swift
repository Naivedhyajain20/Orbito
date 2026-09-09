//
//  NotchNestWidgetsView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Defaults
import AppKit

struct NotchNestWidgetsView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var calendarManager = CalendarManager.shared
    @ObservedObject var timerManager = TimerManager.shared
    @ObservedObject var notesModel = NotesStateViewModel.shared
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @EnvironmentObject var vm: BoringViewModel

    @Default(.showNestPlayer) var showNestPlayer
    @Default(.showNestCalendar) var showNestCalendar
    @Default(.showNestNotes) var showNestNotes
    @Default(.showNestClipboard) var showNestClipboard
    @Default(.showNestTimer) var showNestTimer
    @Default(.showNestCamera) var showNestCamera
    @Default(.nestShortcuts) var nestShortcuts

    // Shortcuts Manager State
    @State private var showShortcutManager: Bool = false
    @State private var newShortcutName: String = ""
    @State private var newShortcutType: ShortcutItem.ShortcutType = .url
    @State private var newShortcutTarget: String = ""
    @State private var newShortcutIcon: String = "globe"

    // Music Seeking
    @State private var isSeeking: Bool = false
    @State private var seekPosition: Double = 0

    // Dynamic Music Accent Colors (Smoothly adapts to currently playing album artwork)
    private var musicAccentColor: Color {
        if musicManager.songTitle.isEmpty {
            return Color(red: 0.95, green: 0.98, blue: 0.20)
        }
        return Color(nsColor: musicManager.avgColor).ensureMinimumBrightness(factor: 0.85)
    }

    private var musicSecondaryColor: Color {
        if musicManager.songTitle.isEmpty {
            return Color(red: 0.90, green: 0.92, blue: 0.40)
        }
        return Color(nsColor: musicManager.avgColor).ensureMinimumBrightness(factor: 0.68)
    }

    // Notes Popup & Creation
    @State private var editingNote: Note? = nil
    @State private var isCreatingNewNote: Bool = false
    @State private var noteDraftText: String = ""

    // Clipboard Copy State
    @State private var copiedItemId: UUID? = nil

    private var effectiveDuration: Double {
        musicManager.songDuration > 0 ? musicManager.songDuration : 180
    }

    var body: some View {
        ZStack {
            // Main horizontal widget bar
            HStack(spacing: 0) {
                // 1. MUSIC PLAYER  ── ~252px
                if showNestPlayer {
                    playerWidget
                        .frame(width: 252)

                    if showNestCalendar || showNestNotes || showNestClipboard || showNestTimer || showNestCamera {
                        divider
                    }
                }

                // 2. CALENDAR ── ~108px
                if showNestCalendar {
                    calendarWidget
                        .frame(width: 108)

                    // 3. SHORTCUTS & QUICK LAUNCHER ── ~46px
                    shortcutsWidget
                        .frame(width: 46)

                    if showNestNotes || showNestClipboard || showNestTimer || showNestCamera {
                        divider
                    }
                }

                // 4. QUICK NOTES (Matching Screenshot Layout) ── ~175px
                if showNestNotes {
                    quickNotesWidget
                        .frame(width: 175)

                    if showNestClipboard || showNestTimer || showNestCamera {
                        divider
                    }
                }

                // 5. CLIPBOARD WIDGET (Live scrollable history with 1-tap copy) ── ~170px
                if showNestClipboard {
                    clipboardWidget
                        .frame(width: 170)

                    if showNestTimer || showNestCamera {
                        divider
                    }
                }

                // 6. POMODORO ── ~140px
                if showNestTimer {
                    pomodoroWidget
                        .frame(width: 140)

                    if showNestCamera {
                        divider
                    }
                }

                // 7. CAMERA / MIRROR (Large Circular preview) ── ~96px
                if showNestCamera {
                    mirrorWidget
                        .frame(width: 96)
                }
            }
            .frame(height: 114)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)

            // Note Pop-Up Editor Modal
            if isCreatingNewNote || editingNote != nil {
                noteEditorPopup
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                    .zIndex(100)
            }

            // Shortcuts & Quick Launcher Manager Modal
            if showShortcutManager {
                shortcutManagerPopup
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                    .zIndex(101)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isCreatingNewNote || editingNote != nil || showShortcutManager)
    }

    // MARK: Vertical divider

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 76)
            .padding(.horizontal, 4)
    }

    // MARK: ── 1. Music Player (Exact Match to Screenshot) ───────────────────

    private var playerWidget: some View {
        HStack(spacing: 12) {
            // Album Art (88x88 large square with rounded corners and Spotify badge)
            ZStack(alignment: .bottomTrailing) {
                Button(action: { musicManager.openMusicApp() }) {
                    ZStack {
                        if !musicManager.songTitle.isEmpty || musicManager.isPlaying {
                            Image(nsImage: musicManager.albumArt)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 86, height: 86)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .blur(radius: musicManager.isPlaying ? 0 : 1.0)
                                .brightness(musicManager.isPlaying ? 0 : -0.12)
                                .opacity(musicManager.isPlaying ? 1.0 : 0.88)
                                .scaleEffect(musicManager.isPlaying ? 1.0 : 0.90)
                                .animation(.spring(response: 0.38, dampingFraction: 0.70), value: musicManager.isPlaying)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(white: 0.20))
                                .frame(width: 86, height: 86)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 30, weight: .semibold))
                                        .foregroundColor(Color(white: 0.50))
                                )
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                musicManager.isPlaying ? Color.white.opacity(0.14) : Color.white.opacity(0.04),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(
                        color: musicManager.isPlaying ? .black.opacity(0.55) : .black.opacity(0.25),
                        radius: musicManager.isPlaying ? 6 : 2,
                        y: musicManager.isPlaying ? 3 : 1
                    )
                    .animation(.spring(response: 0.38, dampingFraction: 0.70), value: musicManager.isPlaying)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open Music App")

                // Spotify-green badge
                Circle()
                    .fill(Color(red: 30/255, green: 215/255, blue: 96/255))
                    .frame(width: 17, height: 17)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 7.5, weight: .heavy))
                            .foregroundColor(.black)
                    )
                    .offset(x: 3, y: 3)
            }

            // Song info + scrubber + timestamps + transport controls
            VStack(alignment: .leading, spacing: 3) {
                // Song title (Dynamic dominant color from album artwork)
                Text(musicManager.songTitle.isEmpty ? "Not Playing" : musicManager.songTitle)
                    .font(.system(size: 13, weight: .heavy, design: .default))
                    .foregroundColor(musicAccentColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .animation(.smooth(duration: 0.35), value: musicManager.avgColor)

                // Artist (Dynamic secondary tint from album artwork)
                Text(musicManager.artistName.isEmpty ? "—" : musicManager.artistName)
                    .font(.system(size: 11.5, weight: .bold, design: .default))
                    .foregroundColor(musicSecondaryColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .animation(.smooth(duration: 0.35), value: musicManager.avgColor)

                Spacer(minLength: 1)

                // Scrubber bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.22))
                            .frame(height: 3.5)

                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: geo.size.width * CGFloat(
                                    min(max((isSeeking ? seekPosition : musicManager.elapsedTime) / effectiveDuration, 0), 1)
                                ),
                                height: 3.5
                            )
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                isSeeking = true
                                seekPosition = min(max(val.location.x / geo.size.width, 0), 1) * effectiveDuration
                            }
                            .onEnded { val in
                                let t = min(max(val.location.x / geo.size.width, 0), 1) * effectiveDuration
                                seekPosition = t
                                musicManager.seek(to: t)
                                isSeeking = false
                            }
                    )
                }
                .frame(height: 4)

                // Timestamps (Dynamic color matching artwork)
                HStack {
                    Text(formatTime(isSeeking ? seekPosition : musicManager.elapsedTime))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(musicSecondaryColor)
                    Spacer()
                    Text(formatTime(effectiveDuration))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(musicSecondaryColor)
                }
                .animation(.smooth(duration: 0.35), value: musicManager.avgColor)

                Spacer(minLength: 1)

                // Transport controls: ◀◀ ▶/❚❚ ▶▶
                HStack(spacing: 18) {
                    Button(action: { musicManager.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.92))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { musicManager.playPause() }) {
                        Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16.5, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { musicManager.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.92))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 3)
    }

    // MARK: ── 2. Calendar ────────────────────────────────────────────────────

    private var calendarWidget: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Month + sparkle
            HStack(spacing: 4) {
                Text(Date().formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 14, weight: .heavy, design: .default))
                    .foregroundColor(.white)
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.70))
            }

            Spacer(minLength: 0)

            // Event title or placeholder
            Text(calendarManager.events.first?.title ?? "No Events")
                .font(.system(size: 11.5, weight: .bold, design: .default))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            Spacer(minLength: 0)

            // ─── Surrounding days strip ───────────────────────────────────────
            HStack(spacing: 4) {
                ForEach(surroundingDays(), id: \.day) { item in
                    VStack(spacing: 2) {
                        Text(item.weekday)
                            .font(.system(size: 8.5, weight: .heavy))
                            .foregroundColor(item.isToday ? .white : .white.opacity(0.40))
                        if item.isToday {
                            Text("\(item.day)")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 20)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.22)))
                        } else {
                            Text("\(item.day)")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white.opacity(0.45))
                                .frame(width: 22, height: 20)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: ── 3. Shortcuts & Quick Launcher (Max 6 limit) ────────────────────

    private var shortcutsWidget: some View {
        let columns = [
            GridItem(.fixed(26), spacing: 4),
            GridItem(.fixed(26), spacing: 4)
        ]

        return LazyVGrid(columns: columns, spacing: 4) {
            // Display shortcuts up to max 6
            ForEach(nestShortcuts.prefix(6)) { item in
                Button(action: {
                    launchShortcut(item)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(white: 0.15))
                            .frame(width: 26, height: 26)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                        Image(systemName: item.iconName.isEmpty ? "link" : item.iconName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .help("\(item.name) (\(item.target))")
                .contextMenu {
                    Button("Open \(item.name)") {
                        launchShortcut(item)
                    }
                    Button("Delete \(item.name)", role: .destructive) {
                        withAnimation {
                            nestShortcuts.removeAll { $0.id == item.id }
                        }
                    }
                    Divider()
                    Button("Manage Shortcuts (Max 6)...") {
                        showShortcutManager = true
                    }
                }
            }

            // If less than 6 shortcuts, show (+) slot to add more
            if nestShortcuts.count < 6 {
                Button(action: {
                    newShortcutName = ""
                    newShortcutTarget = ""
                    newShortcutType = .url
                    newShortcutIcon = "globe"
                    showShortcutManager = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(white: 0.10))
                            .frame(width: 26, height: 26)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 0.8, dash: [2]))
                            )
                        Image(systemName: "plus")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .help("Add Shortcut (\(nestShortcuts.count)/6)")
            }
        }
        .frame(width: 56)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func launchShortcut(_ item: ShortcutItem) {
        if item.type == .app {
            if item.target.hasPrefix("/") {
                let url = URL(fileURLWithPath: item.target)
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.target) {
                NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
            } else if let url = URL(string: item.target) {
                NSWorkspace.shared.open(url)
            }
        } else {
            var urlStr = item.target.trimmingCharacters(in: .whitespacesAndNewlines)
            if !urlStr.contains("://") && !urlStr.hasPrefix("mailto:") && !urlStr.hasPrefix("calshow:") {
                urlStr = "https://" + urlStr
            }
            if let url = URL(string: urlStr) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func chooseAppFile() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            newShortcutTarget = url.path
            if newShortcutName.isEmpty {
                newShortcutName = url.deletingPathExtension().lastPathComponent
            }
            newShortcutIcon = "app.badge.fill"
            newShortcutType = .app
        }
    }

    private func saveNewShortcut() {
        guard nestShortcuts.count < 6 else { return }
        guard !newShortcutName.trimmingCharacters(in: .whitespaces).isEmpty,
              !newShortcutTarget.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let item = ShortcutItem(
            name: newShortcutName.trimmingCharacters(in: .whitespaces),
            type: newShortcutType,
            target: newShortcutTarget.trimmingCharacters(in: .whitespaces),
            iconName: newShortcutIcon
        )
        nestShortcuts.append(item)
        newShortcutName = ""
        newShortcutTarget = ""
    }

    // MARK: ── Shortcuts & Quick Apps Modal (Max 6) ───────────────────────────

    private var shortcutManagerPopup: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.68)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { showShortcutManager = false }

            // Frosted glass modal
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                        Text("Shortcuts & Quick Apps")
                            .font(.system(size: 12.5, weight: .heavy, design: .default))
                            .foregroundColor(.white)
                        Text("\(nestShortcuts.count)/6 MAX")
                            .font(.system(size: 8, weight: .heavy))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(
                                    nestShortcuts.count >= 6 ? Color.red.opacity(0.25) : Color.blue.opacity(0.25)
                                )
                            )
                            .foregroundColor(nestShortcuts.count >= 6 ? .red : Color(red: 0.35, green: 0.75, blue: 1.0))
                    }

                    Spacer()

                    Button(action: { showShortcutManager = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Existing Shortcuts List
                if nestShortcuts.isEmpty {
                    Text("No shortcuts added yet. Add up to 6 apps or URLs below.")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 4) {
                            ForEach(nestShortcuts) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: item.iconName.isEmpty ? "link" : item.iconName)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.name)
                                            .font(.system(size: 10.5, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(item.target)
                                            .font(.system(size: 8.5, weight: .medium))
                                            .foregroundColor(.white.opacity(0.50))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }

                                    Spacer()

                                    // Launch test
                                    Button(action: { launchShortcut(item) }) {
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.70))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Open Shortcut")

                                    // Delete
                                    Button(action: {
                                        withAnimation {
                                            nestShortcuts.removeAll { $0.id == item.id }
                                        }
                                    }) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.red.opacity(0.85))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Delete Shortcut")
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color(white: 0.12))
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 110)
                }

                Divider().background(Color.white.opacity(0.10))

                // Add New Form (Enforce Max 6)
                if nestShortcuts.count >= 6 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 11))
                        Text("Limit reached: Maximum 6 shortcuts allowed. Delete an existing shortcut to add a new one.")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.12)))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ADD NEW SHORTCUT (\(nestShortcuts.count)/6)")
                            .font(.system(size: 8.5, weight: .heavy))
                            .foregroundColor(.white.opacity(0.50))

                        HStack(spacing: 6) {
                            TextField("Name (e.g. Figma, GitHub)", text: $newShortcutName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.08)))

                            Picker("", selection: $newShortcutType) {
                                Text("Web URL").tag(ShortcutItem.ShortcutType.url)
                                Text("Mac App").tag(ShortcutItem.ShortcutType.app)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 140)
                        }

                        HStack(spacing: 6) {
                            TextField(newShortcutType == .url ? "URL (e.g. https://github.com)" : "App Path (/Applications/...)", text: $newShortcutTarget)
                                .textFieldStyle(.plain)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.08)))

                            if newShortcutType == .app {
                                Button(action: { chooseAppFile() }) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "folder")
                                        Text("Browse...")
                                    }
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.18)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Icon Selector Row
                        HStack(spacing: 6) {
                            Text("Icon:")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.55))

                            let availableIcons = [
                                "globe", "link", "bubble.left.and.sparkles.fill", "terminal.fill",
                                "safari.fill", "folder.fill", "chevron.left.forwardslash.chevron.right",
                                "star.fill", "bolt.fill", "app.badge.fill"
                            ]

                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: { newShortcutIcon = icon }) {
                                    ZStack {
                                        Circle()
                                            .fill(newShortcutIcon == icon ? Color(red: 0.35, green: 0.75, blue: 1.0) : Color(white: 0.14))
                                            .frame(width: 18, height: 18)
                                        Image(systemName: icon)
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(newShortcutIcon == icon ? .black : .white)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            Spacer()

                            Button(action: { saveNewShortcut() }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus")
                                    Text("Add")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(red: 0.35, green: 0.75, blue: 1.0)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.70), radius: 24, y: 8)
            )
            .frame(width: 420)
        }
    }

    // MARK: ── 4. Quick Notes (Scrollable List with (+) Add Button & Delete) ──

    private var quickNotesWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header: "Notes" + Count + (+) Add Note Button
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.84, blue: 0.38))
                    Text("Notes")
                        .font(.system(size: 13, weight: .heavy, design: .default))
                        .foregroundColor(.white)
                    if !notesModel.notes.isEmpty {
                        Text("(\(notesModel.notes.count))")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white.opacity(0.60))
                    }
                }

                Spacer()

                // (+) ADD BUTTON
                Button(action: {
                    noteDraftText = ""
                    editingNote = nil
                    isCreatingNewNote = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.16))
                            .frame(width: 22, height: 22)
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .help("Add New Note")
            }

            // Scrollable List of Notes
            if notesModel.notes.isEmpty {
                Button(action: {
                    noteDraftText = ""
                    editingNote = nil
                    isCreatingNewNote = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 13))
                        Text("No notes • Tap + to write")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.60))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 3.5) {
                        ForEach(notesModel.notes) { note in
                            HStack(spacing: 6) {
                                // Green accent indicator bar
                                Capsule()
                                    .fill(Color(red: 0.18, green: 0.84, blue: 0.38))
                                    .frame(width: 3, height: 16)

                                // Note preview text (Clickable -> Pop-up)
                                Button(action: {
                                    editingNote = note
                                    noteDraftText = note.content
                                    isCreatingNewNote = false
                                }) {
                                    Text(note.content)
                                        .font(.system(size: 11, weight: .bold, design: .default))
                                        .foregroundColor(.white.opacity(0.95))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Time ago
                                Text(note.updatedAt.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 8.5, weight: .bold))
                                    .foregroundColor(.white.opacity(0.45))

                                // Delete button for each note
                                Button(action: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        notesModel.delete(note)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 9.5))
                                        .foregroundColor(.red.opacity(0.85))
                                        .padding(2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Delete note")
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                                    )
                            )
                        }
                    }
                }
                .frame(maxHeight: 74)
            }

            Spacer(minLength: 0)

            // Green underline status indicator
            Rectangle()
                .fill(Color(red: 0.18, green: 0.84, blue: 0.38))
                .frame(width: 28, height: 2.5)
                .cornerRadius(1.5)
        }
        .padding(.horizontal, 4)
    }

    // MARK: ── 5. Note Pop-Up Editor Modal ─────────────────────────────────────

    private var noteEditorPopup: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.65)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isCreatingNewNote = false
                    editingNote = nil
                }

            // Glass popup modal
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: isCreatingNewNote ? "note.text.badge.plus" : "note.text")
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.3))
                        Text(isCreatingNewNote ? "New Note" : "Edit Note")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Copy to clipboard button
                    if !noteDraftText.isEmpty {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(noteDraftText, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Copy note text")
                    }

                    // Delete button if editing
                    if let note = editingNote {
                        Button(action: {
                            notesModel.delete(note)
                            editingNote = nil
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red.opacity(0.85))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Delete note")
                    }

                    // Close (X)
                    Button(action: {
                        isCreatingNewNote = false
                        editingNote = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Text Editor
                TextField("Write your thought here...", text: $noteDraftText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.08)))
                    .onSubmit { savePopupNote() }

                // Bottom save bar
                HStack {
                    Text("Press Enter or tap Save")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.50))

                    Spacer()

                    Button(action: { savePopupNote() }) {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9.5, weight: .bold))
                            Text("Save")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4.5)
                        .background(Capsule().fill(Color(red: 0.18, green: 0.84, blue: 0.38)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(14)
            .frame(width: 310)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.12).opacity(0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 12, y: 4)
            )
        }
    }

    private func savePopupNote() {
        let trimmed = noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            if let note = editingNote {
                var updated = note
                updated.content = trimmed
                notesModel.update(updated)
            } else {
                notesModel.add(Note(content: trimmed))
            }
        }
        noteDraftText = ""
        isCreatingNewNote = false
        editingNote = nil
    }

    // MARK: ── 6. Clipboard Widget (Live History & 1-Tap Copy) ─────────────────

    private var clipboardWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header: "Clipboard" + Count + Trash Clear All
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0))
                    Text("Clipboard")
                        .font(.system(size: 13, weight: .heavy, design: .default))
                        .foregroundColor(.white)
                    if !clipboardManager.filteredItems.isEmpty {
                        Text("(\(clipboardManager.filteredItems.count))")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white.opacity(0.60))
                    }
                }

                Spacer()

                // Clear History Trash Button
                if !clipboardManager.filteredItems.isEmpty {
                    Button(action: {
                        withAnimation { clipboardManager.clearUnpinned() }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 9.5))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Clear Clipboard History")
                }
            }

            // Scrollable List of Copied Items
            if clipboardManager.filteredItems.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "tray")
                        .font(.system(size: 12))
                    Text("Empty • Copy to see here")
                        .font(.system(size: 9.5, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 3.5) {
                        ForEach(clipboardManager.filteredItems.prefix(5)) { item in
                            HStack(spacing: 5) {
                                // Blue accent indicator pill
                                Capsule()
                                    .fill(Color(red: 0.35, green: 0.65, blue: 1.0))
                                    .frame(width: 3, height: 16)

                                // Copied snippet text (1-Tap Copy)
                                Button(action: {
                                    clipboardManager.copy(item)
                                    copiedItemId = item.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        if copiedItemId == item.id { copiedItemId = nil }
                                    }
                                }) {
                                    Text(item.text ?? "Image Copied")
                                        .font(.system(size: 11, weight: .bold, design: .default))
                                        .foregroundColor(copiedItemId == item.id ? Color(red: 0.18, green: 0.84, blue: 0.38) : .white.opacity(0.95))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())

                                // 1-Tap Copy Icon / Green Checkmark
                                Button(action: {
                                    clipboardManager.copy(item)
                                    copiedItemId = item.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        if copiedItemId == item.id { copiedItemId = nil }
                                    }
                                }) {
                                    Image(systemName: copiedItemId == item.id ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundColor(copiedItemId == item.id ? Color(red: 0.18, green: 0.84, blue: 0.38) : .white.opacity(0.70))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Copy to clipboard")
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                                    )
                            )
                        }
                    }
                }
                .frame(maxHeight: 74)
            }

            Spacer(minLength: 0)

            // Blue underline status indicator
            Rectangle()
                .fill(Color(red: 0.35, green: 0.65, blue: 1.0))
                .frame(width: 28, height: 2.5)
                .cornerRadius(1.5)
        }
        .padding(.horizontal, 4)
    }

    // MARK: ── 7. Pomodoro ────────────────────────────────────────────────────

    private var pomodoroColor: Color {
        timerManager.pomodoroPhase == .work ? Color(red: 0.18, green: 0.84, blue: 0.38) : Color(red: 0.35, green: 0.75, blue: 1.0)
    }

    private var pomodoroWidget: some View {
        VStack(alignment: .center, spacing: 3) {
            // Phase pill: 🌱 Rest (1/1)
            HStack(spacing: 4) {
                Image(systemName: timerManager.pomodoroPhase == .work ? "target" : "leaf.fill")
                    .font(.system(size: 8.5, weight: .heavy))
                Text(timerManager.pomodoroPhase == .work ? "Focus (1/4)" : "Rest (1/1)")
                    .font(.system(size: 10, weight: .heavy, design: .default))
            }
            .foregroundColor(pomodoroColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(
                Capsule()
                    .fill(pomodoroColor.opacity(0.18))
                    .overlay(
                        Capsule().stroke(pomodoroColor.opacity(0.40), lineWidth: 0.8)
                    )
            )

            // Large monospaced timer digits (Very Bold)
            Text(timerManager.pomodoroString)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.8)

            // Green progress underline bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.10)).frame(height: 2.5)
                    Capsule()
                        .fill(Color(red: 0.18, green: 0.84, blue: 0.38))
                        .frame(width: geo.size.width * CGFloat(timerManager.pomodoroProgress), height: 2.5)
                }
            }
            .frame(height: 2.5)
            .padding(.horizontal, 4)

            // Controls: reset, play/pause, skip in circular button cards
            HStack(spacing: 12) {
                Button(action: { timerManager.resetPomodoro() }) {
                    Circle()
                        .fill(Color(white: 0.14))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.75))
                        )
                }
                .buttonStyle(PlainButtonStyle()).help("Reset")

                Button(action: { timerManager.togglePomodoro() }) {
                    Circle()
                        .fill(Color(white: 0.14))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: timerManager.pomodoroRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(PlainButtonStyle()).help("Start / Pause")

                Button(action: { timerManager.skipPomodoroPhase() }) {
                    Circle()
                        .fill(Color(white: 0.14))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.75))
                        )
                }
                .buttonStyle(PlainButtonStyle()).help("Skip Phase")
            }
        }
        .padding(.horizontal, 3)
    }

    // MARK: ── 8. Camera / Mirror (Large 68x68 Frame) ──────────────────────────

    private var mirrorWidget: some View {
        Button(action: {
            vm.toggleCameraPreview()
        }) {
            ZStack(alignment: .topTrailing) {
                CameraPreviewView(webcamManager: vm.webcamManager)
                    .frame(width: 86, height: 86)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                vm.webcamManager.isSessionRunning ? Color.white.opacity(0.35) : Color.white.opacity(0.12),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(
                        color: vm.webcamManager.isSessionRunning ? Color.black.opacity(0.45) : Color.clear,
                        radius: 6,
                        y: 2
                    )

                if vm.webcamManager.isSessionRunning {
                    // Live green pill
                    HStack(spacing: 2.5) {
                        Circle().fill(Color.green).frame(width: 5, height: 5)
                        Text("LIVE")
                            .font(.system(size: 6.5, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .offset(x: -4, y: 4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .help("Toggle Live Camera / Mirror")
    }

    // MARK: ── Helpers ────────────────────────────────────────────────────────

    private func formatTime(_ seconds: Double) -> String {
        let t = Int(max(seconds, 0))
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    private struct DayInfo { let weekday: String; let day: Int; let isToday: Bool }

    private func surroundingDays() -> [DayInfo] {
        let cal = Calendar.current
        let today = Date()
        return (-1...1).compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: today) else { return nil }
            let f = DateFormatter(); f.dateFormat = "EEE"
            return DayInfo(weekday: f.string(from: d), day: cal.component(.day, from: d), isToday: offset == 0)
        }
    }
}
