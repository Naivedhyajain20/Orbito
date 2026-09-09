//
//  CalculatorView.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import SwiftUI
import AppKit

// MARK: - Expression Parser

struct ExpressionParser {
    /// Evaluates a math expression string. Returns nil on invalid input.
    static func evaluate(_ input: String) -> Double? {
        // Unit conversion check first
        if let result = UnitConverter.convert(input) { return result }

        // Sanitize: replace × ÷ with standard operators
        var expr = input
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "^", with: "**")

        // Use NSExpression for standard math
        guard !expr.isEmpty else { return nil }
        // NSExpression doesn't support **, so handle power separately
        expr = expr.replacingOccurrences(of: "**", with: "^")

        let mathExpression = NSExpression(format: expr)
        guard let result = mathExpression.expressionValue(with: nil, context: nil) as? Double else { return nil }
        guard result.isFinite else { return nil }
        return result
    }

    static func format(_ value: Double) -> String {
        // Show integer if no fractional part
        if value.truncatingRemainder(dividingBy: 1) == 0 && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        // Up to 10 significant digits
        let formatted = String(format: "%.10g", value)
        return formatted
    }
}

// MARK: - Unit Converter

struct UnitConverter {
    struct Rule {
        let pattern: String
        let convert: (Double) -> Double
        let toUnit: String
    }

    static func convert(_ input: String) -> Double? {
        let text = input.lowercased().trimmingCharacters(in: .whitespaces)
        let rules: [(regex: String, convert: (Double, String) -> Double?)] = [
            // Weight
            ("([\\d.]+)\\s*kg\\s*to\\s*lb", { v, _ in v * 2.20462 }),
            ("([\\d.]+)\\s*lb\\s*to\\s*kg", { v, _ in v / 2.20462 }),
            ("([\\d.]+)\\s*g\\s*to\\s*oz", { v, _ in v * 0.035274 }),
            ("([\\d.]+)\\s*oz\\s*to\\s*g", { v, _ in v / 0.035274 }),
            // Length
            ("([\\d.]+)\\s*km\\s*to\\s*miles?", { v, _ in v * 0.621371 }),
            ("([\\d.]+)\\s*miles?\\s*to\\s*km", { v, _ in v / 0.621371 }),
            ("([\\d.]+)\\s*m\\s*to\\s*ft", { v, _ in v * 3.28084 }),
            ("([\\d.]+)\\s*ft\\s*to\\s*m", { v, _ in v / 3.28084 }),
            ("([\\d.]+)\\s*cm\\s*to\\s*in", { v, _ in v / 2.54 }),
            ("([\\d.]+)\\s*in\\s*to\\s*cm", { v, _ in v * 2.54 }),
            // Temperature
            ("([\\d.]+)\\s*c\\s*to\\s*f", { v, _ in v * 9/5 + 32 }),
            ("([\\d.]+)\\s*f\\s*to\\s*c", { v, _ in (v - 32) * 5/9 }),
            // Speed
            ("([\\d.]+)\\s*kmh\\s*to\\s*mph", { v, _ in v * 0.621371 }),
            ("([\\d.]+)\\s*mph\\s*to\\s*kmh", { v, _ in v / 0.621371 }),
        ]

        for (pattern, fn) in rules {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let value = Double(text[range]) {
                return fn(value, "")
            }
        }
        return nil
    }
}

// MARK: - History Entry

struct CalculatorEntry: Identifiable {
    let id = UUID()
    let expression: String
    let result: String
}

// MARK: - Calculator View

struct CalculatorView: View {
    @State private var input: String = ""
    @State private var result: String = ""
    @State private var history: [CalculatorEntry] = []
    @State private var showingError: Bool = false
    @State private var unitLabel: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Input + result display
            VStack(alignment: .trailing, spacing: 4) {
                TextField("Enter expression…", text: $input)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($inputFocused)
                    .onSubmit { calculate() }
                    .onChange(of: input) { _, newVal in liveEvaluate(newVal) }

                HStack(spacing: 4) {
                    if !unitLabel.isEmpty {
                        Text(unitLabel)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    Text(result.isEmpty ? "0" : result)
                        .font(.system(size: 26, weight: .light, design: .monospaced))
                        .foregroundColor(showingError ? .red : .accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.07))
            .cornerRadius(10)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .onTapGesture { inputFocused = true }

            // Buttons
            VStack(spacing: 4) {
                let rows: [[String]] = [
                    ["C", "(", ")", "÷"],
                    ["7", "8", "9", "×"],
                    ["4", "5", "6", "−"],
                    ["1", "2", "3", "+"],
                    ["⌫", "0", ".", "="]
                ]
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(row, id: \.self) { key in
                            CalcButton(label: key) { handleKey(key) }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // History
            if !history.isEmpty {
                Divider().opacity(0.25).padding(.horizontal, 12).padding(.top, 6)
                ScrollView {
                    LazyVStack(alignment: .trailing, spacing: 4) {
                        ForEach(history.prefix(5)) { entry in
                            Button {
                                input = entry.result
                                liveEvaluate(entry.result)
                            } label: {
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(entry.expression)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("= \(entry.result)")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 80)
            }

            Spacer(minLength: 4)
        }
        .onAppear { inputFocused = true }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "C":
            input = ""
            result = ""
            showingError = false
            unitLabel = ""
        case "⌫":
            if !input.isEmpty { input.removeLast() }
        case "=":
            calculate()
        case "−":
            input += "-"
        case "×":
            input += "×"
        case "÷":
            input += "÷"
        default:
            input += key
        }
        liveEvaluate(input)
    }

    private func liveEvaluate(_ expr: String) {
        guard !expr.isEmpty else { result = ""; unitLabel = ""; return }

        // Check if it's a unit conversion
        if UnitConverter.convert(expr) != nil {
            unitLabel = "→"
        } else {
            unitLabel = ""
        }

        if let val = ExpressionParser.evaluate(expr) {
            result = ExpressionParser.format(val)
            showingError = false
        } else {
            showingError = false // Don't show error while typing
        }
    }

    private func calculate() {
        guard !input.isEmpty else { return }
        if let val = ExpressionParser.evaluate(input) {
            let res = ExpressionParser.format(val)
            let entry = CalculatorEntry(expression: input, result: res)
            history.insert(entry, at: 0)
            if history.count > 10 { history.removeLast() }

            // Copy to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(res, forType: .string)

            input = res
            result = res
            showingError = false
        } else {
            showingError = true
            result = "Error"
        }
    }
}

// MARK: - Calculator Button

struct CalcButton: View {
    let label: String
    let action: () -> Void

    private var isOperator: Bool { ["÷", "×", "+", "−", "="].contains(label) }
    private var isClear: Bool { label == "C" }
    private var isDelete: Bool { label == "⌫" }

    private var bgColor: Color {
        if label == "=" { return .accentColor }
        if isOperator { return Color.orange.opacity(0.25) }
        if isClear { return Color.red.opacity(0.2) }
        return Color.white.opacity(0.1)
    }

    private var fgColor: Color {
        if label == "=" { return .white }
        if isOperator { return .orange }
        if isClear { return .red }
        return .white
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(fgColor)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(bgColor)
                .cornerRadius(7)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
