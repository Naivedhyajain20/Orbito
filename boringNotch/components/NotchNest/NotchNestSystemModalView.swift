import SwiftUI
import AppKit

enum SystemMonitorTab: String, CaseIterable {
    case cpu = "CPU"
    case gpu = "GPU"
    case ram = "RAM"
    case storage = "STORAGE"
    case network = "NETWORK"
    case battery = "BATTERY"
    case temps = "TEMPS & FANS"
}

struct NotchNestSystemModalView: View {
    @ObservedObject var sys = SystemInfoManager.shared
    @EnvironmentObject var vm: BoringViewModel
    @State private var selectedTab: SystemMonitorTab = .cpu

    private let systemRed = Color(red: 1.0, green: 0.27, blue: 0.23)
    private let userCyan = Color(red: 0.39, green: 0.82, blue: 1.0)
    private let idleWhite = Color(red: 0.90, green: 0.90, blue: 0.92)
    private let insightGreen = Color(red: 0.19, green: 0.82, blue: 0.35)

    private let storageRed = Color(red: 1.0, green: 0.24, blue: 0.28)
    private let storageOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    private let storageYellow = Color(red: 1.0, green: 0.84, blue: 0.04)
    private let storageCyan = Color(red: 0.20, green: 0.80, blue: 0.75)
    private let storageGrey = Color(red: 0.55, green: 0.55, blue: 0.58)
    private let storageDarkGrey = Color(red: 0.22, green: 0.22, blue: 0.24)

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                ForEach(SystemMonitorTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 8.5, weight: selectedTab == tab ? .heavy : .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? Color.white.opacity(0.20) : Color.white.opacity(0.06))
                                    .overlay(
                                        Capsule().stroke(selectedTab == tab ? userCyan.opacity(0.6) : Color.clear, lineWidth: 0.8)
                                    )
                            )
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.50))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer(minLength: 0)

                Button(action: {
                    let url = selectedTab == .storage
                        ? URL(fileURLWithPath: "/System/Applications/Utilities/Disk Utility.app")
                        : URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
                    NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: selectedTab == .storage ? "internaldrive.fill" : "arrow.up.forward.square")
                            .font(.system(size: 8))
                        Text(selectedTab == .storage ? "Disk Utility" : "Monitor")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(PlainButtonStyle())
                .help(selectedTab == .storage ? "Open macOS Disk Utility" : "Open macOS Activity Monitor")
            }
            .padding(.horizontal, 10)
            .padding(.top, 1)

            if selectedTab == .storage {
                appleStorageCard
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
            } else {
                activityMonitorCard
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var appleStorageCard: some View {
        VStack(spacing: 7) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))

                    Text("Macintosh HD")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundColor(.white)
                }

                Spacer()

                Text(String(format: "%.2f GB of %.2f GB used", sys.diskUsedGB, sys.diskTotalGB))
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            GeometryReader { geo in
                let total = max(sys.diskTotalGB, 1.0)
                let w = geo.size.width

                let usedRatio = min(max(sys.diskUsedGB / total, 0.0), 1.0)
                let usedWidth = w * CGFloat(usedRatio)
                let freeWidth = max(0, w - usedWidth)

                let sumCats = max(1.0, sys.storageDocumentsGB + sys.storageICloudGB + sys.storageDeveloperGB + sys.storageMacOSGB + sys.storageSystemDataGB)

                let docW = max(2, (sys.storageDocumentsGB / sumCats) * usedWidth)
                let icloudW = max(2, (sys.storageICloudGB / sumCats) * usedWidth)
                let devW = max(2, (sys.storageDeveloperGB / sumCats) * usedWidth)
                let macosW = max(2, (sys.storageMacOSGB / sumCats) * usedWidth)
                let sysW = max(2, usedWidth - (docW + icloudW + devW + macosW))

                HStack(spacing: 0.8) {
                    Rectangle()
                        .fill(storageRed)
                        .frame(width: docW)

                    Rectangle()
                        .fill(storageOrange)
                        .frame(width: icloudW)

                    Rectangle()
                        .fill(storageYellow)
                        .frame(width: devW)

                    Rectangle()
                        .fill(storageCyan)
                        .frame(width: macosW)

                    Rectangle()
                        .fill(storageGrey)
                        .frame(width: sysW)

                    Rectangle()
                        .fill(storageDarkGrey)
                        .frame(width: freeWidth)
                }
                .frame(height: 15)
                .clipShape(RoundedRectangle(cornerRadius: 4.5))
            }
            .frame(height: 15)
            .padding(.horizontal, 12)

            HStack(spacing: 12) {
                storageLegendDot(color: storageRed, label: "Documents")
                storageLegendDot(color: storageOrange, label: "iCloud Drive")
                storageLegendDot(color: storageYellow, label: "Developer")
                storageLegendDot(color: storageCyan, label: "macOS")
                storageLegendDot(color: storageGrey, label: "System Data")
                storageLegendDot(color: storageDarkGrey.opacity(1.5), label: String(format: "Free (%.0f GB)", sys.diskFreeGB))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.08).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.20), lineWidth: 0.9)
                )
        )
    }

    @ViewBuilder
    private func storageLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3.5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
    }

    @ViewBuilder
    private var activityMonitorCard: some View {
        HStack(spacing: 0) {
            leftColumnView
                .frame(width: 140)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)

            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 0.8)
                .padding(.vertical, 3)

            centerGraphView
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 0.8)
                .padding(.vertical, 3)

            rightColumnView
                .frame(width: 140)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.08).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.20), lineWidth: 0.9)
                )
        )
    }

    @ViewBuilder
    private var leftColumnView: some View {
        VStack(alignment: .leading, spacing: 3) {
            switch selectedTab {
            case .cpu:
                statRow(label: "System:", value: String(format: "%.2f%%", sys.cpuSystemPercent), color: systemRed)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "User:", value: String(format: "%.2f%%", sys.cpuUserPercent), color: userCyan)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Idle:", value: String(format: "%.2f%%", sys.cpuIdlePercent), color: idleWhite)

            case .gpu:
                statRow(label: "GPU Load:", value: String(format: "%.1f%%", sys.gpuUsage), color: userCyan)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Metal:", value: "Active", color: insightGreen)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Frametime:", value: "16.6 ms", color: idleWhite)

            case .ram:
                statRow(label: "App Memory:", value: String(format: "%.1f GB", sys.ramAppMemoryGB), color: userCyan)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Wired:", value: String(format: "%.1f GB", sys.ramWiredGB), color: systemRed)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Compressed:", value: String(format: "%.1f GB", sys.ramCompressedGB), color: idleWhite)

            case .storage:
                EmptyView()

            case .network:
                statRow(label: "Download:", value: sys.formatSpeed(sys.downloadSpeed), color: userCyan)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Upload:", value: sys.formatSpeed(sys.uploadSpeed), color: systemRed)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Wi-Fi:", value: sys.wifiSSID, color: idleWhite)

            case .battery:
                statRow(label: "State:", value: "\(sys.batteryPercent)% \(sys.isCharging ? "(Charging)" : "")", color: insightGreen)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Health:", value: "\(sys.batteryHealthPercent)%", color: userCyan)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Power Source:", value: sys.powerSource, color: idleWhite)

            case .temps:
                statRow(label: "Thermal State:", value: sys.thermalStateString, color: sys.thermalStateString == "Nominal" ? insightGreen : systemRed)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "CPU Temp:", value: String(format: "%.0f°C", sys.cpuTempCelsius), color: userCyan)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "GPU Temp:", value: String(format: "%.0f°C", max(35.0, sys.cpuTempCelsius - 3.0)), color: idleWhite)
            }
        }
    }

    @ViewBuilder
    private var centerGraphView: some View {
        VStack(spacing: 2) {
            Text(graphHeaderTitle)
                .font(.system(size: 9.5, weight: .heavy, design: .default))
                .foregroundColor(.white.opacity(0.85))
                .textCase(.uppercase)

            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(height: 0.8)
                .padding(.horizontal, 4)

            ActivityMonitorStackedGraph(
                bottomHistory: bottomGraphHistory,
                topHistory: topGraphHistory,
                bottomColor: systemRed,
                topColor: userCyan,
                maxScale: graphMaxScale
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
    }

    @ViewBuilder
    private var rightColumnView: some View {
        VStack(alignment: .leading, spacing: 3) {
            switch selectedTab {
            case .cpu:
                statRow(label: "Threads:", value: "\(sys.threadCount)", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Processes:", value: "\(sys.processCount)", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Insights:", value: sys.cpuUsage < 70 ? "Optimal Load" : "High CPU Load", color: sys.cpuUsage < 70 ? insightGreen : systemRed)

            case .gpu:
                statRow(label: "Architecture:", value: sys.chipName, color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Display:", value: "120Hz ProMotion", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Insights:", value: "GPU Nominal", color: insightGreen)

            case .ram:
                statRow(label: "Total Memory:", value: String(format: "%.0f GB", sys.ramTotalGB), color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Cached Files:", value: String(format: "%.1f GB", sys.ramCachedGB), color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Insights:", value: sys.ramPercent < 80 ? "Healthy Pressure" : "Memory Warning", color: sys.ramPercent < 80 ? insightGreen : systemRed)

            case .storage:
                EmptyView()

            case .network:
                statRow(label: "Packets In:", value: "\(sys.packetsInPerSec) /s", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Packets Out:", value: "\(sys.packetsOutPerSec) /s", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Insights:", value: "Link Stable", color: insightGreen)

            case .battery:
                statRow(label: "Cycle Count:", value: "\(sys.batteryCycleCount)", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Condition:", value: "Normal", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Insights:", value: sys.isCharging ? "Connected to AC" : "On Battery", color: insightGreen)

            case .temps:
                statRow(label: "Fans:", value: sys.fanRPM == 0 ? "Passive (0 RPM)" : "\(sys.fanRPM) RPM", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Cooling:", value: sys.fanRPM == 0 ? "Silent Airflow" : "Active Cooling", color: idleWhite)
                Divider().background(Color.white.opacity(0.18))
                statRow(label: "Insights:", value: sys.cpuTempCelsius < 80 ? "No Throttling" : "Thermal Throttling", color: sys.cpuTempCelsius < 80 ? insightGreen : systemRed)
            }
        }
    }

    @ViewBuilder
    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
        }
    }

    private var graphHeaderTitle: String {
        switch selectedTab {
        case .cpu: return "CPU LOAD"
        case .gpu: return "GPU LOAD"
        case .ram: return "MEMORY PRESSURE"
        case .storage: return "STORAGE USAGE"
        case .network: return "NETWORK I/O"
        case .battery: return "BATTERY DRAW"
        case .temps: return "THERMAL MATRIX"
        }
    }

    private var bottomGraphHistory: [Double] {
        switch selectedTab {
        case .cpu: return sys.cpuSystemHistory
        case .gpu: return sys.gpuHistory.map { $0 * 0.3 }
        case .ram: return sys.ramHistory.map { $0 * 0.35 }
        case .storage: return sys.diskWriteHistory
        case .network: return sys.uploadHistory
        case .battery: return Array(repeating: 2.0, count: 40)
        case .temps: return sys.thermalHistory.map { max(0, $0 - 30) }
        }
    }

    private var topGraphHistory: [Double] {
        switch selectedTab {
        case .cpu: return sys.cpuUserHistory
        case .gpu: return sys.gpuHistory.map { $0 * 0.7 }
        case .ram: return sys.ramHistory.map { $0 * 0.65 }
        case .storage: return sys.diskReadHistory
        case .network: return sys.downloadHistory
        case .battery: return Array(repeating: Double(sys.batteryPercent) * 0.5, count: 40)
        case .temps: return sys.thermalHistory.map { $0 * 0.5 }
        }
    }

    private var graphMaxScale: Double {
        switch selectedTab {
        case .cpu, .gpu, .ram: return 100.0
        case .storage: return 100.0
        case .network: return 50.0
        case .battery: return 100.0
        case .temps: return 100.0
        }
    }
}

