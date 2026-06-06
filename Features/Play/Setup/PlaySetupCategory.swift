import Foundation

/// Top-level Play setup grouping. Standard holds X01/Cricket; Party holds multiplayer formats.
enum PlaySetupCategory: String, CaseIterable, Identifiable, Hashable {
    case standard
    case party

    var id: String { rawValue }
}

/// Party-format games surfaced in setup. Flip `isAvailable` when a mode ships.
enum PartyGame: String, CaseIterable, Identifiable, Hashable {
    case baseball
    case killer
    case shanghai

    var id: String { rawValue }

    /// When `false`, setup shows the game but Start stays disabled with a coming-soon message.
    var isAvailable: Bool {
        switch self {
        case .baseball, .killer, .shanghai:
            true
        }
    }

    var minimumPlayers: Int {
        switch self {
        case .baseball, .shanghai:
            2
        case .killer:
            3
        }
    }

    var titleKey: String {
        switch self {
        case .baseball: "play.party.baseball.title"
        case .killer: "play.party.killer.title"
        case .shanghai: "play.party.shanghai.title"
        }
    }

    var subtitleKey: String {
        switch self {
        case .baseball: "play.party.baseball.subtitle"
        case .killer: "play.party.killer.subtitle"
        case .shanghai: "play.party.shanghai.subtitle"
        }
    }

    var systemImageName: String {
        switch self {
        case .baseball: "sportscourt"
        case .killer: "scope"
        case .shanghai: "sparkles"
        }
    }

    var accessibilityIdentifier: String {
        "setup_party_game_\(rawValue)"
    }
}
