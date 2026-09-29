//
//  PixelPetWidgetView.swift
//  boringNotch
//
//  Pixel pet and motivational quote widget inspired by LaunchMe notch.
//

import SwiftUI
import Defaults
import AVFoundation
import AVKit
import ImageIO

// MARK: - Pixel Pet & Custom Companion Widget

struct PixelPetWidgetView: View {
    @Default(.customCompanionPath) private var customCompanionPath
    @Default(.customCompanionType) private var customCompanionType
    @Default(.widgetCornerRadius) private var widgetCornerRadius
    @Default(.showCompanionText) private var showCompanionText
    @Default(.customCompanionText) private var customCompanionText
    @Default(.companionContentMode) private var companionContentMode
    @Default(.companionMediaSize) private var companionMediaSize
    @State private var currentQuoteIndex: Int = 0
    @State private var isBouncing: Bool = false
    @State private var petState: PetState = .happy
    @State private var heartOpacity: Double = 0.0
    @State private var heartOffset: CGFloat = 0.0

    private let quotes = [
        "YOU ARE PERFECT JUST KEEP GOING",
        "ONE STEP AT A TIME",
        "STAY CURIOUS & KIND",
        "MAKE TODAY COUNT",
        "YOU'VE GOT THIS",
        "BREATHE & RESET"
    ]

    enum PetState {
        case happy, sleeping, dancing
    }

    private var activeCaption: String {
        let custom = customCompanionText.trimmingCharacters(in: .whitespaces)
        return custom.isEmpty ? quotes[currentQuoteIndex] : custom
    }

    var body: some View {
        let isFillMode = companionContentMode == "fill"
        let hasCustomMedia = customCompanionPath != nil && FileManager.default.fileExists(atPath: customCompanionPath!)

        ZStack {
            if hasCustomMedia {
                let path = customCompanionPath!
                if isFillMode {
                    // Full bleed media
                    ZStack(alignment: .bottom) {
                        CustomCompanionMediaView(
                            filePath: path,
                            customType: customCompanionType,
                            isFill: true
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()

                        if showCompanionText {
                            // Bottom scrim with caption
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 38)

                            Text(activeCaption)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.bottom, 4)
                                .shadow(color: .black.opacity(0.8), radius: 2)
                                .contentTransition(.opacity)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
                                    }
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: CGFloat(widgetCornerRadius), style: .continuous))
                } else {
                    // Fit centered mode
                    VStack(spacing: 6) {
                        Spacer(minLength: 2)

                        CustomCompanionMediaView(
                            filePath: path,
                            customType: customCompanionType,
                            size: CGFloat(companionMediaSize),
                            isFill: false
                        )
                        .frame(width: CGFloat(companionMediaSize), height: CGFloat(companionMediaSize))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 5, y: 2)

                        if showCompanionText {
                            Text(activeCaption)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 4)
                                .contentTransition(.opacity)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
                                    }
                                }
                        }

                        Spacer(minLength: 2)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Default Pixel Pet
                VStack(spacing: 6) {
                    Spacer(minLength: 2)

                    ZStack {
                        Text("❤️")
                            .font(.system(size: 14))
                            .offset(y: heartOffset)
                            .opacity(heartOpacity)

                        PixelPetSprite(state: petState)
                            .frame(width: CGFloat(companionMediaSize * 0.8), height: CGFloat(companionMediaSize * 0.8))
                            .offset(y: isBouncing ? -4 : 0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isBouncing)
                            .onTapGesture {
                                triggerPetInteraction()
                            }
                    }
                    .frame(height: max(40, CGFloat(companionMediaSize * 0.85)))

                    if showCompanionText {
                        Text(activeCaption)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 6)
                            .contentTransition(.opacity)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
                                }
                            }
                    }

                    Spacer(minLength: 2)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CGFloat(widgetCornerRadius), style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat(widgetCornerRadius), style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: CGFloat(widgetCornerRadius), style: .continuous))
        .onAppear {
            isBouncing = true
        }
    }

    private func triggerPetInteraction() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            petState = petState == .happy ? .dancing : .happy
            heartOffset = -18
            heartOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                heartOpacity = 0.0
                heartOffset = 0
            }
        }
    }
}