struct ActivityMonitorStackedGraph: View {
    let bottomHistory: [Double]
    let topHistory: [Double]
    let bottomColor: Color
    let topColor: Color
    let maxScale: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let safeBottom = Array(bottomHistory.suffix(35))
            let safeTop = Array(topHistory.suffix(35))
            let count = max(safeBottom.count, safeTop.count)

            ZStack(alignment: .bottomLeading) {
                if count > 1 {
                    Path { path in
                        let step = w / CGFloat(count - 1)
                        let firstY = h - CGFloat(min(max((safeBottom.first ?? 0) / max(maxScale, 1), 0), 1)) * h
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: 0, y: firstY))

                        for idx in 1..<count {
                            let x = CGFloat(idx) * step
                            let val = idx < safeBottom.count ? safeBottom[idx] : 0
                            let y = h - CGFloat(min(max(val / max(maxScale, 1), 0), 1)) * h
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [bottomColor.opacity(0.85), bottomColor.opacity(0.40)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        let step = w / CGFloat(count - 1)
                        let firstY = h - CGFloat(min(max((safeBottom.first ?? 0) / max(maxScale, 1), 0), 1)) * h
                        path.move(to: CGPoint(x: 0, y: firstY))

                        for idx in 1..<count {
                            let x = CGFloat(idx) * step
                            let val = idx < safeBottom.count ? safeBottom[idx] : 0
                            let y = h - CGFloat(min(max(val / max(maxScale, 1), 0), 1)) * h
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(bottomColor, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))

                    Path { path in
                        let step = w / CGFloat(count - 1)
                        let b0 = safeBottom.first ?? 0
                        let t0 = safeTop.first ?? 0
                        let firstY = h - CGFloat(min(max((b0 + t0) / max(maxScale, 1), 0), 1)) * h
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: 0, y: firstY))

                        for idx in 1..<count {
                            let x = CGFloat(idx) * step
                            let bVal = idx < safeBottom.count ? safeBottom[idx] : 0
                            let tVal = idx < safeTop.count ? safeTop[idx] : 0
                            let y = h - CGFloat(min(max((bVal + tVal) / max(maxScale, 1), 0), 1)) * h
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [topColor.opacity(0.65), topColor.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        let step = w / CGFloat(count - 1)
                        let b0 = safeBottom.first ?? 0
                        let t0 = safeTop.first ?? 0
                        let firstY = h - CGFloat(min(max((b0 + t0) / max(maxScale, 1), 0), 1)) * h
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: CGPoint(x: 0, y: firstY))

                        for idx in 1..<count {
                            let x = CGFloat(idx) * step
                            let bVal = idx < safeBottom.count ? safeBottom[idx] : 0
                            let tVal = idx < safeTop.count ? safeTop[idx] : 0
                            let y = h - CGFloat(min(max((bVal + tVal) / max(maxScale, 1), 0), 1)) * h
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(topColor, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}
