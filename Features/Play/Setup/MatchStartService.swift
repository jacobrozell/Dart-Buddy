import Foundation

/// Snapshot of the configured options at the moment the user starts a match,
/// decoupled from `MatchSetupViewModel`'s published state.
struct MatchStartPlan {
    struct RosterEntry {
        let id: UUID
        let name: String
        let botDifficulty: BotDifficulty?
        let isTrainingBot: Bool
        let isCustomBot: Bool
        let customConfiguration: CustomBotConfiguration?
        let linkedPlayerId: UUID?
        let avatarStyleRaw: String?
        let colorTokenRaw: String

        init(player: PlayerSummary) {
            id = player.id
            name = player.name
            botDifficulty = player.botDifficulty
            isTrainingBot = player.isTrainingBot
            isCustomBot = player.isCustomBot
            customConfiguration = player.customBotConfiguration
            linkedPlayerId = player.linkedPlayerId
            avatarStyleRaw = player.isBot ? nil : player.avatarStyle.rawValue
            colorTokenRaw = player.colorToken.rawValue
        }
    }

    let matchType: MatchType
    let config: MatchConfigPayload
    let roster: [RosterEntry]
    let randomOrder: Bool
}

/// Creates and persists a match from a `MatchStartPlan`, and abandons the
/// previous active match when the user opts to replace it. Owns no UI state;
/// outcomes are returned for the view model to publish.
@MainActor
struct MatchStartService {
    enum StartOutcome {
        case started(PlayRoute)
        /// Another match became active mid-start; the caller shows the replace prompt.
        case conflict
        case cancelled
        case failed(messageKey: String)
    }

    let playerRepository: any PlayerRepository
    let matchRepository: any MatchRepository
    let activeMatchStore: ActiveMatchStore
    let logger: any AppLogger

    func start(_ plan: MatchStartPlan) async -> StartOutcome {
        logger.info(
            .scoring,
            eventName: "match_setup_start",
            message: "Starting match from setup.",
            metadata: [
                "matchType": plan.matchType.rawValue,
                "participantCount": String(plan.roster.count)
            ]
        )
        if plan.matchType == .baseball {
            logger.info(
                .scoring,
                eventName: "match_setup_baseball",
                message: "Starting baseball match from party setup.",
                metadata: [
                    "matchType": MatchType.baseball.rawValue,
                    "participantCount": String(plan.roster.count)
                ]
            )
        }
        let catalogEntry = GameModeCatalog.entry(for: plan.matchType)
        let uiTemplate = catalogEntry?.uiTemplate ?? (plan.matchType == .cricket ? .markBoard : .checkoutScore)
        let partyUsesPresetBotsOnly = [.baseball, .killer, .shanghai].contains(plan.matchType)
        let orderedRoster = plan.randomOrder ? plan.roster.shuffled() : plan.roster
        do {
            let participants = try await makeParticipants(
                orderedRoster: orderedRoster,
                matchType: plan.matchType,
                uiTemplate: uiTemplate,
                partyUsesPresetBotsOnly: partyUsesPresetBotsOnly
            )
            let configPayload = try CodablePayloadCoder.encode(plan.config)
            let avatarByPlayerId = Dictionary(
                uniqueKeysWithValues: plan.roster.map { ($0.id, $0.avatarStyleRaw) }
            )
            let participantsForRepository = participants.enumerated().map { index, participant in
                MatchParticipantSummary(
                    id: participant.id,
                    matchId: UUID(),
                    playerId: participant.playerId,
                    turnOrder: index,
                    displayNameAtMatchStart: participant.displayNameAtMatchStart,
                    avatarStyleAtMatchStart: participant.playerId.flatMap { avatarByPlayerId[$0] } ?? nil,
                    botDifficultyRaw: participant.botDifficultyRaw,
                    botKindRaw: participant.botKindRaw,
                    botSkillProfilePayload: participant.botSkillProfilePayload,
                    botEffectiveTierRaw: participant.botEffectiveTierRaw
                )
            }
            let persisted = try await matchRepository.createMatch(
                type: plan.matchType,
                configPayload: configPayload,
                participants: participantsForRepository
            )
            let session = try MatchLifecycleService.createMatch(
                matchId: persisted.id,
                type: plan.matchType,
                config: plan.config,
                participants: participants
            )
            _ = try await matchRepository.saveSnapshot(
                matchId: persisted.id,
                snapshotVersion: session.latestSnapshot.payloadVersion,
                snapshotPayload: session.latestSnapshot.payload
            )
            activeMatchStore.save(session)
            let gameModeMetadata = GameModeAnalytics.metadata(
                for: plan.matchType,
                participantCount: participants.count,
                participants: participants
            )
            logger.info(
                .scoring,
                eventName: "match_started",
                message: "Match created and persisted.",
                metadata: gameModeMetadata.merging([
                    "matchId": persisted.id.uuidString
                ]) { _, new in new },
                correlationId: persisted.id.uuidString
            )
            logger.info(
                .scoring,
                eventName: GameModeAnalytics.playedEventName,
                message: "User started playing a game mode.",
                metadata: gameModeMetadata,
                correlationId: persisted.id.uuidString
            )
            return .started(plan.matchType.playRoute(matchId: persisted.id))
        } catch is CancellationError {
            return .cancelled
        } catch {
            logger.error(
                .scoring,
                eventName: "match_start_failed",
                message: "Match creation failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            if let appError = error as? AppError {
                if appError.code == .conflict {
                    return .conflict
                }
                return .failed(messageKey: appError.userMessageKey)
            }
            return .failed(messageKey: "setup.error.start")
        }
    }

