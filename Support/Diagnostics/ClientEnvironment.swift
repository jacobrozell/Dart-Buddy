import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Snapshot of device class, display routing, and system accessibility settings.
public struct ClientEnvironmentSnapshot: Equatable, Sendable {
    public let deviceClass: String
    public let isVoiceOverRunning: Bool
    public let isSwitchControlRunning: Bool
    public let isBoldTextEnabled: Bool
    public let isReduceMotionEnabled: Bool
    public let isScreenCaptured: Bool
    public let isExternalDisplayConnected: Bool
    public let interfaceOrientation: String

    public init(
        deviceClass: String,
        isVoiceOverRunning: Bool,
        isSwitchControlRunning: Bool,
        isBoldTextEnabled: Bool,
        isReduceMotionEnabled: Bool,
        isScreenCaptured: Bool,
        isExternalDisplayConnected: Bool,
        interfaceOrientation: String
    ) {
        self.deviceClass = deviceClass
        self.isVoiceOverRunning = isVoiceOverRunning
        self.isSwitchControlRunning = isSwitchControlRunning
        self.isBoldTextEnabled = isBoldTextEnabled
        self.isReduceMotionEnabled = isReduceMotionEnabled
        self.isScreenCaptured = isScreenCaptured
        self.isExternalDisplayConnected = isExternalDisplayConnected
        self.interfaceOrientation = interfaceOrientation
    }

    public var analyticsMetadata: [String: String] {
        [
            "deviceClass": deviceClass,
            "isVoiceOverRunning": Self.boolString(isVoiceOverRunning),
            "isSwitchControlRunning": Self.boolString(isSwitchControlRunning),
            "isBoldTextEnabled": Self.boolString(isBoldTextEnabled),
            "isReduceMotionEnabled": Self.boolString(isReduceMotionEnabled),
            "isScreenCaptured": Self.boolString(isScreenCaptured),
            "isExternalDisplayConnected": Self.boolString(isExternalDisplayConnected),
            "interfaceOrientation": interfaceOrientation
        ]
    }

    /// Comma-separated signal names that differ between two snapshots (for change analytics).
    public static func changedSignals(
        from previous: ClientEnvironmentSnapshot,
        to current: ClientEnvironmentSnapshot
    ) -> String {
        var changes: [String] = []
        if previous.isVoiceOverRunning != current.isVoiceOverRunning { changes.append("voiceover") }
        if previous.isSwitchControlRunning != current.isSwitchControlRunning { changes.append("switchControl") }
        if previous.isBoldTextEnabled != current.isBoldTextEnabled { changes.append("boldText") }
        if previous.isReduceMotionEnabled != current.isReduceMotionEnabled { changes.append("reduceMotion") }
        if previous.isScreenCaptured != current.isScreenCaptured { changes.append("screenCapture") }
        if previous.isExternalDisplayConnected != current.isExternalDisplayConnected { changes.append("display") }
        if previous.deviceClass != current.deviceClass { changes.append("deviceClass") }
        if previous.interfaceOrientation != current.interfaceOrientation { changes.append("orientation") }
        return changes.joined(separator: ",")
    }

    public static func current() -> ClientEnvironmentSnapshot {
        #if canImport(UIKit)
        if Thread.isMainThread {
            return makeUIKitSnapshot()
        }
        return DispatchQueue.main.sync {
            makeUIKitSnapshot()
        }
        #else
        ClientEnvironmentSnapshot(
            deviceClass: "unspecified",
            isVoiceOverRunning: false,
            isSwitchControlRunning: false,
            isBoldTextEnabled: false,
            isReduceMotionEnabled: false,
            isScreenCaptured: false,
            isExternalDisplayConnected: false,
            interfaceOrientation: "unknown"
        )
        #endif
    }

    private static func boolString(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    #if canImport(UIKit)
    private static func makeUIKitSnapshot() -> ClientEnvironmentSnapshot {
        ClientEnvironmentSnapshot(
            deviceClass: deviceClass(from: UIDevice.current.userInterfaceIdiom),
            isVoiceOverRunning: UIAccessibility.isVoiceOverRunning,
            isSwitchControlRunning: UIAccessibility.isSwitchControlRunning,
            isBoldTextEnabled: UIAccessibility.isBoldTextEnabled,
            isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
            isScreenCaptured: UIScreen.main.isCaptured,
            isExternalDisplayConnected: hasExternalDisplayConnected(),
            interfaceOrientation: currentInterfaceOrientation()
        )
    }

    private static func deviceClass(from idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone: "iphone"
        case .pad: "ipad"
        case .mac: "mac"
        case .tv: "tv"
        case .carPlay: "carplay"
        case .vision: "vision"
        case .unspecified: "unspecified"
        @unknown default: "unspecified"
        }
    }

    private static func hasExternalDisplayConnected() -> Bool {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .map(\.screen)
            .contains { $0 != UIScreen.main }
    }

    private static func currentInterfaceOrientation() -> String {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
        else {
            return "unknown"
        }

        switch scene.interfaceOrientation {
        case .portrait, .portraitUpsideDown:
            return "portrait"
        case .landscapeLeft, .landscapeRight:
            return "landscape"
        default:
            return "unknown"
        }
    }
    #endif
}

/// Global read accessors for client device and accessibility context.
public enum ClientEnvironment {
    public static var snapshot: ClientEnvironmentSnapshot {
        ClientEnvironmentSnapshot.current()
    }

    public static var isVoiceOverRunning: Bool {
        snapshot.isVoiceOverRunning
    }

    public static var isPad: Bool {
        snapshot.deviceClass == "ipad"
    }

    public static var isPhone: Bool {
        snapshot.deviceClass == "iphone"
    }

    public static var isScreenCaptured: Bool {
        snapshot.isScreenCaptured
    }

    public static var isExternalDisplayConnected: Bool {
        snapshot.isExternalDisplayConnected
    }
}
