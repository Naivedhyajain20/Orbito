//
//  NotchNestPremiumModalView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

struct NotchNestPremiumModalView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 8) {
                // Header with Close Button
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                        Text("NotchNest Plan Comparison")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                // The Two Plan Cards (Side-by-Side) matching the screenshot
                HStack(alignment: .top, spacing: 12) {
                    // LEFT CARD: Trial (Restricted Features)
                    trialCard

                    // RIGHT CARD: NotchNest Premium (Everything Included)
                    premiumCard
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(width: 660)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.09).opacity(0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.7), radius: 25, y: 10)
        }
    }

    // MARK: - Trial Card
    private var trialCard: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text("Trial")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Text("Restricted Features")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 6)

            VStack(spacing: 6) {
                trialRow(icon: "bookmark", title: "1 Bookmark only")
                trialRow(icon: "note.text", title: "1 Note only")
                trialRow(icon: "timer", title: "Limited Pomodoro")
                trialRow(icon: "camera", title: "3 sec Mirror")
                trialRow(icon: "calendar", title: "Today's Events Only")
                trialRow(icon: "gamecontroller", title: "2 Game Plays in 24 hours")
                trialRow(icon: "tray", title: "2 Files Only")
                trialRow(icon: "doc.on.clipboard", title: "5 Pasteboard Item Only")
            }

            Button(action: {}) {
                Text("Past Tier")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.16))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.12).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func trialRow(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 16)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.65))

            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.15).opacity(0.5))
        )
    }

    // MARK: - Premium Card
    private var premiumCard: some View {
        VStack(spacing: 8) {
            // "BEST VALUE" Pill Badge
            Text("BEST VALUE")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.purple.opacity(0.5), radius: 6, y: 1)

            VStack(spacing: 2) {
                Text("NotchNest Premium")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Text("Everything Included")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
            }

            VStack(spacing: 6) {
                premiumRow(icon: "bookmark.fill", title: "Unlimited Bookmarks", color: .blue)
                premiumRow(icon: "note.text", title: "Unlimited Notes", color: .purple)
                premiumRow(icon: "timer", title: "Unlocked Pomodoro", color: .indigo)
                premiumRow(icon: "camera.fill", title: "Unlimited Mirror", color: .cyan)
                premiumRow(icon: "calendar", title: "All Calendar Events", color: .red)
                premiumRow(icon: "gamecontroller.fill", title: "Fully Unlocked Game", color: .orange)
                premiumRow(icon: "tray.fill", title: "Unlimited Tray Files", color: .green)
                premiumRow(icon: "doc.on.clipboard.fill", title: "Unlimited Pasteboard Items", color: .teal)
                premiumRow(icon: "sparkles", title: "All Upcoming Features, Included", color: .pink)
            }

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                    Text("NotchNest Premium Unlocked")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.12).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.6), Color.purple.opacity(0.7), Color.pink.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
        )
    }

    private func premiumRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.25), lineWidth: 0.6)
                )
        )
    }
}
