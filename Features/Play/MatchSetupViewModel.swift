import Foundation

enum X01StartScores {
    static let all = [101, 201, 301, 401, 501, 601]
}

@MainActor
final class MatchSetupViewModel: ObservableObject {
    enum SetupMode: String, CaseIterable, Identifiable {
        case x01
        case cricket
        var id: String { rawValue }
    }

    struct SetupBot: Identifiable, Equatable {
        let id: UUID
        let difficulty: BotDifficulty

        var displayName: String { difficulty.rosterName }
    }

    @Published var mode: SetupMode = .x01
    @Published var selectedPlayerIds: Set<UUID> = []
    @Published var selectedBots: [SetupBot] = []
    @Published var availablePlayers: [PlayerSummary] = []
    @Published var x01StartScore: Int = 501
    @Published var x01LegsToWin: Int = 3
    @Published var x01SetsEnabled = false
    @Published var x01SetsToWin: Int = 1
    @Published var x01CheckoutMode: X01CheckoutMode = .doubleOut
    @Published var x01CheckInMode: X01CheckInMode = .straightIn
    @Published var x01LegFormat: X01LegFormat = .firstTo
    @Published var randomOrder = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var validationErrors: [String] = []
    /// Drives the "Game in Progress" confirmation when a match is already active.
    @Published var showActiveMatchConflict = false

    private let playerRepository: any PlayerRepository
    private let settingsRepository: any SettingsRepository
    private let matchRepository: any MatchRepository
    private let activeMatchStore: ActiveMatchStore
    private let pendingMatchPlayerSelections: PendingMatchPlayerSelections

    init(
        playerRepository: any PlayerRepository,
        settingsRepository: any SettingsRepository,
        matchRepository: any MatchRepository,
        activeMatchStore: ActiveMatchStore,
        pendingMatchPlayerSelections: PendingMatchPlayerSelections
    ) {
        self.playerRepository = playerRepository
        self.settingsRepository = settingsRepository
        self.matchRepository = matchRepository
        self.activeMatchStore = activeMatchStore
        self.pendingMatchPlayerSelections = pendingMatchPlayerSelections
    }

    var canStart: Bool {
        validationErrors.isEmpty && !isSubmitting
    }

    func onAppear() async {
        do {
            availablePlayers = try await playerRepository.fetchPlayers(includeArchived: false)
            let loadedIds = Set(availablePlayers.map(\.id))
            for id in pendingMatchPlayerSelections.dequeueIdsPresent(in: loadedIds) {
                selectedPlayerIds.insert(id)
            }
            let settings = try await settingsRepository.seedDefaultsIfNeeded()
            x01StartScore = X01StartScores.all.contains(settings.defaultX01StartScore) ? settings.defaultX01StartScore : 501
            x01LegsToWin = max(1, settings.defaultLegsToWin)
            x01SetsEnabled = settings.defaultSetsEnabled
            x01CheckoutMode = X01CheckoutMode(rawValue: settings.defaultCheckoutModeRaw) ?? .doubleOut
            x01CheckInMode = X01CheckInMode(rawValue: settings.defaultCheckInModeRaw) ?? .straightIn
            x01LegFormat = X01LegFormat(rawValue: settings.defaultLegFormatRaw) ?? .firstTo
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

    /// Adds a player to the match roster without toggling off if already selected (e.g. after Quick Add).
    func addPlayerToSelection(_ id: UUID) {
        selectedPlayerIds.insert(id)
        revalidate()
    }

    func addBot(_ difficulty: BotDifficulty) {
        selectedBots.append(SetupBot(id: UUID(), difficulty: difficulty))
        revalidate()
    }

    func removeBot(_ id: UUID) {
        selectedBots.removeAll { $0.id == id }
        revalidate()
    }

    var selectedParticipantCount: Int {
        selectedPlayerIds.count + selectedBots.count
    }

    func updateMode(_ mode: SetupMode) {
        self.mode = mode
        revalidate()
    }

    func revalidate() {
        var errors: [String] = []
        if selectedParticipantCount < 2 {
            errors.append("setup.validation.minimumPlayers")
        }
        if mode == .x01 {
            if !X01StartScores.all.contains(x01StartScore) {
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
        // A match is already in progress: ask the user to replace it instead of
        // failing silently with a validation error.
        if (try? await matchRepository.fetchActiveMatch()) != nil {
            showActiveMatchConflict = true
            return nil
        }
        return await performStart()
    }

    /// Deletes the active match and immediately starts the configured one.
    /// Invoked from the "Game in Progress" confirmation popup.
    func confirmReplaceActiveMatch() async -> PlayRoute? {
        showActiveMatchConflict = false
        do {
            if let active = try await matchRepository.fetchActiveMatch() {
                try await matchRepository.deleteMatch(matchId: active.id)
                activeMatchStore.remove(matchId: active.id)
            }
        } catch is CancellationError {
            return nil
        } catch {
            validationErrors = [(error as? AppError)?.userMessageKey ?? "setup.error.start"]
            return nil
        }
        return await performStart()
    }

    private func performStart() async -> PlayRoute? {
        guard canStart else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        struct RosterEntry {
            let id: UUID
            let name: String
            let botDifficulty: BotDifficulty?
        }

        var rosterEntries: [RosterEntry] = availablePlayers
            .filter { selectedPlayerIds.contains($0.id) }
            .map { RosterEntry(id: $0.id, name: $0.name, botDifficulty: nil) }
        rosterEntries += selectedBots.map {
            RosterEntry(id: $0.id, name: $0.displayName, botDifficulty: $0.difficulty)
        }
        let orderedRoster = randomOrder ? rosterEntries.shuffled() : rosterEntries
        let selectedPlayers = orderedRoster
            .enumerated()
            .map { index, entry in
                MatchParticipant(
                    playerId: entry.id,
                    displayNameAtMatchStart: entry.name,
                    turnOrder: index,
                    botDifficultyRaw: entry.botDifficulty?.rawValue
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
                        checkoutMode: x01CheckoutMode,
                        checkInMode: x01CheckInMode,
                        legFormat: x01LegFormat
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
            await persistLastUsedSetup()
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

    private func persistLastUsedSetup() async {
        guard let settings = try? await settingsRepository.fetchSettings() else { return }
        let next = SettingsSummary(
            id: settings.id,
            appearanceModeRaw: settings.appearanceModeRaw,
            hapticsEnabled: settings.hapticsEnabled,
            soundEnabled: settings.soundEnabled,
            defaultMatchTypeRaw: mode == .x01 ? MatchType.x01.rawValue : MatchType.cricket.rawValue,
            defaultX01StartScore: x01StartScore,
            defaultCheckoutModeRaw: x01CheckoutMode.rawValue,
            defaultCheckInModeRaw: x01CheckInMode.rawValue,
            defaultLegFormatRaw: x01LegFormat.rawValue,
            defaultLegsToWin: x01LegsToWin,
            defaultSetsEnabled: x01SetsEnabled,
            updatedAt: Date()
        )
        _ = try? await settingsRepository.updateSettings(next)
    }
}
