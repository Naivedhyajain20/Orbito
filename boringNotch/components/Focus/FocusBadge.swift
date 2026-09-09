//
//  FocusBadge.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import SwiftUI

struct FocusBadge: View {
    let remaining: String
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
                .scaleEffect(pulse ? 1.4 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }

            if !remaining.isEmpty {
                Text(remaining)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 1))
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            FocusModeManager.shared.stopFocus()
        }
        .help("Focus active — tap to stop")
    }
}
