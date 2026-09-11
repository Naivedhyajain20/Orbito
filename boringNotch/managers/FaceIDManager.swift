//
//  FaceIDManager.swift
//  boringNotch
//
//  Created for Dynamic Island Gyroscope Ring Unlock Experience.
//

import AppKit
import AVFoundation
import Combine
import Defaults
import Foundation
import SwiftUI

@MainActor
final class FaceIDManager: ObservableObject {
    static let shared = FaceIDManager()
    
    @Published var currentState: FaceIDState = .gyroscopeRings
    @Published var isActive: Bool = false
    
    private var sequenceTask: Task<Void, Never>?
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    /// Plays Apple Pay sound when success checkmark appears
    private func playUnlockSound() {
        guard Defaults[.faceIDSound] else { return }
        
        let soundURLs = [
            Bundle.main.url(forResource: "Apple-pay-sound-effect", withExtension: "mp3"),
            URL(fileURLWithPath: "/Users/naivedhyajain/boring.notch/Apple-pay-sound-effect.mp3"),
            URL(fileURLWithPath: "/Users/naivedhyajain/boring.notch/boringNotch/Apple-pay-sound-effect.mp3")
        ].compactMap { $0 }
        
        for url in soundURLs {
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    return
                } catch {
                    print("⚠️ [FaceIDManager] Failed to play sound with AVAudioPlayer: \(error)")
                }
            }
        }
        
        // Fallback to NSSound
        if let sound = NSSound(named: "Apple-pay-sound-effect") {
            sound.play()
        }
    }
    
    /// Fast unlock sequence: Glowing Gyroscope Rings -> Green Checkmark (✓) -> Smooth Dismiss
    func triggerUnlockSequence(forced: Bool = false, onComplete: (() -> Void)? = nil) {
        guard forced || Defaults[.enableFaceIDUnlockAnimation] else {
            onComplete?()
            return
        }
        
        sequenceTask?.cancel()
        
        sequenceTask = Task { @MainActor in
            self.isActive = true
            self.currentState = .gyroscopeRings
            
            // Open expanding notch downwards under notch matching Apple Notch width
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                BoringViewCoordinator.shared.toggleExpandingView(
                    status: true,
                    type: .faceID
                )
            }
            
            // Phase 1: 3D Glowing Gyroscope Rings (280ms)
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            
            // Phase 2: Glowing Green Circle + Right Checkmark (✓)
            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                self.currentState = .success
            }
            
            // Play Apple Pay Sound Effect on success tick
            self.playUnlockSound()
            
            // Optional Haptic Feedback
            if Defaults[.faceIDHaptics] && Defaults[.enableHaptics] {
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .now
                )
            }
            
            // Phase 2 hold duration: 420ms (fast, clean)
            try? await Task.sleep(for: .milliseconds(420))
            guard !Task.isCancelled else { return }
            
            // Phase 3: Smooth Dismissal back to closed notch
            withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) {
                BoringViewCoordinator.shared.toggleExpandingView(
                    status: false,
                    type: .faceID
                )
                self.isActive = false
                self.currentState = .gyroscopeRings
            }
            
            try? await Task.sleep(for: .milliseconds(100))
            onComplete?()
        }
    }
    
    /// Instant preview function for settings
    func testUnlockSequence() {
        triggerUnlockSequence(forced: true)
    }
}
