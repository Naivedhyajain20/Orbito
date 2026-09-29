import SwiftUI
import Defaults

struct NotchNestRootView: View {
    @EnvironmentObject var vm: BoringViewModel
    @State private var currentMode: NotchNestMode = .home
    let albumArtNamespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            NotchNestHeaderView(currentMode: $currentMode)
                .zIndex(200)

            Group {
                switch currentMode {
                case .home:
                    NotchNestWidgetsView(currentMode: $currentMode)
                        .transition(.opacity)
                case .timer:
                    QuickTimerRulerView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .clipboard:
                    ClipboardView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .systemMonitor:
                    NotchNestSystemModalView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .bookmarks:
                    NotchNestBookmarksModalView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .game:
                    NotchNestGameView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .tray:
                    NotchNestFileTrayModalView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .coding:
                    NotchNestCodingModalView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: currentMode)
        }
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: currentMode) { _, newMode in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                let targetWidth: CGFloat
                let targetHeight: CGFloat
                switch newMode {
                case .home:
                    targetWidth = openNotchSize.width
                    targetHeight = CGFloat(Defaults[.customOpenHeight])
                case .timer:
                    targetWidth = max(openNotchSize.width, 500)
                    targetHeight = 168
                case .clipboard:
                    targetWidth = max(openNotchSize.width, 680)
                    targetHeight = 220
                case .systemMonitor, .tray, .game, .coding, .bookmarks:
                    targetWidth = openNotchSize.width
                    targetHeight = CGFloat(Defaults[.customOpenHeight])
                }
                vm.notchSize = CGSize(width: targetWidth, height: targetHeight)
            }
        }
        .onChange(of: vm.anyDropZoneTargeting) { _, isTargeted in
            if isTargeted {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    currentMode = .tray
                }
            }
        }
        .onChange(of: vm.dragDetectorTargeting) { _, isTargeted in
            if isTargeted {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    currentMode = .tray
                }
            }
        }
    }
}
