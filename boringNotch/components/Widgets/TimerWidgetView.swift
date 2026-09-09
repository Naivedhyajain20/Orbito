//
//  TimerWidgetView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

/// Compact glass widget for active timer or quick 1-tap timer launcher on the Front Screen.
struct TimerWidgetView: View {
    @StateObject private var manager = TimerManager.shared

    var body: some View {
        HStack(spacing: 8) {
            if let active = manager.timers.first(where: { $0.isRunning && !$0.isFinished }) {
                // Active Countdown
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: CGFloat(active.progress))
                        .stroke(
                            Color.orange,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.2), value: active.progress)

                    Image(systemName: "timer")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(active.timeString)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(active.label)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Button {
                    manager.toggleTimer(active)
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Quick Presets
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.orange)

                HStack(spacing: 4) {
                    quickButton(mins: 5, label: "5m")
                    quickButton(mins: 15, label: "15m")
                    quickButton(mins: 25, label: "25m")
                }
            }
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

    private func quickButton(mins: Int, label: String) -> some View {
        Button {
            let timer = BoringTimer(label: "\(mins)m", duration: TimeInterval(mins * 60), color: "#FF9500")
            manager.timers.append(timer)
            manager.toggleTimer(timer)
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
