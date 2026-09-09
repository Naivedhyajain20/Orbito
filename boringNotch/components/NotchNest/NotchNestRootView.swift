import SwiftUI
import Defaults

struct NotchNestRootView: View {
    @EnvironmentObject var vm: BoringViewModel
    @State private var currentMode: NotchNestMode = .home
    let albumArtNamespace: Namespace.ID

    var body: some View {
        VStack(spacing: 0) {
            NotchNestHeaderView(currentMode: $currentMode)

            Group {
                switch currentMode {
                case .home:
                    NotchNestWidgetsView()
                        .transition(.opacity)
                case .systemMonitor:
                    NotchNestSystemModalView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .bookmarks:
                    NotchNestBookmarksModalView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .game:
                    NotchNestGameView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .clipboard:
                    NotchNestClipboardModalView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .tray:
                    NotchNestFileTrayModalView()
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: currentMode)
        }
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: currentMode) { _, _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                vm.notchSize = CGSize(
                    width: openNotchSize.width,
                    height: CGFloat(Defaults[.customOpenHeight])
                )
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
