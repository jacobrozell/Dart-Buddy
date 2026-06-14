import SwiftUI

@MainActor
final class RaidMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var selectedMultiplier: DartMultiplier = .single
    @Published var enteredDarts: [DartInput] = []
    @Published private(set) var session: MatchLifecycleSession?

    private let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let turnSubmitter: MatchTurnSubmitter

    init(
        matchId: UUID,
        store: ActiveMatchStore,
        logger: any AppLogger,
        matchRepository: any MatchRepository
    ) {
        self.matchId = matchId
        self.store = store
        self.logger = logger
        self.matchRepository = matchRepository
        self.turnSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: .raid,
            eventTypeRaw: "raidVisit",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var raidState: RaidState? { session?.runtime.raidState }

    var canSubmit: Bool { enteredDarts.count == 3 && state == .readyTurn }

    var canHumanInput: Bool { state == .readyTurn && session?.runtime.status == .inProgress }

    var headerText: String {
        guard let state = raidState else { return "" }
        let phase = state.phase == .shield
            ? L10n.string("play.raid.phase.shield")
            : L10n.string("play.raid.phase.expose")
        return L10n.format("play.raid.headerFormat", phase, state.bossHP, state.bossMaxHP)
    }

    var coopChromeHeroes: [CoopBossChromeView.CoopHeroHeartRow] {
        guard let session, let raidState else { return [] }
        let activeId = raidState.heroes.indices.contains(raidState.currentHeroIndex)
            ? raidState.heroes[raidState.currentHeroIndex].playerId
            : nil
        return raidState.heroes.map { hero in
            let participant = session.runtime.participants.first { $0.playerId == hero.playerId }
            return CoopBossChromeView.CoopHeroHeartRow(
                id: hero.playerId,
                name: participant?.displayNameAtMatchStart ?? L10n.string("play.raid.heroFallbackName"),
                hearts: hero.hearts,
                maxHearts: raidState.config.heroHearts,
                isDown: hero.isDown,
                isActive: hero.playerId == activeId && session.runtime.status == .inProgress
            )
        }
    }

    func submitTurn() async {
        await submitTurnAsync()
    }

    func undoLastDart() async {
        await undoLastDartAsync()
    }

    func onAppear() async {
        logger.matchInfo(
            matchId: matchId,
            matchType: .raid,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Raid match screen presented."
        )
        MatchGameplaySessionSync.refreshStoredSession(matchId: matchId, store: store, into: &session)
        if await reconcileAfterSummaryUndo() { return }
        await loadSessionIfNeeded()
    }

    func onDisappear() {}

    func abandonMatch() async {
        await loadSessionIfNeeded()
        guard let current = session, current.runtime.status == .inProgress else { return }
        do {
            let abandoned = try MatchLifecycleService.abandon(session: current)
            try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: abandoned.runtime))
            _ = try await matchRepository.saveSnapshot(
                matchId: matchId,
                snapshotVersion: abandoned.latestSnapshot.payloadVersion,
                snapshotPayload: abandoned.latestSnapshot.payload
            )
            store.remove(matchId: matchId)
            session = abandoned
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .raid,
                category: .appLifecycle,
                eventName: "raid_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    private func reconcileAfterSummaryUndo() async -> Bool {
        guard state == .matchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        session = stored
        state = .readyTurn
        enteredDarts = store.consumeResumeHint(matchId: matchId) ?? []
        return true
    }

    private func submitTurnAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("error.match.mode.raidUnavailable")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "error.match.mode.raidUnavailable"
        ) {
            try MatchLifecycleService.submitRaidVisit(session: current, darts: darts)
        }

        switch outcome {
        case .cancelled:
            state = .readyTurn
        case let .rejected(messageKey):
            state = .entryInvalid(messageKey)
        case let .persistFailed(messageKey):
            state = .error(messageKey)
        case let .succeeded(updated):
            session = updated
            if let event = updated.events.last.flatMap({ envelope -> RaidVisitEvent? in
                if case let .raidVisit(visit) = envelope.payload { return visit }
                return nil
            }) {
                announceVisitIfNeeded(event: event)
            }
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else {
                state = .readyTurn
            }
            enteredDarts.removeAll()
        }
    }

    private func undoLastDartAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        do {
            let undone = try await MatchTurnSupport.undoLastTurn(
                session: current,
                matchId: matchId,
                store: store,
                matchRepository: matchRepository
            )
            session = undone
            state = .readyTurn
            enteredDarts.removeAll()
        } catch {
            state = .error((error as? AppError)?.userMessageKey ?? "error.match.undoFailed")
        }
    }

    private func loadSessionIfNeeded() async {
        if session != nil { return }
        session = store.session(for: matchId)
    }

    private func announceVisitIfNeeded(event: RaidVisitEvent) {
        if event.phaseBefore != event.phaseAfter {
            AccessibilityNotification.Announcement(
                event.phaseAfter == .shield
                    ? L10n.string("play.raid.phase.shield")
                    : L10n.string("play.raid.phase.expose")
            ).post()
        }
        if !event.enrageVictims.isEmpty {
            AccessibilityNotification.Announcement(L10n.string("play.raid.enrageStrikeAnnouncement")).post()
        }
        if event.teamVictory {
            AccessibilityNotification.Announcement(L10n.string("coop.summary.teamVictory")).post()
        } else if event.teamDefeat {
            AccessibilityNotification.Announcement(L10n.string("coop.summary.teamDefeat")).post()
        }
    }
}
