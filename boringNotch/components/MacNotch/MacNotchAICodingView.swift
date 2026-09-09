//
//  MacNotchAICodingView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

struct AISession: Identifiable {
    let id = UUID()
    let repoName: String
    let status: String
    let model: String
    let branch: String
    let messageCount: Int
    let tokens: String
    let timeAgo: String
    let currentTask: String
    let needsApproval: Bool
}

struct MacNotchAICodingView: View {
    @State private var sessions: [AISession] = [
        AISession(
            repoName: "aurora-shop",
            status: "Running",
            model: "Opus",
            branch: "feature/guest-checkout",
            messageCount: 28,
            tokens: "58.1k tok",
            timeAgo: "2 min, 4 sec",
            currentTask: "Editing CheckoutViewModel.swift",
            needsApproval: false
        ),
        AISession(
            repoName: "northwind-api",
            status: "Waiting",
            model: "Sonnet",
            branch: "docs/inventory-webhooks",
            messageCount: 12,
            tokens: "21.3k tok",
            timeAgo: "18 min, 4 sec",
            currentTask: "Sketch OpenAPI for inventory webhooks",
            needsApproval: true
        ),
        AISession(
            repoName: "orbit-ios",
            status: "Running",
            model: "GPT-4o",
            branch: "fix/map-clustering",
            messageCount: 16,
            tokens: "34.2k tok",
            timeAgo: "8 min, 48 sec",
            currentTask: "Fix map clustering on zoom",
            needsApproval: false
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("AI Coding (Beta)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("•  3 active")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }

                Spacer()

                HStack(spacing: 8) {
                    Text("4 sec")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))

                    HStack(spacing: 3) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 9))
                        Text("Agents")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(white: 0.16)))
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 4)

            // Sessions List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 5) {
                    ForEach(sessions) { session in
                        sessionRow(session)
                    }

                    // Recent Completed Item
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text("ledger-web")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("Completed")
                                    .font(.system(size: 7, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color.gray.opacity(0.3)))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Text("Invoice PDF export polish")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        Text("1 hr, 35m ago")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.08).opacity(0.6))
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func sessionRow(_ session: AISession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(session.repoName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)

                    Text(session.status)
                        .font(.system(size: 7, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(session.status == "Running" ? Color.green.opacity(0.25) : Color.yellow.opacity(0.25))
                        )
                        .foregroundColor(session.status == "Running" ? .green : .yellow)

                    Text(session.model)
                        .font(.system(size: 7, weight: .medium))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .foregroundColor(.white.opacity(0.7))

                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 7))
                        .foregroundColor(.white.opacity(0.4))

                    Text(session.branch)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Text(session.currentTask)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer()

            if session.needsApproval {
                HStack(spacing: 4) {
                    Button(action: {}) {
                        Text("Allow")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {}) {
                        Text("Deny")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.red.opacity(0.3)))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(session.timeAgo)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.4))
                    Text("\(session.messageCount) msgs • \(session.tokens)")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.10).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(session.needsApproval ? Color.yellow.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.8)
                )
        )
    }
}
