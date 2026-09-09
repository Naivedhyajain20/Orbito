//
//  MacNotchModulesView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

// MARK: - Todo Module

struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isDone: Bool
    var tag: String
    var due: String
}

struct MacNotchTodoView: View {
    @State private var newTodoText: String = ""
    @State private var todos: [TodoItem] = [
        TodoItem(title: "Finish MacNotch design review", isDone: true, tag: "Work", due: "Today"),
        TodoItem(title: "Update API endpoint webhook docs", isDone: false, tag: "Dev", due: "14:00"),
        TodoItem(title: "Team Standup meeting", isDone: false, tag: "Meeting", due: "15:30"),
        TodoItem(title: "Submit App Store notarization bundle", isDone: false, tag: "Release", due: "Tomorrow")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "checklist")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Tasks & Reminders")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(todos.filter { !$0.isDone }.count) remaining")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                HStack(spacing: 4) {
                    TextField("Add task...", text: $newTodoText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(white: 0.16)))
                        .frame(width: 140)
                        .onSubmit {
                            if !newTodoText.isEmpty {
                                todos.append(TodoItem(title: newTodoText, isDone: false, tag: "General", due: "Today"))
                                newTodoText = ""
                            }
                        }

                    Button(action: {
                        if !newTodoText.isEmpty {
                            todos.append(TodoItem(title: newTodoText, isDone: false, tag: "General", due: "Today"))
                            newTodoText = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach($todos) { $todo in
                        HStack(spacing: 8) {
                            Button(action: { todo.isDone.toggle() }) {
                                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(todo.isDone ? .green : .white.opacity(0.4))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(todo.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(todo.isDone ? .white.opacity(0.4) : .white)
                                .strikethrough(todo.isDone)

                            Spacer()

                            Text(todo.tag)
                                .font(.system(size: 7, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue.opacity(0.2)))
                                .foregroundColor(.blue)

                            Text(todo.due)
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(white: 0.10).opacity(0.8))
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - Day Progress Module

struct MacNotchDayProgressView: View {
    private var progress: Double {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let startMinutes = 9 * 60   // 9:00 AM
        let endMinutes = 18 * 60    // 6:00 PM

        if currentMinutes < startMinutes { return 0.1 }
        if currentMinutes > endMinutes { return 1.0 }
        return Double(currentMinutes - startMinutes) / Double(endMinutes - startMinutes)
    }

    private var hoursRemaining: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let currentMinutes = hour * 60 + minute
        let endMinutes = 18 * 60
        let remainingMinutes = max(0, endMinutes - currentMinutes)
        let h = remainingMinutes / 60
        let m = remainingMinutes % 60
        return remainingMinutes <= 0 ? "0h 0m" : "\(h)h \(m)m"
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "hourglass")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    Text("Day Rhythm & Progress")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("9:00 AM — 6:00 PM")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Work Day Elapsed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(Int(progress * 100))% Completed")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.15)).frame(height: 6)
                            Capsule().fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * CGFloat(progress), height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                HStack(spacing: 20) {
                    metric(title: "Time Remaining", value: hoursRemaining)
                    metric(title: "Current Time", value: Date().formatted(date: .omitted, time: .shortened))
                    metric(title: "Next Transition", value: "Wrap up @ 18:00")
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
            )

            // Quote & Rest Card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text("Mindful Reminder")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("\"Eyes need rest too. Look at something 20 feet away for 20 seconds.\"")
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.white.opacity(0.85))
                    .italic()

                HStack {
                    Spacer()
                    Button("Take 2m Break") {}
                        .buttonStyle(.borderless)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
            .frame(width: 220)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Screen Time Module

struct MacNotchScreenTimeView: View {
    private var uptimeHours: Int {
        Int(ProcessInfo.processInfo.systemUptime) / 3600
    }
    private var uptimeMins: Int {
        (Int(ProcessInfo.processInfo.systemUptime) % 3600) / 60
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.indigo)
                    Text("System Uptime & Activity")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(uptimeHours)h \(uptimeMins)m Uptime")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.indigo)
                }

                VStack(spacing: 4) {
                    categoryBar(title: "Active Session", duration: "\(uptimeHours)h \(uptimeMins)m", color: .cyan, pct: 0.70)
                    categoryBar(title: "Background Services", duration: "Continuous", color: .purple, pct: 0.20)
                    categoryBar(title: "Idle State", duration: "Managed", color: .blue, pct: 0.10)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
            )

            // Top Apps Card
            VStack(alignment: .leading, spacing: 4) {
                Text("Frequently Used Apps")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                HStack {
                    appRow(name: "Xcode", time: "Active", icon: "hammer.fill")
                    appRow(name: "Terminal", time: "Active", icon: "terminal.fill")
                }
                HStack {
                    appRow(name: "Safari", time: "Active", icon: "safari.fill")
                    appRow(name: "Music", time: "Ready", icon: "music.note")
                }
            }
            .frame(width: 220)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func categoryBar(title: String, duration: String, color: Color, pct: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(duration)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                    Capsule().fill(color).frame(width: geo.size.width * pct, height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    private func appRow(name: String, time: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.8))
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white)
                Text(time)
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Health Module

struct MacNotchHealthView: View {
    @State private var waterCount: Int = 4
    @State private var isBreathing: Bool = false
    @State private var breathPhase: String = "Inhale (4s)"

    var body: some View {
        HStack(spacing: 16) {
            // Activity & Well-being
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.pink)
                    Text("Desk Health & Focus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("Posture OK")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.green)
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sitting Duration")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                        Text("52m")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                        Text("Break in 8m")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hydration")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                        HStack(spacing: 4) {
                            Text("\(waterCount)/8")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.cyan)
                            Button(action: { waterCount = min(waterCount + 1, 8) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.cyan)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Text("Glasses logged")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
            )

            // Box Breathing Quick Exercise
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "wind")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text("Box Breathing (4-4-4-4)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Regulate nervous system and reset focus instantly.")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.6))

                HStack {
                    Button(action: {
                        isBreathing.toggle()
                    }) {
                        Text(isBreathing ? "Pause" : "Start Exercise")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.pink.opacity(0.3)))
                            .foregroundColor(.pink)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                    if isBreathing {
                        Text(breathPhase)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: 220)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
