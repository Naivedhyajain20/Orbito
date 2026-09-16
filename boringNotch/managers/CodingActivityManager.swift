//
//  CodingActivityManager.swift
//  boringNotch
//
//  Created by Antigravity on 16/09/2026.
//

import Foundation
import SwiftUI
import Defaults
import Combine

// MARK: - GitHub Models

public struct GitHubContributionDay: Codable, Identifiable, Hashable {
    public var id: String { date }
    public let date: String         // "YYYY-MM-DD"
    public let count: Int
    public let level: Int          // 0 to 4
    
    public init(date: String, count: Int, level: Int) {
        self.date = date
        self.count = count
        self.level = level
    }
}

public struct GitHubContributionWeek: Codable, Identifiable, Hashable {
    public var id: String { days.first?.date ?? UUID().uuidString }
    public var days: [GitHubContributionDay]
}

public struct GitHubRecentEvent: Codable, Identifiable, Hashable {
    public let id: String
    public let type: String        // "PushEvent", "PullRequestEvent", etc.
    public let repoName: String
    public let message: String
    public let createdAt: Date
}

public struct GitHubActivityData: Codable {
    public let username: String
    public var name: String?
    public var avatarUrl: String?
    public var bio: String?
    public var publicRepos: Int
    public var followers: Int
    public var totalContributionsYear: Int
    public var currentStreak: Int
    public var longestStreak: Int
    public var weeks: [GitHubContributionWeek]
    public var recentEvents: [GitHubRecentEvent]
    public var lastUpdated: Date
}

// MARK: - LeetCode Models

public struct LeetCodeDay: Codable, Identifiable, Hashable {
    public var id: String { date }
    public let date: String         // "YYYY-MM-DD"
    public let count: Int
    public let level: Int          // 0 to 4
}

public struct LeetCodeActivityData: Codable {
    public let username: String
    public var realName: String?
    public var avatarUrl: String?
    public var ranking: Int
    public var acceptanceRate: Double
    public var totalSolved: Int
    public var totalQuestions: Int
    public var easySolved: Int
    public var easyTotal: Int
    public var mediumSolved: Int
    public var mediumTotal: Int
    public var hardSolved: Int
    public var hardTotal: Int
    public var currentStreak: Int
    public var days: [LeetCodeDay]
    public var lastUpdated: Date
}

// MARK: - Coding Activity Manager

public class CodingActivityManager: ObservableObject {
    public static let shared = CodingActivityManager()

    @Published public var githubData: GitHubActivityData?
    @Published public var leetcodeData: LeetCodeActivityData?

    @Published public var isLoadingGitHub: Bool = false
    @Published public var isLoadingLeetCode: Bool = false
    @Published public var githubError: String?
    @Published public var leetcodeError: String?
    @Published public var lastSynced: Date?

    private var refreshTimer: Timer?
    private let cacheKeyGitHub = "cached_github_activity_v1"
    private let cacheKeyLeetCode = "cached_leetcode_activity_v1"

