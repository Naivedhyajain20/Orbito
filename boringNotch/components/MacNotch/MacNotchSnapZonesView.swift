//
//  MacNotchSnapZonesView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

enum WindowSnapTarget: String, CaseIterable, Identifiable {
    case leftHalf      = "Left Half"
    case rightHalf     = "Right Half"
    case topHalf       = "Top Half"
    case bottomHalf    = "Bottom Half"
    case topLeft       = "Top Left"
    case topRight      = "Top Right"
    case bottomLeft    = "Bottom Left"
    case bottomRight   = "Bottom Right"
    case leftThird     = "Left 1/3"
    case centerThird   = "Center 1/3"
    case rightThird    = "Right 1/3"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .topLeft: return "rectangle.inset.topleft.filled"
        case .topRight: return "rectangle.inset.topright.filled"
        case .bottomLeft: return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .leftThird: return "rectangle.split.3x1"
        case .centerThird: return "rectangle.split.3x1.fill"
        case .rightThird: return "rectangle.split.3x1"
        }
    }
}

struct MacNotchSnapZonesView: View {
    @State private var hoveredTarget: WindowSnapTarget? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Text("Snap Window")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Halves, quarters & thirds")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            HStack(spacing: 8) {
                ForEach(WindowSnapTarget.allCases) { target in
                    Button(action: {
                        snapActiveWindow(to: target)
                    }) {
                        VStack(spacing: 3) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(hoveredTarget == target ? Color.white.opacity(0.3) : Color(white: 0.16))
                                    .frame(width: 32, height: 32)

                                Image(systemName: target.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }

                            Text(target.rawValue)
                                .font(.system(size: 7))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredTarget = isHovered ? target : nil
                        }
                    }
                    .help(target.rawValue)
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

    private func snapActiveWindow(to target: WindowSnapTarget) {
        // macOS AppleScript window snap action
        let script: String
        switch target {
        case .leftHalf:
            script = "tell application \"System Events\" to tell (first process whose frontmost is true) to set position of window 1 to {0, 25}"
        case .rightHalf:
            script = "tell application \"System Events\" to tell (first process whose frontmost is true) to set position of window 1 to {720, 25}"
        default:
            script = ""
        }
        if !script.isEmpty, let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
