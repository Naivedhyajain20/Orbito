//
//  MacNotchRootView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Defaults

struct MacNotchRootView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @State private var selectedModule: MacNotchModule = .dashboard
    let albumArtNamespace: Namespace.ID

    var body: some View {
        VStack(spacing: 8) {
            // Top Bar
            MacNotchHeaderView(selectedModule: $selectedModule)
                .padding(.top, 2)

            // Content Area / Active Module
            Group {
                if vm.dragDetectorTargeting || vm.generalDropTargeting {
                    MacNotchDropActionsView()
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                } else {
                    switch selectedModule {
                    case .dashboard:
                        MacNotchDashboardView()
                    case .media:
                        MacNotchMediaView()
                    case .calendar:
                        CalendarView()
                            .padding(.horizontal, 8)
                    case .todo:
                        MacNotchTodoView()
                    case .notes:
                        NotesView()
                    case .pomodoro:
                        TimersView()
                    case .dayProgress:
                        MacNotchDayProgressView()
                    case .screenTime:
                        MacNotchScreenTimeView()
                    case .health:
                        MacNotchHealthView()
                    case .weather:
                        MacNotchWeatherView()
                    case .notifications:
                        ClipboardView()
                    case .aiCoding:
                        MacNotchAICodingView()
                    case .shelf:
                        ShelfView()
                    case .snapZones:
                        MacNotchSnapZonesView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: selectedModule)

            // Bottom Floating Dock Pill
            MacNotchDockView(selectedModule: $selectedModule)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