// MARK: - Pixel Pet Canvas Sprite

struct PixelPetSprite: View {
    let state: PixelPetWidgetView.PetState

    // 8x8 pixel cat face pattern
    private let catPixels: [[Int]] = [
        [0, 4, 0, 0, 0, 0, 4, 0],
        [4, 1, 4, 0, 0, 4, 1, 4],
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 2, 1, 1, 1, 1, 2, 1],
        [1, 1, 1, 2, 2, 1, 1, 1],
        [1, 3, 1, 2, 2, 1, 3, 1],
        [0, 1, 1, 1, 1, 1, 1, 0],
        [0, 0, 1, 0, 0, 1, 0, 0]
    ]

    var body: some View {
        Canvas { context, size in
            let pixelSize = size.width / 8.0
            for row in 0..<8 {
                for col in 0..<8 {
                    let val = catPixels[row][col]
                    guard val != 0 else { continue }
                    let rect = CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )

                    let color: Color
                    switch val {
                    case 1: color = Color(red: 0.95, green: 0.90, blue: 0.82)
                    case 2: color = Color(red: 0.20, green: 0.15, blue: 0.15)
                    case 3: color = Color(red: 0.95, green: 0.50, blue: 0.60)
                    case 4: color = Color(red: 0.88, green: 0.62, blue: 0.42)
                    default: color = .clear
                    }

                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}

// MARK: - Custom Companion Media Views (Image, GIF, Video)

struct CustomCompanionMediaView: View {
    var filePath: String? = nil
    var customPath: String? = nil
    var customType: String? = nil
    var size: CGFloat? = 50
    var isFill: Bool = false

    private var effectivePath: String? {
        filePath ?? customPath
    }

    var isVideo: Bool {
        guard let path = effectivePath else { return false }
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return ["mp4", "mov", "m4v"].contains(ext) || customType == "video"
    }

    var isGIF: Bool {
        guard let path = effectivePath else { return false }
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return ext == "gif" || customType == "gif"
    }

    var body: some View {
        if let path = effectivePath, FileManager.default.fileExists(atPath: path) {
            if isVideo {
                LoopingVideoPlayerView(
                    url: URL(fileURLWithPath: path),
                    videoGravity: isFill ? .resizeAspectFill : .resizeAspect
                )
                .frame(width: isFill ? nil : size, height: isFill ? nil : size)
                .clipped()
            } else if isGIF {
                AnimatedGIFImageView(
                    filePath: path,
                    isFill: isFill
                )
                .frame(width: isFill ? nil : size, height: isFill ? nil : size)
                .clipped()
            } else {
                StaticImageView(filePath: path, isFill: isFill)
                    .frame(width: isFill ? nil : size, height: isFill ? nil : size)
                    .clipped()
            }
        } else {
            let s = size ?? 50
            PixelPetSprite(state: .happy)
                .frame(width: s * 0.8, height: s * 0.8)
        }
    }
}

// MARK: - Static Image View

struct StaticImageView: View {
    let filePath: String
    var isFill: Bool = false

    var body: some View {
        if let nsImage = NSImage(contentsOfFile: filePath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: isFill ? .fill : .fit)
        } else {
            Image(systemName: "photo")
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - ImageIO GIF Frame Extractor

final class GIFFrameExtractor {
    struct Frame {
        let image: CGImage
        let duration: Double
    }

    static func extract(from url: URL) -> [Frame] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return [] }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return [] }

        var frames: [Frame] = []
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            var delay: Double = 0.1
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
               let gifProps = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                if let unclamped = gifProps[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclamped > 0.01 {
                    delay = unclamped
                } else if let standard = gifProps[kCGImagePropertyGIFDelayTime] as? Double, standard > 0.01 {
                    delay = standard
                }
            }
            frames.append(Frame(image: cgImage, duration: max(0.02, delay)))
        }
        return frames
    }
}

// MARK: - Continuous Animated GIF View (Does NOT pause in nonactivating panels)

