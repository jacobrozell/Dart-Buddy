import Foundation
import Testing
import UIKit
@testable import DartBuddy

@Suite("Client environment monitor", .tags(.unit, .logging, .regression))
@MainActor
struct ClientEnvironmentMonitorTests {
    @Test
    func startReportingChangesDoesNotLogImmediately() {
        let sink = ClientEnvironmentMonitorRecordingSink()
        let logger = DefaultAppLogger(minimumLevel: .info, sink: sink)

        ClientEnvironmentMonitor.startReportingChanges(using: logger)

        #expect(sink.entries.isEmpty)
    }

    @Test
    func startReportingChangesIsIdempotent() {
        let sink = ClientEnvironmentMonitorRecordingSink()
        let logger = DefaultAppLogger(minimumLevel: .info, sink: sink)

        ClientEnvironmentMonitor.startReportingChanges(using: logger)
        ClientEnvironmentMonitor.startReportingChanges(using: logger)

        postAccessibilityNotifications()
        #expect(sink.entries.isEmpty)
    }

    @Test
    func accessibilityNotificationsDoNotLogWhenSnapshotUnchanged() {
        let sink = ClientEnvironmentMonitorRecordingSink()
        let logger = DefaultAppLogger(minimumLevel: .info, sink: sink)
        ClientEnvironmentMonitor.startReportingChanges(using: logger)

        postAccessibilityNotifications()

        #expect(sink.entries.isEmpty)
    }

    private func postAccessibilityNotifications() {
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
            center.post(name: name, object: nil)
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
}

private final class ClientEnvironmentMonitorRecordingSink: LogSink, @unchecked Sendable {
    var entries: [LogEntry] = []

    func write(_ entry: LogEntry) {
        entries.append(entry)
    }
}
