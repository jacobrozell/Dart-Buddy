import SwiftUI

@MainActor
final class FleetMatchViewModel: ObservableObject {
    enum State: Equatable {
        case ready
        case submitting
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .ready
    @Published var selectedMultiplier: DartMultiplier = .single
    @Published var enteredDarts: [DartInput] = []
    @Published var selectedCall: FleetBoardCell?
    @Published var showLockConfirm = false
    @Published var showWrongPlayerAlert = false
    @Published var showPrivacyShield = false
    @Published var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false
    @Published private(set) var sonarResult: Bool?

    let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let feedbackPreferences: FeedbackPreferences
    private let turnSubmitter: MatchTurnSubmitter
    private let botPlayback = MatchBotPlaybackLifecycle()

    init(
        matchId: UUID,
        store: ActiveMatchStore,
        logger: any AppLogger,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        feedbackPreferences: FeedbackPreferences = FeedbackPreferences()
    ) {
        self.matchId = matchId
        self.store = store
        self.logger = logger
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
        self.feedbackPreferences = feedbackPreferences
        self.turnSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: .fleet,
            eventTypeRaw: "fleetDart",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var fleetState: FleetState? { session?.runtime.fleetState }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .ready && isHuntPhase
    }

    var isHuntPhase: Bool {
        fleetState?.phase == .hunt && fleetState?.isComplete == false
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let fleetState = session.runtime.fleetState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        return DartBotEngine.botSkillProfile(
            playerId: fleetState.currentPlayerId,
            in: session.runtime.participants
        )
    }

    var currentBotDifficulty: BotDifficulty? {
        guard let session, let fleetState = session.runtime.fleetState else { return nil }
        return DartBotEngine.botDifficulty(
            playerId: fleetState.currentPlayerId,
            in: session.runtime.participants
        )
    }

    var dartsRemaining: Int {
        guard let fleetState else { return 3 }
        return max(0, 3 - fleetState.visitDartIndex)
    }

    var shipsPlacedCount: Int {
        guard let fleetState, let audience = placementAudiencePlayerId else { return 0 }
        return fleetState.fleets[audience]?.ships.count ?? 0
    }

    var requiredShipCount: Int {
        fleetState?.config.shipCount.count ?? 5
    }

    var canLockFleet: Bool {
        shipsPlacedCount == requiredShipCount
    }

    var placementAudiencePlayerId: UUID? {
        guard let fleetState else { return nil }
        switch fleetState.placementUIStep {
        case let .handoff(playerId), let .placing(playerId):
            return playerId
        case let .passDevice(playerId):
            return playerId
        case .placementComplete:
            return nil
        }
    }

    var canViewPlacement: Bool {
        guard let fleetState else { return false }
        if case let .placing(playerId) = fleetState.placementUIStep {
            return fleetState.placementAudience == playerId
        }
        return false
    }

    func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }

    func playerName(for playerId: UUID) -> String {
        participant(for: playerId)?.displayNameAtMatchStart
            ?? MatchConfigText.playerName(forIndex: 0)
    }

    func playerColor(for playerId: UUID) -> PlayerColorToken {
        participant(for: playerId)?.colorToken
            ?? PlayerColorToken.defaultForPlayer(id: playerId)
    }

    func ownBoardModel(for audiencePlayerId: UUID) -> FleetBoardGridView.Mode? {
        guard let fleetState else { return nil }
        let fleet = fleetState.fleets[audiencePlayerId] ?? FleetPlayerFleet()
        return .ownFleet(
            fleet: fleet,
            shipHealth: fleetState.config.shipHealth.rawValue,
            color: PlayerVisualViews.color(for: playerColor(for: audiencePlayerId))
        )
    }

    func enemyFogModel(for hunterId: UUID) -> FleetBoardGridView.Mode? {
        guard let fleetState else { return nil }
        return .enemyFog(probeMap: fleetState.probeMaps[hunterId] ?? [:])
    }

    func placementModel(for playerId: UUID) -> FleetBoardGridView.Mode? {
        guard let fleetState else { return nil }
        let ships = fleetState.fleets[playerId]?.ships ?? []
        return .placement(selected: ships, color: PlayerVisualViews.color(for: playerColor(for: playerId)))
    }

