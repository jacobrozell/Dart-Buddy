import Foundation

public enum AchievementEvaluator {
    private static let minimumAverageDarts = 9
    private static let minimumCheckoutAttempts = 3

    public static func evaluateTurnAccepted(_ context: AchievementEvaluationContext) -> [AchievementDelta] {
        guard let latestTurn = context.latestTurn else { return [] }
        var deltas: [AchievementDelta] = []

        for playerId in context.humanPlayerIds {
            let existing = context.existingProgressByPlayer[playerId] ?? [:]
            let lifetime = context.lifetimeByPlayer[playerId] ?? AchievementLifetimeCounters()

            switch latestTurn.payload {
            case let .x01Turn(turn) where turn.playerId == playerId:
                if isT20(darts: turn.darts), !isUnlocked("db.dart.first_t20", existing: existing) {
                    deltas.append(unlock(playerId: playerId, achievementId: "db.dart.first_t20", at: context.evaluationDate))
                }
                if turn.appliedTotal == 180 {
                    deltas.append(contentsOf: visit180Deltas(playerId: playerId, lifetime: lifetime, existing: existing, at: context.evaluationDate))
                }
                if turn.didCheckout, turn.startRemaining >= 100, !isUnlocked("db.checkout.100_plus", existing: existing) {
                    deltas.append(unlock(playerId: playerId, achievementId: "db.checkout.100_plus", at: context.evaluationDate))
                }
                if turn.didCheckout, turn.startRemaining >= 150, !isUnlocked("db.checkout.150_plus", existing: existing) {
                    deltas.append(unlock(playerId: playerId, achievementId: "db.checkout.150_plus", at: context.evaluationDate))
                }
            case let .cricketTurn(turn) where turn.playerId == playerId:
                if isT20(touches: turn.targetsTouched), !isUnlocked("db.dart.first_t20", existing: existing) {
                    deltas.append(unlock(playerId: playerId, achievementId: "db.dart.first_t20", at: context.evaluationDate))
                }
            default:
                break
            }
        }

        return deltas
    }

