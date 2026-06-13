import Foundation

public protocol AchievementService: Sendable {
    func evaluateAfterTurn(session: MatchLifecycleSession) async throws -> [AchievementUnlockPresentation]
    func evaluateAfterMatchCompleted(session: MatchLifecycleSession) async throws -> [AchievementUnlockPresentation]
    func evaluateAfterUndo(session: MatchLifecycleSession) async throws
    func fetchGalleryProgress(playerId: UUID) async throws -> [PlayerAchievementProgress]
    func sessionPresentations(for matchId: UUID) async -> [AchievementUnlockPresentation]
}

public actor DefaultAchievementService: AchievementService {
    private let achievementRepository: any AchievementRepository
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let featureFlags: any FeatureFlagsProvider
    private var sessionPresentations: [UUID: [AchievementUnlockPresentation]] = [:]

    public init(
        achievementRepository: any AchievementRepository,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        featureFlags: any FeatureFlagsProvider
    ) {
        self.achievementRepository = achievementRepository
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
        self.featureFlags = featureFlags
    }

    public func evaluateAfterTurn(session: MatchLifecycleSession) async throws -> [AchievementUnlockPresentation] {
        guard featureFlags.isEnabled(.enableAchievements) else { return [] }
        guard !AchievementLifetimeCounterBuilder.humanPlayerIds(in: session).isEmpty else { return [] }

        let context = try await buildContext(session: session, includeCurrentMatchInLifetime: true)
        let deltas = AchievementEvaluator.evaluateTurnAccepted(context)
        let presentations = try await achievementRepository.apply(deltas: deltas, matchId: session.runtime.matchId)
        mergePresentations(presentations, matchId: session.runtime.matchId)
        return presentations
    }

    public func evaluateAfterMatchCompleted(session: MatchLifecycleSession) async throws -> [AchievementUnlockPresentation] {
        guard featureFlags.isEnabled(.enableAchievements) else { return [] }
        guard session.runtime.status == .completed else { return [] }
        guard !AchievementLifetimeCounterBuilder.humanPlayerIds(in: session).isEmpty else { return [] }

        let context = try await buildContext(session: session, includeCurrentMatchInLifetime: true)
        var deltas = AchievementEvaluator.evaluateTurnAccepted(context)
        deltas.append(contentsOf: AchievementEvaluator.evaluateMatchCompleted(context))
        let presentations = try await achievementRepository.apply(deltas: deltas, matchId: session.runtime.matchId)
        mergePresentations(presentations, matchId: session.runtime.matchId)
        return presentations
    }

    public func evaluateAfterUndo(session: MatchLifecycleSession) async throws {
        guard featureFlags.isEnabled(.enableAchievements) else { return }
        sessionPresentations[session.runtime.matchId] = nil

        let playerIds = AchievementLifetimeCounterBuilder.humanPlayerIds(in: session)
        guard !playerIds.isEmpty else { return }

        let completedMatches = try await loadCompletedMatches(for: playerIds)
        let existing = try await achievementRepository.fetchProgress(playerIds: playerIds)
        var allDeltas: [AchievementDelta] = []

        for playerId in playerIds {
            let lifetime = AchievementLifetimeCounterBuilder.build(
                completedMatches: completedMatches,
                currentSession: session.runtime.status == .completed ? session : nil,
                playerIds: [playerId]
            )[playerId] ?? AchievementLifetimeCounters()
            allDeltas.append(contentsOf: AchievementEvaluator.reconcileAfterUndo(
                playerId: playerId,
                lifetime: lifetime,
                existing: existing[playerId] ?? [:],
                matchEvents: session.events,
                matchType: session.runtime.type,
                matchStatus: session.runtime.status,
                evaluationDate: Date()
            ))
        }

        _ = try await achievementRepository.apply(deltas: allDeltas, matchId: session.runtime.matchId)
    }

    public func fetchGalleryProgress(playerId: UUID) async throws -> [PlayerAchievementProgress] {
        guard featureFlags.isEnabled(.enableAchievements) else { return [] }
        return try await achievementRepository.fetchProgress(playerId: playerId)
    }

    public func sessionPresentations(for matchId: UUID) async -> [AchievementUnlockPresentation] {
        presentations(for: matchId)
    }

    public func presentations(for matchId: UUID) -> [AchievementUnlockPresentation] {
        sessionPresentations[matchId] ?? []
    }

    public func clearPresentations(for matchId: UUID) {
        sessionPresentations[matchId] = nil
    }

    private func buildContext(
        session: MatchLifecycleSession,
        includeCurrentMatchInLifetime: Bool
    ) async throws -> AchievementEvaluationContext {
        let humanPlayerIds = AchievementLifetimeCounterBuilder.humanPlayerIds(in: session)
        let completedMatches = try await loadCompletedMatches(for: humanPlayerIds)
        let existing = try await achievementRepository.fetchProgress(playerIds: humanPlayerIds)
        let lifetimeByPlayer = AchievementLifetimeCounterBuilder.build(
            completedMatches: completedMatches,
            currentSession: includeCurrentMatchInLifetime ? session : nil,
            playerIds: humanPlayerIds
        )

        return AchievementEvaluationContext(
            matchId: session.runtime.matchId,
            matchType: session.runtime.type,
            matchStatus: session.runtime.status,
            isCampaignMatch: false,
            humanPlayerIds: humanPlayerIds,
            winnerPlayerId: session.runtime.winnerPlayerId,
            latestTurn: session.events.last,
            matchEvents: session.events,
            lifetimeByPlayer: lifetimeByPlayer,
            existingProgressByPlayer: existing,
            evaluationDate: Date()
        )
    }

    private func loadCompletedMatches(for playerIds: [UUID]) async throws -> [MatchStatsInput] {
        var allInputs: [MatchStatsInput] = []
        for playerId in playerIds {
            let result = try await MatchStatsLoader.load(
                matchRepository: matchRepository,
                statsRepository: statsRepository,
                request: MatchStatsLoadRequest(participantPlayerId: playerId)
            )
            allInputs.append(contentsOf: result.inputs.filter { !$0.isPartial })
        }
        var byId: [UUID: MatchStatsInput] = [:]
        for input in allInputs where !input.isPartial {
            byId[input.matchId] = input
        }
        return Array(byId.values)
    }

    private func mergePresentations(_ presentations: [AchievementUnlockPresentation], matchId: UUID) {
        guard !presentations.isEmpty else { return }
        var merged = sessionPresentations[matchId] ?? []
        for presentation in presentations {
            if !merged.contains(where: { $0.id == presentation.id }) {
                merged.append(presentation)
            }
        }
        sessionPresentations[matchId] = merged
    }
}

@MainActor
public enum AchievementHooks {
    public static var service: (any AchievementService)?

    public static func evaluateAfterPersistedTurn(_ session: MatchLifecycleSession) async {
        guard let service else { return }
        do {
            if session.runtime.status == .completed {
                _ = try await service.evaluateAfterMatchCompleted(session: session)
            } else {
                _ = try await service.evaluateAfterTurn(session: session)
            }
        } catch {
            // Achievements are best-effort; scoring persistence already succeeded.
        }
    }

    public static func evaluateAfterUndo(_ session: MatchLifecycleSession) async {
        guard let service else { return }
        do {
            try await service.evaluateAfterUndo(session: session)
        } catch {
            // Achievements are best-effort; undo persistence already succeeded.
        }
    }

    public static func register(service: any AchievementService) {
        self.service = service
    }
}
