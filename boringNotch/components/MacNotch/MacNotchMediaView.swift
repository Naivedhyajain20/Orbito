//
//  MacNotchMediaView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI
import Defaults

struct MacNotchMediaView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var volumeManager = VolumeManager.shared
    @State private var isDraggingSlider: Bool = false
    @State private var sliderValue: Double = 0

    private var effectiveDuration: Double {
        musicManager.songDuration > 0 ? musicManager.songDuration : 180
    }

    var body: some View {
        HStack(spacing: 14) {
            // LEFT SIDE: Big Player Card
            HStack(spacing: 14) {
                // Album Art (Click opens music player)
                Button(action: {
                    musicManager.openMusicApp()
                }) {
                    Image(nsImage: musicManager.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 86, height: 86)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 6, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open in Music App")

                // Track Info & Transport
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(musicManager.songTitle.isEmpty ? "No Song Playing" : musicManager.songTitle)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(musicManager.artistName.isEmpty ? "Apple Music • Spotify" : "\(musicManager.artistName) • \(musicManager.album)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }

                    // Scrubber Slider
                    VStack(spacing: 2) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 4)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white, Color.white.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(min(max(sliderValue / effectiveDuration, 0), 1)), height: 4)
                            }
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        isDraggingSlider = true
                                        let ratio = min(max(value.location.x / geo.size.width, 0), 1)
                                        sliderValue = ratio * effectiveDuration
                                    }
                                    .onEnded { value in
                                        let ratio = min(max(value.location.x / geo.size.width, 0), 1)
                                        let target = ratio * effectiveDuration
                                        sliderValue = target
                                        musicManager.seek(to: target)
                                        isDraggingSlider = false
                                    }
                            )
                        }
                        .frame(height: 8)

                        HStack {
                            Text(formatTime(sliderValue))
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                            Text(formatTime(effectiveDuration))
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    // Transport Buttons
                    HStack(spacing: 12) {
                        Button(action: { musicManager.toggleShuffle() }) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 11))
                                .foregroundColor(musicManager.isShuffled ? .cyan : .white.opacity(0.5))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { musicManager.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { musicManager.playPause() }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { musicManager.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { musicManager.toggleRepeat() }) {
                            Image(systemName: "repeat")
                                .font(.system(size: 11))
                                .foregroundColor(musicManager.repeatMode != .off ? .cyan : .white.opacity(0.5))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.10).opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
            )

            // RIGHT SIDE: Synchronized Lyrics Panel
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("Live Lyrics")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if musicManager.isFetchingLyrics {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 6) {
                            if !musicManager.syncedLyrics.isEmpty {
                                ForEach(Array(musicManager.syncedLyrics.enumerated()), id: \.offset) { idx, line in
                                    let isCurrent = isCurrentLyric(time: line.time, nextTime: idx + 1 < musicManager.syncedLyrics.count ? musicManager.syncedLyrics[idx + 1].time : effectiveDuration)
                                    Text(line.text)
                                        .font(.system(size: isCurrent ? 12 : 10, weight: isCurrent ? .bold : .medium))
                                        .foregroundColor(isCurrent ? .white : .white.opacity(0.35))
                                        .id(idx)
                                }
                            } else if !musicManager.currentLyrics.isEmpty {
                                Text(musicManager.currentLyrics)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                VStack(spacing: 6) {
                                    Spacer(minLength: 10)
                                    Image(systemName: "music.mic")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.3))
                                    Text("Enjoying the music")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(musicManager.songTitle.isEmpty ? "Play a track to view synced lyrics" : musicManager.songTitle)
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.4))
                                        .lineLimit(1)
                                    Spacer(minLength: 10)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                }
            }
            .frame(width: 250)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.10).opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onAppear {
            sliderValue = musicManager.elapsedTime
        }
        .onReceive(musicManager.$elapsedTime) { time in
            if !isDraggingSlider {
                sliderValue = time
            }
        }
    }

    private func isCurrentLyric(time: Double, nextTime: Double) -> Bool {
        sliderValue >= time && sliderValue < nextTime
    }

    private func formatTime(_ seconds: Double) -> String {
        let t = Int(max(seconds, 0))
        let m = t / 60
        let s = t % 60
        return String(format: "%d:%02d", m, s)
    }
}
