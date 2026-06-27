import Foundation
import Testing
@testable import DartBuddy

@Suite("Bot behavior verification", .tags(.unit, .regression))
struct BotBehaviorVerificationTests {
    // MARK: - Setup policy

    @Test func botModePlaySupport_allowsCustomBotsOnPartyModes() {
        for matchType in [MatchType.baseball, .shanghai, .killer, .golf, .prisoner] {
            let support = BotModePlaySupport.support(for: matchType)
            #expect(support == .full)
            #expect(support.allowsTrainingAndCustomBots)
        }
    }

    @Test func botModePlaySupport_rejectsBotsOnRaid() {
        let errors = BotModePlaySupport.none.validationErrors(
            matchType: .raid,
            hasBot: true,
            hasTrainingOrCustomBot: true
        )
        #expect(errors == ["setup.validation.coopHumansOnly"])
    }

    // MARK: - Custom bot template resolution

    @Test func customBotResolver_checkoutTemplateAnchorsToX01Average() {
        let configuration = CustomBotConfiguration(x01Average: 22, cricketMPR: 3.2)
        let profile = BotSkillProfileResolver.profile(
            configuration: configuration,
            context: BotPlayContext(matchType: .x01, uiTemplate: .checkoutScore)
        )
        #expect(profile.x01.scoringBehaviorTier == .veryEasy)
    }

    @Test func customBotResolver_markBoardTemplateAnchorsToCricketMPR() {
        let configuration = CustomBotConfiguration(x01Average: 28, cricketMPR: 3.2)
        let profile = BotSkillProfileResolver.profile(
            configuration: configuration,
            context: BotPlayContext(matchType: .cricket, uiTemplate: .markBoard)
        )
        #expect(profile.x01.scoringBehaviorTier != .veryEasy)
    }

    @Test func customBotResolver_advancedConfigurationIgnoresTemplateWeighting() {
        var configuration = CustomBotConfiguration(x01Average: 28, cricketMPR: 3.2)
        configuration = configuration.resetToPreset(.hard)
        let checkout = BotSkillProfileResolver.profile(
            configuration: configuration,
            context: BotPlayContext(matchType: .x01, uiTemplate: .checkoutScore)
        )
        let markBoard = BotSkillProfileResolver.profile(
            configuration: configuration,
            context: BotPlayContext(matchType: .cricket, uiTemplate: .markBoard)
        )
        #expect(checkout == markBoard)
        #expect(checkout.x01.scoringBehaviorTier == .hard)
    }

    // MARK: - Match start snapshots

    @Test func botParticipantFactory_freezesTemplateAwareCustomProfile() async throws {
        let configuration = CustomBotConfiguration(x01Average: 30, cricketMPR: 3.0)
        let participant = try await BotParticipantFactory.makeParticipant(
            input: BotParticipantBuildInput(
                playerId: UUID(),
                displayName: "Custom",
                turnOrder: 0,
                botDifficulty: nil,
                isTrainingBot: false,
                isCustomBot: true,
                customConfiguration: configuration,
                linkedPlayerId: nil,
                colorTokenRaw: PlayerColorToken.green.rawValue,
                matchType: .cricket,
                uiTemplate: .markBoard
            ),
            resolveTrainingSkill: { _, _ in BotDifficulty.medium.skillProfile }
        )

        let payload = try #require(participant.botSkillProfilePayload)
        let snapshot = try CustomBotSkillSnapshot.decode(from: payload)
        let expected = BotSkillProfileResolver.profile(
            configuration: configuration,
            context: BotPlayContext(matchType: .cricket, uiTemplate: .markBoard)
        )
        #expect(snapshot.profile == expected)
        #expect(participant.botKindRaw == BotKind.custom.rawValue)
    }

