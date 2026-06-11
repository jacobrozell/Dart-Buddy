import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Observes accessibility and display context changes and logs allowlisted analytics.
@MainActor
enum ClientEnvironmentMonitor {
    private static var lastSnapshot: ClientEnvironmentSnapshot?
    private static var observers: [NSObjectProtocol] = []

    static func startReportingChanges(using logger: any AppLogger) {
        guard observers.isEmpty else { return }

        lastSnapshot = ClientEnvironment.snapshot
        registerObservers(logger: logger)
    }

    #if canImport(UIKit)
    private static func registerObservers(logger: any AppLogger) {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            UIAccessibility.voiceOverStatusDidChangeNotification,
            UIAccessibility.switchControlStatusDidChangeNotification,
            UIAccessibility.boldTextStatusDidChangeNotification,
            UIAccessibility.reduceMotionStatusDidChangeNotification,
            UIScreen.capturedDidChangeNotification,
            UIDevice.orientationDidChangeNotification,
            UIScene.willConnectNotification,
            UIScene.didDisconnectNotification
        ]

        for name in names {
            let token = center.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    reportChangeIfNeeded(using: logger, trigger: notificationTrigger(for: name))
                }
            }
            observers.append(token)
        }
    }

    private static func notificationTrigger(for name: Notification.Name) -> String {
        switch name {
        case UIAccessibility.voiceOverStatusDidChangeNotification:
            return "voiceover"
        case UIAccessibility.switchControlStatusDidChangeNotification:
            return "switchControl"
        case UIAccessibility.boldTextStatusDidChangeNotification:
            return "boldText"
        case UIAccessibility.reduceMotionStatusDidChangeNotification:
            return "reduceMotion"
        case UIScreen.capturedDidChangeNotification:
            return "screenCapture"
        case UIDevice.orientationDidChangeNotification:
            return "orientation"
        case UIScene.willConnectNotification, UIScene.didDisconnectNotification:
            return "display"
        default:
            return "unknown"
        }
    }
    #else
    private static func registerObservers(logger: any AppLogger) {}
    #endif

    private static func reportChangeIfNeeded(using logger: any AppLogger, trigger: String) {
        let current = ClientEnvironment.snapshot
        guard current != lastSnapshot else { return }

        var metadata = current.analyticsMetadata
        metadata["trigger"] = trigger
        if let previous = lastSnapshot {
            metadata["changedSignals"] = ClientEnvironmentSnapshot.changedSignals(from: previous, to: current)
        }

        logger.info(
            .appLifecycle,
            eventName: "client_environment_changed",
            message: "Client environment context changed.",
            metadata: metadata
        )
        lastSnapshot = current
    }
}
