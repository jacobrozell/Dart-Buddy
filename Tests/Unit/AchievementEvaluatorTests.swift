import Foundation
import Testing
@testable import DartBuddy

@Suite("Achievement evaluator", .tags(.unit, .achievements, .regression))
struct AchievementEvaluatorTests {
    @Test
    func evaluateTurnAcceptedUnlocksFirstT20FromX01Triple20() {
        let playerId = UUID()
        let turn = AchievementTestFixtures.x01Turn(
            playerId: playerId,
            appliedTotal: 60,
            darts: [AchievementTestFixtures.triple20Dart(order: 1)]
        )
        let context = AchievementTestFixtures.context(
            humanPlayerIds: [playerId],
            latestTurn: turn,
            matchEvents: [turn]
        )

        let deltas = AchievementEvaluator.evaluateTurnAccepted(context)

        #expect(deltas.contains {
            $0.playerId == playerId
                && $0.achievementId == "db.dart.first_t20"
                && $0.kind == .unlock
        })
    }

    @Test
    func evaluateTurnAcceptedUnlocksVisit180() {
        let playerId = UUID()
        let turn = AchievementTestFixtures.x01Turn(playerId: playerId, appliedTotal: 180)
        let context = AchievementTestFixtures.context(
            humanPlayerIds: [playerId],
            latestTurn: turn,
            matchEvents: [turn]
        )

        let deltas = AchievementEvaluator.evaluateTurnAccepted(context)

        #expect(deltas.contains { $0.achievementId == "db.visit.180" && $0.kind == .unlock })
    }

    @Test
    func evaluateTurnAcceptedUnlocks100PlusCheckout() {
        let playerId = UUID()
        let turn = AchievementTestFixtures.x01Turn(
            playerId: playerId,
            startRemaining: 120,
            appliedTotal: 120,
            endRemaining: 0,
            didCheckout: true
        )
        let context = AchievementTestFixtures.context(
            humanPlayerIds: [playerId],
            latestTurn: turn,
            matchEvents: [turn]
        )

        let deltas = AchievementEvaluator.evaluateTurnAccepted(context)

        #expect(deltas.contains { $0.achievementId == "db.checkout.100_plus" && $0.kind == .unlock })
    }

    @Test
    func evaluateTurnAcceptedIgnoresNonHumanPlayers() {
        let botId = UUID()
        let turn = AchievementTestFixtures.x01Turn(
            playerId: botId,
            appliedTotal: 60,
            darts: [AchievementTestFixtures.triple20Dart(order: 1)]
        )
        let context = AchievementTestFixtures.context(
            humanPlayerIds: [],
            latestTurn: turn,
            matchEvents: [turn]
        )

        #expect(AchievementEvaluator.evaluateTurnAccepted(context).isEmpty)
    }

    @Test
    func evaluateMatchCompletedUnlocksFirstPlay() {
        let playerId = UUID()
        let context = AchievementTestFixtures.context(
            humanPlayerIds: [playerId],
            matchStatus: .completed,
            lifetime: AchievementLifetimeCounters(completedMatchesPlayed: 1)
        )

        let deltas = AchievementEvaluator.evaluateMatchCompleted(context)

        #expect(deltas.contains { $0.achievementId == "db.play.first" && $0.kind == .unlock })
    }

    @Test
    func evaluateMatchCompletedUnlocksFirstWin() {
        let playerId = UUID()
        let context = AchievementTestFixtures.context(
            humanPlayerIds: [playerId],
            matchStatus: .completed,
            winnerPlayerId: playerId,
            lifetime: AchievementLifetimeCounters(completedMatchesPlayed: 1, matchWins: 1)
        )

        let deltas = AchievementEvaluator.evaluateMatchCompleted(context)

        #expect(deltas.contains { $0.achievementId == "db.win.first" && $0.kind == .unlock })
    }

    @Test
    func evaluateMatchCompletedUnlocksPlay10Milestone() {
        let playerId = UUID()
        let context = AchievementTestFixtures.context(
            humanPlayerIds: [playerId],
            matchStatus: .completed,
            lifetime: AchievementLifetimeCounters(completedMatchesPlayed: 10)
        )

        let deltas = AchievementEvaluator.evaluateMatchCompleted(context)

        #expect(deltas.contains { $0.achievementId == "db.play.10" && $0.kind == .unlock })
    }

    @Test
    func evaluateMatchCompletedEmitsPlay10ProgressBelowThreshold() {
        let playerId = UUID()
        let context = AchievementTestFixtures.context(
            humanPlayerIds: [playerId],
            matchStatus: .completed,
            lifetime: AchievementLifetimeCounters(completedMatchesPlayed: 5)
        )

        let deltas = AchievementEvaluator.evaluateMatchCompleted(context)

        #expect(deltas.contains {
            $0.achievementId == "db.play.10"
                && $0.kind == .progressUpdate
                && $0.progressPercent == 50
        })
    }

    @Test
    func reconcileAfterUndoRevokesCheckoutWhenTurnRemoved() {
        let playerId = UUID()
        let existing: [String: PlayerAchievementProgress] = [
            "db.checkout.100_plus": PlayerAchievementProgress(
                achievementId: "db.checkout.100_plus",
                unlockedAt: Date(),
                progressPercent: 100
            )
        ]
        let events = [
            AchievementTestFixtures.x01Turn(
                playerId: playerId,
                startRemaining: 281,
                appliedTotal: 20,
                endRemaining: 261
            )
        ]

        let deltas = AchievementEvaluator.reconcileAfterUndo(
            playerId: playerId,
            lifetime: AchievementLifetimeCounters(),
            existing: existing,
            matchEvents: events,
            matchType: .x01,
            matchStatus: .inProgress,
            evaluationDate: Date()
        )

        #expect(deltas.contains {
            $0.achievementId == "db.checkout.100_plus" && $0.kind == .revoke
        })
    }
}