    @Test(arguments: [MatchType.killer, .shanghai, .baseball])
    func botParticipantFactory_buildsCustomBotForPartyModes(matchType: MatchType) async throws {
        let uiTemplate: GameplayUITemplate = switch matchType {
        case .killer, .shanghai: .livesElimination
        case .baseball: .inningPoints
        default: .inningPoints
        }
        let participant = try await BotParticipantFactory.makeParticipant(
            input: BotParticipantBuildInput(
                playerId: UUID(),
                displayName: "Ace",
                turnOrder: 0,
                botDifficulty: nil,
                isTrainingBot: false,
                isCustomBot: true,
                customConfiguration: CustomBotConfiguration(x01Average: 50, cricketMPR: 2.0),
                linkedPlayerId: nil,
                colorTokenRaw: PlayerColorToken.blue.rawValue,
                matchType: matchType,
                uiTemplate: uiTemplate
            ),
            resolveTrainingSkill: { _, _ in BotDifficulty.medium.skillProfile }
        )
        #expect(participant.botKindRaw == BotKind.custom.rawValue)
        #expect(participant.botSkillProfilePayload != nil)
    }

    // MARK: - Cricket (including Points Off)

    @Test func cricketBot_pointsOffTurnProducesMarks() throws {
        let players = [UUID(), UUID()]
        let state = try CricketEngine.makeInitialState(
            config: cricketConfig(pointsEnabled: false),
            playerIds: players
        )
        var totalMarks = 0

        for seed in 0 ..< 120 {
            var rng = BotTestSeededRandomNumberGenerator(seed: UInt64(seed))
            let darts = DartBotEngine.generateCricketTurn(
                state: state,
                playerIndex: 0,
                profile: BotDifficulty.medium.skillProfile,
                rng: &rng
            )
            #expect(darts.count == 3)
            totalMarks += darts.reduce(0) { $0 + cricketMarkValue(for: $1) }
        }

        #expect(totalMarks > 0)
    }

    @Test func cricketBot_pointsOffTurnSubmitsToEngine() throws {
        let players = [UUID(), UUID()]
        var state = try CricketEngine.makeInitialState(
            config: cricketConfig(pointsEnabled: false),
            playerIds: players
        )
        var rng = BotTestSeededRandomNumberGenerator(seed: 77)
        let darts = DartBotEngine.generateCricketTurn(
            state: state,
            playerIndex: 0,
            profile: BotDifficulty.easy.skillProfile,
            rng: &rng
        )
        let outcome = try CricketEngine.submitTurn(state: state, darts: darts)
        #expect(outcome.event.totalPointsAdded == 0)
        let marksAdded = outcome.updatedState.players[0].marks.values.reduce(0, +)
        #expect(marksAdded >= state.players[0].marks.values.reduce(0, +))
    }

    // MARK: - 51 By 5's

    @Test func fiftyOneByFivesBot_generatesThreeDarts() throws {
        let players = [UUID(), UUID()]
        let state = try FiftyOneByFivesEngine.makeInitialState(
            config: MatchConfigFiftyOneByFives(),
            playerIds: players
        )
        var rng = BotTestSeededRandomNumberGenerator(seed: 5)
        let darts = DartBotEngine.generateFiftyOneByFivesTurn(
            state: state,
            playerIndex: 0,
            profile: BotDifficulty.medium.skillProfile,
            rng: &rng
        )
        #expect(darts.count == 3)
    }

