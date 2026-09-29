//
//  QuickDropZonesView.swift
//  boringNotch
//
//  Dual Quick Drop Zones (AirDrop & Pocket) inspired by LaunchMe notch.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct QuickDropZonesView: View {
    @EnvironmentObject var vm: BoringViewModel
    @State private var isAirDropTargeted: Bool = false
    @State private var isPocketTargeted: Bool = false
    @State private var airDropSuccess: Bool = false
    @State private var pocketSuccess: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // AirDrop Zone
            dropZoneButton(
                title: "AirDrop",
                subtitle: airDropSuccess ? "Sharing..." : "Drop to share",
                icon: "airdrop",
                accentColor: Color.blue,
                isTargeted: isAirDropTargeted
            )
            .onDrop(of: [.fileURL, .url, .data], isTargeted: $isAirDropTargeted) { providers in
                handleAirDrop(providers: providers)
            }

            // Pocket Zone (Shelf)
            dropZoneButton(
                title: "Pocket",
                subtitle: pocketSuccess ? "Saved!" : "Drop to shelf",
                icon: "archivebox.fill",
                accentColor: Color.orange,
                isTargeted: isPocketTargeted
            )
            .onDrop(of: [.fileURL, .url, .utf8PlainText, .plainText, .data], isTargeted: $isPocketTargeted) { providers in
                handlePocket(providers: providers)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func dropZoneButton(
        title: String,
        subtitle: String,
        icon: String,
        accentColor: Color,
        isTargeted: Bool
    ) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isTargeted ? accentColor.opacity(0.3) : Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isTargeted ? accentColor : .white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isTargeted ? accentColor.opacity(0.15) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            isTargeted ? accentColor.opacity(0.6) : Color.white.opacity(0.1),
                            lineWidth: isTargeted ? 1.5 : 0.8
                        )
                )
        )
        .scaleEffect(isTargeted ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
    }

    private func handleAirDrop(providers: [NSItemProvider]) -> Bool {
        var urlsToShare: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urlsToShare.append(url)
                    } else if let url = item as? URL {
                        urlsToShare.append(url)
                    }
                }
            }
        }

        group.notify(queue: .main) {
            guard !urlsToShare.isEmpty else { return }
            withAnimation { airDropSuccess = true }
            if let service = NSSharingService(named: .sendViaAirDrop) {
                if service.canPerform(withItems: urlsToShare) {
                    service.perform(withItems: urlsToShare)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { airDropSuccess = false }
            }
        }

        return true
    }

    private func handlePocket(providers: [NSItemProvider]) -> Bool {
        withAnimation { pocketSuccess = true }
        vm.dropEvent = true
        ShelfStateViewModel.shared.load(providers)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { pocketSuccess = false }
        }
        return true
    }
}
