import Foundation

public enum PlayerAvatarStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case dart
    case target
    case trophy
    case flame
    case star
    case crown
    case bolt
    case heart
    case medal
    case shield

    public var id: String { rawValue }

    public var symbolName: String {
        switch self {
        case .dart: "location.north.fill"
        case .target: "scope"
        case .trophy: "trophy.fill"
        case .flame: "flame.fill"
        case .star: "star.fill"
        case .crown: "crown.fill"
        case .bolt: "bolt.fill"
        case .heart: "heart.fill"
        case .medal: "medal.fill"
        case .shield: "shield.fill"
        }
    }

    public var displayName: String {
        L10n.string("players.avatar.\(rawValue)")
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
    case orange
    case pink
    case indigo
    case cyan
    case lime
    case coral

    public var id: String { rawValue }

    public var displayName: String {
        L10n.string("players.identity.color.\(rawValue)")
    }

    public static func resolved(raw: String?) -> PlayerColorToken {
        raw.flatMap(PlayerColorToken.init(rawValue:)) ?? .green
    }

    public static func defaultForPlayer(id: UUID) -> PlayerColorToken {
        let index = abs(id.hashValue) % allCases.count
        return allCases[index]
    }
}
