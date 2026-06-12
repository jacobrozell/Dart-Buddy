import Foundation

struct EditablePlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var isArchived: Bool
    var notes: String
    var isBot: Bool
    var isTrainingBot: Bool
    var isCustomBot: Bool
    var customX01Average: Double
    var customCricketMPR: Double
    var customBotConfiguration: CustomBotConfiguration? = nil
    var linkedPlayerId: UUID?
    var botDifficulty: BotDifficulty?
    var avatarStyle: PlayerAvatarStyle
    var colorToken: PlayerColorToken
    var playerRole: PlayerRole? = nil

    var isPrimaryPlayer: Bool {
        playerRole == .primary
    }

    static func from(_ summary: PlayerSummary) -> EditablePlayer {
        EditablePlayer(
            id: summary.id,
            name: summary.name,
            isArchived: summary.isArchived,
            notes: summary.notes ?? "",
            isBot: summary.isBot,
            isTrainingBot: summary.isTrainingBot,
            isCustomBot: summary.isCustomBot,
            customX01Average: summary.customBotMetrics?.x01Average ?? CustomBotMetrics.defaultX01Average,
            customCricketMPR: summary.customBotMetrics?.cricketMPR ?? CustomBotMetrics.defaultCricketMPR,
            customBotConfiguration: summary.customBotConfiguration,
            linkedPlayerId: summary.linkedPlayerId,
            botDifficulty: summary.botDifficulty,
            avatarStyle: summary.avatarStyle,
            colorToken: summary.colorToken,
            playerRole: summary.playerRole
        )
    }
}
