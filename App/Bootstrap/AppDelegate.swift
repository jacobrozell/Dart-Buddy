import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseBootstrap.shouldConfigure {
            FirebaseApp.configure()
            Analytics.setAnalyticsCollectionEnabled(FirebaseBootstrap.isAnalyticsCollectionEnabled)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(
                FirebaseBootstrap.isCrashlyticsCollectionEnabled
            )
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-crashlytics_test_crash") {
            CrashlyticsDebug.triggerTestCrash()
        }
        #endif
        return true
    }
}