    public static func evaluateMatchCompleted(_ context: AchievementEvaluationContext) -> [AchievementDelta] {
        guard context.matchStatus == .completed else { return [] }
        var deltas: [AchievementDelta] = []

        for playerId in context.humanPlayerIds {
            let existing = context.existingProgressByPlayer[playerId] ?? [:]
            let lifetime = context.lifetimeByPlayer[playerId] ?? AchievementLifetimeCounters()
            let didWin = context.winnerPlayerId == playerId

            if lifetime.completedMatchesPlayed == 1, !isUnlocked("db.play.first", existing: existing) {
                deltas.append(unlock(playerId: playerId, achievementId: "db.play.first", at: context.evaluationDate))
            }

            if lifetime.matchWins == 1, didWin, !isUnlocked("db.win.first", existing: existing) {
                deltas.append(unlock(playerId: playerId, achievementId: "db.win.first", at: context.evaluationDate))
            }

            deltas.append(contentsOf: incrementalDeltas(
                playerId: playerId,
                achievementId: "db.play.10",
                currentValue: lifetime.completedMatchesPlayed,
                threshold: 10,
                existing: existing,
                at: context.evaluationDate
            ))
            deltas.append(contentsOf: incrementalDeltas(
                playerId: playerId,
                achievementId: "db.play.50",
                currentValue: lifetime.completedMatchesPlayed,
                threshold: 50,
                existing: existing,
                at: context.evaluationDate
            ))
            deltas.append(contentsOf: incrementalDeltas(
                playerId: playerId,
                achievementId: "db.play.100",
                currentValue: lifetime.completedMatchesPlayed,
                threshold: 100,
                existing: existing,
                at: context.evaluationDate
            ))
            deltas.append(contentsOf: incrementalDeltas(
                playerId: playerId,
                achievementId: "db.play.250",
                currentValue: lifetime.completedMatchesPlayed,
                threshold: 250,
                existing: existing,
                at: context.evaluationDate
            ))
            deltas.append(contentsOf: incrementalDeltas(
                playerId: playerId,
                achievementId: "db.play.500",
                currentValue: lifetime.completedMatchesPlayed,
                threshold: 500,
                existing: existing,
                at: context.evaluationDate
            ))
            deltas.append(contentsOf: incrementalDeltas(
                playerId: playerId,
                achievementId: "db.legs.win_100",
                currentValue: lifetime.legsWon,
                threshold: 100,
                existing: existing,
                at: context.evaluationDate
            ))
            deltas.append(contentsOf: incrementalDeltas(
                playerId: playerId,
                achievementId: "db.streak.days_30_consecutive",
                currentValue: lifetime.consecutiveCalendarDaysPlayed,
                threshold: 30,
                existing: existing,
                at: context.evaluationDate
            ))

            if lifetime.consecutiveMatchWins >= 3, !isUnlocked("db.streak.win_3", existing: existing) {
                deltas.append(unlock(playerId: playerId, achievementId: "db.streak.win_3", at: context.evaluationDate))
            }
            if lifetime.consecutiveCalendarDaysPlayed >= 3, !isUnlocked("db.streak.days_3", existing: existing) {
                deltas.append(unlock(playerId: playerId, achievementId: "db.streak.days_3", at: context.evaluationDate))
            }
            if lifetime.consecutiveCalendarDaysPlayed >= 7, !isUnlocked("db.streak.days_7_consecutive", existing: existing) {
                deltas.append(unlock(playerId: playerId, achievementId: "db.streak.days_7_consecutive", at: context.evaluationDate))
            }

            if context.matchType == .x01 {
                let average = x01MatchAverage(playerId: playerId, events: context.matchEvents)
                if average >= 60, x01DartsThrown(playerId: playerId, events: context.matchEvents) >= minimumAverageDarts,
                   !isUnlocked("db.avg.match_60", existing: existing) {
                    deltas.append(unlock(playerId: playerId, achievementId: "db.avg.match_60", at: context.evaluationDate))
                }
                if average >= 80, x01DartsThrown(playerId: playerId, events: context.matchEvents) >= minimumAverageDarts,
                   !isUnlocked("db.avg.match_80", existing: existing) {
                    deltas.append(unlock(playerId: playerId, achievementId: "db.avg.match_80", at: context.evaluationDate))
                }

                if didWin {
                    let attempts = checkoutAttempts(playerId: playerId, events: context.matchEvents)
                    let successes = checkoutSuccesses(playerId: playerId, events: context.matchEvents)
                    if attempts >= minimumCheckoutAttempts {
                        let rate = Double(successes) / Double(attempts)
                        if rate >= 0.5, !isUnlocked("db.checkout.rate_50", existing: existing) {
                            deltas.append(unlock(playerId: playerId, achievementId: "db.checkout.rate_50", at: context.evaluationDate))
                        }
                        if rate == 1, !isUnlocked("db.checkout.rate_100", existing: existing) {
                            deltas.append(unlock(playerId: playerId, achievementId: "db.checkout.rate_100", at: context.evaluationDate))
                        }
                    }
                }
            }
        }

        return deltas
    }

    public static func evaluateAll(_ context: AchievementEvaluationContext, includeTurnRules: Bool) -> [AchievementDelta] {
        var deltas = evaluateMatchCompleted(context)
        if includeTurnRules {
            deltas.append(contentsOf: evaluateTurnAccepted(context))
        }
        return dedupe(deltas)
    }

    public static func reconcileAfterUndo(
        playerId: UUID,
        lifetime: AchievementLifetimeCounters,
        existing: [String: PlayerAchievementProgress],
        matchEvents: [MatchEventEnvelope],
        matchType: MatchType,
        matchStatus: MatchLifecycleStatus,
        evaluationDate: Date
    ) -> [AchievementDelta] {
        let context = AchievementEvaluationContext(
            matchId: UUID(),
            matchType: matchType,
            matchStatus: matchStatus,
            isCampaignMatch: false,
            humanPlayerIds: [playerId],
            winnerPlayerId: nil,
            latestTurn: matchEvents.last,
            matchEvents: matchEvents,
            lifetimeByPlayer: [playerId: lifetime],
            existingProgressByPlayer: [playerId: existing],
            evaluationDate: evaluationDate
        )

        let desired = Set(evaluateAll(context, includeTurnRules: true).filter { $0.kind != .revoke }.map(\.achievementId))
        var deltas: [AchievementDelta] = []

        for achievementId in AchievementCatalog.phase1.map(\.id) {
            let wasUnlocked = existing[achievementId]?.isUnlocked == true
            let shouldUnlock = desired.contains(achievementId)
            if wasUnlocked, !shouldUnlock {
                deltas.append(AchievementDelta(playerId: playerId, achievementId: achievementId, kind: .revoke))
            }
        }

        deltas.append(contentsOf: evaluateAll(context, includeTurnRules: true))
        return dedupe(deltas)
    }

