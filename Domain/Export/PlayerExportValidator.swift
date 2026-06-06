import Foundation

public enum PlayerExportValidationFailure: Error, Sendable, Equatable {
    case unsupportedVersion(Int)
    case anchorPlayerMismatch
    case matchNotCompleted(UUID)
    case missingParticipants(UUID)
    case eventIndicesNotContiguous(matchId: UUID, expected: Int, actual: Int)
}

public enum PlayerExportValidator {
    public static func validate(_ bundle: PlayerExportBundle) throws {
        guard bundle.dbpeVersion == PlayerExportBundle.supportedVersion else {
            throw PlayerExportValidationFailure.unsupportedVersion(bundle.dbpeVersion)
        }
        guard bundle.player.id == bundle.anchorPlayerId else {
            throw PlayerExportValidationFailure.anchorPlayerMismatch
        }

        for matchBundle in bundle.matches {
            let matchId = matchBundle.match.id
            guard matchBundle.match.status == .completed else {
                throw PlayerExportValidationFailure.matchNotCompleted(matchId)
            }
            guard !matchBundle.participants.isEmpty else {
                throw PlayerExportValidationFailure.missingParticipants(matchId)
            }
            let sortedIndices = matchBundle.events.map(\.eventIndex).sorted()
            for (expected, actual) in sortedIndices.enumerated() where expected != actual {
                throw PlayerExportValidationFailure.eventIndicesNotContiguous(
                    matchId: matchId,
                    expected: expected,
                    actual: actual
                )
            }
        }
    }
}
