//
//  FaceIDNotchView.swift
//  boringNotch
//
//  Created for Dynamic Island Gyroscope Ring Unlock Experience.
//

import SwiftUI
import Defaults

struct FaceIDNotchView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var faceIDManager = FaceIDManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Hardware Notch clearance space
            Spacer(minLength: max(16, vm.effectiveClosedNotchHeight))
            
            // Centered 3D Glowing Gyroscope Rings / Checkmark
            FaceIDGlyphView(
                state: faceIDManager.currentState,
                size: 58
            )
            .frame(width: 64, height: 64)
            
            Spacer(minLength: 12)
        }
        .frame(width: vm.closedNotchSize.width, height: 136)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.88, anchor: .top).combined(with: .opacity),
            removal: .scale(scale: 0.9, anchor: .top).combined(with: .opacity)
        ))
    }
}

#Preview {
    ZStack {
        Color.black
        FaceIDNotchView()
            .environmentObject(BoringViewModel())
    }
    .frame(width: 200, height: 200)
}
