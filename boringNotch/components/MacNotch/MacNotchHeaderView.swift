//
//  MacNotchHeaderView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Defaults

struct MacNotchHeaderView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @Binding var selectedModule: MacNotchModule
    @State private var currentProfile: String = "Work"

    private var isPhysicalNotch: Bool {
        (NSScreen.screen(withUUID: coordinator.selectedScreenUUID)?.safeAreaInsets.top ?? 0) > 0
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Breadcrumb Pill: e.g. "Dashboard > Work >"
            HStack(spacing: 5) {
                Image(systemName: selectedModule.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)

                Text(selectedModule.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))

                Text(currentProfile)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(white: 0.14).opacity(0.92))
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.8
                            )
                    )
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, isPhysicalNotch ? 8 : 4)

            // Center Notch Clearance
            if isPhysicalNotch {
                Rectangle()
                    .fill(Color.black)
                    .frame(
                        width: vm.closedNotchSize.width + 16,
                        height: max(30, vm.effectiveClosedNotchHeight)
                    )
                    .mask {
                        NotchShape(
                            topCornerRadius: 6,
                            bottomCornerRadius: 16
                        )
                    }
            } else {
                Spacer()
            }

            // Right Quick Actions & Profiles
            HStack(spacing: 6) {
                // Profile Switcher Menu
                Menu {
                    Button("Work") { currentProfile = "Work" }
                    Button("Personal") { currentProfile = "Personal" }
                    Button("Focus") { currentProfile = "Focus" }
                    Button("Developer") { currentProfile = "Developer" }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 11))
                        Text(currentProfile)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(white: 0.14).opacity(0.92))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                            )
                    )
                    .foregroundColor(.white.opacity(0.9))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)

                // Window Snap Button
                headerButton(icon: "rectangle.split.2x1.fill", active: selectedModule == .snapZones, tooltip: "Snap Windows") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        selectedModule = .snapZones
                    }
                }

                // Camera Mirror Button
                headerButton(icon: "web.camera", active: vm.isCameraExpanded, tooltip: "Toggle Camera Mirror") {
                    vm.toggleCameraPreview()
                }

                // Settings Button
                headerButton(icon: "gearshape.fill", active: false, tooltip: "Orbito Settings") {
                    DispatchQueue.main.async {
                        SettingsWindowController.shared.showWindow()
                    }
                }

                // Battery Pill
                BoringBatteryView(
                    batteryWidth: 28,
                    isCharging: batteryModel.isCharging,
                    isInLowPowerMode: batteryModel.isInLowPowerMode,
                    isPluggedIn: batteryModel.isPluggedIn,
                    levelBattery: batteryModel.levelBattery,
                    maxCapacity: batteryModel.maxCapacity,
                    timeToFullCharge: batteryModel.timeToFullCharge,
                    isForNotification: false
                )
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, isPhysicalNotch ? 8 : 4)
        }
        .frame(height: max(34, vm.effectiveClosedNotchHeight))
        .padding(.top, isPhysicalNotch ? 4 : 2)
    }

    private func headerButton(icon: String, active: Bool, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(active ? Color.white.opacity(0.25) : Color(white: 0.14).opacity(0.92))
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(active ? Color.white.opacity(0.4) : Color.white.opacity(0.12), lineWidth: 0.8)
                )
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(active ? .white : .white.opacity(0.85))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }
}
