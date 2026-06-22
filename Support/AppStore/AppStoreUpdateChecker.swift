import Foundation

struct AppStoreUpdateOffer: Sendable, Equatable {
    let storeVersion: String
    let storeURL: URL
}

struct AppStoreUpdateChecker: @unchecked Sendable {
    private static let dismissedStoreVersionKey = "app_store_update_dismissed_version"
    static let enableLaunchArgument = "-enable_app_store_update_check"
    static let installedVersionOverrideFlag = "-app_store_update_installed_version"
    // Verified literal URL.
    // swiftlint:disable:next force_unwrapping
    private static let lookupURL = URL(string: "https://itunes.apple.com/lookup")!

    let bundleIdentifier: String
    let installedVersion: String
    let appStoreFallbackURL: URL
    let userDefaults: UserDefaults
    let urlSession: URLSession
    let isEnabled: Bool

    init(
        bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "com.jacobrozell.DartBuddy",
        installedVersion: String = AppStoreUpdateChecker.resolvedInstalledVersion(),
        appStoreFallbackURL: URL = AppLinks.appStore,
        userDefaults: UserDefaults = .standard,
        urlSession: URLSession = .shared,
        isEnabled: Bool = AppStoreUpdateChecker.defaultIsEnabled
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.installedVersion = installedVersion
        self.appStoreFallbackURL = appStoreFallbackURL
        self.userDefaults = userDefaults
        self.urlSession = urlSession
        self.isEnabled = isEnabled
    }

    static var defaultIsEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(enableLaunchArgument) {
            return true
        }
        #if DEBUG
        return false
        #else
        return !arguments.contains("-ui_test_reset")
        #endif
    }

    /// Launch arg `-app_store_update_installed_version 0.9.0` simulates an older build for manual QA.
    static func resolvedInstalledVersion(arguments: [String] = ProcessInfo.processInfo.arguments) -> String {
        if let index = arguments.firstIndex(of: installedVersionOverrideFlag),
           arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    func checkForUpdate() async -> AppStoreUpdateOffer? {
        guard isEnabled else { return nil }
        guard let lookupResult = await fetchLookupResult() else { return nil }
        guard AppVersionComparator.isStoreVersionNewer(store: lookupResult.version, than: installedVersion) else {
            return nil
        }
        guard shouldPrompt(forStoreVersion: lookupResult.version) else { return nil }
        let storeURL = lookupResult.trackViewURL ?? appStoreFallbackURL
        return AppStoreUpdateOffer(storeVersion: lookupResult.version, storeURL: storeURL)
    }

    func recordDismissal(for offer: AppStoreUpdateOffer) {
        userDefaults.set(offer.storeVersion, forKey: Self.dismissedStoreVersionKey)
    }

    static func clearPersistedState(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: dismissedStoreVersionKey)
    }

    private func shouldPrompt(forStoreVersion storeVersion: String) -> Bool {
        guard let dismissedVersion = userDefaults.string(forKey: Self.dismissedStoreVersionKey) else {
            return true
        }
        return AppVersionComparator.isStoreVersionNewer(store: storeVersion, than: dismissedVersion)
    }

    private struct LookupResult: Sendable {
        let version: String
        let trackViewURL: URL?
    }

    private struct LookupResponse: Decodable {
        struct AppResult: Decodable {
            let version: String
            let trackViewUrl: String?
        }

        let results: [AppResult]
    }

    private func fetchLookupResult() async -> LookupResult? {
        var components = URLComponents(url: Self.lookupURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "bundleId", value: bundleIdentifier)]
        guard let url = components?.url else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            let decoded = try JSONDecoder().decode(LookupResponse.self, from: data)
            guard let app = decoded.results.first else { return nil }
            let trackViewURL = app.trackViewUrl.flatMap(URL.init(string:))
            return LookupResult(version: app.version, trackViewURL: trackViewURL)
        } catch {
            return nil
        }
    }
}
