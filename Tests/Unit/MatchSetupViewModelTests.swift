import Foundation
import Testing
@testable import DartBuddy

@MainActor
@Test(.tags(.integration, .setupFlow, .settings, .regression))
func setupOnAppearAppliesSettingsDefaults() async {
    let settings = SettingsSummary(
        id: UUID(),
        appearanceModeRaw: "system",
        hapticsEnabled: true,
        soundEnabled: true,
        turnTotalCallerEnabled: false,
        defaultMatchTypeRaw: MatchType.cricket.rawValue,
        defaultX01StartScore: 601,
        defaultCheckoutModeRaw: X01CheckoutMode.masterOut.rawValue,
        defaultCheckInModeRaw: X01CheckInMode.doubleIn.rawValue,
        defaultLegFormatRaw: X01LegFormat.firstTo.rawValue,
        defaultLegsToWin: 5,
        defaultSetsEnabled: true,
        botStaggerEnabled: true,
        botDartHapticsEnabled: true,
        defaultDartEntryPresentationRaw: "numberPad",
        updatedAt: Date()
    )
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        settingsRepository: FakeSettingsRepository(settings: settings),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )

    await vm.onAppear()

    #expect(vm.mode == .cricket)
    #expect(vm.x01StartScore == 601)
    #expect(vm.x01CheckoutMode == .masterOut)
    #expect(vm.x01CheckInMode == .doubleIn)
    #expect(vm.x01LegsToWin == 5)
    #expect(vm.cricketLegsToWin == 5)
    #expect(vm.x01SetsEnabled == true)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .settings, .regression))
func setupOnAppearFallsBackTo501WhenStartScoreUnsupported() async {
    let settings = SettingsSummary(
        id: UUID(),
        appearanceModeRaw: "system",
        hapticsEnabled: true,
        soundEnabled: true,
        turnTotalCallerEnabled: false,
        defaultMatchTypeRaw: MatchType.x01.rawValue,
        defaultX01StartScore: 701,
        defaultCheckoutModeRaw: X01CheckoutMode.doubleOut.rawValue,
        defaultCheckInModeRaw: X01CheckInMode.straightIn.rawValue,
        defaultLegFormatRaw: X01LegFormat.firstTo.rawValue,
        defaultLegsToWin: 3,
        defaultSetsEnabled: false,
        botStaggerEnabled: true,
        botDartHapticsEnabled: true,
        defaultDartEntryPresentationRaw: "numberPad",
        updatedAt: Date()
    )
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        settingsRepository: FakeSettingsRepository(settings: settings),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )

    await vm.onAppear()

    #expect(vm.x01StartScore == 501)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .settings, .regression))
