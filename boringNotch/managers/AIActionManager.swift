//
//  AIActionManager.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import AppKit
import Foundation

enum AIAction: String, CaseIterable, Identifiable {
    case summarize    = "Summarize"
    case rewrite      = "Rewrite"
    case translate    = "Translate to English"
    case fixGrammar   = "Fix Grammar"
    case makeFormal   = "Make Formal"
    case makeCasual   = "Make Casual"
    case bulletPoints = "To Bullet Points"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .summarize:    return "text.magnifyingglass"
        case .rewrite:      return "pencil.and.outline"
        case .translate:    return "globe"
        case .fixGrammar:   return "checkmark.circle"
        case .makeFormal:   return "briefcase"
        case .makeCasual:   return "bubble.left"
        case .bulletPoints: return "list.bullet"
        }
    }
}

enum AIProvider: String, CaseIterable {
    case openAI = "OpenAI"
    case gemini = "Gemini"
}

@MainActor
final class AIActionManager: ObservableObject {
    static let shared = AIActionManager()

    @Published var selectedText: String = ""
    @Published var result: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Settings — stored in UserDefaults
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "aiApiKey") }
    }
    @Published var provider: AIProvider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: "aiProvider") }
    }

    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "aiApiKey") ?? ""
        let savedProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? AIProvider.openAI.rawValue
        self.provider = AIProvider(rawValue: savedProvider) ?? .openAI
    }

    /// Reads selected text from the frontmost app via Accessibility API
    func readSelectedText() -> String? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else { return nil }
        let element = focusedElement as! AXUIElement
        var selectedText: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
              let text = selectedText as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }

    func run(_ action: AIAction, on text: String) {
        guard !text.isEmpty else {
            error = "No text to process"
            return
        }
        guard !apiKey.isEmpty else {
            // Fallback: simple on-device rules for some actions
            result = onDeviceFallback(action: action, text: text) ?? ""
            if result.isEmpty { error = "Please add an API key in Settings → AI Actions" }
            return
        }

        isLoading = true
        error = nil
        result = ""

        Task {
            do {
                let response = try await callAPI(action: action, text: text)
                result = response
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - On-device fallback (no API key needed)

    private func onDeviceFallback(action: AIAction, text: String) -> String? {
        switch action {
        case .bulletPoints:
            // Split into sentences and bullet them
            let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return sentences.map { "• \($0)." }.joined(separator: "\n")

        case .makeFormal:
            return text
                .replacingOccurrences(of: "gonna", with: "going to")
                .replacingOccurrences(of: "wanna", with: "want to")
                .replacingOccurrences(of: "gotta", with: "have to")
                .replacingOccurrences(of: "kinda", with: "kind of")
                .replacingOccurrences(of: " u ", with: " you ")
                .replacingOccurrences(of: "lol", with: "")
                .replacingOccurrences(of: "btw", with: "by the way")

        default:
            return nil
        }
    }

    // MARK: - API call

    private func callAPI(action: AIAction, text: String) async throws -> String {
        let prompt = buildPrompt(action: action, text: text)

        switch provider {
        case .openAI:
            return try await callOpenAI(prompt: prompt)
        case .gemini:
            return try await callGemini(prompt: prompt)
        }
    }

    private func buildPrompt(action: AIAction, text: String) -> String {
        switch action {
        case .summarize:
            return "Summarize the following text concisely in 2-3 sentences:\n\n\(text)"
        case .rewrite:
            return "Rewrite the following text to be clearer and more engaging, keeping the same meaning:\n\n\(text)"
        case .translate:
            return "Translate the following text to English. Only return the translation:\n\n\(text)"
        case .fixGrammar:
            return "Fix any grammar and spelling errors in the following text. Only return the corrected text:\n\n\(text)"
        case .makeFormal:
            return "Rewrite the following text in a formal, professional tone:\n\n\(text)"
        case .makeCasual:
            return "Rewrite the following text in a casual, friendly tone:\n\n\(text)"
        case .bulletPoints:
            return "Convert the following text into a concise bulleted list:\n\n\(text)"
        }
    }

    private func callOpenAI(prompt: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 500
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI response"])
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func callGemini(prompt: String) async throws -> String {
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "AI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini response"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
