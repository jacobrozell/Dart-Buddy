import Foundation
import Testing
@testable import DartBuddy

@Suite struct RaidEngineTests {
    private let hero = UUID()

    @Test func makeInitialStateAllowsSoloHero() throws {
        let state = try RaidEngine.makeInitialState(
            config: MatchConfigRaid(bossTier: .standard, heroHearts: 3),
            playerIds: [hero]
        )
        #expect(state.heroes.count == 1)
        #expect(state.bossHP == 60)
        #expect(state.phase == .shield)
    }

    @Test func shieldCloseDealsEightDamage() throws {
        var state = try RaidEngine.makeInitialState(
            config: MatchConfigRaid(bossTier: .challenger, heroHearts: 3),
            playerIds: [hero]
        )
        let outcome = try RaidEngine.submitVisit(
            state: state,
            darts: [
                DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20))
            ]
        )
        state = outcome.updatedState
        #expect(outcome.event.bossHPBefore - outcome.event.bossHPAfter == 8)
        #expect(state.closedShieldSegments.contains(20))
    }

    @Test func exposePhaseDoubleDealsTwoDamage() throws {
        var state = try RaidEngine.makeInitialState(
            config: MatchConfigRaid(bossTier: .challenger, heroHearts: 3),
            playerIds: [hero]
        )
        state.bossHP = 40
        state.phase = .expose
        let outcome = try RaidEngine.submitVisit(
            state: state,
            darts: [
                DartInput(multiplier: .double, segment: .oneToTwenty(16)),
                DartInput(multiplier: .single, segment: .oneToTwenty(16)),
                DartInput(multiplier: .single, segment: .oneToTwenty(16))
            ]
        )
        #expect(outcome.event.bossHPBefore - outcome.event.bossHPAfter == 2)
    }

    @Test func bossZeroHPTriggersTeamVictory() throws {
        var state = try RaidEngine.makeInitialState(
            config: MatchConfigRaid(bossTier: .challenger, heroHearts: 3, enrageEnabled: false),
            playerIds: [hero]
        )
        state.bossHP = 2
        state.phase = .expose
        let outcome = try RaidEngine.submitVisit(
            state: state,
            darts: [
                DartInput(multiplier: .double, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20))
            ]
        )
        #expect(outcome.updatedState.isComplete)
        #expect(outcome.updatedState.teamVictory)
        #expect(outcome.updatedState.winnerPlayerId == nil)
    }

    @Test func tripleInExposePhaseDealsThreeDamage() throws {
        var state = try RaidEngine.makeInitialState(
            config: MatchConfigRaid(bossTier: .challenger, heroHearts: 3),
            playerIds: [hero]
        )
        state.bossHP = 40
        state.phase = .expose
        let outcome = try RaidEngine.submitVisit(
            state: state,
            darts: [
                DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20))
            ]
        )
        #expect(outcome.event.bossHPBefore - outcome.event.bossHPAfter == 3)
    }

    @Test func bossHPDropTransitionsFromShieldToExpose() throws {
        var state = try RaidEngine.makeInitialState(
            config: MatchConfigRaid(bossTier: .challenger, heroHearts: 3, enrageEnabled: false),
            playerIds: [hero]
        )
        state.bossHP = 45
        let outcome = try RaidEngine.submitVisit(
            state: state,
            darts: [
                DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20))
            ]
        )
        #expect(outcome.updatedState.phase == .expose)
        #expect(outcome.updatedState.bossHP == 37)
        #expect(outcome.updatedState.closedShieldSegments.contains(20))
    }

    @Test func soloEnrageStrikesWhenVisitBelowThreshold() throws {
        var state = try RaidEngine.makeInitialState(
            config: MatchConfigRaid(bossTier: .challenger, heroHearts: 3, enrageEnabled: true),
            playerIds: [hero]
        )
        state.bossHP = 15
        state.phase = .expose
        state.enrageActive = true
        let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
        let outcome = try RaidEngine.submitVisit(
            state: state,
            darts: [miss, miss, miss]
        )
        #expect(outcome.event.enrageVictims.contains(hero))
        #expect(outcome.updatedState.heroes[0].hearts == 2)
    }

    @Test func allHeroesDownTriggersTeamDefeat() throws {
        var state = try RaidEngine.makeInitialState(
            config: MatchConfigRaid(bossTier: .challenger, heroHearts: 1, enrageEnabled: true),
            playerIds: [hero]
        )
        state.bossHP = 15
        state.phase = .expose
        state.enrageActive = true
        let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
        let outcome = try RaidEngine.submitVisit(
            state: state,
            darts: [miss, miss, miss]
        )
        #expect(outcome.updatedState.isComplete)
        #expect(!outcome.updatedState.teamVictory)
        #expect(outcome.updatedState.winnerPlayerId != nil)
    }
}
