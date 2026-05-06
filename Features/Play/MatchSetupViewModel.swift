import Foundation

@MainActor
final class MatchSetupViewModel: ObservableObject {
    enum SetupMode: String, CaseIterable, Identifiable {
        case x01
        case cricket
        var id: String { rawValue }
    }

    @Published var mode: SetupMode = .x01
    @Published var selectedPlayerIds: Set<UUID> = []
    @Published var availablePlayers: [PlayerSummary] = []
    @Published var x01StartScore: Int = 501
    @Published var x01LegsToWin: Int = 3
    @Published var x01SetsEnabled = false
    @Published var x01SetsToWin: Int = 1
    @Published var x01CheckoutMode: X01CheckoutMode = .doubleOut
    @Published private(set) var isSubmitting = false
    @Published private(set) var validationErrors: [String] = []

    private let playerRepository: any PlayerRepository
    private let settingsRepository: any SettingsRepository
    private let matchRepository: any MatchRepository
    private let activeMatchStore: ActiveMatchStore

    init(
        playerRepository: any PlayerRepository,
        settingsRepository: any SettingsRepository,
        matchRepository: any MatchRepository,
        activeMatchStore: ActiveMatchStore
    ) {
        self.playerRepository = playerRepository
        self.settingsRepository = settingsRepository
        self.matchRepository = matchRepository
        self.activeMatchStore = activeMatchStore
    }

    var canStart: Bool {
        validationErrors.isEmpty && !isSubmitting
    }

    func onAppear() async {
        do {
            availablePlayers = try await playerRepository.fetchPlayers(includeArchived: false)
            let settings = try await settingsRepository.seedDefaultsIfNeeded()
            x01StartScore = [301, 501].contains(settings.defaultX01StartScore) ? settings.defaultX01StartScore : 501
            x01LegsToWin = max(1, settings.defaultLegsToWin)
            x01SetsEnabled = settings.defaultSetsEnabled
            x01CheckoutMode = settings.defaultCheckoutModeRaw == X01CheckoutMode.singleOut.rawValue ? .singleOut : .doubleOut
            mode = settings.defaultMatchTypeRaw == MatchType.cricket.rawValue ? .cricket : .x01
        } catch {
            validationErrors = ["setup.error.load"]
        }
        revalidate()
    }

    func togglePlayer(_ id: UUID) {
        if selectedPlayerIds.contains(id) {
            selectedPlayerIds.remove(id)
        } else {
            selectedPlayerIds.insert(id)
        }
        revalidate()
    }

    func updateMode(_ mode: SetupMode) {
        self.mode = mode
        revalidate()
    }

    func revalidate() {
        var errors: [String] = []
        if selectedPlayerIds.count < 2 {
            errors.append("setup.validation.minimumPlayers")
        }
        if mode == .x01 {
            if ![301, 501].contains(x01StartScore) {
                errors.append("setup.validation.invalidStartScore")
            }
            if x01LegsToWin <= 0 {
                errors.append("setup.validation.invalidLegs")
            }
            if x01SetsEnabled && x01SetsToWin <= 0 {
                errors.append("setup.validation.invalidSets")
            }
        }
        validationErrors = errors
    }

    func startMatchRoute() async -> PlayRoute? {
        revalidate()
        guard canStart else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        let selectedPlayers = availablePlayers
            .filter { selectedPlayerIds.contains($0.id) }
            .enumerated()
            .map { index, player in
                MatchParticipant(
                    playerId: player.id,
                    displayNameAtMatchStart: player.name,
                    turnOrder: index
                )
            }
        do {
            let config: MatchConfigPayload
            let session: MatchLifecycleSession
            let route: PlayRoute
            if mode == .x01 {
                config = .x01(
                    MatchConfigX01(
                        startScore: x01StartScore,
                        legsToWin: x01LegsToWin,
                        setsEnabled: x01SetsEnabled,
                        setsToWin: x01SetsEnabled ? x01SetsToWin : nil,
                        checkoutMode: x01CheckoutMode
                    )
                )
            } else {
                config = .cricket(MatchConfigCricket())
            }
            let configPayload = try CodablePayloadCoder.encode(config)
            let participantsForRepository = selectedPlayers.enumerated().map { index, participant in
                MatchParticipantSummary(
                    id: participant.id,
                    matchId: UUID(),
                    playerId: participant.playerId,
                    turnOrder: index,
                    displayNameAtMatchStart: participant.displayNameAtMatchStart,
                    avatarStyleAtMatchStart: nil
                )
            }
            let persisted = try await matchRepository.createMatch(
                type: mode == .x01 ? .x01 : .cricket,
                configPayload: configPayload,
                participants: participantsForRepository
            )

            if mode == .x01 {
                session = try MatchLifecycleService.createMatch(
                    matchId: persisted.id,
                    type: .x01,
                    config: config,
                    participants: selectedPlayers
                )
                route = .x01Match(matchId: persisted.id)
            } else {
                session = try MatchLifecycleService.createMatch(
                    matchId: persisted.id,
                    type: .cricket,
                    config: config,
                    participants: selectedPlayers
                )
                route = .cricketMatch(matchId: persisted.id)
            }
            _ = try await matchRepository.saveSnapshot(
                matchId: persisted.id,
                snapshotVersion: session.latestSnapshot.payloadVersion,
                snapshotPayload: session.latestSnapshot.payload
            )
            activeMatchStore.save(session)
            return route
        } catch is CancellationError {
            return nil
        } catch {
            if let appError = error as? AppError {
                validationErrors = [appError.userMessageKey]
            } else {
                validationErrors = ["setup.error.start"]
            }
            return nil
        }
    }
}
