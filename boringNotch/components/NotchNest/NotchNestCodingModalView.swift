//
//  NotchNestCodingModalView.swift
//  boringNotch
//
//  Created by Antigravity on 16/09/2026.
//

import SwiftUI
import AppKit
import Defaults

enum CodingModalTab: String, CaseIterable {
    case github = "GitHub"
    case leetcode = "LeetCode"
    case overview = "Overview"
}

struct NotchNestCodingModalView: View {
    @ObservedObject var manager = CodingActivityManager.shared
    @State private var selectedTab: CodingModalTab = .github
    @State private var hoveredGitHubDay: GitHubContributionDay? = nil
    @State private var hoveredLeetCodeDay: LeetCodeDay? = nil
    @State private var isRotatingSync: Bool = false

    // GitHub brand colors
    private let ghDarkCell = Color(red: 22/255, green: 27/255, blue: 34/255)
    private let ghGreen1 = Color(red: 14/255, green: 68/255, blue: 41/255)
    private let ghGreen2 = Color(red: 0/255, green: 109/255, blue: 50/255)
    private let ghGreen3 = Color(red: 38/255, green: 166/255, blue: 65/255)
    private let ghGreen4 = Color(red: 57/255, green: 211/255, blue: 83/255)

    // LeetCode brand colors
    private let lcEasy = Color(red: 0/255, green: 184/255, blue: 163/255)       // #00B8A3
    private let lcMedium = Color(red: 255/255, green: 192/255, blue: 30/255)   // #FFC01E
    private let lcHard = Color(red: 255/255, green: 55/255, blue: 95/255)      // #FF375F
    private let lcOrange = Color(red: 255/255, green: 161/255, blue: 22/255)   // #FFA116

