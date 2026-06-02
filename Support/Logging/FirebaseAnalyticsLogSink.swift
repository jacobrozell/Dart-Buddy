import FirebaseAnalytics
import Foundation

public struct FirebaseAnalyticsLogSink: RemoteAnalyticsLogSink {
    private let appVersion: String?
    private let isCollectionEnabled: Bool

    public init(
        appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        isCollectionEnabled: Bool = FirebaseBootstrap.isAnalyticsCollectionEnabled
    ) {
        self.appVersion = appVersion
        self.isCollectionEnabled = isCollectionEnabled
    }

    public func write(_ entry: LogEntry) {
        guard isCollectionEnabled,
              FirebaseBootstrap.shouldConfigure,
              let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: appVersion)
        else {
            return
        }

        Analytics.logEvent(event.name, parameters: event.parameters.isEmpty ? nil : event.parameters)
    }
}