    func onAppear() async {
        logger.matchInfo(
            matchId: matchId,
            matchType: .fleet,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Fleet match screen presented."
        )
        MatchGameplaySessionSync.refreshStoredSession(matchId: matchId, store: store, into: &session)
        if await reconcileAfterSummaryUndo() { return }
        await loadSessionIfNeeded()
        reconcileInterruptedBotPlayback()
        scheduleBotAutomationIfNeeded()
    }

    func onDisappear() {
        botPlayback.cancel { reconcileInterruptedBotPlayback() }
    }

    func onScenePhaseChanged(_ phase: ScenePhase) {
        guard fleetState?.phase == .placement else {
            showPrivacyShield = false
            return
        }
        showPrivacyShield = phase != .active
    }

    func confirmHandoff(for playerId: UUID) async {
        await mutateSession { session in
            try MatchLifecycleService.confirmFleetHandoff(session: session, playerId: playerId)
        }
    }

    func confirmPassDevice(for playerId: UUID) async {
        await mutateSession { session in
            try MatchLifecycleService.confirmFleetPassDevice(session: session, playerId: playerId)
        }
    }

    func togglePlacementCell(_ cell: FleetBoardCell) async {
        guard let playerId = placementAudiencePlayerId, canViewPlacement else { return }
        await mutateSession { session in
            try MatchLifecycleService.toggleFleetPlacementCell(session: session, playerId: playerId, cell: cell)
        }
    }

    func clearPlacement() async {
        guard let playerId = placementAudiencePlayerId, canViewPlacement else { return }
        await mutateSession { session in
            try MatchLifecycleService.clearFleetPlacement(session: session, playerId: playerId)
        }
    }

    func lockFleet() async {
        guard let playerId = placementAudiencePlayerId, canViewPlacement else { return }
        await mutateSession { session in
            try MatchLifecycleService.submitFleetPlacementLock(session: session, playerId: playerId)
        }
    }

    func selectCall(_ cell: FleetBoardCell) {
        selectedCall = cell
    }

    func useSonar(on cell: FleetBoardCell) async {
        guard let fleetState, canHumanInput else { return }
        await mutateSession { session in
            try MatchLifecycleService.submitFleetSonar(
                session: session,
                playerId: fleetState.currentPlayerId,
                cell: cell
            )
        }
        if let event = lastSonarEvent() {
            sonarResult = event.inFleet
        }
    }

    func submitDart() async {
        guard let fleetState, let call = selectedCall ?? fleetState.pendingCall else { return }
        guard enteredDarts.count == 1, let dart = enteredDarts.first else { return }
        guard let currentSession = session else { return }
        state = .submitting
        let outcome = await turnSubmitter.submitTurn(
            from: currentSession,
            invalidTurnFallbackKey: "error.match.fleet.invalidCall"
        ) {
            try MatchLifecycleService.submitFleetDart(
                session: currentSession,
                playerId: fleetState.currentPlayerId,
                callCell: call,
                dart: dart
            )
        }
        switch outcome {
        case .cancelled:
            state = .ready
        case let .rejected(messageKey):
            state = .error(messageKey)
        case let .persistFailed(messageKey):
            state = .error(messageKey)
        case let .succeeded(updated):
            session = updated
            enteredDarts.removeAll()
            selectedCall = nil
            sonarResult = nil
            selectedMultiplier = .single
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else {
                state = .ready
                await playBotTurnIfNeeded()
            }
        }
    }