func setupOnAppearResyncsDefaultModeFromSettings() async {
    let repository = FakeSettingsRepository()
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        settingsRepository: repository,
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )

    await vm.onAppear()
    #expect(vm.mode == .x01)

    await repository.replaceSettings(SettingsSummary(
        id: UUID(),
        appearanceModeRaw: "system",
        hapticsEnabled: true,
        soundEnabled: true,
        turnTotalCallerEnabled: false,
        defaultMatchTypeRaw: MatchType.cricket.rawValue,
        defaultX01StartScore: 501,
        defaultCheckoutModeRaw: X01CheckoutMode.doubleOut.rawValue,
        defaultCheckInModeRaw: X01CheckInMode.straightIn.rawValue,
        defaultLegFormatRaw: X01LegFormat.firstTo.rawValue,
        defaultLegsToWin: 3,
        defaultSetsEnabled: false,
        botStaggerEnabled: true,
        botDartHapticsEnabled: true,
        defaultDartEntryPresentationRaw: "numberPad",
        updatedAt: Date()
    ))
    await vm.onAppear()
    #expect(vm.mode == .cricket)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupValidationRequiresMinimumPlayers() async {
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A")]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    // Cricket keeps the two-player minimum; X01 now allows solo play.
    vm.mode = .cricket
    vm.selectedPlayerIds = []
    vm.revalidate()

    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.minimumPlayers"))
    #expect(!vm.isRosterEmpty)
    #expect(vm.displayValidationErrors.contains("setup.validation.minimumPlayers"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupAllowsSoloX01WithSingleHuman() async {
    let player = makePlayer("Solo")
    let vm = makeSetupViewModel(players: [player])
    await vm.onAppear()
    vm.mode = .x01
    vm.togglePlayer(player.id)
    vm.revalidate()

    #expect(vm.selectedParticipantCount == 1)
    #expect(vm.canStart)
    #expect(!vm.validationErrors.contains("setup.validation.minimumPlayers"))
    #expect(!vm.validationErrors.contains("setup.validation.requiresHuman"))
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupPartyKillerAllowsThreeHumans() async {
    guard ProductSurface.showsPartyModes else { return }
    let players = [makePlayer("A"), makePlayer("B"), makePlayer("C")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.updateSetupCategory(.party)
    vm.updatePartyGame(.killer)
    selectAll(players, in: vm)
    vm.revalidate()

    #expect(vm.canStart)
    #expect(vm.validationErrors.isEmpty)
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func applyPendingModeSelectionPrefillsPartyKiller() async {
    guard ProductSurface.showsPartyModes else { return }
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B"), makePlayer("C")]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )

    vm.applyPendingModeSelection(
        PendingModeSelection(
            setupCategory: .party,
            mode: nil,
            partyGame: .killer,
            matchType: .killer
        )
    )

    #expect(vm.setupCategory == .party)
    #expect(vm.partyGame == .killer)
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func onAppearDoesNotResetCatalogModeSelection() async {
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    vm.applyPendingModeSelection(
        PendingModeSelection(setupCategory: .standard, mode: nil, partyGame: nil, matchType: .golf)
    )

    await vm.onAppear()

    #expect(vm.selectedCatalogMatchType == .golf)
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupPartyKillerAllowsPresetBot() async {
    guard ProductSurface.showsPartyModes else { return }
    let human = makePlayer("Human")
    let bot = PlayerSummary(
        id: UUID(),
        name: "Bot",
        isArchived: false,
        isBot: true,
        botDifficultyRaw: BotDifficulty.easy.rawValue,
        botKindRaw: BotKind.preset.rawValue,
        createdAt: Date(),
        updatedAt: Date()
    )
    let third = makePlayer("Guest")
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [human, bot, third]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.updateSetupCategory(.party)
    vm.updatePartyGame(.killer)
    vm.selectedPlayerIds = [human.id, bot.id, third.id]
    vm.revalidate()

    #expect(vm.canStart)
    #expect(vm.validationErrors.isEmpty)
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupPartyKillerBlocksCustomTrainingBots() async {
    guard ProductSurface.showsPartyModes else { return }
    let human = makePlayer("Human")
    let custom = makeCustomBot("Custom")
    let third = makePlayer("Guest")
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [human, custom, third]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.updateSetupCategory(.party)
    vm.updatePartyGame(.killer)
    vm.selectedPlayerIds = [human.id, custom.id, third.id]
    vm.revalidate()

    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.killerBotsPresetOnly"))
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupPartyBaseballBlocksCustomTrainingBots() async {
    guard ProductSurface.showsPartyModes else { return }
    let human = makePlayer("Human")
    let custom = makeCustomBot("Custom")
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [human, custom]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.updateSetupCategory(.party)
    vm.updatePartyGame(.baseball)
    vm.selectedPlayerIds = [human.id, custom.id]
    vm.revalidate()

    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.baseballBotsPresetOnly"))
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupExistingCustomBotAppendsToSelection() async {
    let human = makePlayer("Human")
    let custom = makeCustomBot("Custom Ace")
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [human, custom]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(human.id)
    vm.addExistingCustomBot(custom.id)

    #expect(vm.selectedPlayerIds.contains(human.id))
    #expect(vm.selectedPlayerIds.contains(custom.id))
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func displayValidationErrorsHidesMinimumPlayersWhenRosterEmpty() async {
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: []),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    // Cricket keeps the two-player minimum; X01 now allows solo play.
    vm.mode = .cricket
    vm.revalidate()

    #expect(vm.isRosterEmpty)
    #expect(vm.validationErrors.contains("setup.validation.minimumPlayers"))
    #expect(vm.displayValidationErrors.isEmpty)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupOnAppearSelectsPendingPlayersWhenPresent() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let pending = PendingMatchPlayerSelections()
    pending.enqueueForNextMatchSetup(players[1].id)
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: pending
    )
    await vm.onAppear()
    #expect(vm.selectedPlayerIds.contains(players[1].id))
    #expect(!vm.selectedPlayerIds.contains(players[0].id))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupCreateHumanPlayerAutoSelectsNewPlayer() async {
    let repository = HumanCreatingPlayerRepository()
    let pending = PendingMatchPlayerSelections()
    let vm = MatchSetupViewModel(
        playerRepository: repository,
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: pending
    )
    await vm.onAppear()
    #expect(vm.availableHumans.isEmpty)

    let draft = EditablePlayer(
        id: UUID(),
        name: "Casey",
        isArchived: false,
        notes: "",
        isBot: false,
        isTrainingBot: false,
        isCustomBot: false,
        customX01Average: CustomBotMetrics.defaultX01Average,
        customCricketMPR: CustomBotMetrics.defaultCricketMPR,
        customBotConfiguration: nil,
        linkedPlayerId: nil,
        botDifficulty: nil,
        avatarStyle: .dart,
        colorToken: .blue
    )
    await vm.createHumanPlayer(draft)

    #expect(vm.availableHumans.isEmpty)
    #expect(vm.selectedPlayers.count == 1)
    #expect(vm.selectedPlayers[0].name == "Casey")
    #expect(vm.selectedPlayerIds == [vm.selectedPlayers[0].id])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupAddPlayerToSelectionIsIdempotent() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.addPlayerToSelection(players[0].id)
    vm.addPlayerToSelection(players[0].id)
    #expect(vm.selectedPlayerIds == [players[0].id])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupMoveSelectedPlayersReordersTurnOrder() async {
    let players = [makePlayer("A"), makePlayer("B"), makePlayer("C")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)
    vm.togglePlayer(players[2].id)
    #expect(vm.selectedPlayers.map(\.name) == ["A", "B", "C"])

    vm.moveSelectedPlayers(from: IndexSet(integer: 2), to: 0)
    #expect(vm.selectedPlayers.map(\.name) == ["C", "A", "B"])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupRemoveSelectedPlayersAtOffsets() async {
    let players = [makePlayer("A"), makePlayer("B"), makePlayer("C")]
    let vm = makeSetupViewModel(players: players)
    await vm.onAppear()
    selectAll(players, in: vm)

    vm.removeSelectedPlayers(at: IndexSet(integer: 1))

    #expect(vm.selectedPlayers.map(\.name) == ["A", "C"])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupRemoveFromSelectionReturnsPlayerToAvailableRoster() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = makeSetupViewModel(players: players)
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    vm.removeFromSelection(players[1].id)

    #expect(vm.selectedPlayers.map(\.name) == ["A"])
    #expect(vm.availableHumans.map(\.name) == ["B"])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupRemoveSelectedPlayersBlocksStartBelowMinimum() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = makeSetupViewModel(players: players)
    await vm.onAppear()
    // Cricket keeps the two-player minimum; X01 now allows solo play.
    vm.mode = .cricket
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    vm.removeSelectedPlayers(at: IndexSet(integer: 1))

    #expect(vm.selectedParticipantCount == 1)
    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.minimumPlayers"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupRemoveMultipleSelectedPlayersAtOffsets() async {
    let players = [makePlayer("A"), makePlayer("B"), makePlayer("C"), makePlayer("D")]
    let vm = makeSetupViewModel(players: players)
    await vm.onAppear()
    selectAll(players, in: vm)

    vm.removeSelectedPlayers(at: IndexSet([1, 2]))

    #expect(vm.selectedPlayers.map(\.name) == ["A", "D"])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupRemoveLastSelectedPlayerClearsTurnOrder() async {
    let players = [makePlayer("A")]
    let vm = makeSetupViewModel(players: players)
    await vm.onAppear()
    vm.togglePlayer(players[0].id)

    vm.removeFromSelection(players[0].id)

    #expect(vm.selectedPlayerIds.isEmpty)
    #expect(vm.selectedPlayers.isEmpty)
    #expect(vm.availableHumans.map(\.name) == ["A"])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupTogglePlayerRemovesFromTurnOrderWhenAlreadySelected() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = makeSetupViewModel(players: players)
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    vm.togglePlayer(players[0].id)

    #expect(vm.selectedPlayers.map(\.name) == ["B"])
    #expect(vm.availableHumans.map(\.name) == ["A"])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupStartMatchUsesManualTurnOrder() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let repo = TurnOrderCapturingMatchRepository()
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: repo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.randomOrder = false
    vm.togglePlayer(players[1].id)
    vm.togglePlayer(players[0].id)

    _ = await vm.startMatchRoute()

    #expect(await repo.lastParticipantNames == ["B", "A"])
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .regression))
func setupValidationBlocksBotOnlyMatch() async {
    let easyBot = PlayerSummary(
        id: UUID(),
        name: "Easy Bot 1",
        isArchived: false,
        isBot: true,
        botDifficultyRaw: BotDifficulty.easy.rawValue,
        createdAt: Date(),
        updatedAt: Date()
    )
    let mediumBot = PlayerSummary(
        id: UUID(),
        name: "Medium Bot 1",
        isArchived: false,
        isBot: true,
        botDifficultyRaw: BotDifficulty.medium.rawValue,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [easyBot, mediumBot]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(easyBot.id)
    vm.togglePlayer(mediumBot.id)

    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.requiresHuman"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupAllowsCutThroatCricketWithBot() async {
    let human = makePlayer("Alice")
    let vm = makeSetupViewModel(players: [human])
    await vm.onAppear()
    vm.updateMode(.cricket)
    vm.cricketScoringMode = .cutThroat
    vm.cricketPointsEnabled = true
    vm.togglePlayer(human.id)
    await vm.addBot(.easy)

    #expect(vm.canStart)
    #expect(!vm.validationErrors.contains("setup.validation.cricketBotUnsupported"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .regression))
func setupBlocksCricketBotWhenPointsOff() async {
    let human = makePlayer("Alice")
    let vm = makeSetupViewModel(players: [human])
    await vm.onAppear()
    vm.updateMode(.cricket)
    vm.cricketPointsEnabled = false
    vm.togglePlayer(human.id)
    await vm.addBot(.easy)

    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.cricketBotUnsupported"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupPartyBaseballStartRoute() async {
    guard ProductSurface.showsPartyModes else { return }
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.updateSetupCategory(.party)
    vm.updatePartyGame(.baseball)
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.startMatchRoute()
    if case .baseballMatch = route {
        #expect(true)
    } else {
        Issue.record("Expected baseball route, got \(String(describing: route))")
    }
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupStartRouteUsesSelectedMode() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.updateMode(.cricket)
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.startMatchRoute()
    if case .cricketMatch = route {
        #expect(true)
    } else {
        Issue.record("Expected cricket route")
    }
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .regression))
func setupStartMatchRouteSurfacesErrorWhenActiveLookupFails() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: ThrowingActiveLookupMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.startMatchRoute()
    #expect(route == nil)
    #expect(vm.validationErrors.contains("setup.error.start"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .regression))
func setupStartPromptsWhenAnotherMatchIsActive() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let repo = ActiveConflictMatchRepository(hasActive: true)
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: repo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.startMatchRoute()
    #expect(route == nil)
    #expect(vm.showActiveMatchConflict)
    #expect(await repo.deletedCount == 0)
    #expect(vm.validationErrors.isEmpty)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .regression))
func setupConfirmReplaceAbandonsWithoutSnapshotWhenStoreEmpty() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let activeId = UUID()
    let active = MatchSummary(
        id: activeId,
        type: .x01,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let repo = NoSnapshotActiveConflictRepository(active: active)
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: repo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.confirmReplaceActiveMatch()
    #expect(route != nil)
    #expect(await repo.abandonedCount == 1)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .regression))
func setupConfirmReplaceAbandonsViaSnapshotWhenStoreEmpty() async throws {
    let players = [makePlayer("A"), makePlayer("B")]
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: players[0].id, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: players[1].id, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let matchId = session.runtime.matchId
    let active = MatchSummary(
        id: matchId,
        type: .x01,
        status: .inProgress,
        startedAt: session.runtime.startedAt,
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.runtime.eventCount,
        createdAt: session.runtime.startedAt,
        updatedAt: Date()
    )
    let snapshotSummary = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload,
        updatedAt: Date()
    )
    let repo = SnapshotOnlyActiveConflictRepository(active: active, snapshot: snapshotSummary)
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: repo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.confirmReplaceActiveMatch()
    #expect(route != nil)
    #expect(await repo.abandonedCount == 1)
    #expect(await repo.snapshotSaved)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .regression))
func setupConfirmReplaceAbandonsActiveMatchThenStarts() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let repo = ActiveConflictMatchRepository(hasActive: true)
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: repo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.confirmReplaceActiveMatch()
    #expect(route != nil)
    #expect(!vm.showActiveMatchConflict)
    #expect(await repo.abandonedCount == 1)
    #expect(await repo.deletedCount == 0)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupRematchAppliesCompletedMatchConfiguration() async throws {
    let players = [makePlayer("A"), makePlayer("B")]
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 301,
                legsToWin: 5,
                setsEnabled: true,
                setsToWin: 3,
                checkoutMode: .masterOut,
                checkInMode: .doubleIn,
                legFormat: .bestOf
            )
        ),
        participants: [
            MatchParticipant(playerId: players[1].id, displayNameAtMatchStart: "B", turnOrder: 1),
            MatchParticipant(playerId: players[0].id, displayNameAtMatchStart: "A", turnOrder: 0)
        ]
    )
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()

    vm.applyRematchConfiguration(from: session.runtime)

    #expect(vm.mode == .x01)
    #expect(vm.selectedPlayerIds == [players[0].id, players[1].id])
    #expect(vm.x01StartScore == 301)
    #expect(vm.x01LegsToWin == 5)
    #expect(vm.x01SetsEnabled)
    #expect(vm.x01SetsToWin == 3)
    #expect(vm.x01CheckoutMode == .masterOut)
    #expect(vm.x01CheckInMode == .doubleIn)
    #expect(vm.x01LegFormat == .bestOf)
    #expect(!vm.randomOrder)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupStartRematchRouteStartsNewMatchWithSameRoster() async throws {
    let players = [makePlayer("A"), makePlayer("B")]
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: players[0].id, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: players[1].id, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    var completed = session
    completed.runtime.status = .completed
    let matchRepo = FakeMatchRepository()
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: matchRepo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )

    let route = await vm.startRematchRoute(from: completed.runtime)

    if case let .x01Match(newMatchId) = route {
        #expect(newMatchId != completed.runtime.matchId)
        #expect(vm.selectedPlayerIds == [players[0].id, players[1].id])
        #expect(vm.x01StartScore == 101)
    } else {
        Issue.record("Expected x01 rematch route")
    }
}

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupStartMatchSnapshotsTrainingBotSkill() async throws {
    let humanId = UUID()
    let trainingBotId = UUID()
    let human = PlayerSummary(id: humanId, name: "Alice", isArchived: false, createdAt: Date(), updatedAt: Date())
    let trainingBot = PlayerSummary(
        id: trainingBotId,
        name: "Alice's Training Partner",
        isArchived: false,
        isBot: true,
        botKindRaw: BotKind.training.rawValue,
        linkedPlayerId: humanId,
        createdAt: Date(),
        updatedAt: Date()
    )
    let profile = BotDifficulty.medium.skillProfile
    let playerRepo = TrainingSkillPlayerRepository(
        players: [human, trainingBot],
        skillByBotId: [trainingBotId: profile]
    )
    let matchRepo = ParticipantCapturingMatchRepository()
    let vm = MatchSetupViewModel(
        playerRepository: playerRepo,
        settingsRepository: FakeSettingsRepository(),
        matchRepository: matchRepo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(humanId)
    vm.togglePlayer(trainingBotId)

    _ = await vm.startMatchRoute()

    let participants = await matchRepo.lastParticipants
    let botParticipant = try #require(participants.first { $0.playerId == trainingBotId })
    #expect(botParticipant.botKindRaw == BotKind.training.rawValue)
    #expect(botParticipant.botDifficultyRaw == nil)
    #expect(botParticipant.botSkillProfilePayload != nil)
    let snapshot = try TrainingBotSkillSnapshot.decode(from: try #require(botParticipant.botSkillProfilePayload))
    #expect(snapshot.profile.x01.scoringVisitMax == profile.x01.scoringVisitMax)
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupAvailableBotFiltersExcludeSelectedPlayers() async {
    let human = makePlayer("Human")
    let preset = PlayerSummary(
        id: UUID(),
        name: "Easy Bot",
        isArchived: false,
        isBot: true,
        botDifficultyRaw: BotDifficulty.easy.rawValue,
        botKindRaw: BotKind.preset.rawValue,
        createdAt: Date(),
        updatedAt: Date()
    )
    let custom = makeCustomBot("Custom")
    let training = PlayerSummary(
        id: UUID(),
        name: "Training",
        isArchived: false,
        isBot: true,
        botKindRaw: BotKind.training.rawValue,
        linkedPlayerId: human.id,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [human, preset, custom, training]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(preset.id)

    #expect(vm.availableBots.map(\.id) == [custom.id])
    #expect(vm.availableCustomBots.map(\.id) == [custom.id])
    #expect(vm.availableTrainingBots.map(\.id) == [training.id])
    #expect(vm.availableHumans.map(\.id) == [human.id])
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupAddTrainingBotAppendsToSelection() async {
    let human = makePlayer("Human")
    let training = PlayerSummary(
        id: UUID(),
        name: "Partner",
        isArchived: false,
        isBot: true,
        botKindRaw: BotKind.training.rawValue,
        linkedPlayerId: human.id,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [human, training]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(human.id)
    vm.addTrainingBot(training.id)

    #expect(vm.selectedPlayerIds.contains(training.id))
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupApplyPendingModeSelectionPrefillsStandardCricket() async {
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )

    vm.applyPendingModeSelection(
        PendingModeSelection(setupCategory: .standard, mode: .cricket, partyGame: nil, matchType: .cricket)
    )

    #expect(vm.setupCategory == .standard)
    #expect(vm.mode == .cricket)
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupApplyPendingModeSelectionPrefillsStandardX01() async {
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )

    vm.applyPendingModeSelection(
        PendingModeSelection(setupCategory: .standard, mode: .x01, partyGame: nil, matchType: .x01)
    )

    #expect(vm.setupCategory == .standard)
    #expect(vm.mode == .x01)
}

@MainActor
@Test(.tags(.unit, .setupFlow, .regression))
func setupAddCustomBotCreatesAndSelectsBot() async {
    let human = makePlayer("Human")
    let repo = CustomBotCreatingPlayerRepository(existing: [human])
    let vm = MatchSetupViewModel(
        playerRepository: repo,
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(human.id)
    await vm.addCustomBot(name: "Ace", metrics: CustomBotMetrics(x01Average: 50, cricketMPR: 2.0))

    #expect(vm.selectedPlayerIds.count == 2)
    #expect(vm.availablePlayers.contains(where: { $0.name == "Ace" && $0.isCustomBot }))
}

@MainActor
private func makeSetupViewModel(players: [PlayerSummary]) -> MatchSetupViewModel {
    MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
}

@MainActor
private func selectAll(_ players: [PlayerSummary], in vm: MatchSetupViewModel) {
    for player in players {
        vm.togglePlayer(player.id)
    }
}

private func makePlayer(_ name: String) -> PlayerSummary {
    PlayerSummary(id: UUID(), name: name, isArchived: false, createdAt: Date(), updatedAt: Date())
}

private func makeCustomBot(_ name: String) -> PlayerSummary {
    let metrics = CustomBotMetrics(x01Average: 45, cricketMPR: 2.0)
    return PlayerSummary(
        id: UUID(),
        name: name,
        isArchived: false,
        isBot: true,
        botDifficultyRaw: metrics.encode(),
        botKindRaw: BotKind.custom.rawValue,
        createdAt: Date(),
        updatedAt: Date()
    )
}

private actor HumanCreatingPlayerRepository: PlayerRepository {
    private var players: [PlayerSummary] = []

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name: String) async throws -> PlayerSummary {
        let created = PlayerSummary(id: UUID(), name: name, isArchived: false, createdAt: Date(), updatedAt: Date())
        players.append(created)
        return created
    }
    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        PlayerSummary(
            id: UUID(),
            name: BotNaming.nextDefaultName(difficulty: difficulty, existingNames: players.map(\.name)),
            isArchived: false,
            isBot: true,
            botDifficultyRaw: difficulty.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    func updatePlayerName(playerId: UUID, name: String) async throws -> PlayerSummary {
        try await updatePlayerProfile(
            playerId: playerId,
            name: name,
            avatarStyle: .dart,
            colorToken: .blue,
            notes: ""
        )
    }
    func updatePlayerProfile(
        playerId: UUID,
        name: String,
        avatarStyle: PlayerAvatarStyle,
        colorToken: PlayerColorToken,
        notes: String
    ) async throws -> PlayerSummary {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else {
            throw AppError(code: .notFound, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.player.notFound")
        }
        let existing = players[index]
        let updated = PlayerSummary(
            id: existing.id,
            name: name,
            isArchived: existing.isArchived,
            avatarStyleRaw: avatarStyle.rawValue,
            preferredColorToken: colorToken.rawValue,
            notes: notes.isEmpty ? nil : notes,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )
        players[index] = updated
        return updated
    }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor FakePlayerRepository: PlayerRepository {
    let players: [PlayerSummary]
    init(players: [PlayerSummary]) { self.players = players }
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { players[0] }
    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        PlayerSummary(
            id: UUID(),
            name: BotNaming.nextDefaultName(difficulty: difficulty, existingNames: players.map(\.name)),
            isArchived: false,
            isBot: true,
            botDifficultyRaw: difficulty.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { players[0] }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { players[0] }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor CustomBotCreatingPlayerRepository: PlayerRepository {
    var players: [PlayerSummary]

    init(existing: [PlayerSummary]) {
        players = existing
    }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { players[0] }
    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        PlayerSummary(
            id: UUID(),
            name: "Bot",
            isArchived: false,
            isBot: true,
            botDifficultyRaw: difficulty.rawValue,
            botKindRaw: BotKind.preset.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func createCustomBot(name: String, metrics: CustomBotMetrics) async throws -> PlayerSummary {
        let created = PlayerSummary(
            id: UUID(),
            name: name,
            isArchived: false,
            isBot: true,
            botDifficultyRaw: metrics.encode(),
            botKindRaw: BotKind.custom.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
        players.append(created)
        return created
    }

    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { players[0] }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { players[0] }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor FakeSettingsRepository: SettingsRepository {
    var settings: SettingsSummary

    init(settings: SettingsSummary? = nil) {
        self.settings = settings ?? SettingsSummary(
            id: UUID(),
            appearanceModeRaw: "system",
            hapticsEnabled: true,
            soundEnabled: true,
            turnTotalCallerEnabled: false,
            defaultMatchTypeRaw: "x01",
            defaultX01StartScore: 501,
            defaultCheckoutModeRaw: "doubleOut",
            defaultCheckInModeRaw: "straightIn",
            defaultLegFormatRaw: "firstTo",
            defaultLegsToWin: 3,
            defaultSetsEnabled: false,
            botStaggerEnabled: true,
            botDartHapticsEnabled: true,
            defaultDartEntryPresentationRaw: "numberPad",
            updatedAt: Date()
        )
    }

    func fetchSettings() async throws -> SettingsSummary {
        settings
    }

    func seedDefaultsIfNeeded() async throws -> SettingsSummary {
        settings
    }

    func replaceSettings(_ next: SettingsSummary) {
        settings = next
    }

    func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary {
        settings
    }

    func resetPreferencesToDefaults() async throws {}

    func resetAllLocalData() async throws {}
}

private actor TrainingSkillPlayerRepository: PlayerRepository {
    let players: [PlayerSummary]
    let skillByBotId: [UUID: BotSkillProfile]

    init(players: [PlayerSummary], skillByBotId: [UUID: BotSkillProfile]) {
        self.players = players
        self.skillByBotId = skillByBotId
    }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { players[0] }
    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        PlayerSummary(
            id: UUID(),
            name: "Bot",
            isArchived: false,
            isBot: true,
            botDifficultyRaw: difficulty.rawValue,
            botKindRaw: BotKind.preset.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { players[0] }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { players[0] }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
    func fetchTrainingBot(linkedTo _: UUID) async throws -> PlayerSummary? { nil }
    func createTrainingBot(for _: UUID) async throws -> PlayerSummary { players[0] }

    func resolveTrainingBotSkill(for botId: UUID, mode _: MatchType) async throws -> BotSkillProfile {
        guard let profile = skillByBotId[botId] else {
            throw AppError(code: .notFound, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "trainingBot.error.notTrainingBot")
        }
        return profile
    }
}

private actor ParticipantCapturingMatchRepository: MatchRepository {
    private(set) var lastParticipants: [MatchParticipantSummary] = []

    func createMatch(type: MatchType, configPayload _: Data, participants: [MatchParticipantSummary]) async throws -> MatchSummary {
        lastParticipants = participants
        return MatchSummary(
            id: UUID(),
            type: type,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor TurnOrderCapturingMatchRepository: MatchRepository {
    private(set) var lastParticipantNames: [String] = []

    func createMatch(type: MatchType, configPayload _: Data, participants: [MatchParticipantSummary]) async throws -> MatchSummary {
        lastParticipantNames = participants.sorted { $0.turnOrder < $1.turnOrder }.map(\.displayNameAtMatchStart)
        return MatchSummary(
            id: UUID(),
            type: type,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor FakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(
            id: UUID(),
            type: type,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(
            id: UUID(),
            matchId: matchId,
            snapshotVersion: snapshotVersion,
            snapshotPayload: snapshotPayload,
            updatedAt: Date()
        )
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor ThrowingActiveLookupMatchRepository: MatchRepository {
    func fetchActiveMatch() async throws -> MatchSummary? {
        throw AppError(code: .storageUnavailable, layer: .data, severity: .error, isRecoverable: true, userMessageKey: "setup.error.start")
    }
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

/// Active match with no snapshot and no in-memory store entry.
private actor NoSnapshotActiveConflictRepository: MatchRepository {
    let active: MatchSummary
    private(set) var abandonedCount = 0
    private(set) var snapshotSaved = false

    init(active: MatchSummary) { self.active = active }

    func fetchActiveMatch() async throws -> MatchSummary? { active }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func updateMatch(_ match: MatchSummary) async throws {
        if match.status == .abandoned { abandonedCount += 1 }
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        snapshotSaved = true
        return MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(id: UUID(), type: type, status: .inProgress, startedAt: Date(), endedAt: nil, winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0, eventCount: 0, createdAt: Date(), updatedAt: Date())
    }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

/// Active match with a persisted snapshot but no in-memory store entry.
private actor SnapshotOnlyActiveConflictRepository: MatchRepository {
    let active: MatchSummary
    let snapshot: MatchSnapshotSummary
    private(set) var abandonedCount = 0
    private(set) var snapshotSaved = false

    init(active: MatchSummary, snapshot: MatchSnapshotSummary) {
        self.active = active
        self.snapshot = snapshot
    }

    func fetchActiveMatch() async throws -> MatchSummary? { active }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        matchId == active.id ? snapshot : nil
    }
    func updateMatch(_ match: MatchSummary) async throws {
        if match.status == .abandoned { abandonedCount += 1 }
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        snapshotSaved = true
        return MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(id: UUID(), type: type, status: .inProgress, startedAt: Date(), endedAt: nil, winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0, eventCount: 0, createdAt: Date(), updatedAt: Date())
    }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

/// Reports an in-progress match so the setup flow must prompt before starting,
/// and records abandon vs delete operations from the "Game in Progress" confirmation.
private actor ActiveConflictMatchRepository: MatchRepository {
    private var hasActive: Bool
    private(set) var deletedCount = 0
    private(set) var abandonedCount = 0

    init(hasActive: Bool) { self.hasActive = hasActive }

    private func activeSummary() -> MatchSummary {
        MatchSummary(
            id: UUID(),
            type: .x01,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(id: UUID(), type: type, status: .inProgress, startedAt: Date(), endedAt: nil, winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0, eventCount: 0, createdAt: Date(), updatedAt: Date())
    }

    func fetchActiveMatch() async throws -> MatchSummary? { hasActive ? activeSummary() : nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_ match: MatchSummary) async throws {
        if match.status == .abandoned {
            abandonedCount += 1
            hasActive = false
        }
    }
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {
        deletedCount += 1
        hasActive = false
    }
}
