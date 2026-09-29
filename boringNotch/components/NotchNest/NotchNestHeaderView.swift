//
//  NotchNestHeaderView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Defaults

enum NotchNestMode: String, CaseIterable {
    case home
    case timer
    case clipboard
    case tray
    case systemMonitor
    case bookmarks
    case game
    case coding
}

struct NotchNestHeaderView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var brightnessManager = BrightnessManager.shared
    @ObservedObject var volumeManager = VolumeManager.shared
    @Binding var currentMode: NotchNestMode
    @State private var showPremiumSheet: Bool = false
    @State private var showDisplayControls: Bool = false
    @Default(.showBatteryIndicator) var showBatteryIndicator
    @Default(.showCodingActivityInNotch) var showCodingActivityInNotch

    private var isPhysicalNotch: Bool {
        (NSScreen.screen(withUUID: coordinator.selectedScreenUUID)?.safeAreaInsets.top ?? 0) > 0
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── LEFT EAR: Nav icons + Explore Premium pill ──────────────────
            HStack(spacing: 4) {
                // Home
                navIconButton(icon: "house.fill", active: currentMode == .home, tooltip: "Home") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { currentMode = .home }
                }
                // Ruler Timer
                navIconButton(icon: "timer", active: currentMode == .timer, tooltip: "Ruler Timer") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        currentMode = currentMode == .timer ? .home : .timer
                    }
                }
                // Clipboard
                navIconButton(icon: "doc.on.clipboard.fill", active: currentMode == .clipboard, tooltip: "Clipboard") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        currentMode = currentMode == .clipboard ? .home : .clipboard
                    }
                }
                // Disk Utility & Performance Monitor
                navIconButton(icon: "gauge.with.needle.fill", active: currentMode == .systemMonitor, tooltip: "Disk Utility & Performance (CPU, RAM, GPU, Disk)") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        currentMode = currentMode == .systemMonitor ? .home : .systemMonitor
                    }
                }
                // File Tray
                navIconButton(icon: "tray.fill", active: currentMode == .tray, tooltip: "File Tray") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        currentMode = currentMode == .tray ? .home : .tray
                    }
                }
                // Games
                navIconButton(icon: "gamecontroller.fill", active: currentMode == .game, tooltip: "Infinity Run") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        currentMode = currentMode == .game ? .home : .game
                    }
                }
                // Developer / Coding Activity (GitHub & LeetCode)
                if showCodingActivityInNotch {
                    navIconButton(icon: "chevron.left.forwardslash.chevron.right", active: currentMode == .coding, tooltip: "Coding Activity (GitHub & LeetCode)") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                            currentMode = currentMode == .coding ? .home : .coding
                        }
                    }
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, isPhysicalNotch ? 10 : 6)

            // ── CENTER: Hardware Notch black clearance ───────────────────────
            if isPhysicalNotch {
                Rectangle()
                    .fill(Color.black)
                    .frame(
                        width: vm.closedNotchSize.width + 18,
                        height: max(30, vm.effectiveClosedNotchHeight)
                    )
                    .mask {
                        NotchShape(topCornerRadius: 6, bottomCornerRadius: 16)
                    }
            } else {
                Spacer()
            }

            // ── RIGHT EAR: Orbito Brand, Battery, Settings, Close ─────────────────────────
            HStack(spacing: 6) {
                // Orbito Brand Badge before Battery
                HStack(spacing: 4.5) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .shadow(color: Color(red: 0.5, green: 0.6, blue: 1.0).opacity(0.45), radius: 2.5)

                    Text("Orbito")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.88, green: 0.90, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.6, green: 0.7, blue: 1.0).opacity(0.35), radius: 2.5, x: 0, y: 0)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(
                    Capsule()
                        .fill(Color(white: 0.12).opacity(0.85))
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.22),
                                            Color.white.opacity(0.06)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.8
                                )
                        )
                )

                // Battery capsule: charging bolt + percentage
                if showBatteryIndicator {
                    HStack(spacing: 3) {
                        Image(systemName: batteryModel.isCharging ? "battery.100.bolt" : batteryIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(batteryColor)

                        Text("\(Int(batteryModel.levelBattery))%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color(white: 0.13).opacity(0.88))
                            .overlay(
                                Capsule().stroke(batteryColor.opacity(0.35), lineWidth: 0.8)
                            )
                    )
                }

                // Display & Audio Controls
                sysButton(icon: "sun.max.fill", active: showDisplayControls, tooltip: "Display & Volume") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        showDisplayControls.toggle()
                    }
                }

                // Settings gear
                sysButton(icon: "gearshape.fill", tooltip: "Settings") {
                    DispatchQueue.main.async { SettingsWindowController.shared.showWindow() }
                }

                // Close X
                sysButton(icon: "xmark", tooltip: "Close") {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) { vm.close() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, isPhysicalNotch ? 10 : 6)
        }
        .frame(height: max(32, vm.effectiveClosedNotchHeight))
        .padding(.top, isPhysicalNotch ? 3 : 1)
        .overlay(alignment: .topTrailing) {
            if showDisplayControls {
                ZStack(alignment: .topTrailing) {
                    // Full dismiss background
                    Color.black.opacity(0.40)
                        .frame(width: 2500, height: 1600)
                        .offset(x: 600, y: 300)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                showDisplayControls = false
                            }
                        }

                    displayControlsCard
                        .padding(.top, max(36, vm.effectiveClosedNotchHeight + 4))
                        .padding(.trailing, 10)
                }
                .transition(.scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
                .zIndex(300)
            }
        }
    }

    // MARK: - Helpers

    private var batteryIcon: String {
        if batteryModel.levelBattery < 20 { return "battery.25" }
        if batteryModel.levelBattery < 50 { return "battery.50" }
        return "battery.100"
    }

    private var batteryColor: Color {
        if batteryModel.isCharging { return Color(red: 0.2, green: 0.85, blue: 0.38) }
        if batteryModel.levelBattery < 20 { return .red }
        return .white.opacity(0.85)
    }

    /// Small circular nav icon on the left
    private func navIconButton(icon: String, active: Bool, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if active {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 29, height: 29)
                        .overlay(Circle().stroke(Color.white.opacity(0.32), lineWidth: 0.7))
                }
                Image(systemName: icon)
                    .font(.system(size: 12.5, weight: active ? .bold : .semibold))
                    .foregroundColor(active ? .white : .white.opacity(0.72))
            }
            .frame(width: 29, height: 29)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }

    /// Small circular system button on the right
    private func sysButton(icon: String, active: Bool = false, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(active ? Color.blue.opacity(0.35) : Color(white: 0.13).opacity(0.88))
                .frame(width: 29, height: 29)
                .overlay(Circle().stroke(active ? Color.blue : Color.white.opacity(0.12), lineWidth: active ? 1.2 : 0.7))
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(active ? .white : .white.opacity(0.88))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }

    private var displayControlsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Display & Sound")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        showDisplayControls = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Divider().background(Color.white.opacity(0.10))

            // Brightness Row
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("Brightness")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                    Text("\(Int(brightnessManager.rawBrightness * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }

                Slider(value: Binding(
                    get: { Double(brightnessManager.rawBrightness) },
                    set: { brightnessManager.setAbsolute(value: Float($0)) }
                ), in: 0...1)
                .accentColor(.yellow)
            }

            // Volume Row
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: volumeManager.rawVolume == 0 || volumeManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0))
                        Text("Volume")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                    Text("\(Int(volumeManager.rawVolume * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }

                Slider(value: Binding(
                    get: { Double(volumeManager.rawVolume) },
                    set: { volumeManager.setAbsolute(Float32($0)) }
                ), in: 0...1)
                .accentColor(Color(red: 0.35, green: 0.65, blue: 1.0))
            }
        }
        .padding(12)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.85), radius: 24, y: 10)
        )
    }
}
