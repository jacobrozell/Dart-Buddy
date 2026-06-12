import Foundation

/// Ensures every install has at most one designated primary human player.
enum PrimaryPlayerBootstrap {
    static func promoteOldestHumanIfNeeded(using repository: any PlayerRepository) async {
        guard (try? await repository.fetchPrimaryPlayer()) == nil else { return }
        guard let humans = try? await repository.fetchPlayers(includeArchived: false).filter({ !$0.isBot }),
              let oldest = humans.min(by: { $0.createdAt < $1.createdAt })
        else { return }
        _ = try? await repository.designatePrimaryPlayer(playerId: oldest.id)
    }
}
