//
//  ProductivitySettings.swift
//  boringNotch
//
//  Created by Claude on 05/09/2026.
//

import SwiftUI
import Defaults

struct ProductivitySettings: View {
    @Default(.showNotes) var showNotes
    @Default(.showTimers) var showTimers
    @Default(.showCalculator) var showCalculator
    @Default(.showClipboard) var showClipboard
    @Default(.showSystemMonitor) var showSystemMonitor
    @Default(.showAIActions) var showAIActions

    @ObservedObject var focusManager = FocusModeManager.shared
    @ObservedObject var aiManager = AIActionManager.shared

    @State private var selectedFocusDuration: Double = 25

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Productivity Tools")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Enable or disable productivity features in the notch")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }

            // MARK: - Quick Tools
            Section(header: Text("Quick Tools")) {
                Toggle("Quick Notes", isOn: $showNotes)
                Text("Instantly jot down notes, pin important ones, and copy to clipboard")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Timers & Stopwatch", isOn: $showTimers)
                Text("Multiple countdown timers with notifications, stopwatch with lap times, and Pomodoro")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Calculator", isOn: $showCalculator)
                Text("Quick calculations with expression support, unit converter (kg→lb, km→miles, etc.) and history")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Clipboard Manager", isOn: $showClipboard)
                Text("Access recent clipboard history with text, images and smart detection")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: - Optional Tools
            Section(header: Text("Optional Tools")) {
                Toggle("System Monitor", isOn: $showSystemMonitor)
                Text("CPU, RAM, Wi-Fi signal and network speed with sparkline graphs")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("AI Quick Actions", isOn: $showAIActions)
                Text("Summarize, rewrite, translate and fix grammar on selected text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: - Focus Mode
            Section(header: Text("Focus Mode")) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus Mode")
                        Text(focusManager.isFocusActive ? "Active — \(focusManager.remainingTime) remaining" : "Inactive")
                            .font(.caption)
                            .foregroundColor(focusManager.isFocusActive ? .green : .secondary)
                    }
                    Spacer()
                    Button(focusManager.isFocusActive ? "Stop" : "Start") {
                        focusManager.toggleFocus(duration: selectedFocusDuration * 60)
                    }
                    .foregroundColor(focusManager.isFocusActive ? .red : .accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus Duration: \(Int(selectedFocusDuration)) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $selectedFocusDuration, in: 5...120, step: 5)
                        .onAppear {
                            selectedFocusDuration = focusManager.focusDuration / 60
                        }
                        .onChange(of: selectedFocusDuration) { _, val in
                            focusManager.focusDuration = val * 60
                        }
                }
            }

            // MARK: - AI Settings
            if showAIActions {
                Section(header: Text("AI Quick Actions Settings")) {
                    Picker("Provider", selection: $aiManager.provider) {
                        ForEach(AIProvider.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(aiManager.provider.rawValue) API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Paste your API key here", text: $aiManager.apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Without an API key, only Bullet Points and Formal Tone work on-device.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.blue)
                    Text("Use keyboard shortcuts (⌘ + Shift + T/C/K…) to quickly access these features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    ProductivitySettings()
        .frame(width: 500)
}
