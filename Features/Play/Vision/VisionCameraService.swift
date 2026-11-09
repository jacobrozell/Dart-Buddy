import AVFoundation
import Foundation

/// Owns the `AVCaptureSession` for vision scoring and streams analyzed frames.
/// Capture and analysis run on a dedicated serial queue; consumers receive
/// `VisionFrameAnalysis` values via `analysisStream`.
final class VisionCameraService: NSObject, @unchecked Sendable {
    enum CameraError: Error {
        case cameraUnavailable
        case configurationFailed
    }

    let captureSession = AVCaptureSession()

    private let sampleQueue = DispatchQueue(label: "com.jacobrozell.DartBuddy.visionCamera")
    private let analyzer = DartboardFrameAnalyzer()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var device: AVCaptureDevice?
    private var continuation: AsyncStream<VisionFrameAnalysis>.Continuation?
    private var isConfigured = false
    private var rotationAngle: CGFloat = 90
    private var framesSinceYield = 0
    private static let idleYieldInterval = 6

    static var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    /// Single-consumer stream of analyzed frames. Creating a new stream replaces
    /// the previous consumer.
    func analysisStream() -> AsyncStream<VisionFrameAnalysis> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            sampleQueue.async { [weak self] in
                self?.continuation = continuation
            }
        }
    }

    func start() throws {
        if !isConfigured {
            try configure()
            isConfigured = true
        }
        sampleQueue.async { [weak self] in
            guard let self else { return }
            analyzer.startSearching()
            applyRotationAngle()
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }

    func stop() {
        sampleQueue.async { [weak self] in
            guard let self else { return }
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
            setImagingLocked(false)
        }
    }

    /// Looks for the board again. Exposure, focus and white balance return to automatic.
    func startSearching() {
        sampleQueue.async { [weak self] in
            guard let self else { return }
            analyzer.startSearching()
            setImagingLocked(false)
        }
    }

    /// Watches the calibrated board for darts. Exposure, focus and white balance are
    /// frozen so the image only changes when something in the scene does.
    func startTracking(_ calibration: BoardCalibration) {
        sampleQueue.async { [weak self] in
            guard let self else { return }
            setImagingLocked(true)
            analyzer.startTracking(calibration)
        }
    }

    /// Keeps delivered frames upright for the current interface orientation
    /// (`0` = landscape with the camera on the left … `90` = portrait).
    func setVideoRotationAngle(_ angle: CGFloat) {
        sampleQueue.async { [weak self] in
            guard let self, self.rotationAngle != angle else { return }
            rotationAngle = angle
            applyRotationAngle()
        }
    }

    private func applyRotationAngle() {
        guard let connection = videoOutput.connection(with: .video),
              connection.isVideoRotationAngleSupported(rotationAngle),
              connection.videoRotationAngle != rotationAngle else { return }
        connection.videoRotationAngle = rotationAngle
    }

    private func setImagingLocked(_ locked: Bool) {
        guard let device, (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }
        let exposure: AVCaptureDevice.ExposureMode = locked ? .locked : .continuousAutoExposure
        if device.isExposureModeSupported(exposure) {
            device.exposureMode = exposure
        }
        let whiteBalance: AVCaptureDevice.WhiteBalanceMode = locked ? .locked : .continuousAutoWhiteBalance
        if device.isWhiteBalanceModeSupported(whiteBalance) {
            device.whiteBalanceMode = whiteBalance
        }
        let focus: AVCaptureDevice.FocusMode = locked ? .locked : .continuousAutoFocus
        if device.isFocusModeSupported(focus) {
            device.focusMode = focus
        }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            throw CameraError.cameraUnavailable
        }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .hd1280x720
        guard captureSession.canAddInput(input) else { throw CameraError.configurationFailed }
        captureSession.addInput(input)

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        guard captureSession.canAddOutput(videoOutput) else { throw CameraError.configurationFailed }
        captureSession.addOutput(videoOutput)
        self.device = device
    }
}

extension VisionCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let analysis = analyzer.analyze(pixelBuffer) else { return }
        // Every frame is analyzed, but the UI only needs the ones that carry news
        // plus a steady trickle for the guidance hints.
        framesSinceYield += 1
        let carriesNews = analysis.event != nil || analysis.didSearchForBoard || analysis.calibrationAgreement != nil
        guard carriesNews || framesSinceYield >= Self.idleYieldInterval else { return }
        framesSinceYield = 0
        continuation?.yield(analysis)
    }
}
