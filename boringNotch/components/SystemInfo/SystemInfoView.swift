//
//  SystemInfoView.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import SwiftUI

struct SystemInfoView: View {
    @StateObject private var manager = SystemInfoManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // CPU Card
                SysInfoCard(
                    icon: "cpu",
                    title: "CPU",
                    value: String(format: "%.1f%%", manager.cpuUsage),
                    color: cpuColor(manager.cpuUsage),
                    history: manager.cpuHistory,
                    maxValue: 100
                )

                // RAM Card
                SysInfoCard(
                    icon: "memorychip",
                    title: "Memory",
                    value: manager.ramUsageString,
                    color: ramColor(manager.ramPercent),
                    history: manager.ramHistory,
                    maxValue: 100
                )

                // Storage Card
                HStack {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    Text("Storage (Macintosh HD)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(manager.diskUsageString)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )

                // Network Card
                HStack(spacing: 8) {
                    NetworkStatCard(
                        icon: "arrow.down.circle",
                        label: "Download",
                        value: manager.formatSpeed(manager.downloadSpeed),
                        history: manager.downloadHistory,
                        color: .green
                    )
                    NetworkStatCard(
                        icon: "arrow.up.circle",
                        label: "Upload",
                        value: manager.formatSpeed(manager.uploadSpeed),
                        history: manager.uploadHistory,
                        color: .blue
                    )
                }

                // Wi-Fi Card
                WifiCard(ssid: manager.wifiSSID, strength: manager.wifiStrength)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private func cpuColor(_ usage: Double) -> Color {
        if usage > 80 { return .red }
        if usage > 50 { return .orange }
        return .green
    }

    private func ramColor(_ percent: Double) -> Color {
        if percent > 85 { return .red }
        if percent > 65 { return .orange }
        return .blue
    }
}

// MARK: - Sys Info Card

struct SysInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let history: [Double]
    let maxValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }

            // Sparkline
            SparklineView(values: history, color: color, maxValue: maxValue)
                .frame(height: 28)
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Network Stat Card

struct NetworkStatCard: View {
    let icon: String
    let label: String
    let value: String
    let history: [Double]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            SparklineView(values: history, color: color, maxValue: 100)
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Wi-Fi Card

struct WifiCard: View {
    let ssid: String
    let strength: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: wifiIcon)
                .font(.system(size: 18))
                .foregroundColor(strength > 0 ? .blue : .gray)

            VStack(alignment: .leading, spacing: 2) {
                Text(ssid)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(strength > 0 ? "Signal: \(["Weak", "Fair", "Good", "Excellent"][min(strength-1, 3)])" : "Not connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Signal bars
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(1...4, id: \.self) { bar in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(bar <= strength ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 4, height: CGFloat(bar * 4 + 2))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }

    private var wifiIcon: String {
        switch strength {
        case 0: return "wifi.slash"
        case 1: return "wifi"
        case 2: return "wifi"
        case 3: return "wifi"
        default: return "wifi"
        }
    }
}

// MARK: - Sparkline

struct SparklineView: View {
    let values: [Double]
    let color: Color
    let maxValue: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = values.count
            guard count > 1 else { return AnyView(EmptyView()) }

            let step = w / CGFloat(count - 1)
            let points: [CGPoint] = values.enumerated().map { i, v in
                let x = CGFloat(i) * step
                let norm = maxValue > 0 ? min(max(v / maxValue, 0), 1) : 0
                let y = h - CGFloat(norm) * h
                return CGPoint(x: x, y: y)
            }

            return AnyView(
                ZStack {
                    // Fill
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: h))
                        points.forEach { path.addLine(to: $0) }
                        path.addLine(to: CGPoint(x: points.last!.x, y: h))
                        path.closeSubpath()
                    }
                    .fill(color.opacity(0.15))

                    // Line
                    Path { path in
                        path.move(to: points[0])
                        points.dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            )
        }
    }
}
