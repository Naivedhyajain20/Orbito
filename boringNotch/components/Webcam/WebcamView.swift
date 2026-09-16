//
//  WebcamView.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 19/08/24.
//

import AVFoundation
import Defaults
import SwiftUI

struct CameraPreviewView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var webcamManager: WebcamManager
    @State private var isHovering: Bool = false
    @State private var isBlinking: Bool = false

    var body: some View {
        ZStack {
            if let previewLayer = webcamManager.previewLayer {
                CameraPreviewLayerView(previewLayer: previewLayer)
                    .scaleEffect(x: -1, y: 1)
                    .clipShape(Circle())
                    .opacity(webcamManager.isSessionRunning ? 1 : 0)
            }

            if !webcamManager.isSessionRunning {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.14))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                    VStack(spacing: 5) {
                        Image(systemName: webcamManager.authorizationStatus == .denied ? "exclamationmark.triangle" : "web.camera")
                            .foregroundStyle(.gray)
                            .font(.system(size: 26))
                        Text(webcamManager.authorizationStatus == .denied ? "Access Denied" : "Mirror")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            } else {
                // Active session overlay
                if webcamManager.isRecording {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.2
                        )
                        .shadow(color: Color.red.opacity(0.6), radius: 4)
                }

                // Interactive Controls Overlay
                VStack(spacing: 0) {
                    Spacer().frame(height: 4)

                    Spacer()

                    // Center / Bottom: Record / Stop Button (visible on hover or when recording)
                    if isHovering || webcamManager.isRecording {
                        Button(action: {
                            webcamManager.toggleRecording()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(webcamManager.isRecording ? Color.red : Color.white, lineWidth: 1.5)
                                    )

                                if webcamManager.isRecording {
                                    // Stop indicator (Square)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                } else {
                                    // Record indicator (Red Dot)
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(webcamManager.isRecording ? "Stop & Save Video" : "Record Video")
                        .padding(.bottom, 6)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // Saved video notification pill
                if webcamManager.showSavedToast {
                    VStack {
                        Spacer()
                        Button(action: {
                            webcamManager.revealLastRecordingInFinder()
                        }) {
                            HStack(spacing: 3.5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 8))
                                Text("Saved")
                                    .font(.system(size: 7.5, weight: .bold))
                                    .foregroundColor(.white)
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 7))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.92)))
                            .overlay(Capsule().stroke(Color.green.opacity(0.7), lineWidth: 0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Click to reveal recording in Finder")
                        .padding(.bottom, 4)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .contentShape(Circle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

final class CameraPreviewContainerView: NSView {
    private var currentLayer: AVCaptureVideoPreviewLayer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        self.autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        self.autoresizingMask = [.width, .height]
    }

    func attachLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        if currentLayer !== previewLayer {
            currentLayer?.removeFromSuperlayer()
            currentLayer = previewLayer
            previewLayer.videoGravity = .resizeAspectFill
            self.layer?.addSublayer(previewLayer)
        }
        updateLayerFrame()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateLayerFrame()
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        updateLayerFrame()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateLayerFrame()
    }

    override func layout() {
        super.layout()
        updateLayerFrame()
    }

    private func updateLayerFrame() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        currentLayer?.frame = bounds
        CATransaction.commit()
    }
}

struct CameraPreviewLayerView: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeNSView(context: Context) -> CameraPreviewContainerView {
        let view = CameraPreviewContainerView(frame: .zero)
        view.attachLayer(previewLayer)
        return view
    }

    func updateNSView(_ nsView: CameraPreviewContainerView, context: Context) {
        nsView.attachLayer(previewLayer)
    }
}

#Preview {
    CameraPreviewView(webcamManager: .shared)
}