    @Test func fiftyOneByFivesBot_veryEasyUsesSinglesOnSegment20() throws {
        let players = [UUID(), UUID()]
        let state = try FiftyOneByFivesEngine.makeInitialState(
            config: MatchConfigFiftyOneByFives(),
            playerIds: players
        )
        var rng = BotTestSeededRandomNumberGenerator(seed: 99)
        let darts = DartBotEngine.generateFiftyOneByFivesTurn(
            state: state,
            playerIndex: 0,
            profile: BotDifficulty.veryEasy.skillProfile,
            rng: &rng
        )
        #expect(darts.allSatisfy { $0.multiplier == .single || $0.isMiss })
        #expect(darts.allSatisfy { dart in
            dart.isMiss || dart.segment == .oneToTwenty(20)
        })
    }

    @Test func fiftyOneByFivesBot_proHitsSegment20MoreThanVeryEasy() throws {
        let players = [UUID(), UUID()]
        let state = try FiftyOneByFivesEngine.makeInitialState(
            config: MatchConfigFiftyOneByFives(),
            playerIds: players
        )
        let (veryEasy, pro) = compareBotMetricTotals(lower: .veryEasy, upper: .pro) { profile, rng in
            DartBotEngine.generateFiftyOneByFivesTurn(
                state: state,
                playerIndex: 0,
                profile: profile,
                rng: &rng
            ).filter { !$0.isMiss && $0.segment == .oneToTwenty(20) }.count
        }
        #expect(pro > veryEasy)
    }

    // MARK: - Tic-Tac-Toe

    @Test func ticTacToeBot_attemptsWinningCellFirst() throws {
        var grid: [TicTacToeSide?] = Array(repeating: nil, count: 9)
        grid[0] = .o
        grid[1] = .o
        let players = [
            TicTacToePlayerState(playerId: UUID(), side: .x),
            TicTacToePlayerState(playerId: UUID(), side: .o),
        ]
        let state = TicTacToeState(
            config: MatchConfigTicTacToe(),
            players: players,
            grid: grid,
            currentPlayerIndex: 1
        )
        let winningCell = state.config.cells[2]

        var rng = BotTestSeededRandomNumberGenerator(seed: 1)
        let darts = DartBotEngine.generateTicTacToeTurn(
            state: state,
            profile: BotDifficulty.pro.skillProfile,
            rng: &rng
        )
        #expect(darts.contains(where: { winningCell.matches($0) }))
    }

    @Test func ticTacToeBot_proHitsConfiguredCellsMoreThanVeryEasy() throws {
        let state = try TicTacToeEngine.makeInitialState(
            config: MatchConfigTicTacToe(),
            playerIds: [UUID(), UUID()]
        )
        let (veryEasy, pro) = compareBotMetricTotals(lower: .veryEasy, upper: .pro) { profile, rng in
            DartBotEngine.generateTicTacToeTurn(
                state: state,
                profile: profile,
                rng: &rng
            ).filter { dart in
                state.config.cells.contains { $0.matches(dart) }
            }.count
        }
        #expect(pro > veryEasy)
    }

    // MARK: - Loop

    @Test func loopBot_proMatchesLeaderMoreThanVeryEasy() throws {
        let players = [UUID(), UUID()]
        var state = try LoopEngine.makeInitialState(
            config: MatchConfigLoop(),
            playerIds: players
        )
        let opening = LoopSubmittedDart(
            dart: DartInput(multiplier: .double, segment: .oneToTwenty(16)),
            wireTarget: LoopWireTargetArea(segment: 16, kind: .standard, ring: .double)
        )
        state = try LoopEngine.submitVisit(state: state, darts: [opening]).updatedState

        let (veryEasy, pro) = compareBotMetricTotals(lower: .veryEasy, upper: .pro) { profile, rng in
            DartBotEngine.generateLoopVisit(state: state, profile: profile, rng: &rng)
                .filter { $0.wireTarget == state.target }.count
        }
        #expect(pro > veryEasy)
    }

    // MARK: - Shanghai / shared resolution

    @Test func shanghaiBot_generatesThreeDartsPerInning() {
        var rng = BotTestSeededRandomNumberGenerator(seed: 3)
        let darts = DartBotEngine.generateShanghaiTurn(
            targetSegment: 6,
            profile: BotDifficulty.medium.skillProfile,
            rng: &rng
        )
        #expect(darts.count == 3)
    }

    @Test func sharedResolution_higherTierHitsSinglesMoreOften() {
        let segment = 18
        let (veryEasy, pro) = compareBotMetricTotals(lower: .veryEasy, upper: .pro, samples: 200) { profile, rng in
            let dart = DartBotEngine.resolveSingleOnSegment(segment: segment, profile: profile, rng: &rng)
            if dart.isMiss { return 0 }
            if case let .oneToTwenty(value) = dart.segment, value == segment {
                return 1
            }
            return 0
        }
        #expect(pro > veryEasy)
    }
}
