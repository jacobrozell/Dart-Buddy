import Foundation

public enum AchievementLifetimeCounterBuilder {
    private static let calendar = Calendar.current

    public static func humanPlayerIds(in session: MatchLifecycleSession) -> [UUID] {
        session.runtime.participants
            .filter { !$0.isBot }
            .map { $0.playerId ?? $0.id }
    }

    public static func build(
        completedMatches: [MatchStatsInput],
        currentSession: MatchLifecycleSession?,
        playerIds: [UUID]
    ) -> [UUID: AchievementLifetimeCounters] {
        var byPlayer: [UUID: AchievementLifetimeCounters] = [:]
        for playerId in playerIds {
            byPlayer[playerId] = AchievementLifetimeCounters()
        }

        let sortedMatches = completedMatches.sorted { $0.playedAt < $1.playedAt }
        for match in sortedMatches where !match.isPartial {
            applyMatch(match, to: &byPlayer)
        }

        if let currentSession {
            let currentInput = statsInput(from: currentSession)
            if currentSession.runtime.status == .completed || currentSession.runtime.status == .forfeited {
                if !sortedMatches.contains(where: { $0.matchId == currentInput.matchId }) {
                    applyMatch(currentInput, to: &byPlayer)
                }
            } else {
                applyInProgressDartStats(currentInput, to: &byPlayer)
            }
        }

        return byPlayer
    }

    private static func applyInProgressDartStats(
        _ match: MatchStatsInput,
        to counters: inout [UUID: AchievementLifetimeCounters]
    ) {
        for playerId in match.participantKeys {
            guard var state = counters[playerId] else { continue }
            for envelope in match.events {
                switch envelope.payload {
                case let .x01Turn(turn) where turn.playerId == playerId:
                    if turn.appliedTotal == 180 {
                        state.lifetime180Visits += 1
                    }
                    for dart in turn.darts where !dart.wasMiss {
                        if dart.segmentRaw == "20", dart.multiplierRaw == DartMultiplier.triple.rawValue {
                            state.hasHitT20 = true
                        }
                    }
                case let .cricketTurn(turn) where turn.playerId == playerId:
                    for touch in turn.targetsTouched where !touch.wasMiss {
                        if touch.targetRaw == "20", touch.multiplierRaw == DartMultiplier.triple.rawValue {
                            state.hasHitT20 = true
                        }
                    }
                default:
                    break
                }
            }
            counters[playerId] = state
        }
    }

    public static func statsInput(from session: MatchLifecycleSession) -> MatchStatsInput {
        MatchStatsInput(
            matchId: session.runtime.matchId,
            playedAt: session.runtime.endedAt ?? session.runtime.startedAt,
            type: session.runtime.type,
            participantKeys: session.runtime.participants.map { $0.playerId ?? $0.id },
            winnerKey: session.runtime.winnerPlayerId,
            events: session.events,
            isPartial: session.runtime.status != .completed && session.runtime.status != .forfeited
        )
    }

    private static func applyMatch(
        _ match: MatchStatsInput,
        to counters: inout [UUID: AchievementLifetimeCounters]
    ) {
        if match.isPartial { return }
        for playerId in match.participantKeys {
            guard var state = counters[playerId] else { continue }

            state.completedMatchesPlayed += 1
            if match.winnerKey == playerId {
                state.matchWins += 1
                state.consecutiveMatchWins += 1
            } else if match.winnerKey != nil {
                state.consecutiveMatchWins = 0
            } else {
                state.consecutiveMatchWins = 0
            }

            let day = calendar.startOfDay(for: match.playedAt)
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
            if let lastDay = state.lastPlayedCalendarDay {
                if lastDay == dayComponents {
                    // Same day — streak unchanged.
                } else if isNextDay(after: lastDay, before: dayComponents) {
                    state.consecutiveCalendarDaysPlayed += 1
                    state.lastPlayedCalendarDay = dayComponents
                } else {
                    state.consecutiveCalendarDaysPlayed = 1
                    state.lastPlayedCalendarDay = dayComponents
                }
            } else {
                state.consecutiveCalendarDaysPlayed = 1
                state.lastPlayedCalendarDay = dayComponents
            }

            for envelope in match.events {
                switch envelope.payload {
                case let .x01Turn(turn) where turn.playerId == playerId:
                    if turn.appliedTotal == 180 {
                        state.lifetime180Visits += 1
                    }
                    if turn.didCheckout {
                        state.legsWon += 1
                    }
                    for dart in turn.darts where !dart.wasMiss {
                        if dart.segmentRaw == "20", dart.multiplierRaw == DartMultiplier.triple.rawValue {
                            state.hasHitT20 = true
                        }
                    }
                case let .cricketTurn(turn) where turn.playerId == playerId:
                    for touch in turn.targetsTouched where !touch.wasMiss {
                        if touch.targetRaw == "20", touch.multiplierRaw == DartMultiplier.triple.rawValue {
                            state.hasHitT20 = true
                        }
                    }
                default:
                    break
                }
            }

            if match.winnerKey == playerId, match.type != .x01 {
                state.legsWon += 1
            }

            counters[playerId] = state
        }
    }

    private static func isNextDay(after previous: DateComponents, before next: DateComponents) -> Bool {
        guard let previousDate = calendar.date(from: previous),
              let nextDate = calendar.date(from: next) else {
            return false
        }
        guard let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: previousDate)) else {
            return false
        }
        return calendar.isDate(expected, inSameDayAs: nextDate)
    }
}
