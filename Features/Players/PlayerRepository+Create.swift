import Foundation

extension PlayerRepository {
    func createHumanPlayer(from player: EditablePlayer) async throws -> PlayerSummary {
        let created = try await createPlayer(name: player.name)
        let updated = try await updatePlayerProfile(
            playerId: created.id,
            name: player.name,
            avatarStyle: player.avatarStyle,
            colorToken: player.colorToken,
            notes: player.notes
        )
        if player.isPrimaryPlayer {
            return try await designatePrimaryPlayer(playerId: updated.id)
        }
        return updated
    }
}
