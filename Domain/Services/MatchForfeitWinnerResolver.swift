import Foundation

enum MatchForfeitWinnerResolution: Equatable {
    case automatic(winnerPlayerId: UUID?)
    case chooseAmongTied([ForfeitCandidate])
}

struct ForfeitCandidate: Identifiable, Equatable {
    let playerId: UUID
    let displayName: String
    let standingSummary: String

    var id: UUID { playerId }
}

enum MatchForfeitWinnerResolver {
    static func resolve(
        session: MatchLifecycleSession,
        forfeitingPlayerId: UUID
    ) throws -> MatchForfeitWinnerResolution {
        let remaining = session.runtime.participants.filter {
            ($0.playerId ?? $0.id) != forfeitingPlayerId
        }
        guard !remaining.isEmpty else {
            return .automatic(winnerPlayerId: nil)
        }
        if remaining.count == 1 {
            let key = remaining[0].playerId ?? remaining[0].id
            return .automatic(winnerPlayerId: key)
        }

        let nameById = Dictionary(
            session.runtime.participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) },
            uniquingKeysWith: { first, _ in first }
        )

        let standings = try remaining.map { participant -> MatchForfeitStanding in
            let key = participant.playerId ?? participant.id
            return try MatchForfeitStandingsRegistry.standing(for: key, in: session)
        }

        let sorted = standings.sorted { lhs, rhs in
            compare(lhs, rhs)
        }

        guard let best = sorted.first else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: false,
                userMessageKey: "error.match.forfeit.invalid"
            )
        }

        let tied = sorted.filter { compare($0, best) == false && isTied($0, best) }
        if tied.count == 1 {
            return .automatic(winnerPlayerId: best.playerId)
        }

        let candidates = tied.map { standing -> ForfeitCandidate in
            ForfeitCandidate(
                playerId: standing.playerId,
                displayName: nameById[standing.playerId] ?? standing.playerId.uuidString.prefix(6).description,
                standingSummary: L10n.format(standing.summaryKey, standing.summaryValue)
            )
        }
        return .chooseAmongTied(candidates)
    }

    private static func compare(_ lhs: MatchForfeitStanding, _ rhs: MatchForfeitStanding) -> Bool {
        if lhs.prefersLowerScore {
            if lhs.primaryScore != rhs.primaryScore { return lhs.primaryScore < rhs.primaryScore }
        } else if lhs.primaryScore != rhs.primaryScore {
            return lhs.primaryScore > rhs.primaryScore
        }
        return lhs.tieBreakKey < rhs.tieBreakKey
    }

    private static func isTied(_ lhs: MatchForfeitStanding, _ rhs: MatchForfeitStanding) -> Bool {
        lhs.primaryScore == rhs.primaryScore && lhs.tieBreakKey == rhs.tieBreakKey
    }
}
