import Foundation

enum StoredBotConfiguration: Codable, Sendable, Equatable {
    case preset(BotDifficulty)
    case training(TrainingBotStoredState)
    case custom(CustomBotConfiguration)

    var botKind: BotKind {
        switch self {
        case .preset: .preset
        case .training: .training
        case .custom: .custom
        }
    }

    static func decode(player: PlayerSummary) -> StoredBotConfiguration? {
        guard player.isBot else { return nil }
        if let kind = player.botKind {
            switch kind {
            case .custom:
                guard let configuration = player.customBotConfiguration else { return nil }
                return .custom(configuration)
            case .training:
                guard let linkedPlayerId = player.linkedPlayerId else { return nil }
                return .training(TrainingBotStoredState(linkedPlayerId: linkedPlayerId))
            case .preset:
                guard let difficulty = player.botDifficulty else { return nil }
                return .preset(difficulty)
            }
        }
        if let configuration = player.customBotConfiguration {
            return .custom(configuration)
        }
        if let difficulty = player.botDifficulty {
            return .preset(difficulty)
        }
        return nil
    }
}

struct TrainingBotStoredState: Codable, Equatable, Sendable {
    let linkedPlayerId: UUID

    init(linkedPlayerId: UUID) {
        self.linkedPlayerId = linkedPlayerId
    }
}
