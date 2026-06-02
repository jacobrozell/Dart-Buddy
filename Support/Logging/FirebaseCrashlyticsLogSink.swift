import FirebaseCrashlytics
import Foundation

public struct FirebaseCrashlyticsLogSink: LogSink {
    private let appVersion: String?
    private let isCollectionEnabled: Bool

    public init(
        appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        isCollectionEnabled: Bool = FirebaseBootstrap.isCrashlyticsCollectionEnabled
    ) {
        self.appVersion = appVersion
        self.isCollectionEnabled = isCollectionEnabled
    }

    public func write(_ entry: LogEntry) {
        guard isCollectionEnabled, FirebaseBootstrap.shouldConfigure else { return }

        if entry.level >= .error,
           let error = FirebaseCrashlyticsEventMapping.nonFatalError(for: entry, appVersion: appVersion) {
            Crashlytics.crashlytics().record(error: error)
        }

        if entry.level >= .info {
            Crashlytics.crashlytics().log("[\(entry.category.rawValue)] \(entry.eventName)")
        }
    }
}
