//
//  NotchNestGameView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Combine

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    let width: CGFloat = 16
    let height: CGFloat = 24
}

struct NotchNestGameView: View {
    @State private var isPlaying: Bool = false
    @State private var isGameOver: Bool = false
    @State private var score: Int = 0
    @State private var highScore: Int = UserDefaults.standard.integer(forKey: "NotchNestGameHighScore")

    // Physics
    @State private var playerY: CGFloat = 0       // 0 is ground
    @State private var playerVelocityY: CGFloat = 0
    @State private var isJumping: Bool = false
    @State private var obstacles: [Obstacle] = []

    private let gravity: CGFloat = 1.2
    private let jumpForce: CGFloat = 13.5
    private let groundY: CGFloat = 0
    private let gameTimer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 4) {
            // Game Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11))
                    Text("Infinity Run")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("PRO UNLOCKED")
                        .font(.system(size: 7, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.25)))
                        .foregroundColor(.orange)
                }

                Spacer()

                HStack(spacing: 12) {
                    Text("HI: \(highScore)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))

                    Text("SCORE: \(score)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 12)

            // Game Playfield Area
            ZStack(alignment: .bottom) {
                // Background Sky
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )

                // Ground line
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 2)
                    .offset(y: -10)

                // Obstacles
                ForEach(obstacles) { obs in
                    Text("🌵")
                        .font(.system(size: 18))
                        .position(x: obs.x, y: 56)
                }

                // Player (Chicken Runner)
                Text(isGameOver ? "💥" : (isJumping ? "🐔" : "🐥"))
                    .font(.system(size: 22))
                    .offset(y: -10 - playerY)
                    .position(x: 45, y: 56)

                // Overlays
                if !isPlaying && !isGameOver {
                    VStack(spacing: 4) {
                        Text("TAP OR PRESS SPACE TO JUMP")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("Jump over obstacles to set a new record")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                } else if isGameOver {
                    VStack(spacing: 4) {
                        Text("GAME OVER")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                        Text("Score: \(score)  •  Tap to Restart")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.6))
                }
            }
            .frame(height: 85)
            .contentShape(Rectangle())
            .onTapGesture {
                jumpOrStart()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onReceive(gameTimer) { _ in
            updatePhysics()
        }
    }

    private func jumpOrStart() {
        if isGameOver {
            resetGame()
            return
        }
        if !isPlaying {
            isPlaying = true
        }
        if !isJumping {
            playerVelocityY = jumpForce
            isJumping = true
        }
    }

    private func resetGame() {
        score = 0
        obstacles = []
        playerY = 0
        playerVelocityY = 0
        isJumping = false
        isGameOver = false
        isPlaying = true
    }

    private func updatePhysics() {
        guard isPlaying && !isGameOver else { return }

        // Player jump gravity
        if isJumping {
            playerY += playerVelocityY
            playerVelocityY -= gravity

            if playerY <= groundY {
                playerY = groundY
                playerVelocityY = 0
                isJumping = false
            }
        }

        // Spawn obstacles
        if obstacles.isEmpty || (obstacles.last?.x ?? 0) < 550 {
            if Int.random(in: 0...35) == 0 {
                obstacles.append(Obstacle(x: 650))
            }
        }

        // Move obstacles
        let speed: CGFloat = 6.0 + CGFloat(score / 15)
        for i in obstacles.indices {
            obstacles[i].x -= speed
        }

        // Remove off-screen obstacles and award points
        obstacles.removeAll { obs in
            if obs.x < -20 {
                score += 1
                if score > highScore {
                    highScore = score
                    UserDefaults.standard.set(highScore, forKey: "NotchNestGameHighScore")
                }
                return true
            }
            return false
        }

        // Collision detection (Player is at x: 45)
        for obs in obstacles {
            if abs(obs.x - 45) < 16 && playerY < 18 {
                isGameOver = true
                isPlaying = false
                break
            }
        }
    }
}
