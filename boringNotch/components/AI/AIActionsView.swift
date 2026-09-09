//
//  AIActionsView.swift
//  boringNotch
//
//  Created by boringNotch on 07/09/2026.
//

import SwiftUI

struct AIActionsView: View {
    @StateObject private var manager = AIActionManager.shared
    @State private var customText: String = ""
    @State private var useCustomText: Bool = false

    var textToProcess: String {
        useCustomText ? customText : manager.selectedText
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with text source toggle
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
                Text("AI Quick Actions")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    manager.selectedText = manager.readSelectedText() ?? ""
                } label: {
                    Label("Grab Selection", systemImage: "cursorarrow.rays")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Input text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(useCustomText ? "Custom text:" : "Selected text:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(useCustomText ? "Use selection" : "Type manually") {
                        useCustomText.toggle()
                    }
                    .font(.caption2)
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.blue)
                }

                if useCustomText {
                    TextEditor(text: $customText)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                        .frame(height: 50)
                } else {
                    Text(manager.selectedText.isEmpty ? "No text selected — click 'Grab Selection'" : manager.selectedText)
                        .font(.system(size: 11))
                        .foregroundColor(manager.selectedText.isEmpty ? .gray : .white.opacity(0.9))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 12)

            Divider().opacity(0.2).padding(.horizontal, 12).padding(.vertical, 6)

            // Action buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(AIAction.allCases) { action in
                        AIActionButton(action: action, isLoading: manager.isLoading) {
                            manager.run(action, on: textToProcess)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            // Result
            if manager.isLoading {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("Processing…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
            } else if let err = manager.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
            } else if !manager.result.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Result")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(manager.result, forType: .string)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    ScrollView {
                        Text(manager.result)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 80)
                    .padding(8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }

            Spacer(minLength: 8)
        }
    }
}

struct AIActionButton: View {
    let action: AIAction
    let isLoading: Bool
    let onTap: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Image(systemName: action.icon)
                    .font(.system(size: 12))
                Text(action.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(hovering ? .white : .purple)
            .frame(width: 60, height: 44)
            .background(hovering ? Color.purple.opacity(0.4) : Color.purple.opacity(0.12))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.12), value: hovering)
        .disabled(isLoading)
        .opacity(isLoading ? 0.5 : 1)
    }
}