    private func makeParticipants(
        orderedRoster: [MatchStartPlan.RosterEntry],
        matchType: MatchType,
        uiTemplate: GameplayUITemplate,
        partyUsesPresetBotsOnly: Bool
    ) async throws -> [MatchParticipant] {
        let repository = playerRepository
        return try await withThrowingTaskGroup(of: (Int, MatchParticipant).self) { group in
            for (index, entry) in orderedRoster.enumerated() {
                group.addTask {
                    let participant = try await BotParticipantFactory.makeParticipant(
                        input: BotParticipantBuildInput(
                            playerId: entry.id,
                            displayName: entry.name,
                            turnOrder: index,
                            botDifficulty: entry.botDifficulty,
                            isTrainingBot: entry.isTrainingBot,
                            isCustomBot: entry.isCustomBot,
                            customConfiguration: entry.customConfiguration,
                            linkedPlayerId: entry.linkedPlayerId,
                            colorTokenRaw: entry.colorTokenRaw,
                            matchType: matchType,
                            uiTemplate: uiTemplate,
                            partyUsesPresetBotsOnly: partyUsesPresetBotsOnly
                        ),
                        resolveTrainingSkill: { botId, mode in
                            try await repository.resolveTrainingBotSkill(for: botId, mode: mode)
                        }
                    )
                    return (index, participant)
                }
            }
            var byIndex: [Int: MatchParticipant] = [:]
            for try await item in group {
                byIndex[item.0] = item.1
            }
            return (0 ..< orderedRoster.count).compactMap { byIndex[$0] }
        }
    }

    func abandonActiveMatch(_ active: MatchSummary) async throws {
        if let session = activeMatchStore.session(for: active.id) {
            let abandoned = try MatchLifecycleService.abandon(session: session)
            try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: abandoned.runtime))
            _ = try await matchRepository.saveSnapshot(
                matchId: active.id,
                snapshotVersion: abandoned.latestSnapshot.payloadVersion,
                snapshotPayload: abandoned.latestSnapshot.payload
            )
            activeMatchStore.remove(matchId: active.id)
            return
        }

        guard let snapshotSummary = try await matchRepository.fetchLatestSnapshot(matchId: active.id) else {
            try await matchRepository.updateMatch(
                MatchSummary(
                    id: active.id,
                    type: active.type,
                    status: .abandoned,
                    startedAt: active.startedAt,
                    endedAt: Date(),
                    winnerPlayerId: nil,
                    currentTurnPlayerId: nil,
                    currentLegIndex: active.currentLegIndex,
                    currentSetIndex: active.currentSetIndex,
                    eventCount: active.eventCount,
                    createdAt: active.createdAt,
                    updatedAt: Date()
                )
            )
            activeMatchStore.remove(matchId: active.id)
            return
        }

        let runtime = try CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshotSummary.snapshotPayload)
        let snapshot = MatchSnapshot(
            payloadVersion: snapshotSummary.snapshotVersion,
            eventCount: runtime.eventCount,
            createdAt: snapshotSummary.updatedAt,
            payload: snapshotSummary.snapshotPayload
        )
        let session = MatchLifecycleSession(runtime: runtime, events: [], latestSnapshot: snapshot)
        let abandoned = try MatchLifecycleService.abandon(session: session)
        try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: abandoned.runtime))
        _ = try await matchRepository.saveSnapshot(
            matchId: active.id,
            snapshotVersion: abandoned.latestSnapshot.payloadVersion,
            snapshotPayload: abandoned.latestSnapshot.payload
        )
        activeMatchStore.remove(matchId: active.id)
    }
}
