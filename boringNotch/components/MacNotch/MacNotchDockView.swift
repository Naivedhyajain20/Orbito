//
//  MacNotchDockView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Defaults

enum MacNotchModule: String, CaseIterable, Identifiable {
    case dashboard      = "Dashboard"
    case media          = "Media"
    case calendar       = "Calendar"
    case todo           = "Todo"
    case notes          = "Notes"
    case pomodoro       = "Pomodoro"
    case dayProgress    = "Day Progress"
    case screenTime     = "Screen Time"
    case health         = "Health"
    case weather        = "Weather"
    case notifications  = "Notifications"
    case aiCoding       = "AI Coding"
    case shelf          = "Shelf"
    case snapZones      = "Snap Window"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .media: return "music.note"
        case .calendar: return "calendar"
        case .todo: return "checkmark.circle.fill"
        case .notes: return "note.text"
        case .pomodoro: return "timer"
        case .dayProgress: return "hourglass"
        case .screenTime: return "chart.bar.fill"
        case .health: return "heart.fill"
        case .weather: return "cloud.sun.fill"
        case .notifications: return "bell.fill"
        case .aiCoding: return "chevron.left.forwardslash.chevron.right"
        case .shelf: return "tray.fill"
        case .snapZones: return "rectangle.split.2x1.fill"
        }
    }
}

struct MacNotchDockView: View {
    @Binding var selectedModule: MacNotchModule
    @State private var hoveredModule: MacNotchModule? = nil

    var body: some View {
        HStack(spacing: 3) {
            ForEach(MacNotchModule.allCases) { module in
                Button(action: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        selectedModule = module
                    }
                }) {
                    ZStack {
                        if selectedModule == module {
                            Circle()
                                .fill(Color.white.opacity(0.24))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                                )
                        } else if hoveredModule == module {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 24, height: 24)
                        }

                        Image(systemName: module.icon)
                            .font(.system(size: 12, weight: selectedModule == module ? .bold : .medium))
                            .foregroundColor(selectedModule == module ? .white : .white.opacity(0.65))
                    }
                    .frame(width: 28, height: 28)
                    .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        hoveredModule = isHovered ? module : nil
                    }
                }
                .help(module.rawValue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color(white: 0.11).opacity(0.92))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.24), Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.5), radius: 10, y: 4)
    }
}
