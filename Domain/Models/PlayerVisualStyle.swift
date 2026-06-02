import Foundation

public enum PlayerAvatarStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case dart
    case target
    case trophy
    case flame
    case star

    public var id: String { rawValue }

    public var symbolName: String {
        switch self {
        case .dart: "location.north.fill"
        case .target: "scope"
        case .trophy: "trophy.fill"
        case .flame: "flame.fill"
        case .star: "star.fill"
        }
    }

    public static func resolved(raw: String?) -> PlayerAvatarStyle {
        raw.flatMap(PlayerAvatarStyle.init(rawValue:)) ?? .dart
    }

    public static func defaultForPlayer(id: UUID, isBot: Bool) -> PlayerAvatarStyle {
        if isBot { return .target }
        let index = abs(id.hashValue) % allCases.count
        return allCases[index]
    }
}

public enum PlayerColorToken: String, CaseIterable, Codable, Sendable, Identifiable {
    case green
    case amber
    case red
    case blue
    case purple
    case teal

    public var id: String { rawValue }

    public static func resolved(raw: String?) -> PlayerColorToken {
        raw.flatMap(PlayerColorToken.init(rawValue:)) ?? .green
    }

    public static func defaultForPlayer(id: UUID) -> PlayerColorToken {
        let index = abs(id.hashValue) % allCases.count
        return allCases[index]
    }
}
