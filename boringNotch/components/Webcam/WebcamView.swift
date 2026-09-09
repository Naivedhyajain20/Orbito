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
            }
        }
        .contentShape(Circle())
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
