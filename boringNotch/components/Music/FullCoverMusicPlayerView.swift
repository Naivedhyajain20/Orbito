//
//  FullCoverMusicPlayerView.swift
//  boringNotch
//
//  Full-cover animated album art music player widget inspired by LaunchMe notch.
//

import Defaults
import SwiftUI

struct FullCoverMusicPlayerView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @State private var isSeeking: Bool = false
    @State private var seekPosition: Double = 0

    private var effectiveDuration: Double {
        musicManager.songDuration > 0 ? musicManager.songDuration : 180
    }

    private var currentPosition: Double {
        isSeeking ? seekPosition : musicManager.elapsedTime
    }

    private var remainingTime: Double {
        max(effectiveDuration - currentPosition, 0)
    }

    var body: some View {
        ZStack {
            // MARK: - 1. Full-Cover Album Art Background
            if !musicManager.songTitle.isEmpty || musicManager.isPlaying {
                Image(nsImage: musicManager.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .scaleEffect(musicManager.isPlaying ? 1.04 : 1.0)
                    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: musicManager.isPlaying)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.16),
                        Color(red: 0.06, green: 0.06, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // MARK: - 2. Cinematic Dark Vignette Overlay
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.15), location: 0.0),
                    .init(color: .black.opacity(0.40), location: 0.4),
                    .init(color: .black.opacity(0.85), location: 0.8),
                    .init(color: .black.opacity(0.95), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // MARK: - 3. Content Layer
            VStack(alignment: .leading, spacing: 4) {
                // Top header: Source badge + Artist
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 30/255, green: 215/255, blue: 96/255))
                        .frame(width: 7, height: 7)

                    Text(musicManager.artistName.isEmpty ? "Now Playing" : musicManager.artistName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)

                    if !musicManager.album.isEmpty {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                        Text(musicManager.album)
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                    }

                    Spacer()
                }

                Spacer(minLength: 4)

                // Song Title
                Text(musicManager.songTitle.isEmpty ? "No Media Playing" : musicManager.songTitle)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)

                // Scrubber Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track background
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 4)

                        // Elapsed fill
                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: geo.size.width * CGFloat(
                                    min(max(currentPosition / effectiveDuration, 0), 1)
                                ),
                                height: 4
                            )
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                isSeeking = true
                                seekPosition = min(max(val.location.x / geo.size.width, 0), 1) * effectiveDuration
                            }
                            .onEnded { val in
                                let t = min(max(val.location.x / geo.size.width, 0), 1) * effectiveDuration
                                seekPosition = t
                                musicManager.seek(to: t)
                                isSeeking = false
                            }
                    )
                }
                .frame(height: 6)

                // Timestamps (Elapsed & -Remaining)
                HStack {
                    Text(formatTime(currentPosition))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.75))

                    Spacer()

                    Text("-\(formatTime(remainingTime))")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.75))
                }

                // Transport Controls
                HStack(spacing: 20) {
                    Spacer()

                    Button(action: { musicManager.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { musicManager.playPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 32, height: 32)

                            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { musicManager.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 3)
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
