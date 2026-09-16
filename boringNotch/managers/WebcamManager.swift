//
//  WebcamManager.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 19/08/24.
//
import AppKit
import AVFoundation
import Defaults
import SwiftUI

class WebcamManager: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    static let shared = WebcamManager()
    
    @Published var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            objectWillChange.send()
        }
    }
    
    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var durationTimer: Timer?

    @Published var isSessionRunning: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }
    
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined {
        didSet {
            objectWillChange.send()
        }
    }
    
    @Published var cameraAvailable: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }

    // MARK: - Recording State
    @Published var isRecording: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }
    @Published var recordingDuration: TimeInterval = 0 {
        didSet {
            objectWillChange.send()
        }
    }
    @Published var lastSavedVideoURL: URL? = nil {
        didSet {
            objectWillChange.send()
        }
    }
    @Published var showSavedToast: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }

    private let sessionQueue = DispatchQueue(label: "BoringNotch.WebcamManager.SessionQueue", qos: .userInitiated)
    
    private var isCleaningUp: Bool = false
    
    // MARK: - Constants
    
    enum WebcamError: Error, LocalizedError {
        case deviceUnavailable
        case accessDenied
        case configurationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .deviceUnavailable:
                return "No camera devices available"
            case .accessDenied:
                return "Camera access denied"
            case .configurationFailed(let message):
                return "Camera configuration failed: \(message)"
            }
        }
    }
    
    // MARK: - Properties
    
    private override init() {
        super.init()
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        self.authorizationStatus = status
        NotificationCenter.default.addObserver(self, selector: #selector(deviceWasDisconnected), name: .AVCaptureDeviceWasDisconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceWasConnected), name: .AVCaptureDeviceWasConnected, object: nil)
        checkCameraAvailability()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        if let session = captureSession {
            if session.isRunning {
                session.stopRunning()
            }
        }
        captureSession = nil
            
        previewLayer = nil
    }

    // MARK: - Camera Management
    
    /// Checks current authorization status and requests access if needed
    func checkAndRequestVideoAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorized:
            checkCameraAvailability() // Check availability if authorized
        case .notDetermined:
            requestVideoAccess()
        case .denied, .restricted:
            NSLog("Camera access denied or restricted")
        @unknown default:
            NSLog("Unknown authorization status")
        }
    }
    
    /// Requests access to the camera
    private func requestVideoAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.authorizationStatus = granted ? .authorized : .denied
                if granted {
                    self?.checkCameraAvailability() // Check availability if access granted
                }
            }
        }
    }
    
    /// Checks if any camera devices are available and sets up capture session if needed
    func checkCameraAvailability() {
        let availableDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices
        
        let hasAvailableDevices = !availableDevices.isEmpty
        
        DispatchQueue.main.async {
            self.cameraAvailable = hasAvailableDevices
        }
    }
    
    /// Sets up the capture session with a completion handler
    private func setupCaptureSession(completion: @escaping (Bool) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { 
                completion(false)
                return 
            }
            
            // Clean up any existing session before creating a new one
            self.cleanupExistingSession()
            
            let session = AVCaptureSession()
            
            do {
                // Get available devices and prefer external camera if available
                let discoverySession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.external, .builtInWideAngleCamera],
                    mediaType: .video,
                    position: .unspecified
                )
                
                guard let videoDevice = discoverySession.devices.first else {
                    NSLog("No video devices available")
                    DispatchQueue.main.async {
                        self.isSessionRunning = false
                        self.cameraAvailable = false
                    }
                    completion(false)
                    return
                }
                
                NSLog("Using camera: \(videoDevice.localizedName)")
                
                // Lock device for configuration
                try videoDevice.lockForConfiguration()
                defer { videoDevice.unlockForConfiguration() }
                
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                guard session.canAddInput(videoInput) else {
                    throw NSError(domain: "BoringNotch.WebcamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"])
                }
                
                session.beginConfiguration()
                session.sessionPreset = .high
                session.addInput(videoInput)

                // Optional audio input for video recording
                if Defaults[.mirrorRecordAudio] {
                    let audioAuth = AVCaptureDevice.authorizationStatus(for: .audio)
                    if audioAuth == .authorized,
                       let audioDevice = AVCaptureDevice.default(for: .audio),
                       let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
                       session.canAddInput(audioInput) {
                        session.addInput(audioInput)
                    }
                }
                
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(nil, queue: nil)
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                }

                let movieOutput = AVCaptureMovieFileOutput()
                if session.canAddOutput(movieOutput) {
                    session.addOutput(movieOutput)
                    self.movieOutput = movieOutput
                }
                session.commitConfiguration()
                
                self.captureSession = session
                
                // Create and set up preview layer on main thread
                DispatchQueue.main.async {
                    self.cameraAvailable = true
                    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer.videoGravity = .resizeAspectFill
                    self.previewLayer = previewLayer
                    
                    // Setup is complete, let the caller know
                    completion(true)
                }
                
                NSLog("Capture session setup completed successfully")
            } catch {
                NSLog("Failed to setup capture session: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                    self.cameraAvailable = false
                    self.previewLayer = nil
                }
                completion(false)
            }
        }
    }
    
    /// Cleans up an existing capture session, removing all inputs and outputs
    private func cleanupExistingSession() {
        if let existingSession = self.captureSession {
            // First stop any ongoing recording
            if self.isRecording {
                self.movieOutput?.stopRecording()
                DispatchQueue.main.async {
                    self.isRecording = false
                    self.durationTimer?.invalidate()
                    self.durationTimer = nil
                }
            }
            self.movieOutput = nil

            // Then stop the session if running
            if existingSession.isRunning {
                existingSession.stopRunning()
            }
            
            // Then perform configuration cleanup
            existingSession.beginConfiguration()
            
            // Remove all inputs and outputs
            for input in existingSession.inputs {
                existingSession.removeInput(input)
            }
            for output in existingSession.outputs {
                existingSession.removeOutput(output)
            }
            
            existingSession.commitConfiguration()
            self.captureSession = nil
            
            // Clear preview layer on main thread
            DispatchQueue.main.async {
                self.previewLayer = nil
            }
        }
    }

    @objc private func deviceWasDisconnected(notification: Notification) {
        NSLog("Camera device was disconnected")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.stopSession()
            DispatchQueue.main.async {
                self.cameraAvailable = false
            }
        }
    }

    @objc private func deviceWasConnected(notification: Notification) {
        NSLog("Camera device was connected")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.checkCameraAvailability()
        }
    }

    private func updateSessionState() {
        let isRunning = self.captureSession?.isRunning ?? false
        DispatchQueue.main.async {
            self.isSessionRunning = isRunning
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // If no session exists, create new session
            if self.captureSession == nil {
                self.setupCaptureSession { success in
                    if success {
                        // Only start the session if setup was successful
                        self.startRunningCaptureSession()
                    }
                }
            } else {
                // Session already exists, just start it
                self.startRunningCaptureSession()
            }
        }
    }
    
    private func startRunningCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession, !session.isRunning else {
                return
            }
            
            session.startRunning()
            
            // Update state on main thread
            self.updateSessionState()
            
            NSLog("Capture session started successfully")
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Update state to indicate we're stopping
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
            
            self.cleanupExistingSession()
            
            NSLog("Capture session stopped and cleaned up")
        }
    }

    // MARK: - Video Recording Controls
    
    func startRecording() {
        guard let movieOutput = self.movieOutput, !isRecording else {
            NSLog("Cannot start recording: movieOutput unavailable or already recording")
            return
        }

        let folderURL: URL
        let customFolder = Defaults[.mirrorRecordingsFolder]
        if !customFolder.isEmpty {
            folderURL = URL(fileURLWithPath: customFolder)
        } else if let moviesURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first {
            folderURL = moviesURL.appendingPathComponent("Orbito Recordings", isDirectory: true)
        } else {
            folderURL = FileManager.default.temporaryDirectory
        }

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            NSLog("Failed to create recordings directory: \(error.localizedDescription)")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Orbito_Recording_\(formatter.string(from: Date())).mov"
        let fileURL = folderURL.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }

        DispatchQueue.main.async {
            self.isRecording = true
            self.recordingDuration = 0
            self.showSavedToast = false
            self.durationTimer?.invalidate()
            self.durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordingDuration += 1
            }
        }

        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
        NSLog("Started video recording to: \(fileURL.path)")
    }

    func stopRecording() {
        guard isRecording else { return }
        movieOutput?.stopRecording()
        DispatchQueue.main.async {
            self.isRecording = false
            self.durationTimer?.invalidate()
            self.durationTimer = nil
        }
        NSLog("Stopped video recording")
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func revealLastRecordingInFinder() {
        guard let url = lastSavedVideoURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.durationTimer?.invalidate()
            self.durationTimer = nil

            if error == nil {
                self.lastSavedVideoURL = outputFileURL
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.showSavedToast = true
                }
                NSSound(named: "Glass")?.play()
                NSLog("Successfully saved recording to \(outputFileURL.path)")

                // Auto-dismiss notification pill after 7 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                    if self.lastSavedVideoURL == outputFileURL {
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.showSavedToast = false
                        }
                    }
                }
            } else {
                NSLog("Recording finished with error: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
}
