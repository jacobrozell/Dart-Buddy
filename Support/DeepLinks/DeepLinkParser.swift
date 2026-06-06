import Foundation

enum DeepLinkParser {
    static func parse(_ url: URL) -> Result<AppDestination, DeepLinkError> {
        guard url.scheme?.lowercased() == DartBuddyURL.scheme else {
            return .failure(.unsupportedScheme)
        }

        let components = normalizedPathComponents(for: url)
        guard let version = components.first else {
            return .failure(.malformedPath)
        }
        guard version == DartBuddyURL.pathVersion else {
            return .failure(.unsupportedVersion(version))
        }

        let path = Array(components.dropFirst())
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return parseV1(path: path, queryItems: queryItems)
    }

    private static func normalizedPathComponents(for url: URL) -> [String] {
        var components: [String] = []
        if let host = url.host, !host.isEmpty {
            components.append(host)
        }
        components.append(contentsOf: url.path.split(separator: "/").map(String.init))

        // Alias: dartbuddy://play → dartbuddy://v1/play
        if components == ["play"] {
            return [DartBuddyURL.pathVersion, "play"]
        }

        return components
    }

    private static func parseV1(path: [String], queryItems: [URLQueryItem]) -> Result<AppDestination, DeepLinkError> {
        guard let head = path.first else {
            return .failure(.malformedPath)
        }

        switch head {
        case "tab":
            guard path.count == 2, let tab = TabDestination(rawValue: path[1]) else {
                return .failure(.unknownPath)
            }
            return .success(.tab(tab))

        case "play":
            switch path.count {
            case 1:
                return .success(.play(.home))
            case 2 where path[1] == "resume":
                return .success(.play(.resumeActive))
            default:
                return .failure(.unknownPath)
            }

        case "activity":
            _ = queryItems
            return .failure(.unknownPath)

        case "players":
            return .failure(.unknownPath)

        case "settings":
            return .failure(.unknownPath)

        default:
            return .failure(.unknownPath)
        }
    }
}
