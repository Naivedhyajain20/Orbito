//
//  FaceIDGlyphView.swift
//  boringNotch
//
//  Created for Dynamic Island Gyroscope Ring Unlock Experience (matching demo.mp4).
//

import SwiftUI

enum FaceIDState: Equatable {
    case gyroscopeRings  // 3D Glowing Green Rotating Gyroscope Rings
    case success         // Glowing Green Circle + Right Checkmark (✓)
    case failed          // Failed X
}

struct FaceIDGlyphView: View {
    var state: FaceIDState = .gyroscopeRings
    var size: CGFloat = 64
    
    // Glowing Mint / Matrix Green Palette matching demo.mp4
    private let neonGreen = Color(red: 0.45, green: 0.96, blue: 0.55)
    private let glowGreen = Color(red: 0.45, green: 0.96, blue: 0.55).opacity(0.7)
    
    // Gyroscope Rotations
    @State private var rotationY: Double = 0
    @State private var rotationX: Double = 0
    @State private var rotationZ: Double = 0
    @State private var pulseGlow: Bool = false
    
    var body: some View {
        ZStack {
            switch state {
            case .gyroscopeRings:
                // 3D Rotating Glowing Gyroscope Rings (matching demo.mp4)
                ZStack {
                    // Ambient radial glow
                    RadialGradient(
                        colors: [neonGreen.opacity(pulseGlow ? 0.35 : 0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.65
                    )
                    .blur(radius: 6)
                    
                    // Ring 1 (Y-Axis)
                    Circle()
                        .stroke(neonGreen.opacity(0.92), lineWidth: size * 0.07)
                        .shadow(color: glowGreen, radius: 4)
                        .rotation3DEffect(
                            .degrees(rotationY),
                            axis: (x: 0, y: 1, z: 0)
                        )
                    
                    // Ring 2 (X-Axis & Tilted)
                    Circle()
                        .stroke(neonGreen.opacity(0.88), lineWidth: size * 0.07)
                        .shadow(color: glowGreen, radius: 4)
                        .rotation3DEffect(
                            .degrees(rotationX),
                            axis: (x: 1, y: 0.35, z: 0)
                        )
                    
                    // Ring 3 (Z-Axis & Diagonal)
                    Circle()
                        .stroke(neonGreen.opacity(0.78), lineWidth: size * 0.06)
                        .shadow(color: glowGreen, radius: 3)
                        .rotation3DEffect(
                            .degrees(rotationZ),
                            axis: (x: 0.4, y: 0.6, z: 1)
                        )
                }
                .frame(width: size * 0.95, height: size * 0.95)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
                
            case .success:
                // Glowing Circle + Right Checkmark (✓) (matching demo.mp4)
                ZStack {
                    // Outer bloom blur
                    Circle()
                        .stroke(neonGreen.opacity(0.4), lineWidth: size * 0.12)
                        .blur(radius: 4)
                    
                    // Sharp glowing ring
                    Circle()
                        .stroke(neonGreen, lineWidth: size * 0.085)
                        .shadow(color: glowGreen, radius: 5)
                    
                    // Bold checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.46, weight: .bold))
                        .foregroundStyle(neonGreen)
                        .shadow(color: glowGreen, radius: 3)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
                .frame(width: size * 0.9, height: size * 0.9)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                
            case .failed:
                ZStack {
                    Circle()
                        .stroke(Color.red, lineWidth: size * 0.085)
                        .shadow(color: Color.red.opacity(0.6), radius: 4)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: size * 0.44, weight: .bold))
                        .foregroundStyle(Color.red)
                }
                .frame(width: size * 0.9, height: size * 0.9)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: state)
        .onAppear {
            startGyroscopeSpin()
        }
        .onChange(of: state) { _, newState in
            if newState == .gyroscopeRings {
                startGyroscopeSpin()
            }
        }
    }
    
    private func startGyroscopeSpin() {
        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
            rotationY = 360
        }
        withAnimation(.linear(duration: 2.3).repeatForever(autoreverses: false)) {
            rotationX = 360
        }
        withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
            rotationZ = 360
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulseGlow = true
        }
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        HStack(spacing: 30) {
            FaceIDGlyphView(state: .gyroscopeRings, size: 64)
            FaceIDGlyphView(state: .success, size: 64)
        }
        .padding(40)
    }
}
