import Foundation

/// Single source of truth for deep-link URL construction.
enum DartBuddyURL {
    static let scheme = "dartbuddy"
    static let pathVersion = "v1"

    static func play() -> URL {
        makeURL(pathComponents: ["play"])
    }

    static func resumeActiveMatch() -> URL {
        makeURL(pathComponents: ["play", "resume"])
    }

    static func tab(_ tab: TabDestination) -> URL {
        makeURL(pathComponents: ["tab", tab.rawValue])
    }

    static func makeURL(pathComponents: [String], queryItems: [URLQueryItem] = []) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = pathVersion
        components.path = "/" + pathComponents.joined(separator: "/")
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url!
    }
}