private enum AchievementTestFixtures {
    static func context(
        humanPlayerIds: [UUID],
        matchStatus: MatchLifecycleStatus = .inProgress,
        winnerPlayerId: UUID? = nil,
        latestTurn: MatchEventEnvelope? = nil,
        matchEvents: [MatchEventEnvelope] = [],
        lifetime: AchievementLifetimeCounters = AchievementLifetimeCounters(),
        existing: [String: PlayerAchievementProgress] = [:]
    ) -> AchievementEvaluationContext {
        let lifetimeByPlayer = Dictionary(
            uniqueKeysWithValues: humanPlayerIds.map { ($0, lifetime) }
        )
        let existingByPlayer = Dictionary(
            uniqueKeysWithValues: humanPlayerIds.map { ($0, existing) }
        )
        return AchievementEvaluationContext(
            matchId: UUID(),
            matchType: .x01,
            matchStatus: matchStatus,
            isCampaignMatch: false,
            humanPlayerIds: humanPlayerIds,
            winnerPlayerId: winnerPlayerId,
            latestTurn: latestTurn,
            matchEvents: matchEvents,
            lifetimeByPlayer: lifetimeByPlayer,
            existingProgressByPlayer: existingByPlayer,
            evaluationDate: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    static func x01Turn(
        playerId: UUID,
        startRemaining: Int = 301,
        appliedTotal: Int,
        endRemaining: Int? = nil,
        didCheckout: Bool = false,
        darts: [X01DartEvent] = []
    ) -> MatchEventEnvelope {
        let resolvedEnd = endRemaining ?? (startRemaining - appliedTotal)
        let turn = X01TurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: 0,
            legIndex: 0,
            setIndex: 0,
            startRemaining: startRemaining,
            enteredTotal: appliedTotal,
            appliedTotal: appliedTotal,
            endRemaining: resolvedEnd,
            isBust: false,
            didCheckout: didCheckout,
            checkoutModeRaw: X01CheckoutMode.singleOut.rawValue,
            checkoutDartCount: didCheckout ? 3 : nil,
            darts: darts,
            timestamp: Date(),
            dartsThrown: darts.isEmpty ? 3 : darts.count
        )
        return MatchEventEnvelope(eventIndex: 0, payload: .x01Turn(turn), timestamp: Date())
    }

    static func triple20Dart(order: Int) -> X01DartEvent {
        X01DartEvent(
            dartOrder: order,
            multiplierRaw: DartMultiplier.triple.rawValue,
            segmentRaw: "20",
            points: 60,
            wasMiss: false
        )
    }
}
