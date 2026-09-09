//
//  SystemMonitorWidgetView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

/// Apple-grade compact glass widget displaying live CPU, RAM, and Network gauges for the Front Screen.
struct SystemMonitorWidgetView: View {
    @StateObject private var manager = SystemInfoManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // CPU Circular Gauge
            GaugeRing(
                title: "CPU",
                value: manager.cpuUsage / 100.0,
                displayValue: String(format: "%.0f%%", manager.cpuUsage),
                gradient: Gradient(colors: [Color.cyan, Color.blue])
            )

            // RAM Circular Gauge
            GaugeRing(
                title: "RAM",
                value: manager.ramPercent / 100.0,
                displayValue: String(format: "%.0f%%", manager.ramPercent),
                gradient: Gradient(colors: [Color.purple, Color.pink])
            )

            // Storage (Disk) Circular Gauge
            GaugeRing(
                title: "Disk",
                value: manager.diskUsedPercent / 100.0,
                displayValue: String(format: "%.0f%%", manager.diskUsedPercent),
                gradient: Gradient(colors: [Color.orange, Color.yellow])
            )

            // Network & Wi-Fi Column
            VStack(alignment: .leading, spacing: 4) {
                // Download
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                    Text(manager.formatSpeed(manager.downloadSpeed))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }

                // Upload
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(manager.formatSpeed(manager.uploadSpeed))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }

                // Wi-Fi SSID
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Text(manager.wifiSSID)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 85, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Mini Gauge Ring

private struct GaugeRing: View {
    let title: String
    let value: Double
    let displayValue: String
    let gradient: Gradient

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)

                // Progress Arc
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(value, 0), 1)))
                    .stroke(
                        AngularGradient(gradient: gradient, center: .center),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: value)

                // Value Text inside ring
                Text(displayValue)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 38, height: 38)

            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
}
