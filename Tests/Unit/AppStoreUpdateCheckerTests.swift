import Foundation
import Testing
@testable import DartBuddy

@Suite("App Store update", .tags(.unit, .regression))
struct AppStoreUpdateCheckerTests {
    @Test
    func versionComparatorTreatsPatchAsNewer() {
        #expect(AppVersionComparator.isStoreVersionNewer(store: "1.0.10", than: "1.0.9"))
        #expect(!AppVersionComparator.isStoreVersionNewer(store: "1.0.9", than: "1.0.10"))
    }

    @Test
    func versionComparatorTreatsMinorAsNewer() {
        #expect(AppVersionComparator.isStoreVersionNewer(store: "1.2.0", than: "1.1.9"))
    }

    @Test
    func versionComparatorEqualVersionsAreNotNewer() {
        #expect(AppVersionComparator.compare("1.0.0", "1.0.0") == .orderedSame)
        #expect(!AppVersionComparator.isStoreVersionNewer(store: "1.0.0", than: "1.0.0"))
    }

    @Test
    func versionComparatorIgnoresBuildMetadataSuffix() {
        #expect(AppVersionComparator.components("1.2.3-beta") == [1, 2, 3])
        #expect(AppVersionComparator.compare("1.2.3", "1.2.3-rc1") == .orderedSame)
    }

    @Test
    func versionComparatorPadsMissingSegmentsWithZero() {
        #expect(AppVersionComparator.compare("1.2", "1.2.0") == .orderedSame)
        #expect(AppVersionComparator.isStoreVersionNewer(store: "2.0", than: "1.9.9"))
    }

    @Test
    func checkerSkipsWhenStoreNotNewer() async {
        let bundleIdentifier = uniqueBundleIdentifier()
        let defaults = makeIsolatedDefaults()
        configureMockLookup(version: "1.0.0", bundleIdentifier: bundleIdentifier)
        let checker = AppStoreUpdateChecker(
            bundleIdentifier: bundleIdentifier,
            installedVersion: "1.0.0",
            appStoreFallbackURL: AppLinks.appStore,
            userDefaults: defaults,
            urlSession: makeMockSession(),
            isEnabled: true
        )
        #expect(await checker.checkForUpdate() == nil)
    }

    @Test
    func checkerRespectsDismissedStoreVersion() async {
        let bundleIdentifier = uniqueBundleIdentifier()
        let defaults = makeIsolatedDefaults()
        defaults.set("9.9.9", forKey: "app_store_update_dismissed_version")
        configureMockLookup(version: "9.9.9", bundleIdentifier: bundleIdentifier)

        let checker = AppStoreUpdateChecker(
            bundleIdentifier: bundleIdentifier,
            installedVersion: "1.0.0",
            appStoreFallbackURL: AppLinks.appStore,
            userDefaults: defaults,
            urlSession: makeMockSession(),
            isEnabled: true
        )
        #expect(await checker.checkForUpdate() == nil)
    }

    @Test
    func checkerReturnsOfferWhenStoreIsNewer() async throws {
        let bundleIdentifier = uniqueBundleIdentifier()
        let defaults = makeIsolatedDefaults()
        configureMockLookup(
            version: "2.0.0",
            bundleIdentifier: bundleIdentifier,
            trackViewURL: "https://apps.apple.com/app/id6775713346"
        )

        let checker = AppStoreUpdateChecker(
            bundleIdentifier: bundleIdentifier,
            installedVersion: "1.0.0",
            appStoreFallbackURL: AppLinks.appStore,
            userDefaults: defaults,
            urlSession: makeMockSession(),
            isEnabled: true
        )
        let offer = try #require(await checker.checkForUpdate())
        #expect(offer.storeVersion == "2.0.0")
        #expect(offer.storeURL.absoluteString.contains("apps.apple.com"))
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "AppStoreUpdateCheckerTests.\(UUID().uuidString)")!
    }

    private func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockITunesLookupURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func uniqueBundleIdentifier() -> String {
        "com.example.app.\(UUID().uuidString)"
    }

    private func configureMockLookup(
        version: String,
        bundleIdentifier: String,
        trackViewURL: String = "https://apps.apple.com/app/id1"
    ) {
        MockITunesLookupURLProtocol.setResponse(
            """
            {"resultCount":1,"results":[{"version":"\(version)","trackViewUrl":"\(trackViewURL)"}]}
            """,
            forBundleIdentifier: bundleIdentifier
        )
    }
}

private final class MockITunesLookupURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var responsesByBundleIdentifier: [String: String] = [:]

    static func setResponse(_ json: String, forBundleIdentifier bundleIdentifier: String) {
        lock.lock()
        responsesByBundleIdentifier[bundleIdentifier] = json
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.absoluteString.contains("itunes.apple.com/lookup") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let bundleIdentifier = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "bundleId" })?
            .value ?? ""
        Self.lock.lock()
        let json = Self.responsesByBundleIdentifier[bundleIdentifier] ?? "{\"resultCount\":0,\"results\":[]}"
        Self.lock.unlock()
        let data = json.data(using: .utf8) ?? Data()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
