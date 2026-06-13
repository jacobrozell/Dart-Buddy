import AVFoundation
import SwiftUI
import UIKit

/// Live camera preview with the board-fit guidance overlay (spec §5). The overlay
/// circle is drawn in a shape layer and converted from capture-device coordinates via
/// the preview layer, so it stays aligned across orientations and aspect-fill crops.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let overlay: VisionScoringViewModel.BoardOverlay?

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.boardOverlay = overlay
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

    private let overlayLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        overlayLayer.fillColor = UIColor.clear.cgColor
        overlayLayer.lineWidth = 3
        layer.addSublayer(overlayLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        overlayLayer.frame = bounds
        updateOverlayPath()
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
}