final class GIFPlayerNSView: NSView {
    private var frames: [GIFFrameExtractor.Frame] = []
    private var currentIndex: Int = 0
    private var timer: Timer?
    var currentPath: String = ""

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    func load(path: String, isFill: Bool) {
        guard currentPath != path else {
            layer?.contentsGravity = isFill ? .resizeAspectFill : .resizeAspect
            return
        }
        currentPath = path
        layer?.contentsGravity = isFill ? .resizeAspectFill : .resizeAspect
        timer?.invalidate()
        timer = nil

        let fileURL = URL(fileURLWithPath: path)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let extracted = GIFFrameExtractor.extract(from: fileURL)
            DispatchQueue.main.async {
                guard let self = self, self.currentPath == path else { return }
                self.frames = extracted
                self.currentIndex = 0
                if let first = extracted.first {
                    self.layer?.contents = first.image
                }
                self.scheduleNext()
            }
        }
    }

    private func scheduleNext() {
        guard frames.count > 1 else { return }
        let current = frames[currentIndex]
        timer?.invalidate()
        let t = Timer(timeInterval: current.duration, repeats: false) { [weak self] _ in
            guard let self = self, !self.frames.isEmpty else { return }
            self.currentIndex = (self.currentIndex + 1) % self.frames.count
            self.layer?.contents = self.frames[self.currentIndex].image
            self.scheduleNext()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil && !frames.isEmpty {
            scheduleNext()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    deinit {
        timer?.invalidate()
    }
}

struct AnimatedGIFImageView: NSViewRepresentable {
    let filePath: String
    var isFill: Bool = false

    func makeNSView(context: Context) -> GIFPlayerNSView {
        let view = GIFPlayerNSView()
        view.load(path: filePath, isFill: isFill)
        return view
    }

    func updateNSView(_ nsView: GIFPlayerNSView, context: Context) {
        nsView.load(path: filePath, isFill: isFill)
    }
}

// MARK: - Video Container NSView

final class VideoContainerNSView: NSView {
    var playerLayer: AVPlayerLayer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = bounds
        CATransaction.commit()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = NSRect(origin: .zero, size: newSize)
        CATransaction.commit()
    }
}

// MARK: - Looping Video Player View

struct LoopingVideoPlayerView: NSViewRepresentable {
    let url: URL
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> VideoContainerNSView {
        let view = VideoContainerNSView()

        let player = AVQueuePlayer()
        player.isMuted = true
        player.volume = 0.0
        player.actionAtItemEnd = .none

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = videoGravity
        playerLayer.frame = view.bounds
        view.layer?.addSublayer(playerLayer)
        view.playerLayer = playerLayer

        let item = AVPlayerItem(url: url)
        let looper = AVPlayerLooper(player: player, templateItem: item)
        context.coordinator.player = player
        context.coordinator.looper = looper
        context.coordinator.lastURL = url
        context.coordinator.lastGravity = videoGravity

        // Fallback notification in case AVPlayerLooper is unsupported on certain container formats
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak player] notif in
            if let endedItem = notif.object as? AVPlayerItem, endedItem == player?.currentItem {
                player?.seek(to: .zero)
                player?.play()
            }
        }

        player.play()
        return view
    }

    func updateNSView(_ nsView: VideoContainerNSView, context: Context) {
        if context.coordinator.lastGravity != videoGravity {
            nsView.playerLayer?.videoGravity = videoGravity
            context.coordinator.lastGravity = videoGravity
        }

        if nsView.bounds != .zero {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            nsView.playerLayer?.frame = nsView.bounds
            CATransaction.commit()
        }

        if context.coordinator.lastURL != url {
            context.coordinator.looper = nil
            context.coordinator.player?.pause()

            let player = AVQueuePlayer()
            player.isMuted = true
            player.volume = 0.0
            player.actionAtItemEnd = .none
            nsView.playerLayer?.player = player

            let item = AVPlayerItem(url: url)
            let looper = AVPlayerLooper(player: player, templateItem: item)
            context.coordinator.player = player
            context.coordinator.looper = looper
            context.coordinator.lastURL = url

            player.play()
        } else {
            if context.coordinator.player?.timeControlStatus != .playing {
                context.coordinator.player?.play()
            }
        }
    }

    class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
        var lastURL: URL?
        var lastGravity: AVLayerVideoGravity?
    }
}

