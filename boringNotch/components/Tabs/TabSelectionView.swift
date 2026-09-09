//
//  TabSelectionView.swift
//  boringNotch
//
//  Created by Hugo Persson on 2024-08-25.
//

import SwiftUI
import Defaults

struct TabModel: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let view: NotchViews
}

func availableTabs() -> [TabModel] {
    var tabs = [
        TabModel(label: "Home", icon: "house.fill", view: .home),
        TabModel(label: "Shelf", icon: "tray.fill", view: .shelf)
    ]

    if Defaults[.showNotes] {
        tabs.append(TabModel(label: "Notes", icon: "note.text", view: .notes))
    }
    if Defaults[.showTimers] {
        tabs.append(TabModel(label: "Timers", icon: "timer", view: .timers))
    }
    if Defaults[.showCalculator] {
        tabs.append(TabModel(label: "Calc", icon: "function", view: .calculator))
    }
    if Defaults[.showClipboard] {
        tabs.append(TabModel(label: "Clipboard", icon: "clipboard", view: .clipboard))
    }
    if Defaults[.showSystemMonitor] {
        tabs.append(TabModel(label: "System", icon: "cpu", view: .systemInfo))
    }
    if Defaults[.showAIActions] {
        tabs.append(TabModel(label: "AI", icon: "wand.and.stars", view: .aiActions))
    }

    return tabs
}

struct TabSelectionView: View {
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @Namespace var animation

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(availableTabs()) { tab in
                    TabButton(label: tab.label, icon: tab.icon, selected: coordinator.currentView == tab.view) {
                        withAnimation(.smooth) {
                            coordinator.currentView = tab.view
                        }
                    }
                    .frame(height: 26)
                    .foregroundStyle(tab.view == coordinator.currentView ? .white : .gray)
                    .background {
                        if tab.view == coordinator.currentView {
                            Capsule()
                                .fill(coordinator.currentView == tab.view ? Color(nsColor: .secondarySystemFill) : Color.clear)
                                .matchedGeometryEffect(id: "capsule", in: animation)
                        } else {
                            Capsule()
                                .fill(coordinator.currentView == tab.view ? Color(nsColor: .secondarySystemFill) : Color.clear)
                                .matchedGeometryEffect(id: "capsule", in: animation)
                                .hidden()
                        }
                    }
                }
            }
        }
        .clipShape(Capsule())
    }
}

#Preview {
    BoringHeader().environmentObject(BoringViewModel())
}