    func undoLastDart() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        if !enteredDarts.isEmpty {
            enteredDarts.removeAll()
            selectedMultiplier = .single
            return
        }
        do {
            let undone = try await MatchTurnSupport.undoLastTurn(
                session: current,
                matchId: matchId,
                store: store,
                matchRepository: matchRepository
            )
            session = undone
            state = .ready
            selectedCall = nil
            sonarResult = nil
            await playBotTurnIfNeeded()
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "error.turn.undoFailed"))
        }
    }


    func recoverBotPlaybackIfNeeded() {
        MatchBotPlaybackRecovery.recoverIfNeeded(
            isBotTurn: isCurrentPlayerBot,
            isBotPlaying: isBotPlaying,
            reconcile: reconcileInterruptedBotPlayback,
            schedule: scheduleBotAutomationIfNeeded
        )
    }

    private func scheduleBotAutomationIfNeeded() {
        botPlayback.schedule { await self.runBotAutomationIfNeeded() }
    }

    private func runBotAutomationIfNeeded() async {
        while await runSingleBotAutomationIfNeeded() {}
    }

    @discardableResult
    private func runSingleBotAutomationIfNeeded() async -> Bool {
        guard let fleetState = session?.runtime.fleetState else { return false }
        guard state == .ready else { return false }

        if fleetState.phase == .placement {
            return await runBotPlacementIfNeeded()
        }
        return await playSingleBotHuntTurnIfNeeded()
    }

    private func runBotPlacementIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              let fleetState = session?.runtime.fleetState,
              fleetState.phase == .placement else { return false }
        guard let currentSession = session,
              let botId = placementAudiencePlayerId,
              DartBotEngine.botSkillProfile(playerId: botId, in: currentSession.runtime.participants) != nil else {
            return false
        }

        isBotPlaying = true
        defer { isBotPlaying = false }

        if case .handoff = fleetState.placementUIStep {
            await confirmHandoff(for: botId)
        } else if case .passDevice = fleetState.placementUIStep {
            await confirmPassDevice(for: botId)
        } else if canViewPlacement {
            var rng = SystemRandomNumberGenerator()
            let ships = FleetBotPolicy.pickPlacementCells(
                count: fleetState.config.shipCount.count,
                bullAllowed: fleetState.config.bullAllowed,
                profile: profile,
                rng: &rng
            )
            await mutateSession { session in
                var updated = session
                for cell in ships {
                    updated = try MatchLifecycleService.toggleFleetPlacementCell(
                        session: updated,
                        playerId: botId,
                        cell: cell
                    )
                }
                return try MatchLifecycleService.submitFleetPlacementLock(session: updated, playerId: botId)
            }
        }
        return currentBotSkillProfile != nil
    }

    @discardableResult
    private func playSingleBotHuntTurnIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              let fleetState = session?.runtime.fleetState,
              fleetState.phase == .hunt else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        var rng = SystemRandomNumberGenerator()
        let playerId = fleetState.currentPlayerId

        if FleetBotPolicy.shouldUseSonar(
            state: fleetState,
            botId: playerId,
            profile: profile,
            rng: &rng
        ),
           let pool = FleetBotPolicy.pickSonarCell(
               state: fleetState,
               botId: playerId,
               rng: &rng
           ) {
            await useSonar(on: pool)
        }

        guard let call = FleetBotPolicy.pickCallCell(
            state: fleetState,
            botId: playerId,
            profile: profile,
            rng: &rng
        ) else { return false }

        selectedCall = call
        let dart = DartBotEngine.generateFleetHuntDart(
            callCell: call,
            profile: profile,
            callMode: fleetState.config.callMode,
            rng: &rng
        )
        enteredDarts = [dart]
        try? await Task.sleep(nanoseconds: BotTurnPacing.submitDelayNanoseconds(feedbackPreferences: feedbackPreferences))
        await submitDart()
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && state == .ready
    }

    private func mutateSession(_ transform: (MatchLifecycleSession) throws -> MatchLifecycleSession) async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        do {
            let updated = try transform(current)
            session = updated
            store.save(updated)
            try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: updated.runtime))
            _ = try await matchRepository.saveSnapshot(
                matchId: matchId,
                snapshotVersion: updated.latestSnapshot.payloadVersion,
                snapshotPayload: updated.latestSnapshot.payload
            )
            if updated.runtime.status == .completed {
                state = .matchCompleted
            }
            scheduleBotAutomationIfNeeded()
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "error.match.fleet.invalidCall"))
        }
    }

    private func reconcileInterruptedBotPlayback() {
        isBotPlaying = false
    }

    private func reconcileAfterSummaryUndo() async -> Bool {
        false
    }

    func loadSessionIfNeeded() async {
        if session != nil { return }
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: .fleet,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "fleet.error.sessionMissing"
        ) {
        case let .loaded(loaded):
            session = loaded
        case .missing:
            break
        case let .failed(messageKey):
            state = .error(messageKey)
        }
    }

    private func lastSonarEvent() -> FleetSonarEvent? {
        guard let session else { return nil }
        for envelope in session.events.reversed() {
            if case let .fleetSonar(event) = envelope.payload { return event }
        }
        return nil
    }

    private func playBotTurnIfNeeded() async {
        await runBotAutomationIfNeeded()
    }
}
extension FleetMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submitting }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .fleet }
}
