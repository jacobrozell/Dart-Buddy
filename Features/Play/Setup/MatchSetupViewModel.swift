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
    @Published var americanCricketPointsEnabled = true
    @Published var aroundTheClockIncludeBullFinish = false
    @Published var aroundTheClockResetPolicy: AroundTheClockResetPolicy = .noReset
    @Published var aroundTheClock180ParScoreEnabled = false
    @Published var aroundTheClock180ParScore: Int = 60
    @Published var chaseTheDragonLaps: ChaseTheDragonLaps = .one
    @Published var englishCricketWicketsPerInnings: Int = 10
    @Published var englishCricketEndWhenTargetPassed = true
    @Published var footballGoalsToWin: Int = 10
    @Published var footballKickoffMode: FootballKickoffMode = .singleBull
    @Published var golfCourseLength: Int = GolfCourseLength.nine.rawValue
    @Published var grandNationalRuleset: GrandNationalRuleset = .novice
    @Published var grandNationalLaps: Int = 2
    @Published var hareAndHoundsHoundStart: HoundStartPosition = .segment5
    @Published var knockoutStrikesToEliminate: Int = 3
    @Published var suddenDeathEliminateAllTied = true
    @Published var suddenDeathVisitsPerRound: Int = 1
    @Published var fiftyOneByFivesTargetPoints: Int = 51
    @Published var fiftyOneByFivesMustFinishExact = false
    @Published var nineLivesStartingLives: NineLivesStartingLives = .nine
    @Published var fleetPreset: FleetSetupPreferences.Preset = .standard
    @Published var fleetShipCount: FleetShipCount = .standard
    @Published var fleetShipHealth: FleetShipHealth = .armored
    @Published var fleetBullAllowed = false
    @Published var fleetCallMode: FleetCallMode = .strict
    @Published var fleetSonarEnabled = true
    @Published var fleetHandoffEachTurn = false
    @Published var raidBossTier: RaidBossTier = .standard
    @Published var raidHeroHearts: Int = 3
    @Published var raidEnrageEnabled = true
    @Published var randomOrder = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var validationErrors: [String] = []
    @Published private(set) var selectedCatalogMatchType: MatchType?
    /// Drives the "Game in Progress" confirmation when a match is already active.
    @Published var showActiveMatchConflict = false

    private let playerRepository: any PlayerRepository
    private let settingsRepository: any SettingsRepository
    private let matchRepository: any MatchRepository
    private let pendingMatchPlayerSelections: PendingMatchPlayerSelections
    private let logger: any AppLogger
    private let startService: MatchStartService
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
        self.pendingMatchPlayerSelections = pendingMatchPlayerSelections
        self.logger = logger
        self.startService = MatchStartService(
            playerRepository: playerRepository,
            matchRepository: matchRepository,
            activeMatchStore: activeMatchStore,
            logger: logger
        )
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
            fleetPreset = FleetSetupPreferences.loadPreset()
            fleetShipCount = FleetSetupPreferences.loadShipCount()
            fleetShipHealth = FleetSetupPreferences.loadShipHealth()
            fleetBullAllowed = FleetSetupPreferences.loadBullAllowed()
            fleetCallMode = FleetSetupPreferences.loadCallMode()
            fleetSonarEnabled = FleetSetupPreferences.loadSonarEnabled()
            fleetHandoffEachTurn = FleetSetupPreferences.loadHandoffEachTurn()
            let raidPrefs = RaidSetupPreferences.makeConfig()
            raidBossTier = raidPrefs.bossTier
            raidHeroHearts = raidPrefs.heroHearts
            raidEnrageEnabled = raidPrefs.enrageEnabled
            if let preferred = pendingMatchPlayerSelections.consumePreferredMatchType() {
                applyMatchTypePreferred(preferred)
            } else if selectedCatalogMatchType == nil {
                mode = settings.defaultMatchTypeRaw == MatchType.cricket.rawValue ? .cricket : .x01
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

    /// Adds a player to the match roster without toggling off if already selected (e.g. after creating from setup).
    func addPlayerToSelection(_ id: UUID) {
        appendToSelection(id)
        revalidate()
    }

    func createHumanPlayer(_ player: EditablePlayer) async {
        do {
            let created = try await playerRepository.createHumanPlayer(from: player)
            pendingMatchPlayerSelections.enqueueForNextMatchSetup(created.id)
            await onAppear()
        } catch let appError as AppError {
            logger.warning(
                .ui,
                eventName: "setup_create_human_player_failed",
                message: "Failed to create human player from setup.",
                metadata: ["error": appError.userMessageKey]
            )
        } catch {
            logger.warning(
                .ui,
                eventName: "setup_create_human_player_failed",
                message: "Failed to create human player from setup.",
                metadata: ["error": "error.player.create"]
            )
        }
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
        return validationErrors.filter {
            $0 != "setup.validation.minimumPlayers" && $0 != "setup.validation.requiresHuman"
        }
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

    /// Restores roster and mode options from a completed match for a one-tap rematch.
    func applyRematchConfiguration(from runtime: MatchRuntimeState) {
        applyMatchTypePreferred(runtime.type)

        let ordered = runtime.participants.sorted { $0.turnOrder < $1.turnOrder }
        selectedPlayerIds = ordered.map { $0.playerId ?? $0.id }
        randomOrder = false

        switch runtime.config {
        case let .x01(config):
            x01StartScore = X01StartScores.all.contains(config.startScore) ? config.startScore : 501
            x01LegsToWin = max(1, config.legsToWin)
            x01SetsEnabled = config.setsEnabled
            x01SetsToWin = max(1, config.setsToWin ?? 1)
            x01CheckoutMode = config.checkoutMode
            x01CheckInMode = config.checkInMode
            x01LegFormat = config.legFormat
        case let .cricket(config):
            cricketPointsEnabled = config.pointsEnabled
            cricketScoringMode = config.scoringMode
            cricketLegsToWin = max(1, config.legsToWin)
            cricketSetsEnabled = config.setsEnabled
            cricketSetsToWin = max(1, config.setsToWin ?? 1)
            cricketLegFormat = config.legFormat
        case let .baseball(config):
            baseballInningCount = config.inningCount
            baseballTieBreaker = config.tieBreaker
            baseballSeventhInningStretch = config.seventhInningStretch
        case let .killer(config):
            killerStartingLives = config.startingLives
        case let .shanghai(config):
            shanghaiRoundCount = config.roundCount
            shanghaiBonusRule = config.bonusRule
        case let .americanCricket(config):
            americanCricketPointsEnabled = config.pointsEnabled
        case .mickeyMouse, .mulligan:
            break
        case let .englishCricket(config):
            englishCricketWicketsPerInnings = config.wicketsPerInnings
            englishCricketEndWhenTargetPassed = config.endWhenTargetPassed
        case let .knockout(config):
            knockoutStrikesToEliminate = config.strikesToEliminate
        case let .suddenDeath(config):
            suddenDeathVisitsPerRound = config.visitsPerRound
            suddenDeathEliminateAllTied = config.eliminationRule == .eliminateAllTied
        case let .fiftyOneByFives(config):
            fiftyOneByFivesTargetPoints = config.targetPoints
            fiftyOneByFivesMustFinishExact = config.mustFinishExact
        case let .golf(config):
            golfCourseLength = config.courseLength.rawValue
        case let .football(config):
            footballGoalsToWin = config.goalsToWin
            footballKickoffMode = config.kickoffMode
        case let .grandNational(config):
            grandNationalRuleset = config.ruleset
            grandNationalLaps = config.laps
        case let .hareAndHounds(config):
            hareAndHoundsHoundStart = config.houndStart
        case let .aroundTheClock(config):
            aroundTheClockIncludeBullFinish = config.includeBullFinish
            aroundTheClockResetPolicy = config.resetPolicy
        case let .aroundTheClock180(config):
            if let par = config.parScore {
                aroundTheClock180ParScoreEnabled = true
                aroundTheClock180ParScore = par
            } else {
                aroundTheClock180ParScoreEnabled = false
            }
        case let .chaseTheDragon(config):
            chaseTheDragonLaps = config.laps
        case let .nineLives(config):
            nineLivesStartingLives = config.startingLives
        case let .fleet(config):
            fleetShipCount = config.shipCount
            fleetShipHealth = config.shipHealth
            fleetBullAllowed = config.bullAllowed
            fleetCallMode = config.callMode
            fleetSonarEnabled = config.sonarEnabled
            fleetHandoffEachTurn = config.handoffEachTurn
        case let .raid(config):
            raidBossTier = config.bossTier
            raidHeroHearts = config.heroHearts
            raidEnrageEnabled = config.enrageEnabled
        }

        normalizeForProductSurface()
        revalidate()
    }

    /// Starts a new match using the completed match's roster and configuration.
    func startRematchRoute(from runtime: MatchRuntimeState) async -> PlayRoute? {
        do {
            availablePlayers = try await playerRepository.fetchPlayers(includeArchived: false)
        } catch {
            logger.error(
                .ui,
                eventName: "rematch_player_load_failed",
                message: "Failed to load players for rematch.",
                metadata: appErrorMetadata(for: error)
            )
            validationErrors = [(error as? AppError)?.userMessageKey ?? "setup.error.load"]
            return nil
        }

        applyRematchConfiguration(from: runtime)
        let loadedIds = Set(availablePlayers.map(\.id))
        selectedPlayerIds.removeAll { !loadedIds.contains($0) }
        revalidate()
        guard canStart else { return nil }
        return await performStart(source: .rematch)
    }

    func applyPendingModeSelection(_ selection: PendingModeSelection) {
        if selection.setupCategory == .party, !ProductSurface.showsPartyModes { return }
        if let matchType = selection.matchType,
           let entry = GameModeCatalog.entry(for: matchType),
           entry.section == .coop,
           !ProductSurface.showsCoopModes {
            return
        }
        setupCategory = selection.setupCategory
        if let mode = selection.mode {
            self.mode = mode
        }
        if let partyGame = selection.partyGame {
            self.partyGame = partyGame
        }
        selectedCatalogMatchType = selection.matchType
        normalizeForProductSurface()
        revalidate()
    }

    private func applyMatchTypePreferred(_ matchType: MatchType) {
        selectedCatalogMatchType = matchType
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
        if let catalogType = selectedCatalogMatchType,
           let entry = GameModeCatalog.entry(for: catalogType),
           entry.section == .coop,
           !ProductSurface.showsCoopModes {
            setupCategory = .standard
            mode = .x01
            selectedCatalogMatchType = nil
        }
    }

    func revalidate() {
        var errors: [String] = []
        if let catalogType = selectedCatalogMatchType,
           let entry = GameModeCatalog.entry(for: catalogType) {
            errors.append(contentsOf: catalogSelectionValidationErrors(catalogType: catalogType, entry: entry))
        } else if setupCategory == .party {
            errors.append(contentsOf: partySelectionValidationErrors())
        } else {
            errors.append(contentsOf: defaultRosterValidationErrors())
        }
        errors.append(contentsOf: standardModeConfigValidationErrors())
        validationErrors = errors
    }

    private func catalogSelectionValidationErrors(
        catalogType: MatchType,
        entry: GameModeCatalogEntry
    ) -> [String] {
        if entry.section == .party, !ProductSurface.showsPartyModes {
            return ["setup.validation.partyComingSoon"]
        }
        if entry.section == .coop, !ProductSurface.showsCoopModes {
            return ["setup.validation.coopComingSoon"]
        }
        if !entry.isAvailable {
            return ["setup.validation.partyComingSoon"]
        }
        if selectedParticipantCount < entry.minimumPlayers {
            let key = catalogType == .killer
                ? "setup.validation.partyKillerMinimumPlayers"
                : "setup.validation.minimumPlayers"
            return [key]
        }
        if selectedPlayers.allSatisfy(\.isBot) {
            return ["setup.validation.requiresHuman"]
        }
        if catalogType == .fleet, selectedParticipantCount != 2 {
            return ["setup.validation.fleetExactTwoPlayers"]
        }
        if entry.section == .coop {
            if selectedParticipantCount > 3 {
                return ["setup.validation.raidHeroCount"]
            }
            if selectedPlayers.contains(where: \.isBot) {
                return ["setup.validation.coopHumansOnly"]
            }
        }
        return []
    }

    private func partySelectionValidationErrors() -> [String] {
        if !ProductSurface.showsPartyModes {
            return ["setup.validation.partyComingSoon"]
        }
        if !partyGame.isAvailable {
            return ["setup.validation.partyComingSoon"]
        }
        if selectedParticipantCount < partyGame.minimumPlayers {
            return [partyMinimumPlayersValidationKey]
        }

        var errors: [String] = []
        let selected = selectedPlayers
        if selected.allSatisfy(\.isBot) {
            errors.append("setup.validation.requiresHuman")
        }
        if partyGame == .baseball,
           selected.contains(where: \.isCustomBot) || selected.contains(where: \.isTrainingBot) {
            errors.append("setup.validation.baseballBotsPresetOnly")
        }
        if partyGame == .shanghai,
           selected.contains(where: \.isCustomBot) || selected.contains(where: \.isTrainingBot) {
            errors.append("setup.validation.shanghaiBotsPresetOnly")
        }
        if partyGame == .killer,
           selected.contains(where: \.isCustomBot) || selected.contains(where: \.isTrainingBot) {
            errors.append("setup.validation.killerBotsPresetOnly")
        }
        return errors
    }

    private func defaultRosterValidationErrors() -> [String] {
        if mode == .x01 {
            // Solo X01 is allowed (single-player practice); only require a human.
            // `allSatisfy` is vacuously true for an empty roster, so this also
            // covers the "no players selected" case.
            if selectedPlayers.allSatisfy(\.isBot) {
                return ["setup.validation.requiresHuman"]
            }
            return []
        }
        if selectedParticipantCount < 2 {
            return ["setup.validation.minimumPlayers"]
        }
        if selectedPlayers.allSatisfy(\.isBot) {
            return ["setup.validation.requiresHuman"]
        }
        return []
    }

    private func standardModeConfigValidationErrors() -> [String] {
        if setupCategory == .standard, mode == .x01 {
            var errors: [String] = []
            if !X01StartScores.all.contains(x01StartScore) {
                errors.append("setup.validation.invalidStartScore")
            }
            if x01LegsToWin <= 0 {
                errors.append("setup.validation.invalidLegs")
            }
            if x01SetsEnabled, x01SetsToWin <= 0 {
                errors.append("setup.validation.invalidSets")
            }
            return errors
        }
        if setupCategory == .standard {
            var errors: [String] = []
            if cricketLegsToWin <= 0 {
                errors.append("setup.validation.invalidLegs")
            }
            if cricketSetsEnabled, cricketSetsToWin <= 0 {
                errors.append("setup.validation.invalidSets")
            }
            let hasBot = selectedPlayers.contains(where: \.isBot)
            if hasBot, !cricketPointsEnabled {
                errors.append("setup.validation.cricketBotUnsupported")
            }
            return errors
        }
        return []
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
                try await startService.abandonActiveMatch(active)
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

    private var currentMatchType: MatchType {
        if let selectedCatalogMatchType {
            return selectedCatalogMatchType
        }
        if setupCategory == .party {
            switch partyGame {
            case .baseball: return .baseball
            case .killer: return .killer
            case .shanghai: return .shanghai
            }
        }
        return mode == .x01 ? .x01 : .cricket
    }

    private var currentConfig: MatchConfigPayload {
        switch currentMatchType {
        case .baseball:
            return .baseball(
                MatchConfigBaseball(
                    inningCount: baseballInningCount,
                    tieBreaker: baseballTieBreaker,
                    seventhInningStretch: baseballSeventhInningStretch
                )
            )
        case .killer:
            return .killer(MatchConfigKiller(startingLives: killerStartingLives))
        case .shanghai:
            return .shanghai(
                MatchConfigShanghai(
                    roundCount: shanghaiRoundCount,
                    bonusRule: shanghaiBonusRule
                )
            )
        case .x01:
            return .x01(
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
        case .cricket:
            return .cricket(
                MatchConfigCricket(
                    pointsEnabled: cricketPointsEnabled,
                    scoringMode: cricketPointsEnabled ? cricketScoringMode : .standard,
                    legsToWin: cricketLegsToWin,
                    setsEnabled: cricketSetsEnabled,
                    setsToWin: cricketSetsEnabled ? cricketSetsToWin : nil,
                    legFormat: cricketLegFormat
                )
            )
        case .americanCricket:
            return .americanCricket(MatchConfigAmericanCricket(pointsEnabled: americanCricketPointsEnabled))
        case .mickeyMouse:
            return .mickeyMouse(MatchConfigMickeyMouse())
        case .mulligan:
            return MatchConfigDefaults.config(for: .mulligan)
        case .englishCricket:
            return .englishCricket(
                MatchConfigEnglishCricket(
                    wicketsPerInnings: englishCricketWicketsPerInnings,
                    endWhenTargetPassed: englishCricketEndWhenTargetPassed
                )
            )
        case .knockout:
            return .knockout(MatchConfigKnockout(strikesToEliminate: knockoutStrikesToEliminate))
        case .suddenDeath:
            return .suddenDeath(
                MatchConfigSuddenDeath(
                    visitsPerRound: suddenDeathVisitsPerRound,
                    eliminationRule: suddenDeathEliminateAllTied ? .eliminateAllTied : .eliminateOne
                )
            )
        case .fiftyOneByFives:
            return .fiftyOneByFives(
                MatchConfigFiftyOneByFives(
                    targetPoints: fiftyOneByFivesTargetPoints,
                    mustFinishExact: fiftyOneByFivesMustFinishExact
                )
            )
        case .golf:
            return .golf(
                MatchConfigGolf(
                    courseLength: GolfCourseLength(rawValue: golfCourseLength) ?? .nine
                )
            )
        case .football:
            return .football(
                MatchConfigFootball(
                    goalsToWin: footballGoalsToWin,
                    kickoffMode: footballKickoffMode
                )
            )
        case .grandNational:
            return .grandNational(
                MatchConfigGrandNational(
                    ruleset: grandNationalRuleset,
                    laps: grandNationalLaps
                )
            )
        case .hareAndHounds:
            return .hareAndHounds(MatchConfigHareAndHounds(houndStart: hareAndHoundsHoundStart))
        case .aroundTheClock:
            return .aroundTheClock(
                MatchConfigAroundTheClock(
                    includeBullFinish: aroundTheClockIncludeBullFinish,
                    resetPolicy: aroundTheClockResetPolicy
                )
            )
        case .aroundTheClock180:
            return .aroundTheClock180(
                MatchConfigAroundTheClock180(
                    parScore: aroundTheClock180ParScoreEnabled ? aroundTheClock180ParScore : nil
                )
            )
        case .chaseTheDragon:
            return .chaseTheDragon(MatchConfigChaseTheDragon(laps: chaseTheDragonLaps))
        case .nineLives:
            return .nineLives(MatchConfigNineLives(startingLives: nineLivesStartingLives))
        case .fleet:
            return .fleet(
                MatchConfigFleet(
                    shipCount: fleetShipCount,
                    shipHealth: fleetShipHealth,
                    bullAllowed: fleetBullAllowed,
                    callMode: fleetCallMode,
                    sonarEnabled: fleetSonarEnabled,
                    handoffEachTurn: fleetHandoffEachTurn
                )
            )
        case .raid:
            return .raid(
                MatchConfigRaid(
                    bossTier: raidBossTier,
                    heroHearts: raidHeroHearts,
                    enrageEnabled: raidEnrageEnabled
                )
            )
        case .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt:
            return MatchConfigDefaults.config(for: .x01)
        }
    }

    private func performStart(source: MatchStartSource = .setup) async -> PlayRoute? {
        guard canStart else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        let plan = MatchStartPlan(
            matchType: currentMatchType,
            config: currentConfig,
            roster: selectedPlayers.map(MatchStartPlan.RosterEntry.init),
            randomOrder: randomOrder,
            startSource: source
        )
        switch await startService.start(plan) {
        case let .started(route):
            await persistLastUsedSetup()
            return route
        case .conflict:
            showActiveMatchConflict = true
            validationErrors = []
            return nil
        case .cancelled:
            return nil
        case let .failed(messageKey):
            validationErrors = [messageKey]
            return nil
        }
    }

    func applyFleetPreset(_ preset: FleetSetupPreferences.Preset) {
        fleetPreset = preset
        let config = preset.config
        fleetShipCount = config.shipCount
        fleetShipHealth = config.shipHealth
        fleetBullAllowed = config.bullAllowed
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
        if selectedCatalogMatchType == .fleet || currentMatchType == .fleet {
            FleetSetupPreferences.save(preset: fleetPreset)
            FleetSetupPreferences.save(shipCount: fleetShipCount)
            FleetSetupPreferences.save(shipHealth: fleetShipHealth)
            FleetSetupPreferences.save(bullAllowed: fleetBullAllowed)
            FleetSetupPreferences.save(callMode: fleetCallMode)
            FleetSetupPreferences.save(sonarEnabled: fleetSonarEnabled)
            FleetSetupPreferences.save(handoffEachTurn: fleetHandoffEachTurn)
            return
        }
        if mode == .cricket {
            CricketSetupPreferences.save(
                pointsEnabled: cricketPointsEnabled,
                scoringMode: cricketPointsEnabled ? cricketScoringMode : .standard
            )
        }
        let settings: SettingsSummary
        do {
            settings = try await settingsRepository.fetchSettings()
        } catch {
            logger.warning(
                .ui,
                eventName: "setup_defaults_fetch_failed",
                message: "Could not load settings to persist last-used setup.",
                metadata: appErrorMetadata(for: error)
            )
            return
        }
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
            defaultDartEntryPresentationRaw: settings.defaultDartEntryPresentationRaw,
            updatedAt: Date()
        )
        do {
            _ = try await settingsRepository.updateSettings(next)
        } catch {
            logger.warning(
                .ui,
                eventName: "setup_defaults_update_failed",
                message: "Could not persist last-used setup defaults.",
                metadata: appErrorMetadata(for: error)
            )
        }
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
