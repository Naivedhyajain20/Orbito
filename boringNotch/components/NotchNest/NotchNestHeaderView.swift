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
    case systemMonitor
    case bookmarks
    case game
    case clipboard
    case tray
}

struct NotchNestHeaderView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @Binding var currentMode: NotchNestMode
    @State private var showPremiumSheet: Bool = false
    @Default(.showBatteryIndicator) var showBatteryIndicator

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
                // Clipboard
                navIconButton(icon: "doc.on.clipboard.fill", active: currentMode == .clipboard, tooltip: "Clipboard") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        currentMode = currentMode == .clipboard ? .home : .clipboard
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
    private func sysButton(icon: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color(white: 0.13).opacity(0.88))
                .frame(width: 29, height: 29)
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.7))
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.88))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }
}