    private static func visit180Deltas(
        playerId: UUID,
        lifetime: AchievementLifetimeCounters,
        existing: [String: PlayerAchievementProgress],
        at date: Date
    ) -> [AchievementDelta] {
        var deltas: [AchievementDelta] = []
        if !isUnlocked("db.visit.180", existing: existing) {
            deltas.append(unlock(playerId: playerId, achievementId: "db.visit.180", at: date))
        }
        deltas.append(contentsOf: incrementalDeltas(
            playerId: playerId,
            achievementId: "db.visit.180_20",
            currentValue: lifetime.lifetime180Visits,
            threshold: 20,
            existing: existing,
            at: date
        ))
        deltas.append(contentsOf: incrementalDeltas(
            playerId: playerId,
            achievementId: "db.visit.180_100",
            currentValue: lifetime.lifetime180Visits,
            threshold: 100,
            existing: existing,
            at: date
        ))
        return deltas
    }

    private static func incrementalDeltas(
        playerId: UUID,
        achievementId: String,
        currentValue: Int,
        threshold: Int,
        existing: [String: PlayerAchievementProgress],
        at date: Date
    ) -> [AchievementDelta] {
        guard threshold > 0 else { return [] }
        let percent = min(100, (currentValue * 100) / threshold)
        if currentValue >= threshold {
            if isUnlocked(achievementId, existing: existing) { return [] }
            return [unlock(playerId: playerId, achievementId: achievementId, at: date, progressPercent: 100)]
        }
        let previous = existing[achievementId]?.progressPercent ?? 0
        guard percent > previous else { return [] }
        return [
            AchievementDelta(
                playerId: playerId,
                achievementId: achievementId,
                kind: .progressUpdate,
                progressPercent: percent
            )
        ]
    }

    private static func unlock(
        playerId: UUID,
        achievementId: String,
        at date: Date,
        progressPercent: Int = 100
    ) -> AchievementDelta {
        AchievementDelta(
            playerId: playerId,
            achievementId: achievementId,
            kind: .unlock,
            progressPercent: progressPercent,
            unlockedAt: date
        )
    }

    private static func isUnlocked(_ achievementId: String, existing: [String: PlayerAchievementProgress]) -> Bool {
        existing[achievementId]?.isUnlocked == true
    }

    private static func isT20(darts: [X01DartEvent]) -> Bool {
        darts.contains { !$0.wasMiss && $0.segmentRaw == "20" && $0.multiplierRaw == DartMultiplier.triple.rawValue }
    }

    private static func isT20(touches: [CricketDartTouch]) -> Bool {
        touches.contains { !$0.wasMiss && $0.targetRaw == "20" && $0.multiplierRaw == DartMultiplier.triple.rawValue }
    }

    private static func x01MatchAverage(playerId: UUID, events: [MatchEventEnvelope]) -> Double {
        var points = 0
        var darts = 0
        for envelope in events {
            guard case let .x01Turn(turn) = envelope.payload, turn.playerId == playerId else { continue }
            points += turn.appliedTotal
            darts += turn.effectiveDartsThrown
        }
        return StatsService.x01Average3Dart(totalPointsScored: points, totalDartsThrown: darts)
    }

    private static func x01DartsThrown(playerId: UUID, events: [MatchEventEnvelope]) -> Int {
        events.reduce(into: 0) { total, envelope in
            guard case let .x01Turn(turn) = envelope.payload, turn.playerId == playerId else { return }
            total += turn.effectiveDartsThrown
        }
    }

    private static func checkoutAttempts(playerId: UUID, events: [MatchEventEnvelope]) -> Int {
        events.reduce(into: 0) { count, envelope in
            guard case let .x01Turn(turn) = envelope.payload,
                  turn.playerId == playerId,
                  turn.startRemaining <= 170,
                  turn.effectiveDartsThrown > 0 else { return }
            count += 1
        }
    }

    private static func checkoutSuccesses(playerId: UUID, events: [MatchEventEnvelope]) -> Int {
        events.reduce(into: 0) { count, envelope in
            guard case let .x01Turn(turn) = envelope.payload,
                  turn.playerId == playerId,
                  turn.startRemaining <= 170,
                  turn.effectiveDartsThrown > 0,
                  turn.didCheckout else { return }
            count += 1
        }
    }

    private static func dedupe(_ deltas: [AchievementDelta]) -> [AchievementDelta] {
        var seen = Set<String>()
        return deltas.filter { delta in
            let key = "\(delta.playerId.uuidString)-\(delta.achievementId)-\(delta.kind.rawValue)"
            return seen.insert(key).inserted
        }
    }
}
