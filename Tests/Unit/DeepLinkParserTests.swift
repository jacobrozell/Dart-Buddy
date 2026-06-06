import Foundation
import Testing
@testable import DartBuddy

@Suite("Deep link parser", .tags(.unit, .navigation, .regression))
struct DeepLinkParserTests {
    @Test
    func parsesPlayHome() {
        let result = DeepLinkParser.parse(DartBuddyURL.play())
        #expect(result == .success(.play(.home)))
    }

    @Test
    func parsesPlayResume() {
        let result = DeepLinkParser.parse(DartBuddyURL.resumeActiveMatch())
        #expect(result == .success(.play(.resumeActive)))
    }

    @Test
    func parsesTabRoutes() throws {
        for tab in TabDestination.allCases {
            let result = DeepLinkParser.parse(DartBuddyURL.tab(tab))
            #expect(result == .success(.tab(tab)))
        }
    }

    @Test
    func parsesPlayAliasWithoutVersion() throws {
        let url = try #require(URL(string: "dartbuddy://play"))
        let result = DeepLinkParser.parse(url)
        #expect(result == .success(.play(.home)))
    }

    @Test
    func rejectsUnsupportedScheme() throws {
        let url = try #require(URL(string: "https://example.com/v1/play"))
        let result = DeepLinkParser.parse(url)
        #expect(result == .failure(.unsupportedScheme))
    }

    @Test
    func rejectsUnsupportedVersion() throws {
        let url = try #require(URL(string: "dartbuddy://v2/play"))
        let result = DeepLinkParser.parse(url)
        #expect(result == .failure(.unsupportedVersion("v2")))
    }

    @Test
    func rejectsUnknownPlayPath() throws {
        let url = try #require(URL(string: "dartbuddy://v1/play/setup"))
        let result = DeepLinkParser.parse(url)
        #expect(result == .failure(.unknownPath))
    }

    @Test
    func rejectsUnknownTab() throws {
        let url = try #require(URL(string: "dartbuddy://v1/tab/unknown"))
        let result = DeepLinkParser.parse(url)
        #expect(result == .failure(.unknownPath))
    }

    @Test
    func roundTripsBuilderURLs() {
        let urls: [(URL, AppDestination)] = [
            (DartBuddyURL.play(), .play(.home)),
            (DartBuddyURL.resumeActiveMatch(), .play(.resumeActive)),
            (DartBuddyURL.tab(.activity), .tab(.activity)),
        ]

        for (url, expected) in urls {
            let result = DeepLinkParser.parse(url)
            #expect(result == .success(expected))
        }
    }

    @Test
    func acceptsSchemeCaseInsensitively() throws {
        let url = try #require(URL(string: "DARTBUDDY://v1/play"))
        let result = DeepLinkParser.parse(url)
        #expect(result == .success(.play(.home)))
    }

    @Test
    func rejectsVersionOnlyPath() throws {
        let url = try #require(URL(string: "dartbuddy://v1"))
        let result = DeepLinkParser.parse(url)
        #expect(result == .failure(.malformedPath))
    }

    @Test
    func acceptsTripleSlashPathForm() throws {
        let url = try #require(URL(string: "dartbuddy:///v1/play"))
        let result = DeepLinkParser.parse(url)
        #expect(result == .success(.play(.home)))
    }

    @Test
    func builderURLsUseExpectedSchemeAndVersion() {
        let url = DartBuddyURL.play()
        #expect(url.scheme == DartBuddyURL.scheme)
        #expect(url.host == DartBuddyURL.pathVersion)
        #expect(url.path == "/play")
    }
}

private extension TabDestination {
    static var allCases: [TabDestination] {
        [.play, .modes, .players, .activity, .settings]
    }
}
