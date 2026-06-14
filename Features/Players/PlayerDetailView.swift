import SwiftUI

struct PlayerDetailView: View {
    let player: EditablePlayer?
    let existingNames: [String]
    let dependencies: AppDependencies
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void
    let onSave: (EditablePlayer) -> Void
    let onExportResult: (Result<URL, Error>) -> Void
    let onSelectRecentMatch: (UUID) -> Void

    init(
        player: EditablePlayer?,
        existingNames: [String],
        dependencies: AppDependencies,
        onEdit: @escaping () -> Void,
        onArchiveToggle: @escaping () -> Void,
        onSave: @escaping (EditablePlayer) -> Void,
        onExportResult: @escaping (Result<URL, Error>) -> Void = { _ in },
        onSelectRecentMatch: @escaping (UUID) -> Void = { _ in }
    ) {
        self.player = player
        self.existingNames = existingNames
        self.dependencies = dependencies
        self.onEdit = onEdit
        self.onArchiveToggle = onArchiveToggle
        self.onSave = onSave
        self.onExportResult = onExportResult
        self.onSelectRecentMatch = onSelectRecentMatch
    }

    var body: some View {
        Group {
            if let player {
                if player.isBot, player.isCustomBot {
                    CustomBotDetailView(
                        player: player,
                        existingNames: existingNames,
                        dependencies: dependencies,
                        onSave: onSave,
                        onSelectRecentMatch: onSelectRecentMatch
                    )
                } else if player.isBot, let botDifficulty = player.botDifficulty {
                    BotDetailView(
                        player: player,
                        difficulty: botDifficulty,
                        existingNames: existingNames,
                        dependencies: dependencies,
                        onSave: onSave,
                        onSelectRecentMatch: onSelectRecentMatch
                    )
                } else if player.isBot {
                    TrainingBotDetailView(
                        player: player,
                        existingNames: existingNames,
                        dependencies: dependencies,
                        onSave: onSave,
                        onSelectRecentMatch: onSelectRecentMatch
                    )
                } else {
                    PlayerStatsDetailView(
                        player: player,
                        dependencies: dependencies,
                        onEdit: onEdit,
                        onArchiveToggle: onArchiveToggle,
                        onExportResult: onExportResult,
                        onSelectRecentMatch: onSelectRecentMatch
                    )
                }
            } else {
                ContentUnavailableView(L10n.playerNotFound, systemImage: "person.crop.circle.badge.exclamationmark")
                    .brandScoreboardEmptyState()
            }
        }
        .navigationTitle(player?.isBot == true ? L10n.botDetailTitle : L10n.playerDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