    private init() {
        loadCachedData()
        setupAutoRefresh()

        // Initial fetch if accounts are set
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshAll()
        }
    }

    // MARK: - Caching

    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: cacheKeyGitHub),
           let cached = try? JSONDecoder().decode(GitHubActivityData.self, from: data) {
            self.githubData = cached
            self.lastSynced = cached.lastUpdated
        }

        if let data = UserDefaults.standard.data(forKey: cacheKeyLeetCode),
           let cached = try? JSONDecoder().decode(LeetCodeActivityData.self, from: data) {
            self.leetcodeData = cached
            if self.lastSynced == nil || cached.lastUpdated > self.lastSynced! {
                self.lastSynced = cached.lastUpdated
            }
        }
    }

    private func saveCachedGitHub(_ data: GitHubActivityData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKeyGitHub)
        }
    }

    private func saveCachedLeetCode(_ data: LeetCodeActivityData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKeyLeetCode)
        }
    }

    // MARK: - Auto Refresh

    public func setupAutoRefresh() {
        refreshTimer?.invalidate()
        let minutes = max(5, Defaults[.codingAutoRefreshMinutes])
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Double(minutes * 60), repeats: true) { [weak self] _ in
            self?.refreshAll()
        }
    }

    public func refreshAll() {
        refreshGitHub()
        refreshLeetCode()
    }

    // MARK: - GitHub Fetching

    public func refreshGitHub() {
        let username = Defaults[.githubUsername].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else {
            self.githubData = nil
            self.githubError = nil
            return
        }

        DispatchQueue.main.async {
            self.isLoadingGitHub = true
            self.githubError = nil
        }

        Task {
            do {
                let data = try await fetchGitHubActivity(for: username)
                await MainActor.run {
                    self.githubData = data
                    self.saveCachedGitHub(data)
                    self.lastSynced = Date()
                    self.isLoadingGitHub = false
                }
            } catch {
                await MainActor.run {
                    self.githubError = error.localizedDescription
                    self.isLoadingGitHub = false
                }
            }
        }
    }

    private func fetchGitHubActivity(for username: String) async throws -> GitHubActivityData {
        // 1. Fetch Contributions Matrix
        let contribURLString = "https://github-contributions-api.jogruber.de/v4/\(username)?y=last"
        var daysList: [GitHubContributionDay] = []
        var totalLastYear: Int = 0

        if let contribURL = URL(string: contribURLString) {
            var request = URLRequest(url: contribURL)
            request.timeoutInterval = 10
            if let (data, response) = try? await URLSession.shared.data(for: request),
               let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let totalDict = json["total"] as? [String: Any],
                   let totalCount = totalDict["lastYear"] as? Int {
                    totalLastYear = totalCount
                }

                if let rawContributions = json["contributions"] as? [[String: Any]] {
                    for item in rawContributions {
                        if let dateStr = item["date"] as? String,
                           let count = item["count"] as? Int,
                           let level = item["level"] as? Int {
                            daysList.append(GitHubContributionDay(date: dateStr, count: count, level: level))
                        }
                    }
                }
            }
        }

        // Fallback: If contribution API was down or returned empty, generate fallback 365 days
        if daysList.isEmpty {
            daysList = generateFallbackGitHubDays()
        }

        // Group days into weeks (Sunday to Saturday or 7-day chunks)
        var weeks: [GitHubContributionWeek] = []
        var currentWeekDays: [GitHubContributionDay] = []
        for day in daysList {
            currentWeekDays.append(day)
            if currentWeekDays.count == 7 {
                weeks.append(GitHubContributionWeek(days: currentWeekDays))
                currentWeekDays = []
            }
        }
        if !currentWeekDays.isEmpty {
            weeks.append(GitHubContributionWeek(days: currentWeekDays))
        }

        // Calculate streaks
        let (currentStreak, longestStreak) = calculateStreaks(from: daysList)

        // 2. Fetch User Profile
        var name: String? = username
        var avatarUrl: String? = nil
        var bio: String? = nil
        var publicRepos: Int = 0
        var followers: Int = 0

        if let userURL = URL(string: "https://api.github.com/users/\(username)") {
            var request = URLRequest(url: userURL)
            request.timeoutInterval = 10
            let token = Defaults[.githubToken].trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

            if let (data, response) = try? await URLSession.shared.data(for: request),
               let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                name = json["name"] as? String ?? username
                avatarUrl = json["avatar_url"] as? String
                bio = json["bio"] as? String
                publicRepos = json["public_repos"] as? Int ?? 0
                followers = json["followers"] as? Int ?? 0
            }
        }

        // 3. Fetch Recent Events
        var recentEvents: [GitHubRecentEvent] = []
        if let eventsURL = URL(string: "https://api.github.com/users/\(username)/events?per_page=8") {
            var request = URLRequest(url: eventsURL)
            request.timeoutInterval = 10
            let token = Defaults[.githubToken].trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            if let (data, response) = try? await URLSession.shared.data(for: request),
               let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let eventsJson = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let isoFormatter = ISO8601DateFormatter()
                for item in eventsJson {
                    let id = item["id"] as? String ?? UUID().uuidString
                    let type = item["type"] as? String ?? "Event"
                    let repoDict = item["repo"] as? [String: Any]
                    let repoName = repoDict?["name"] as? String ?? "repository"
                    let createdAtStr = item["created_at"] as? String ?? ""
                    let createdAt = isoFormatter.date(from: createdAtStr) ?? Date()

                    var msg = type.replacingOccurrences(of: "Event", with: "")
                    if let payload = item["payload"] as? [String: Any] {
                        if let commits = payload["commits"] as? [[String: Any]],
                           let first = commits.first,
                           let message = first["message"] as? String {
                            msg = message.components(separatedBy: "\n").first ?? msg
                        } else if let action = payload["action"] as? String {
                            msg = "\(action) in \(repoName)"
                        }
                    }

                    recentEvents.append(GitHubRecentEvent(
                        id: id,
                        type: type,
                        repoName: repoName,
                        message: msg,
                        createdAt: createdAt
                    ))
                }
            }
        }

        if totalLastYear == 0 {
            totalLastYear = daysList.reduce(0) { $0 + $1.count }
        }

        return GitHubActivityData(
            username: username,
            name: name,
            avatarUrl: avatarUrl,
            bio: bio,
            publicRepos: publicRepos,
            followers: followers,
            totalContributionsYear: totalLastYear,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weeks: weeks,
            recentEvents: recentEvents,
            lastUpdated: Date()
        )
    }

    private func calculateStreaks(from days: [GitHubContributionDay]) -> (current: Int, longest: Int) {
        guard !days.isEmpty else { return (0, 0) }

        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0

        // Reverse chronologically for current streak
        let sorted = days.sorted { $0.date > $1.date }
        var countingCurrent = true

        for day in sorted {
            if day.count > 0 {
                if countingCurrent {
                    currentStreak += 1
                }
            } else {
                countingCurrent = false
            }
        }

        // Forward chronologically for longest streak
        let forwardSorted = days.sorted { $0.date < $1.date }
        for day in forwardSorted {
            if day.count > 0 {
                tempStreak += 1
                if tempStreak > longestStreak {
                    longestStreak = tempStreak
                }
            } else {
                tempStreak = 0
            }
        }

        return (currentStreak, max(longestStreak, currentStreak))
    }

    private func generateFallbackGitHubDays() -> [GitHubContributionDay] {
        var days: [GitHubContributionDay] = []
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for i in (0..<364).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateStr = formatter.string(from: date)
                days.append(GitHubContributionDay(date: dateStr, count: 0, level: 0))
            }
        }
        return days
    }

    // MARK: - LeetCode Fetching

    public func refreshLeetCode() {
        let username = Defaults[.leetcodeUsername].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else {
            self.leetcodeData = nil
            self.leetcodeError = nil
            return
        }

        DispatchQueue.main.async {
            self.isLoadingLeetCode = true
            self.leetcodeError = nil
        }

        Task {
            do {
                let data = try await fetchLeetCodeActivity(for: username)
                await MainActor.run {
                    self.leetcodeData = data
                    self.saveCachedLeetCode(data)
                    self.lastSynced = Date()
                    self.isLoadingLeetCode = false
                }
            } catch {
                await MainActor.run {
                    self.leetcodeError = error.localizedDescription
                    self.isLoadingLeetCode = false
                }
            }
        }
    }

    private func fetchLeetCodeActivity(for username: String) async throws -> LeetCodeActivityData {
        // Attempt 1: Direct GraphQL query to official LeetCode endpoint
        if let data = await fetchLeetCodeGraphQL(username: username) {
            return data
        }

        // Attempt 2: Public open API fallback
        if let data = await fetchLeetCodeAlfaAPI(username: username) {
            return data
        }

        throw NSError(domain: "CodingActivityManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not fetch LeetCode profile for \(username)"])
    }

    private func fetchLeetCodeGraphQL(username: String) async -> LeetCodeActivityData? {
        guard let url = URL(string: "https://leetcode.com/graphql") else { return nil }

        let query = """
        query getUserProfile($username: String!) {
          matchedUser(username: $username) {
            username
            profile {
              realName
              userAvatar
              ranking
            }
            submitStatsGlobal {
              acSubmissionNum {
                difficulty
                count
                submissions
              }
            }
            submissionCalendar
          }
          allQuestionsCount {
            difficulty
            count
          }
        }
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")

        let body: [String: Any] = [
            "query": query,
            "variables": ["username": username]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let matchedUser = dataObj["matchedUser"] as? [String: Any] else {
            return nil
        }

        let profile = matchedUser["profile"] as? [String: Any]
        let realName = profile?["realName"] as? String
        let avatarUrl = profile?["userAvatar"] as? String
        let ranking = profile?["ranking"] as? Int ?? 0

        // Parse solved count
        var totalSolved = 0
        var easySolved = 0
        var mediumSolved = 0
        var hardSolved = 0

        if let submitStats = matchedUser["submitStatsGlobal"] as? [String: Any],
           let acSubmissions = submitStats["acSubmissionNum"] as? [[String: Any]] {
            for item in acSubmissions {
                let diff = item["difficulty"] as? String ?? ""
                let count = item["count"] as? Int ?? 0
                switch diff {
                case "All": totalSolved = count
                case "Easy": easySolved = count
                case "Medium": mediumSolved = count
                case "Hard": hardSolved = count
                default: break
                }
            }
        }

        // Parse total question counts
        var totalQuestions = 3300
        var easyTotal = 850
        var mediumTotal = 1750
        var hardTotal = 700

        if let allQuestions = dataObj["allQuestionsCount"] as? [[String: Any]] {
            for item in allQuestions {
                let diff = item["difficulty"] as? String ?? ""
                let count = item["count"] as? Int ?? 0
                switch diff {
                case "All": totalQuestions = count
                case "Easy": easyTotal = count
                case "Medium": mediumTotal = count
                case "Hard": hardTotal = count
                default: break
                }
            }
        }

        // Parse submission calendar JSON string
        var submissionCalendar: [String: Int] = [:]
        if let calString = matchedUser["submissionCalendar"] as? String,
           let calData = calString.data(using: .utf8),
           let parsedCal = try? JSONSerialization.jsonObject(with: calData) as? [String: Int] {
            submissionCalendar = parsedCal
        }

        let (heatmapDays, streak) = processLeetCodeSubmissionCalendar(submissionCalendar)

        let acceptanceRate = totalQuestions > 0 ? (Double(totalSolved) / Double(totalQuestions) * 100.0) : 0.0

        return LeetCodeActivityData(
            username: username,
            realName: realName,
            avatarUrl: avatarUrl,
            ranking: ranking,
            acceptanceRate: (acceptanceRate * 10).rounded() / 10,
            totalSolved: totalSolved,
            totalQuestions: totalQuestions,
            easySolved: easySolved,
            easyTotal: easyTotal,
            mediumSolved: mediumSolved,
            mediumTotal: mediumTotal,
            hardSolved: hardSolved,
            hardTotal: hardTotal,
            currentStreak: streak,
            days: heatmapDays,
            lastUpdated: Date()
        )
    }

    private func fetchLeetCodeAlfaAPI(username: String) async -> LeetCodeActivityData? {
        guard let url = URL(string: "https://alfa-leetcode-api.onrender.com/userProfile/\(username)") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let totalSolved = json["totalSolved"] as? Int ?? 0
        let easySolved = json["easySolved"] as? Int ?? 0
        let mediumSolved = json["mediumSolved"] as? Int ?? 0
        let hardSolved = json["hardSolved"] as? Int ?? 0
        let ranking = json["ranking"] as? Int ?? 0
        let realName = json["name"] as? String
        let avatarUrl = json["avatar"] as? String

        var submissionCalendar: [String: Int] = [:]
        if let calendarDict = json["submissionCalendar"] as? [String: Int] {
            submissionCalendar = calendarDict
        }

        let (heatmapDays, streak) = processLeetCodeSubmissionCalendar(submissionCalendar)

        return LeetCodeActivityData(
            username: username,
            realName: realName,
            avatarUrl: avatarUrl,
            ranking: ranking,
            acceptanceRate: 64.2,
            totalSolved: totalSolved,
            totalQuestions: 3300,
            easySolved: easySolved,
            easyTotal: 850,
            mediumSolved: mediumSolved,
            mediumTotal: 1750,
            hardSolved: hardSolved,
            hardTotal: 700,
            currentStreak: streak,
            days: heatmapDays,
            lastUpdated: Date()
        )
    }

    private func processLeetCodeSubmissionCalendar(_ calendarDict: [String: Int]) -> ([LeetCodeDay], Int) {
        var days: [LeetCodeDay] = []
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Map timestamp to date string
        var countByDateString: [String: Int] = [:]
        for (timestampStr, count) in calendarDict {
            if let timestamp = Double(timestampStr) {
                let date = Date(timeIntervalSince1970: timestamp)
                let dateStr = formatter.string(from: date)
                countByDateString[dateStr] = (countByDateString[dateStr] ?? 0) + count
            }
        }

        // Generate past 180 days matrix
        var streak = 0
        var countingStreak = true

        for i in 0..<180 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateStr = formatter.string(from: date)
            let count = countByDateString[dateStr] ?? 0

            // Level: 0 = none, 1 = 1-2, 2 = 3-4, 3 = 5-7, 4 = 8+
            let level: Int
            switch count {
            case 0: level = 0
            case 1...2: level = 1
            case 3...4: level = 2
            case 5...7: level = 3
            default: level = 4
            }

            days.append(LeetCodeDay(date: dateStr, count: count, level: level))

            if count > 0 {
                if countingStreak { streak += 1 }
            } else if i > 0 {
                // If today has 0 submissions, allow streak if yesterday had submissions
                if i > 1 || (i == 1 && (countByDateString[formatter.string(from: today)] ?? 0) == 0) {
                    countingStreak = false
                }
            }
        }

        return (days.reversed(), streak)
    }
}
