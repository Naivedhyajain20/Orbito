//
//  MacNotchDropActionsView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Defaults

struct MacNotchDropActionsView: View {
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @EnvironmentObject var vm: BoringViewModel
    @State private var hoveredTarget: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Text("Drop to act")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            HStack(spacing: 12) {
                dropTarget(title: "Shelf", subtitle: "Store files", icon: "tray.fill", id: "shelf") {
                    coordinator.currentView = .shelf
                }

                dropTarget(title: "iCloud", subtitle: "Save to Drive", icon: "icloud.fill", id: "icloud") {
                    // Open iCloud Drive
                    if let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
                        NSWorkspace.shared.open(url)
                    }
                }

                dropTarget(title: "AirDrop", subtitle: "Send nearby", icon: "arrow.up.circle.fill", id: "airdrop") {
                    // Trigger AirDrop sharing
                }

                dropTarget(title: "Open with", subtitle: "Smart app", icon: "macwindow", id: "openWith") {
                }

                dropTarget(title: "Expand", subtitle: "Show second row", icon: "arrow.up.left.and.arrow.down.right", id: "expand") {
                    withAnimation {
                        vm.open()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.08).opacity(0.95))
        )
    }

    private func dropTarget(title: String, subtitle: String, icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(hoveredTarget == id ? Color.white.opacity(0.25) : Color(white: 0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(hoveredTarget == id ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredTarget = isHovered ? id : nil
            }
        }
    }
}
