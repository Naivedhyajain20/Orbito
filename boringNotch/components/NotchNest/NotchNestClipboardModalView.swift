import SwiftUI
import AppKit

struct NotchNestClipboardModalView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @State private var searchText: String = ""
    @State private var copiedItemId: UUID? = nil

    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        } else {
            return clipboardManager.items.filter { ($0.text ?? "").localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.40))

                    TextField("Search clipboard...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(.white)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.13))
                )

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        clipboardManager.clearAll()
                    }
                }) {
                    Text("Clear Clipboard History")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.70))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Clear entire clipboard history")
            }
            .padding(.horizontal, 12)
            .padding(.top, 2)

            if filteredItems.isEmpty {
                VStack(spacing: 4) {
                    Spacer(minLength: 0)
                    Text(searchText.isEmpty ? "No clipboard history yet" : "No matches found")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(filteredItems.prefix(20))) { item in
                            clipboardCard(item)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func clipboardCard(_ item: ClipboardItem) -> some View {
        let isRecentlyCopied = copiedItemId == item.id
        let isFirst = filteredItems.first?.id == item.id

        Button(action: {
            clipboardManager.copy(item)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                copiedItemId = item.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedItemId == item.id {
                    copiedItemId = nil
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.preview)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer(minLength: 0)

                HStack {
                    if isRecentlyCopied {
                        Text("Copied!")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                    } else {
                        Text(item.timeAgo)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }

                    Spacer(minLength: 0)

                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                }
            }
            .padding(9)
            .frame(width: 142, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isRecentlyCopied
                            ? Color(red: 0.12, green: 0.22, blue: 0.35).opacity(0.95)
                            : (isFirst ? Color(red: 0.08, green: 0.14, blue: 0.22).opacity(0.95) : Color(white: 0.12).opacity(0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isRecentlyCopied
                                    ? Color(red: 0.35, green: 0.65, blue: 1.0)
                                    : (isFirst ? Color(red: 0.25, green: 0.45, blue: 0.75).opacity(0.70) : Color.white.opacity(0.06)),
                                lineWidth: (isRecentlyCopied || isFirst) ? 1.2 : 0.8
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Copy") { clipboardManager.copy(item) }
            Button(item.isPinned ? "Unpin" : "Pin") { clipboardManager.togglePin(item) }
            Divider()
            Button("Delete", role: .destructive) { clipboardManager.delete(item) }
        }
    }
}
