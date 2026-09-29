//
//  ImageCropPreviewView.swift
//  boringNotch
//
//  Preview & crop sheet shown after selecting an image for wallpaper or companion widget.
//

import SwiftUI
import AppKit

// MARK: - App Support Directory Helpers

func getAppSupportSubfolder(_ name: String) -> URL {
    let fm = FileManager.default
    let support = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let dir = (support ?? fm.temporaryDirectory)
        .appendingPathComponent("boringNotch", isDirectory: true)
        .appendingPathComponent(name, isDirectory: true)
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

func saveCroppedImageToAppSupport(_ image: NSImage, originalPath: String, subfolder: String = "wallpapers") -> String? {
    let dir = getAppSupportSubfolder(subfolder)
    let originalURL = URL(fileURLWithPath: originalPath)
    let baseName = originalURL.deletingPathExtension().lastPathComponent
    let filename = "\(baseName)_cropped_\(Int(Date().timeIntervalSince1970)).png"
    let targetURL = dir.appendingPathComponent(filename)

    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        return nil
    }

    do {
        try data.write(to: targetURL)
        return targetURL.path
    } catch {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        return tempURL.path
    }
}

func copyMediaToAppSupport(sourceURL: URL, subfolder: String) -> String? {
    let dir = getAppSupportSubfolder(subfolder)
    let ext = sourceURL.pathExtension
    let baseName = sourceURL.deletingPathExtension().lastPathComponent
    let filename = "\(baseName)_\(Int(Date().timeIntervalSince1970)).\(ext)"
    let targetURL = dir.appendingPathComponent(filename)

    let _ = sourceURL.startAccessingSecurityScopedResource()
    defer { sourceURL.stopAccessingSecurityScopedResource() }

    do {
        let data = try Data(contentsOf: sourceURL)
        try data.write(to: targetURL)
        return targetURL.path
    } catch {
        do {
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
            return targetURL.path
        } catch {
            return sourceURL.path
        }
    }
}

// MARK: - Image Crop Preview Sheet

struct ImageCropPreviewSheet: View {
    let sourceImage: NSImage
    let targetAspectRatio: CGFloat // width / height (e.g. 3.2 for notch wallpaper, 1.0 for pet widget)
    var title: String = "Preview & Adjust"
    let onConfirm: (NSImage) -> Void
    let onCancel: () -> Void

    @State private var cropOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0

    private let previewBoxWidth: CGFloat = 460
    private let previewBoxHeight: CGFloat = 280

    // The visible crop region dimensions inside the preview
    private var cropFrameSize: CGSize {
        let maxW: CGFloat = previewBoxWidth - 40
        let maxH: CGFloat = previewBoxHeight - 40
        if targetAspectRatio >= 1.0 {
            var w = maxW
            var h = w / targetAspectRatio
            if h > maxH {
                h = maxH
                w = h * targetAspectRatio
            }
            return CGSize(width: max(w, 80), height: max(h, 40))
        } else {
            var h = maxH
            var w = h * targetAspectRatio
            if w > maxW {
                w = maxW
                h = w / targetAspectRatio
            }
            return CGSize(width: max(w, 40), height: max(h, 80))
        }
    }

    var body: some View {
        let cw = cropFrameSize.width
        let ch = cropFrameSize.height
        let imgW = max(sourceImage.size.width, 1)
        let imgH = max(sourceImage.size.height, 1)

        // Calculate base size of the image to fill the crop frame
        let baseScale = max(cw / imgW, ch / imgH)
        let displayW = imgW * baseScale * zoomScale
        let displayH = imgH * baseScale * zoomScale

        let currentOffsetX = cropOffset.width + dragOffset.width
        let currentOffsetY = cropOffset.height + dragOffset.height

        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Drag to reposition, scroll or use slider to zoom. Exactly what's inside the frame will be visible.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }

            // Preview viewport
            ZStack {
                // Dimmed outer frame
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.05))
                    .frame(width: previewBoxWidth, height: previewBoxHeight)

                // Background dim of entire image for spatial orientation
                Image(nsImage: sourceImage)
                    .resizable()
                    .interpolation(.low)
                    .frame(width: displayW, height: displayH)
                    .offset(x: currentOffsetX, y: currentOffsetY)
                    .opacity(0.18)
                    .frame(width: previewBoxWidth, height: previewBoxHeight)
                    .clipped()

                // Active Crop Frame Viewport
                ZStack {
                    // Image inside crop frame
                    Image(nsImage: sourceImage)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: displayW, height: displayH)
                        .offset(x: currentOffsetX, y: currentOffsetY)

