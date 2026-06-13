import UIKit

/// Locks interface orientation for marketing screenshot capture (`-snapshot_orientation`).
enum SnapshotOrientationLock {
    enum Requested: String {
        case portrait
        case landscape
    }

    private(set) static var mask: UIInterfaceOrientationMask = .all
    private(set) static var requested: Requested?

    static func configureFromLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-snapshot_orientation"),
              arguments.indices.contains(arguments.index(after: index)),
              let orientation = Requested(rawValue: arguments[index + 1])
        else {
            mask = .all
            requested = nil
            return
        }

        requested = orientation
        switch orientation {
        case .portrait:
            mask = .portrait
        case .landscape:
            mask = [.landscapeLeft, .landscapeRight]
        }
    }

    @MainActor
    static func applyIfNeeded() {
        guard let requested else { return }

        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in
                Task { @MainActor in
                    forceDeviceOrientation(for: requested)
                }
            }
            return
        }

        forceDeviceOrientation(for: requested)
    }

    @MainActor
    private static func forceDeviceOrientation(for requested: Requested) {
        let interfaceOrientation: UIInterfaceOrientation = switch requested {
        case .portrait: .portrait
        case .landscape: .landscapeLeft
        }
        UIDevice.current.setValue(interfaceOrientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
