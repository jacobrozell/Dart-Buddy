import AVFoundation
import SwiftUI
import UIKit

/// Live camera preview. Reports the rotation that keeps video upright for the
/// current interface orientation so captured frames can be rotated to match:
/// what the detector analyzes is then exactly what the player sees, and "up" in
/// the image is "up" on screen.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let onRotationAngleChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onRotationAngleChange = onRotationAngleChange
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.onRotationAngleChange = onRotationAngleChange
        uiView.syncRotation()
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

    var onRotationAngleChange: ((CGFloat) -> Void)?
    private var reportedAngle: CGFloat?

    override func layoutSubviews() {
        super.layoutSubviews()
        syncRotation()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        syncRotation()
    }

    /// Applies the upright rotation to the preview and reports it when it changes.
    func syncRotation() {
        guard let orientation = window?.windowScene?.interfaceOrientation else { return }
        let angle = Self.videoRotationAngle(for: orientation)
        if let connection = previewLayer.connection,
           connection.isVideoRotationAngleSupported(angle),
           connection.videoRotationAngle != angle {
            connection.videoRotationAngle = angle
        }
        if reportedAngle != angle {
            reportedAngle = angle
            onRotationAngleChange?(angle)
        }
    }

    /// Rotation (degrees) that makes back-camera video upright in an interface orientation.
    static func videoRotationAngle(for orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .landscapeRight: return 0
        case .landscapeLeft: return 180
        case .portraitUpsideDown: return 270
        default: return 90
        }
    }
}

/// Maps between image width units and points in a view that shows the camera
/// image aspect-filled (matching `AVLayerVideoGravity.resizeAspectFill`).
struct AspectFillMapping {
    let viewSize: CGSize
    /// Image height divided by width.
    let aspectRatio: Double

    private var scale: Double {
        max(Double(viewSize.width), Double(viewSize.height) / max(aspectRatio, 0.0001))
    }

    func viewPoint(for point: ImagePoint) -> CGPoint {
        CGPoint(
            x: (point.x - 0.5) * scale + Double(viewSize.width) / 2,
            y: (point.y - aspectRatio / 2) * scale + Double(viewSize.height) / 2
        )
    }

    func imagePoint(for point: CGPoint) -> ImagePoint {
        ImagePoint(
            x: (Double(point.x) - Double(viewSize.width) / 2) / scale + 0.5,
            y: (Double(point.y) - Double(viewSize.height) / 2) / scale + aspectRatio / 2
        )
    }
}