                    // Rule of thirds subtle grid lines
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        Path { path in
                            path.move(to: CGPoint(x: w / 3, y: 0))
                            path.addLine(to: CGPoint(x: w / 3, y: h))
                            path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                            path.addLine(to: CGPoint(x: 2 * w / 3, y: h))
                            path.move(to: CGPoint(x: 0, y: h / 3))
                            path.addLine(to: CGPoint(x: w, y: h / 3))
                            path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                            path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
                        }
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                    }

                    // Bright viewport border
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1.5)

                    // Corner indicators
                    ForEach(0..<4) { corner in
                        let x: CGFloat = corner % 2 == 0 ? -cw/2 : cw/2
                        let y: CGFloat = corner < 2 ? -ch/2 : ch/2
                        Circle()
                            .fill(Color.white)
                            .frame(width: 7, height: 7)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                            .offset(x: x, y: y)
                    }
                }
                .frame(width: cw, height: ch)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.65), radius: 12)
            }
            .frame(width: previewBoxWidth, height: previewBoxHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        cropOffset.width += value.translation.width
                        cropOffset.height += value.translation.height
                        dragOffset = .zero
                    }
            )
            .onScrollGesture { delta in
                let newScale = zoomScale + delta * 0.012
                zoomScale = min(max(newScale, 0.5), 4.0)
            }

            // Zoom control
            HStack(spacing: 12) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Slider(value: $zoomScale, in: 0.5...4.0)
                    .accentColor(.blue)
                    .frame(maxWidth: 220)
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                Text("\(Int(zoomScale * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 48)
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        cropOffset = .zero
                        dragOffset = .zero
                        zoomScale = 1.0
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    let cropped = cropImage()
                    onConfirm(cropped)
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                        Text("Apply")
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(22)
        .frame(width: previewBoxWidth + 44)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Mathematically Exact Crop

    private func cropImage() -> NSImage {
        let cw = cropFrameSize.width
        let ch = cropFrameSize.height
        guard cw > 0 && ch > 0 else { return sourceImage }

        let imgW = sourceImage.size.width
        let imgH = sourceImage.size.height
        guard imgW > 0 && imgH > 0 else { return sourceImage }

        let baseScale = max(cw / imgW, ch / imgH)
        let displayW = imgW * baseScale * zoomScale
        let displayH = imgH * baseScale * zoomScale

        let totalOffsetX = cropOffset.width + dragOffset.width
        let totalOffsetY = cropOffset.height + dragOffset.height

        // High-resolution destination image
        // Match source resolution if possible, capped between 800 and 2400 pt
        let targetPixelWidth = max(800.0, min(2400.0, imgW))
        let targetPixelHeight = targetPixelWidth / targetAspectRatio

        let outW = Int(targetPixelWidth.rounded())
        let outH = Int(targetPixelHeight.rounded())
        guard outW > 0 && outH > 0 else { return sourceImage }

        // Scale factor from preview points to destination pixels
        let S = targetPixelWidth / cw

        // In preview:
        // Viewport center is (cw / 2, ch / 2)
        // Image center is (cw / 2 + totalOffsetX, ch / 2 + totalOffsetY)
        // In AppKit (0,0 is bottom-left):
        // Canvas center is (targetPixelWidth / 2, targetPixelHeight / 2)
        // Positive totalOffsetX (right) increases CenterX
        // Positive totalOffsetY (down in SwiftUI) decreases CenterY in AppKit!
        let centerX = (targetPixelWidth / 2.0) + (totalOffsetX * S)
        let centerY = (targetPixelHeight / 2.0) - (totalOffsetY * S)

        let drawW = displayW * S
        let drawH = displayH * S

        let drawOriginX = centerX - (drawW / 2.0)
        let drawOriginY = centerY - (drawH / 2.0)

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: outW,
            pixelsHigh: outH,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return sourceImage
        }

        bitmapRep.size = NSSize(width: targetPixelWidth, height: targetPixelHeight)

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current = context

        // Fill black background in case edges are visible
        NSColor.black.setFill()
        NSRect(x: 0, y: 0, width: targetPixelWidth, height: targetPixelHeight).fill()

        sourceImage.draw(
            in: NSRect(x: drawOriginX, y: drawOriginY, width: drawW, height: drawH),
            from: NSRect(origin: .zero, size: sourceImage.size),
            operation: .sourceOver,
            fraction: 1.0
        )

        NSGraphicsContext.restoreGraphicsState()

        let croppedImage = NSImage(size: NSSize(width: targetPixelWidth, height: targetPixelHeight))
        croppedImage.addRepresentation(bitmapRep)
        return croppedImage
    }
}

// MARK: - Scroll Gesture Helper

extension View {
    func onScrollGesture(perform action: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            ScrollGestureView(onScroll: action)
        )
    }
}

struct ScrollGestureView: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ScrollableNSView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let scrollView = nsView as? ScrollableNSView {
            scrollView.onScroll = onScroll
        }
    }
}

class ScrollableNSView: NSView {
    var onScroll: ((CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        onScroll?(event.deltaY)
    }
}

