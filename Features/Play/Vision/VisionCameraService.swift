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
    private var continuation: AsyncStream<VisionFrameAnalysis>.Continuation?
    private var isConfigured = false

    static var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    /// Single-consumer stream of analyzed frames. Creating a new stream replaces
    /// the previous consumer.
    func analysisStream() -> AsyncStream<VisionFrameAnalysis> {
        AsyncStream { continuation in
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
        sampleQueue.async { [captureSession, analyzer] in
            analyzer.reset()
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }

    func stop() {
        sampleQueue.async { [captureSession] in
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

    func resetAnalyzer() {
        sampleQueue.async { [analyzer] in
            analyzer.reset()
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

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        guard captureSession.canAddOutput(output) else { throw CameraError.configurationFailed }
        captureSession.addOutput(output)
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
        continuation?.yield(analysis)
    }
}
