import Foundation

enum MatchHistoryCardBuilder {
    static func build(from runtime: MatchRuntimeState, nameById: [UUID: String]) -> MatchHistoryCardPayload {
        let (configText, standings) = standingsAndConfig(from: runtime, nameById: nameById)
        return MatchHistoryCardPayload(configText: configText, standings: standings)
    }

    private static func standingsAndConfig(
        from runtime: MatchRuntimeState,
        nameById: [UUID: String]
    ) -> (String, [MatchHistoryCardStanding]) {
        if let state = runtime.x01State {
            let configText = MatchConfigText.x01CardConfig(from: state.config)
            let standings = state.players.map { player in
                MatchHistoryCardStanding(
                    playerId: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: player.setsWon,
                    legs: player.legsWon,
                    score: player.remainingScore
                )
            }
            return (configText, sortStandings(standings))
        }

        if let state = runtime.cricketState {
            let standings = state.players.map { player in
                MatchHistoryCardStanding(
                    playerId: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.score
                )
            }
            return (MatchConfigText.modeLabel(for: .cricket), sortStandings(standings))
        }

        if let state = runtime.baseballState {
            let standings = state.players.map { player in
                MatchHistoryCardStanding(
                    playerId: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.cumulativeRuns
                )
            }
            return (MatchConfigText.modeLabel(for: .baseball), sortStandings(standings))
        }

        if let state = runtime.killerState {
            let standings = state.players.map { player in
                MatchHistoryCardStanding(
                    playerId: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.lives
                )
            }
            return (MatchConfigText.modeLabel(for: .killer), sortStandings(standings))
        }

        if let state = runtime.shanghaiState {
            let standings = state.players.map { player in
                MatchHistoryCardStanding(
                    playerId: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.cumulativePoints
                )
            }
            return (MatchConfigText.modeLabel(for: .shanghai), sortStandings(standings))
        }

        return (MatchConfigText.modeLabel(for: runtime.type), [])
    }

    private static func sortStandings(_ standings: [MatchHistoryCardStanding]) -> [MatchHistoryCardStanding] {
        standings.sorted { lhs, rhs in
            if lhs.isWinner != rhs.isWinner { return lhs.isWinner }
            return lhs.score < rhs.score
        }
    }
}
