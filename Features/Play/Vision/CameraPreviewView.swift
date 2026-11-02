import AVFoundation
import SwiftUI
import UIKit

/// Live camera preview with the board-fit guidance overlay (spec §5). The overlay
/// circle is drawn in a shape layer and converted from capture-device coordinates via
/// the preview layer, so it stays aligned across orientations and aspect-fill crops.
struct CameraPreviewView: UIViewRepresentable {
    struct DartMarker: Equatable {
        let number: Int
        let imageX: Double
        let imageY: Double
    }

    let session: AVCaptureSession
    let overlay: VisionScoringViewModel.BoardOverlay?
    let calibrationTaps: [VisionScoringViewModel.CalibrationTap]
    let dartMarkers: [DartMarker]
    let aspectRatio: Double
    let onCalibrationTap: (Double, Double) -> Void

    init(
        session: AVCaptureSession,
        overlay: VisionScoringViewModel.BoardOverlay?,
        calibrationTaps: [VisionScoringViewModel.CalibrationTap],
        dartMarkers: [DartMarker] = [],
        aspectRatio: Double,
        onCalibrationTap: @escaping (Double, Double) -> Void
    ) {
        self.session = session
        self.overlay = overlay
        self.calibrationTaps = calibrationTaps
        self.dartMarkers = dartMarkers
        self.aspectRatio = aspectRatio
        self.onCalibrationTap = onCalibrationTap
    }

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.boardOverlay = overlay
        uiView.calibrationTaps = calibrationTaps
        uiView.dartMarkers = dartMarkers
        uiView.aspectRatio = aspectRatio
        uiView.onCalibrationTap = onCalibrationTap
    }
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let previewLayer = layer as? AVCaptureVideoPreviewLayer else {
            preconditionFailure("CameraPreviewUIView.layerClass must be AVCaptureVideoPreviewLayer")
        }
        return previewLayer
    }

    var boardOverlay: VisionScoringViewModel.BoardOverlay? {
        didSet { updateOverlayPath() }
    }

    var calibrationTaps: [VisionScoringViewModel.CalibrationTap] = [] {
        didSet { updateMarkerPath() }
    }

    var dartMarkers: [CameraPreviewView.DartMarker] = [] {
        didSet { updateDartMarkers() }
    }

    /// Buffer height divided by width. Taps convert through this into width units.
    var aspectRatio: Double = 0

    var onCalibrationTap: ((Double, Double) -> Void)?

    private let overlayLayer = CAShapeLayer()
    private let markerLayer = CAShapeLayer()
    private let dartMarkerContainer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        overlayLayer.fillColor = UIColor.clear.cgColor
        overlayLayer.lineWidth = 3
        layer.addSublayer(overlayLayer)
        markerLayer.fillColor = UIColor.systemGreen.cgColor
        markerLayer.strokeColor = UIColor.white.cgColor
        markerLayer.lineWidth = 2
        layer.addSublayer(markerLayer)
        layer.addSublayer(dartMarkerContainer)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCalibrationTap(_:)))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        overlayLayer.frame = bounds
        markerLayer.frame = bounds
        dartMarkerContainer.frame = bounds
        updateOverlayPath()
        updateMarkerPath()
        updateDartMarkers()
    }

    @objc private func handleCalibrationTap(_ recognizer: UITapGestureRecognizer) {
        guard aspectRatio > 0 else { return }
        let layerPoint = recognizer.location(in: self)
        // Capture-device space matches the sensor buffer the analyzer uses: (0, 0) is
        // the top left. Width-unit y scales by the buffer aspect ratio, same as impacts.
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
        onCalibrationTap?(Double(devicePoint.x), Double(devicePoint.y) * aspectRatio)
    }

    private func updateOverlayPath() {
        guard let boardOverlay, bounds.width > 0, boardOverlay.aspectRatio > 0 else {
            overlayLayer.path = nil
            return
        }
        // Overlay values are in width units; capture-device points are per-axis
        // normalized, so y converts back through the aspect ratio.
        let deviceY = boardOverlay.centerY / boardOverlay.aspectRatio
        let center = previewLayer.layerPointConverted(
            fromCaptureDevicePoint: CGPoint(x: boardOverlay.centerX, y: deviceY)
        )
        let edge = previewLayer.layerPointConverted(
            fromCaptureDevicePoint: CGPoint(x: boardOverlay.centerX + boardOverlay.radius, y: deviceY)
        )
        let radius = hypot(edge.x - center.x, edge.y - center.y)
        guard radius.isFinite, radius > 1 else {
            overlayLayer.path = nil
            return
        }
        overlayLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        ).cgPath
        overlayLayer.strokeColor = boardOverlay.isLocked
            ? UIColor.systemGreen.cgColor
            : UIColor.systemYellow.cgColor
        overlayLayer.lineDashPattern = boardOverlay.isLocked ? nil : [8, 6]
    }

    private func updateMarkerPath() {
        guard aspectRatio > 0, bounds.width > 0, !calibrationTaps.isEmpty else {
            markerLayer.path = nil
            return
        }
        let path = UIBezierPath()
        for tap in calibrationTaps {
            let center = previewLayer.layerPointConverted(
                fromCaptureDevicePoint: CGPoint(x: tap.imageX, y: tap.imageY / aspectRatio)
            )
            path.append(UIBezierPath(arcCenter: center, radius: 8, startAngle: 0, endAngle: 2 * .pi, clockwise: true))
        }
        markerLayer.path = path.cgPath
    }

    private func updateDartMarkers() {
        dartMarkerContainer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard aspectRatio > 0, bounds.width > 0 else { return }
        let amber = UIColor(red: 0.96, green: 0.70, blue: 0.12, alpha: 1)
        for marker in dartMarkers {
            let center = previewLayer.layerPointConverted(
                fromCaptureDevicePoint: CGPoint(x: marker.imageX, y: marker.imageY / aspectRatio)
            )
            let circle = CAShapeLayer()
            circle.path = UIBezierPath(
                arcCenter: center,
                radius: 11,
                startAngle: 0,
                endAngle: 2 * .pi,
                clockwise: true
            ).cgPath
            circle.fillColor = amber.cgColor
            circle.strokeColor = UIColor.white.cgColor
            circle.lineWidth = 2
            dartMarkerContainer.addSublayer(circle)

            let label = CATextLayer()
            label.string = "\(marker.number)"
            label.alignmentMode = .center
            label.fontSize = 12
            label.font = UIFont.boldSystemFont(ofSize: 12)
            label.foregroundColor = UIColor.black.cgColor
            label.contentsScale = UIScreen.main.scale
            label.frame = CGRect(x: center.x - 11, y: center.y - 7, width: 22, height: 14)
            dartMarkerContainer.addSublayer(label)
        }
    }
}
