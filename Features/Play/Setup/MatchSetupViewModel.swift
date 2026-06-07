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

    @Published var setupCategory: PlaySetupCategory = .standard
    @Published var partyGame: PartyGame = .baseball
    @Published var mode: SetupMode = .x01
    /// Selected players in throw order (first throws first unless `randomOrder` is on at start).
    @Published var selectedPlayerIds: [UUID] = []
    @Published var availablePlayers: [PlayerSummary] = []
    @Published var x01StartScore: Int = 501
    @Published var x01LegsToWin: Int = 3
    @Published var x01SetsEnabled = false
    @Published var x01SetsToWin: Int = 1
    @Published var x01CheckoutMode: X01CheckoutMode = .doubleOut
    @Published var x01CheckInMode: X01CheckInMode = .straightIn
    @Published var x01LegFormat: X01LegFormat = .firstTo
    @Published var cricketPointsEnabled = true
    @Published var cricketScoringMode: CricketScoringMode = .standard
    @Published var cricketLegsToWin: Int = 1
    @Published var cricketSetsEnabled = false
    @Published var cricketSetsToWin: Int = 1
    @Published var cricketLegFormat: X01LegFormat = .firstTo
    @Published var baseballInningCount: Int = 9
    @Published var baseballTieBreaker: BaseballTieBreaker = .extraInnings
    @Published var baseballSeventhInningStretch = false
    @Published var killerStartingLives: Int = 3
    @Published var shanghaiRoundCount: Int = 20
    @Published var shanghaiBonusRule: ShanghaiBonusRule = .bonus150
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
    private let logger: any AppLogger
    private var hasAppliedSettingsDefaultMode = false

    init(
        playerRepository: any PlayerRepository,
        settingsRepository: any SettingsRepository,
        matchRepository: any MatchRepository,
        activeMatchStore: ActiveMatchStore,
        pendingMatchPlayerSelections: PendingMatchPlayerSelections,
        logger: any AppLogger = DefaultAppLogger(minimumLevel: .fault, sink: NoOpLogSink())
    ) {
        self.playerRepository = playerRepository
        self.settingsRepository = settingsRepository
        self.matchRepository = matchRepository
        self.activeMatchStore = activeMatchStore
        self.pendingMatchPlayerSelections = pendingMatchPlayerSelections
        self.logger = logger
    }

    var canStart: Bool {
        validationErrors.isEmpty && !isSubmitting
    }

    func onAppear() async {
        do {
            availablePlayers = try await playerRepository.fetchPlayers(includeArchived: false)
            let loadedIds = Set(availablePlayers.map(\.id))
            selectedPlayerIds.removeAll { !loadedIds.contains($0) }
            for id in pendingMatchPlayerSelections.dequeueIdsPresent(in: loadedIds) {
                appendToSelection(id)
            }
            let settings = try await settingsRepository.seedDefaultsIfNeeded()
            x01StartScore = X01StartScores.all.contains(settings.defaultX01StartScore) ? settings.defaultX01StartScore : 501
            x01LegsToWin = max(1, settings.defaultLegsToWin)
            x01SetsEnabled = settings.defaultSetsEnabled
            x01CheckoutMode = X01CheckoutMode(rawValue: settings.defaultCheckoutModeRaw) ?? .doubleOut
            x01CheckInMode = X01CheckInMode(rawValue: settings.defaultCheckInModeRaw) ?? .straightIn
            x01LegFormat = X01LegFormat(rawValue: settings.defaultLegFormatRaw) ?? .firstTo
            cricketLegsToWin = max(1, settings.defaultLegsToWin)
            cricketSetsEnabled = settings.defaultSetsEnabled
            cricketSetsToWin = max(1, settings.defaultSetsEnabled ? 2 : 1)
            cricketLegFormat = X01LegFormat(rawValue: settings.defaultLegFormatRaw) ?? .firstTo
            let cricketPrefs = CricketSetupPreferences.load()
            cricketPointsEnabled = cricketPrefs.pointsEnabled
            cricketScoringMode = cricketPrefs.scoringMode
            let baseballPrefs = BaseballSetupPreferences.load()
            baseballInningCount = baseballPrefs.inningCount
            baseballTieBreaker = baseballPrefs.tieBreaker
            baseballSeventhInningStretch = baseballPrefs.seventhInningStretch
            killerStartingLives = KillerSetupPreferences.load()
            let shanghaiPrefs = ShanghaiSetupPreferences.load()
            shanghaiRoundCount = shanghaiPrefs.roundCount
            shanghaiBonusRule = shanghaiPrefs.bonusRule
            if let preferred = pendingMatchPlayerSelections.consumePreferredMatchType() {
                applyMatchTypePreferred(preferred)
            } else if !hasAppliedSettingsDefaultMode {
                mode = settings.defaultMatchTypeRaw == MatchType.cricket.rawValue ? .cricket : .x01
                hasAppliedSettingsDefaultMode = true
            }
        } catch {
            validationErrors = ["setup.error.load"]
        }
        revalidate()
    }

    func togglePlayer(_ id: UUID) {
        if let index = selectedPlayerIds.firstIndex(of: id) {
            selectedPlayerIds.remove(at: index)
        } else {
            appendToSelection(id)
        }
        revalidate()
    }

    /// Adds a player to the match roster without toggling off if already selected (e.g. after Quick Add).
    func addPlayerToSelection(_ id: UUID) {
        appendToSelection(id)
        revalidate()
    }

    func removeFromSelection(_ id: UUID) {
        selectedPlayerIds.removeAll { $0 == id }
        revalidate()
    }

    func moveSelectedPlayers(from source: IndexSet, to destination: Int) {
        selectedPlayerIds.move(fromOffsets: source, toOffset: destination)
    }

    func removeSelectedPlayers(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard selectedPlayerIds.indices.contains(index) else { continue }
            selectedPlayerIds.remove(at: index)
        }
        revalidate()
    }

    var selectedPlayers: [PlayerSummary] {
        selectedPlayerIds.compactMap { id in
            availablePlayers.first { $0.id == id }
        }
    }

    var availableHumans: [PlayerSummary] {
        availablePlayers.filter { !$0.isBot && !selectedPlayerIds.contains($0.id) }
    }

    var availableBots: [PlayerSummary] {
        availablePlayers.filter { ($0.isPresetBot || $0.isCustomBot) && !selectedPlayerIds.contains($0.id) }
    }

    var availableTrainingBots: [PlayerSummary] {
        availablePlayers.filter { $0.isTrainingBot && !selectedPlayerIds.contains($0.id) }
    }

    var availableCustomBots: [PlayerSummary] {
        availablePlayers.filter { $0.isCustomBot && !selectedPlayerIds.contains($0.id) }
    }

    var isRosterEmpty: Bool {
        availableHumans.isEmpty && availableBots.isEmpty && selectedPlayers.isEmpty
    }

    /// Validation messages shown in the UI; defers minimum-player copy when the roster is still empty.
    var displayValidationErrors: [String] {
        guard isRosterEmpty else { return validationErrors }
        return validationErrors.filter { $0 != "setup.validation.minimumPlayers" }
    }

    private func appendToSelection(_ id: UUID) {
        guard !selectedPlayerIds.contains(id) else { return }
        selectedPlayerIds.append(id)
    }

    func addTrainingBot(_ botId: UUID) {
        appendToSelection(botId)
        revalidate()
    }

    func addExistingCustomBot(_ botId: UUID) {
        appendToSelection(botId)
        revalidate()
    }

    func addBot(_ difficulty: BotDifficulty) async {
        do {
            let created = try await playerRepository.createBot(difficulty: difficulty)
            if !availablePlayers.contains(where: { $0.id == created.id }) {
                availablePlayers.append(created)
            }
            appendToSelection(created.id)
            revalidate()
        } catch {
            validationErrors = [(error as? AppError)?.userMessageKey ?? "setup.error.load"]
        }
    }

    func addCustomBot(name: String, metrics: CustomBotMetrics) async {
        do {
            let created = try await playerRepository.createCustomBot(name: name, metrics: metrics)
            if !availablePlayers.contains(where: { $0.id == created.id }) {
                availablePlayers.append(created)
            }
            appendToSelection(created.id)
            revalidate()
        } catch {
            validationErrors = [(error as? AppError)?.userMessageKey ?? "setup.error.load"]
        }
    }

    var selectedParticipantCount: Int {
        selectedPlayerIds.count
    }

    func updateSetupCategory(_ category: PlaySetupCategory) {
        setupCategory = category
        revalidate()
    }

    func updatePartyGame(_ game: PartyGame) {
        partyGame = game
        revalidate()
    }

    func updateMode(_ mode: SetupMode) {
        self.mode = mode
        revalidate()
    }

    func applyPendingModeSelection(_ selection: PendingModeSelection) {
        if selection.setupCategory == .party, !ProductSurface.showsPartyModes { return }
        setupCategory = selection.setupCategory
        if let mode = selection.mode {
            self.mode = mode
        }
        if let partyGame = selection.partyGame {
            self.partyGame = partyGame
        }
        normalizeForProductSurface()
        revalidate()
    }

    private func applyMatchTypePreferred(_ matchType: MatchType) {
        if let entry = GameModeCatalog.entry(for: matchType),
           let selection = entry.pendingModeSelection {
            applyPendingModeSelection(selection)
            return
        }
        setupCategory = .standard
        mode = matchType == .cricket ? .cricket : .x01
        normalizeForProductSurface()
    }

    private func normalizeForProductSurface() {
        if setupCategory == .party, !ProductSurface.showsPartyModes {
            setupCategory = .standard
            mode = .x01
        }
    }

    func revalidate() {
        var errors: [String] = []
        if setupCategory == .party {
            if !ProductSurface.showsPartyModes {
                errors.append("setup.validation.partyComingSoon")
            } else if !partyGame.isAvailable {
                errors.append("setup.validation.partyComingSoon")
            } else if selectedParticipantCount < partyGame.minimumPlayers {
                errors.append(partyMinimumPlayersValidationKey)
            } else {
                let selected = selectedPlayers
                if selected.allSatisfy(\.isBot) {
                    errors.append("setup.validation.requiresHuman")
                }
                if partyGame == .baseball {
                    if selected.contains(where: \.isCustomBot) || selected.contains(where: \.isTrainingBot) {
                        errors.append("setup.validation.baseballBotsPresetOnly")
                    }
                }
                if partyGame == .shanghai {
                    if selected.contains(where: \.isCustomBot) || selected.contains(where: \.isTrainingBot) {
                        errors.append("setup.validation.shanghaiBotsPresetOnly")
                    }
                }
                if partyGame == .killer {
                    if selected.contains(where: \.isCustomBot) || selected.contains(where: \.isTrainingBot) {
                        errors.append("setup.validation.killerBotsPresetOnly")
                    }
                }
            }
        } else if mode == .x01 {
            // Solo X01 is allowed (single-player practice); only require a human.
            // `allSatisfy` is vacuously true for an empty roster, so this also
            // covers the "no players selected" case.
            if selectedPlayers.allSatisfy(\.isBot) {
                errors.append("setup.validation.requiresHuman")
            }
        } else if selectedParticipantCount < 2 {
            errors.append("setup.validation.minimumPlayers")
        } else if selectedPlayers.allSatisfy(\.isBot) {
            errors.append("setup.validation.requiresHuman")
        }
        if setupCategory == .standard, mode == .x01 {
            if !X01StartScores.all.contains(x01StartScore) {
                errors.append("setup.validation.invalidStartScore")
            }
            if x01LegsToWin <= 0 {
                errors.append("setup.validation.invalidLegs")
            }
            if x01SetsEnabled && x01SetsToWin <= 0 {
                errors.append("setup.validation.invalidSets")
            }
        } else if setupCategory == .standard {
            if cricketLegsToWin <= 0 {
                errors.append("setup.validation.invalidLegs")
            }
            if cricketSetsEnabled && cricketSetsToWin <= 0 {
                errors.append("setup.validation.invalidSets")
            }
            let hasBot = selectedPlayers.contains(where: \.isBot)
            if hasBot, !cricketPointsEnabled {
                errors.append("setup.validation.cricketBotUnsupported")
            }
        }
        validationErrors = errors
    }

    private var partyMinimumPlayersValidationKey: String {
        switch partyGame {
        case .killer:
            "setup.validation.partyKillerMinimumPlayers"
        case .baseball, .shanghai:
            "setup.validation.partyMinimumPlayers"
        }
    }

    func startMatchRoute() async -> PlayRoute? {
        normalizeForProductSurface()
        revalidate()
        guard canStart else { return nil }
        // A match is already in progress: ask the user to replace it instead of
        // failing silently with a validation error.
        do {
            if try await matchRepository.fetchActiveMatch() != nil {
                logger.debug(.ui, eventName: "active_match_conflict", message: "Setup blocked by in-progress match.")
                showActiveMatchConflict = true
                return nil
            }
        } catch is CancellationError {
            return nil
        } catch {
            logger.error(
                .ui,
                eventName: "active_match_lookup_failed",
                message: "Failed to check for an active match before start.",
                metadata: appErrorMetadata(for: error)
            )
            validationErrors = [(error as? AppError)?.userMessageKey ?? "setup.error.start"]
            return nil
        }
        return await performStart()
    }

    /// Abandons the active match and immediately starts the configured one.
    /// Invoked from the "Game in Progress" confirmation popup.
    func confirmReplaceActiveMatch() async -> PlayRoute? {
        showActiveMatchConflict = false
        do {
            if let active = try await matchRepository.fetchActiveMatch() {
                logger.info(
                    .scoring,
                    eventName: "active_match_replaced",
                    message: "Replacing in-progress match before starting a new one.",
                    metadata: [
                        "matchId": active.id.uuidString,
                        "matchType": active.type.rawValue
                    ]
                )
                try await abandonActiveMatch(active)
            }
        } catch is CancellationError {
            return nil
        } catch {
            logger.error(
                .scoring,
                eventName: "active_match_replace_failed",
                message: "Failed to abandon active match before replacement.",
                metadata: appErrorMetadata(for: error)
            )
            validationErrors = [(error as? AppError)?.userMessageKey ?? "setup.error.start"]
            return nil
        }
        return await performStart()
    }

    private func abandonActiveMatch(_ active: MatchSummary) async throws {
        if let session = activeMatchStore.session(for: active.id) {
            let abandoned = try MatchLifecycleService.abandon(session: session)
            try await matchRepository.updateMatch(matchSummary(from: abandoned.runtime))
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
        try await matchRepository.updateMatch(matchSummary(from: abandoned.runtime))
        _ = try await matchRepository.saveSnapshot(
            matchId: active.id,
            snapshotVersion: abandoned.latestSnapshot.payloadVersion,
            snapshotPayload: abandoned.latestSnapshot.payload
        )
        activeMatchStore.remove(matchId: active.id)
    }

    private func matchSummary(from runtime: MatchRuntimeState) -> MatchSummary {
        MatchSummary(
            id: runtime.matchId,
            type: runtime.type,
            status: MatchStatus(rawValue: runtime.status.rawValue) ?? .inProgress,
            startedAt: runtime.startedAt,
            endedAt: runtime.endedAt,
            winnerPlayerId: runtime.winnerPlayerId,
            currentTurnPlayerId: runtime.currentTurnPlayerId,
            currentLegIndex: runtime.currentLegIndex,
            currentSetIndex: runtime.currentSetIndex,
            eventCount: runtime.eventCount,
            createdAt: runtime.startedAt,
            updatedAt: Date()
        )
    }

    private func performStart() async -> PlayRoute? {
        guard canStart else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        let isBaseballParty = setupCategory == .party && partyGame == .baseball
        let isKillerParty = setupCategory == .party && partyGame == .killer
        let isShanghaiParty = setupCategory == .party && partyGame == .shanghai
        let matchType: MatchType = if isBaseballParty {
            .baseball
        } else if isKillerParty {
            .killer
        } else if isShanghaiParty {
            .shanghai
        } else {
            mode == .x01 ? .x01 : .cricket
        }
        logger.debug(
            .scoring,
            eventName: "match_setup_start",
            message: "Starting match from setup.",
            metadata: [
                "matchType": matchType.rawValue,
                "participantCount": String(selectedParticipantCount)
            ]
        )
        if isBaseballParty {
            logger.info(
                .scoring,
                eventName: "match_setup_baseball",
                message: "Starting baseball match from party setup.",
                metadata: [
                    "matchType": MatchType.baseball.rawValue,
                    "participantCount": String(selectedParticipantCount)
                ]
            )
        }
        struct RosterEntry {
            let id: UUID
            let name: String
            let botDifficulty: BotDifficulty?
            let isTrainingBot: Bool
            let isCustomBot: Bool
            let customMetrics: CustomBotMetrics?
            let linkedPlayerId: UUID?
            let avatarStyleRaw: String?
            let colorTokenRaw: String
        }

        let rosterEntries: [RosterEntry] = selectedPlayers.map { player in
            RosterEntry(
                id: player.id,
                name: player.name,
                botDifficulty: player.botDifficulty,
                isTrainingBot: player.isTrainingBot,
                isCustomBot: player.isCustomBot,
                customMetrics: player.customBotMetrics,
                linkedPlayerId: player.linkedPlayerId,
                avatarStyleRaw: player.isBot ? nil : player.avatarStyle.rawValue,
                colorTokenRaw: player.colorToken.rawValue
            )
        }
        let orderedRoster = randomOrder ? rosterEntries.shuffled() : rosterEntries
        do {
            let selectedPlayers: [MatchParticipant] = try await withThrowingTaskGroup(of: (Int, MatchParticipant).self) { group in
                for (index, entry) in orderedRoster.enumerated() {
                    group.addTask {
                        var botDifficultyRaw = entry.botDifficulty?.rawValue
                        var botKindRaw: String?
                        var botSkillProfilePayload: Data?
                        if isBaseballParty || isShanghaiParty || isKillerParty {
                            if entry.botDifficulty != nil {
                                botKindRaw = BotKind.preset.rawValue
                            }
                        } else if entry.isTrainingBot {
                            let profile = try await self.playerRepository.resolveTrainingBotSkill(
                                for: entry.id,
                                mode: matchType
                            )
                            let snapshot = TrainingBotSkillSnapshot(
                                profile: profile,
                                linkedPlayerId: entry.linkedPlayerId ?? entry.id,
                                sourcePlayerAvg: nil,
                                sourcePlayerMPR: nil
                            )
                            botSkillProfilePayload = try TrainingBotSkillSnapshot.encode(snapshot)
                            botKindRaw = BotKind.training.rawValue
                            botDifficultyRaw = nil
                        } else if entry.isCustomBot, let metrics = entry.customMetrics {
                            let profile = CustomBotSkillResolver.profile(for: matchType, metrics: metrics)
                            let snapshot = CustomBotSkillSnapshot(
                                profile: profile,
                                x01Average: metrics.x01Average,
                                cricketMPR: metrics.cricketMPR
                            )
                            botSkillProfilePayload = try CustomBotSkillSnapshot.encode(snapshot)
                            botKindRaw = BotKind.custom.rawValue
                            botDifficultyRaw = nil
                        } else if entry.botDifficulty != nil {
                            botKindRaw = BotKind.preset.rawValue
                        }
                        let participant = MatchParticipant(
                            playerId: entry.id,
                            displayNameAtMatchStart: entry.name,
                            turnOrder: index,
                            botDifficultyRaw: botDifficultyRaw,
                            botKindRaw: botKindRaw,
                            botSkillProfilePayload: botSkillProfilePayload,
                            preferredColorTokenAtMatchStart: entry.colorTokenRaw
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
            let config: MatchConfigPayload
            let session: MatchLifecycleSession
            let route: PlayRoute
            if isBaseballParty {
                config = .baseball(
                    MatchConfigBaseball(
                        inningCount: baseballInningCount,
                        tieBreaker: baseballTieBreaker,
                        seventhInningStretch: baseballSeventhInningStretch
                    )
                )
            } else if isKillerParty {
                config = .killer(MatchConfigKiller(startingLives: killerStartingLives))
            } else if isShanghaiParty {
                config = .shanghai(
                    MatchConfigShanghai(
                        roundCount: shanghaiRoundCount,
                        bonusRule: shanghaiBonusRule
                    )
                )
            } else if mode == .x01 {
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
                let scoringMode = cricketPointsEnabled ? cricketScoringMode : .standard
                config = .cricket(
                    MatchConfigCricket(
                        pointsEnabled: cricketPointsEnabled,
                        scoringMode: scoringMode,
                        legsToWin: cricketLegsToWin,
                        setsEnabled: cricketSetsEnabled,
                        setsToWin: cricketSetsEnabled ? cricketSetsToWin : nil,
                        legFormat: cricketLegFormat
                    )
                )
            }
            let configPayload = try CodablePayloadCoder.encode(config)
            let avatarByPlayerId = Dictionary(
                uniqueKeysWithValues: rosterEntries.map { ($0.id, $0.avatarStyleRaw) }
            )
            let participantsForRepository = selectedPlayers.enumerated().map { index, participant in
                MatchParticipantSummary(
                    id: participant.id,
                    matchId: UUID(),
                    playerId: participant.playerId,
                    turnOrder: index,
                    displayNameAtMatchStart: participant.displayNameAtMatchStart,
                    avatarStyleAtMatchStart: participant.playerId.flatMap { avatarByPlayerId[$0] } ?? nil,
                    botDifficultyRaw: participant.botDifficultyRaw,
                    botKindRaw: participant.botKindRaw,
                    botSkillProfilePayload: participant.botSkillProfilePayload
                )
            }
            let persisted = try await matchRepository.createMatch(
                type: matchType,
                configPayload: configPayload,
                participants: participantsForRepository
            )

            if isBaseballParty {
                session = try MatchLifecycleService.createMatch(
                    matchId: persisted.id,
                    type: .baseball,
                    config: config,
                    participants: selectedPlayers
                )
                route = .baseballMatch(matchId: persisted.id)
            } else if isKillerParty {
                session = try MatchLifecycleService.createMatch(
                    matchId: persisted.id,
                    type: .killer,
                    config: config,
                    participants: selectedPlayers
                )
                route = .killerMatch(matchId: persisted.id)
            } else if isShanghaiParty {
                session = try MatchLifecycleService.createMatch(
                    matchId: persisted.id,
                    type: .shanghai,
                    config: config,
                    participants: selectedPlayers
                )
                route = .shanghaiMatch(matchId: persisted.id)
            } else if mode == .x01 {
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
            logger.info(
                .scoring,
                eventName: "match_started",
                message: "Match created and persisted.",
                metadata: [
                    "matchId": persisted.id.uuidString,
                    "matchType": matchType.rawValue,
                    "participantCount": String(selectedPlayers.count)
                ],
                correlationId: persisted.id.uuidString
            )
            return route
        } catch is CancellationError {
            return nil
        } catch {
            logger.error(
                .scoring,
                eventName: "match_start_failed",
                message: "Match creation failed.",
                metadata: appErrorMetadata(for: error)
            )
            if let appError = error as? AppError {
                if appError.code == .conflict {
                    showActiveMatchConflict = true
                    validationErrors = []
                    return nil
                }
                validationErrors = [appError.userMessageKey]
            } else {
                validationErrors = ["setup.error.start"]
            }
            return nil
        }
    }

    private func persistLastUsedSetup() async {
        if setupCategory == .party, partyGame == .baseball {
            BaseballSetupPreferences.save(
                inningCount: baseballInningCount,
                tieBreaker: baseballTieBreaker,
                seventhInningStretch: baseballSeventhInningStretch
            )
            return
        }
        if setupCategory == .party, partyGame == .killer {
            KillerSetupPreferences.save(startingLives: killerStartingLives)
            return
        }
        if setupCategory == .party, partyGame == .shanghai {
            ShanghaiSetupPreferences.save(roundCount: shanghaiRoundCount, bonusRule: shanghaiBonusRule)
            return
        }
        if mode == .cricket {
            CricketSetupPreferences.save(
                pointsEnabled: cricketPointsEnabled,
                scoringMode: cricketPointsEnabled ? cricketScoringMode : .standard
            )
        }
        guard let settings = try? await settingsRepository.fetchSettings() else { return }
        let legsToWin = mode == .x01 ? x01LegsToWin : cricketLegsToWin
        let setsEnabled = mode == .x01 ? x01SetsEnabled : cricketSetsEnabled
        let legFormat = mode == .x01 ? x01LegFormat : cricketLegFormat
        let next = SettingsSummary(
            id: settings.id,
            appearanceModeRaw: settings.appearanceModeRaw,
            hapticsEnabled: settings.hapticsEnabled,
            soundEnabled: settings.soundEnabled,
            turnTotalCallerEnabled: settings.turnTotalCallerEnabled,
            defaultMatchTypeRaw: mode == .x01 ? MatchType.x01.rawValue : MatchType.cricket.rawValue,
            defaultX01StartScore: x01StartScore,
            defaultCheckoutModeRaw: x01CheckoutMode.rawValue,
            defaultCheckInModeRaw: x01CheckInMode.rawValue,
            defaultLegFormatRaw: legFormat.rawValue,
            defaultLegsToWin: legsToWin,
            defaultSetsEnabled: setsEnabled,
            botStaggerEnabled: settings.botStaggerEnabled,
            botDartHapticsEnabled: settings.botDartHapticsEnabled,
            updatedAt: Date()
        )
        _ = try? await settingsRepository.updateSettings(next)
    }

    private func appErrorMetadata(for error: Error) -> [String: String] {
        if let appError = error as? AppError {
            return [
                "errorCode": appError.code.rawValue,
                "layer": appError.layer.rawValue
            ]
        }
        return ["errorCode": "unknown"]
    }
}
