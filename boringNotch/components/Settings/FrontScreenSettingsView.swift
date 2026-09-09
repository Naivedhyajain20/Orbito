//
//  FrontScreenSettingsView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import Defaults
import SwiftUI

struct FrontScreenSettingsView: View {
    @Default(.frontWidgetMusic) var frontWidgetMusic
    @Default(.frontWidgetSystem) var frontWidgetSystem
    @Default(.frontWidgetCalendar) var frontWidgetCalendar
    @Default(.frontWidgetTimer) var frontWidgetTimer
    @Default(.frontWidgetClipboard) var frontWidgetClipboard
    @Default(.frontWidgetQuickNote) var frontWidgetQuickNote
    @Default(.notchTheme) var notchTheme
    @ObservedObject var modeManager = NotchModeManager.shared

    var body: some View {
        Form {
            Section {
                Text("Customize which widgets and modules appear when you open the Notch. Everything updates live with zero latency.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle(isOn: $frontWidgetMusic) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Music Player")
                            Text("Album artwork, scrubber, and playback controls")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "music.note")
                            .foregroundColor(.pink)
                    }
                }

                Toggle(isOn: $frontWidgetSystem) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Monitor")
                            Text("CPU & RAM circular micro-gauges + live network upload/download speeds")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "cpu")
                            .foregroundColor(.cyan)
                    }
                }

                Toggle(isOn: $frontWidgetCalendar) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Calendar Events")
                            Text("Next meeting and schedule directly in the notch")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.red)
                    }
                }

                Toggle(isOn: $frontWidgetTimer) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Timer & Quick Presets")
                            Text("Active countdown progress ring and 1-tap 5m/15m/25m timers")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                    }
                }

                Toggle(isOn: $frontWidgetClipboard) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recent Clipboard")
                            Text("Last copied text, URL, or image snippet with 1-tap copy")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(.blue)
                    }
                }

                Toggle(isOn: $frontWidgetQuickNote) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick Scratchpad Note")
                            Text("Instant 1-line note field on the front screen that syncs to Notes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.yellow)
                    }
                }
            } header: {
                Text("Front Screen Widgets")
            }

            Section {
                Picker("Theme Style", selection: $notchTheme) {
                    ForEach(NotchTheme.allCases) { theme in
                        Label(theme.rawValue, systemImage: theme.icon).tag(theme)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    switch notchTheme {
                    case .glass:
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.cyan)
                            Text("Apple Liquid Glass — Translucent frosted material with depth gradients and delicate rim highlight.")
                        }
                    case .darkBlack:
                        HStack(spacing: 6) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.black)
                            Text("Pure OLED Dark Black — 100% deep pitch-black background with zero translucent glow.")
                        }
                    case .darkSolid:
                        HStack(spacing: 6) {
                            Image(systemName: "square.fill")
                                .foregroundColor(.primary)
                            Text("Dark Solid — 100% pitch black to match the hardware notch bezel seamlessly.")
                        }
                    case .transparent:
                        HStack(spacing: 6) {
                            Image(systemName: "square.dashed")
                                .foregroundColor(.blue)
                            Text("Crystal Clear — High translucency floating HUD glass.")
                        }
                    case .minimal:
                        HStack(spacing: 6) {
                            Image(systemName: "squareshape")
                                .foregroundColor(.gray)
                            Text("Minimal Slate — Modern dark slate finish with high contrast.")
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

                Defaults.Toggle(key: .pureBlackBackground) {
                    Text("Always use Dark Black background")
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Open Notch Height")
                        Spacer()
                        Text("\(Int(Defaults[.customOpenHeight])) pt")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.secondary)
                        Button("Reset") {
                            Defaults[.customOpenHeight] = 240.0
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    Slider(
                        value: Binding(
                            get: { Defaults[.customOpenHeight] },
                            set: { Defaults[.customOpenHeight] = $0 }
                        ),
                        in: 190...340,
                        step: 5
                    )
                    Text("Adjust how tall the notch expands when opened to accommodate your favorite widgets.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            } header: {
                Text("Glass & Visual Appearance")
            }

            Section {
                Picker("Active Profile Mode", selection: $modeManager.currentMode) {
                    ForEach(NotchMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Text(modeManager.currentMode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Notch Mode Behavior")
            }
        }
        .formStyle(.grouped)
    }
}