    var body: some View {
        VStack(spacing: 6) {
            // MARK: Top Navigation & Action Header
            HStack(spacing: 6) {
                // Tab switch capsules
                HStack(spacing: 4) {
                    ForEach(CodingModalTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 4) {
                                if tab == .github {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 8, weight: .bold))
                                } else if tab == .leetcode {
                                    Image(systemName: "curlybraces")
                                        .font(.system(size: 8, weight: .bold))
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 8, weight: .bold))
                                }

                                Text(tab.rawValue)
                                    .font(.system(size: 9, weight: selectedTab == tab ? .heavy : .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? Color.white.opacity(0.18) : Color.white.opacity(0.05))
                                    .overlay(
                                        Capsule().stroke(
                                            selectedTab == tab
                                                ? (tab == .github ? ghGreen4.opacity(0.7) : lcOrange.opacity(0.7))
                                                : Color.white.opacity(0.08),
                                            lineWidth: 0.8
                                        )
                                    )
                            )
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.55))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Spacer(minLength: 4)

                // Sync / Refresh Button
                Button(action: {
                    withAnimation(.linear(duration: 0.8)) {
                        isRotatingSync = true
                    }
                    manager.refreshAll()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isRotatingSync = false
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 8.5, weight: .semibold))
                            .rotationEffect(.degrees(isRotatingSync || manager.isLoadingGitHub || manager.isLoadingLeetCode ? 360 : 0))
                            .animation(
                                (isRotatingSync || manager.isLoadingGitHub || manager.isLoadingLeetCode)
                                    ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                    : .default,
                                value: isRotatingSync || manager.isLoadingGitHub || manager.isLoadingLeetCode
                            )
                        Text(manager.isLoadingGitHub || manager.isLoadingLeetCode ? "Syncing..." : "Sync")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
                    .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Fetch latest commits and submissions")

                // Open in Browser Button
                if currentProfileURL != nil {
                    Button(action: {
                        if let url = currentProfileURL {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.forward.square")
                                .font(.system(size: 8))
                            Text("Profile")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
                        .foregroundColor(.white.opacity(0.75))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Open profile in web browser")
                }

                // Settings link gear
                Button(action: {
                    SettingsWindowController.shared.showWindow()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 9))
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                        .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Configure accounts in Settings")
            }
            .padding(.horizontal, 8)

            // MARK: Tab Content Area
            Group {
                switch selectedTab {
                case .github:
                    if let gh = manager.githubData {
                        githubContentView(gh)
                    } else if manager.isLoadingGitHub {
                        loadingView(platform: "GitHub")
                    } else {
                        unlinkedView(platform: "GitHub", prompt: "Enter your GitHub username in Settings to see your commit heatmap.")
                    }

                case .leetcode:
                    if let lc = manager.leetcodeData {
                        leetCodeContentView(lc)
                    } else if manager.isLoadingLeetCode {
                        loadingView(platform: "LeetCode")
                    } else {
                        unlinkedView(platform: "LeetCode", prompt: "Enter your LeetCode username in Settings to view problem stats & submission streak.")
                    }

                case .overview:
                    overviewContentView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, 2)
        .padding(.horizontal, 6)
        .padding(.bottom, 2)
    }

    private var currentProfileURL: URL? {
        switch selectedTab {
        case .github:
            let u = Defaults[.githubUsername].trimmingCharacters(in: .whitespacesAndNewlines)
            return u.isEmpty ? nil : URL(string: "https://github.com/\(u)")
        case .leetcode:
            let u = Defaults[.leetcodeUsername].trimmingCharacters(in: .whitespacesAndNewlines)
            return u.isEmpty ? nil : URL(string: "https://leetcode.com/\(u)")
        case .overview:
            return nil
        }
    }

    // MARK: - GitHub Content View

    private func githubContentView(_ data: GitHubActivityData) -> some View {
        VStack(spacing: 5) {
            // User Header & Streak Metric Cards
            HStack(spacing: 8) {
                // Profile Capsule
                HStack(spacing: 5) {
                    if let avatar = data.avatarUrl, let url = URL(string: avatar) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Image(systemName: "person.circle.fill").foregroundColor(.gray)
                            }
                        }
                        .frame(width: 22, height: 22)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ghGreen4.opacity(0.8), lineWidth: 1))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    VStack(alignment: .leading, spacing: 0.5) {
                        Text(data.name ?? data.username)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("@\(data.username)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))

                // Stat pill: Contributions
                metricBadge(
                    icon: "calendar",
                    value: "\(data.totalContributionsYear)",
                    label: "Past Year",
                    tint: ghGreen4
                )

                // Stat pill: Current Streak
                metricBadge(
                    icon: "flame.fill",
                    value: "\(data.currentStreak)d",
                    label: "Streak",
                    tint: Color(red: 1.0, green: 0.45, blue: 0.15)
                )

                // Stat pill: Longest Streak
                metricBadge(
                    icon: "trophy.fill",
                    value: "\(data.longestStreak)d",
                    label: "Best",
                    tint: Color(red: 1.0, green: 0.8, blue: 0.1)
                )

                Spacer()

                // Tooltip indicator when hovering
                if let hovered = hoveredGitHubDay {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(githubColor(for: hovered.level))
                            .frame(width: 6, height: 6)
                        Text("\(hovered.count) contribution\(hovered.count == 1 ? "" : "s") on \(hovered.date)")
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.7))
                    .transition(.opacity)
                }
            }

            // MARK: The Iconic GitHub Green Contribution Matrix
            VStack(alignment: .leading, spacing: 2) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 2.2) {
                        ForEach(data.weeks) { week in
                            VStack(spacing: 2.2) {
                                ForEach(week.days) { day in
                                    RoundedRectangle(cornerRadius: 1.8)
                                        .fill(githubColor(for: day.level))
                                        .frame(width: 8.2, height: 8.2)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 1.8)
                                                .stroke(hoveredGitHubDay?.date == day.date ? Color.white : Color.clear, lineWidth: 0.8)
                                        )
                                        .onHover { hovering in
                                            if hovering {
                                                hoveredGitHubDay = day
                                            } else if hoveredGitHubDay?.date == day.date {
                                                hoveredGitHubDay = nil
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.08).opacity(0.75))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
                )

                // Heatmap footer: Legend
                HStack {
                    if let firstDate = data.weeks.first?.days.first?.date,
                       let lastDate = data.weeks.last?.days.last?.date {
                        Text("\(firstDate) – \(lastDate)")
                            .font(.system(size: 7.5, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    HStack(spacing: 3) {
                        Text("Less")
                            .font(.system(size: 7.5))
                            .foregroundColor(.white.opacity(0.4))
                        RoundedRectangle(cornerRadius: 1.2).fill(ghDarkCell).frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1.2).fill(ghGreen1).frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1.2).fill(ghGreen2).frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1.2).fill(ghGreen3).frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1.2).fill(ghGreen4).frame(width: 6, height: 6)
                        Text("More")
                            .font(.system(size: 7.5))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func githubColor(for level: Int) -> Color {
        switch level {
        case 1: return ghGreen1
        case 2: return ghGreen2
        case 3: return ghGreen3
        case 4: return ghGreen4
        default: return ghDarkCell
        }
    }

    // MARK: - LeetCode Content View

    private func leetCodeContentView(_ data: LeetCodeActivityData) -> some View {
        VStack(spacing: 5) {
            // Profile & Metric Row
            HStack(spacing: 8) {
                // User Profile
                HStack(spacing: 5) {
                    if let avatar = data.avatarUrl, let url = URL(string: avatar) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Image(systemName: "curlybraces.square.fill").foregroundColor(lcOrange)
                            }
                        }
                        .frame(width: 22, height: 22)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(lcOrange.opacity(0.8), lineWidth: 1))
                    } else {
                        Image(systemName: "curlybraces.square.fill")
                            .font(.system(size: 20))
                            .foregroundColor(lcOrange)
                    }

                    VStack(alignment: .leading, spacing: 0.5) {
                        Text(data.realName ?? data.username)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if data.ranking > 0 {
                            Text("Rank #\(data.ranking)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(lcOrange)
                                .lineLimit(1)
                        } else {
                            Text("@\(data.username)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))

                // Total Solved
                metricBadge(
                    icon: "checkmark.seal.fill",
                    value: "\(data.totalSolved)",
                    label: "Solved",
                    tint: lcOrange
                )

                // Easy / Medium / Hard Breakdown Badges
                HStack(spacing: 4) {
                    diffBadge(label: "Easy", count: data.easySolved, color: lcEasy)
                    diffBadge(label: "Med", count: data.mediumSolved, color: lcMedium)
                    diffBadge(label: "Hard", count: data.hardSolved, color: lcHard)
                }

                // Streak
                metricBadge(
                    icon: "flame.fill",
                    value: "\(data.currentStreak)d",
                    label: "Streak",
                    tint: Color(red: 1.0, green: 0.45, blue: 0.15)
                )

                Spacer()

                if let hovered = hoveredLeetCodeDay {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(leetCodeHeatColor(for: hovered.level))
                            .frame(width: 6, height: 6)
                        Text("\(hovered.count) submission\(hovered.count == 1 ? "" : "s") on \(hovered.date)")
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.7))
                }
            }

            // MARK: LeetCode Heatmap
            VStack(alignment: .leading, spacing: 2) {
                ScrollView(.horizontal, showsIndicators: false) {
                    let chunkedWeeks = chunkIntoWeeks(data.days)
                    HStack(alignment: .top, spacing: 2.2) {
                        ForEach(chunkedWeeks.indices, id: \.self) { weekIdx in
                            VStack(spacing: 2.2) {
                                ForEach(chunkedWeeks[weekIdx]) { day in
                                    RoundedRectangle(cornerRadius: 1.8)
                                        .fill(leetCodeHeatColor(for: day.level))
                                        .frame(width: 8.2, height: 8.2)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 1.8)
                                                .stroke(hoveredLeetCodeDay?.date == day.date ? Color.white : Color.clear, lineWidth: 0.8)
                                        )
                                        .onHover { hovering in
                                            if hovering {
                                                hoveredLeetCodeDay = day
                                            } else if hoveredLeetCodeDay?.date == day.date {
                                                hoveredLeetCodeDay = nil
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.08).opacity(0.75))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
                )

                HStack {
                    Text("Submission Activity (Recent Months)")
                        .font(.system(size: 7.5, weight: .regular))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    HStack(spacing: 3) {
                        Text("0")
                            .font(.system(size: 7.5))
                            .foregroundColor(.white.opacity(0.4))
                        RoundedRectangle(cornerRadius: 1.2).fill(ghDarkCell).frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1.2).fill(Color(red: 20/255, green: 70/255, blue: 60/255)).frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1.2).fill(Color(red: 0/255, green: 130/255, blue: 110/255)).frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1.2).fill(lcEasy).frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1.2).fill(lcOrange).frame(width: 6, height: 6)
                        Text("Active")
                            .font(.system(size: 7.5))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func chunkIntoWeeks(_ days: [LeetCodeDay]) -> [[LeetCodeDay]] {
        var weeks: [[LeetCodeDay]] = []
        var current: [LeetCodeDay] = []
        for day in days {
            current.append(day)
            if current.count == 7 {
                weeks.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            weeks.append(current)
        }
        return weeks
    }

    private func leetCodeHeatColor(for level: Int) -> Color {
        switch level {
        case 1: return Color(red: 20/255, green: 70/255, blue: 60/255)
        case 2: return Color(red: 0/255, green: 130/255, blue: 110/255)
        case 3: return lcEasy
        case 4: return lcOrange
        default: return ghDarkCell
        }
    }

    private func diffBadge(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 2.5) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(label):")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text("\(count)")
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(color)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }

    // MARK: - Overview Content View

    private func overviewContentView() -> some View {
        HStack(spacing: 12) {
            // Left Card: GitHub Pulse
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundColor(ghGreen4)
                    Text("GitHub Pulse")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if let gh = manager.githubData {
                        Text("\(gh.currentStreak)d streak")
                            .font(.system(size: 8.5, weight: .heavy))
                            .foregroundColor(ghGreen4)
                    }
                }

                if let gh = manager.githubData {
                    HStack(spacing: 6) {
                        metricBadge(icon: "calendar", value: "\(gh.totalContributionsYear)", label: "Contributions", tint: ghGreen4)
                        metricBadge(icon: "folder", value: "\(gh.publicRepos)", label: "Repos", tint: .blue)
                        metricBadge(icon: "person.2", value: "\(gh.followers)", label: "Followers", tint: .purple)
                    }

                    if let recent = gh.recentEvents.first {
                        HStack(spacing: 4) {
                            Circle().fill(ghGreen4).frame(width: 5, height: 5)
                            Text("Latest: \(recent.message)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                        }
                        .padding(.top, 2)
                    }
                } else {
                    Text("GitHub account not linked.")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.10).opacity(0.75))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
            )

            // Right Card: LeetCode Pulse
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "curlybraces")
                        .foregroundColor(lcOrange)
                    Text("LeetCode Pulse")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if let lc = manager.leetcodeData {
                        Text("\(lc.currentStreak)d streak")
                            .font(.system(size: 8.5, weight: .heavy))
                            .foregroundColor(lcOrange)
                    }
                }

                if let lc = manager.leetcodeData {
                    HStack(spacing: 6) {
                        metricBadge(icon: "checkmark.seal.fill", value: "\(lc.totalSolved)", label: "Solved", tint: lcOrange)
                        metricBadge(icon: "chart.line.uptrend.xyaxis", value: lc.ranking > 0 ? "#\(lc.ranking)" : "—", label: "Rank", tint: lcEasy)
                        metricBadge(icon: "flame.fill", value: "\(lc.currentStreak)d", label: "Streak", tint: Color(red: 1.0, green: 0.45, blue: 0.15))
                    }

                    HStack(spacing: 4) {
                        diffBadge(label: "E", count: lc.easySolved, color: lcEasy)
                        diffBadge(label: "M", count: lc.mediumSolved, color: lcMedium)
                        diffBadge(label: "H", count: lc.hardSolved, color: lcHard)
                    }
                    .padding(.top, 2)
                } else {
                    Text("LeetCode account not linked.")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.10).opacity(0.75))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
            )
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Reusable UI Helpers

    private func metricBadge(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 3.5) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 6.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }

    private func loadingView(platform: String) -> some View {
        VStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.7)
            Text("Loading \(platform) activity...")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func unlinkedView(platform: String, prompt: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: platform == "GitHub" ? "chevron.left.forwardslash.chevron.right" : "curlybraces")
                .font(.system(size: 22))
                .foregroundColor(platform == "GitHub" ? ghGreen4 : lcOrange)

            Text("Link your \(platform) account")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)

            Text(prompt)
                .font(.system(size: 8.5))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            Button(action: {
                SettingsWindowController.shared.showWindow()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 8))
                    Text("Open Orbito Settings")
                        .font(.system(size: 9, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            colors: platform == "GitHub"
                                ? [ghGreen3, ghGreen2]
                                : [lcOrange, Color(red: 230/255, green: 120/255, blue: 10/255)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
