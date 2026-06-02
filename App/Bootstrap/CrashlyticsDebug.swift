#if DEBUG
enum CrashlyticsDebug {
    static func triggerTestCrash() -> Never {
        fatalError("Crashlytics test crash")
    }
}
#endif
