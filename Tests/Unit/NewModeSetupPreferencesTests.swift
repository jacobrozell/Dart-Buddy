import Foundation
import Testing
@testable import DartBuddy

@Suite("New mode setup preferences", .tags(.unit, .setupFlow, .regression))
struct NewModeSetupPreferencesTests {
    @Test
    func americanCricketPreferencesDefaultToPointsOn() {
        defer { AmericanCricketSetupPreferences.clearStored() }

        AmericanCricketSetupPreferences.clearStored()
        #expect(AmericanCricketSetupPreferences.load() == true)

        AmericanCricketSetupPreferences.save(pointsEnabled: false)
        #expect(AmericanCricketSetupPreferences.load() == false)
    }

    @Test
    func aroundTheClockPreferencesRoundTrip() {
        defer { AroundTheClockSetupPreferences.clearStored() }

        AroundTheClockSetupPreferences.save(
            includeBullFinish: true,
            resetPolicy: .resetEntireSequence
        )
        let loaded = AroundTheClockSetupPreferences.load()
        #expect(loaded.includeBullFinish == true)
        #expect(loaded.resetPolicy == .resetEntireSequence)
    }

    @Test
    func aroundTheClock180PreferencesClampParScore() {
        defer { AroundTheClock180SetupPreferences.clearStored() }

        AroundTheClock180SetupPreferences.save(parScore: 999, parScoreEnabled: true)
        let loaded = AroundTheClock180SetupPreferences.load()
        #expect(loaded.parScore == 180)
        #expect(loaded.parScoreEnabled == true)
    }

    @Test
    func chaseTheDragonPreferencesRoundTrip() {
        defer { ChaseTheDragonSetupPreferences.clearStored() }

        ChaseTheDragonSetupPreferences.save(laps: .three)
        #expect(ChaseTheDragonSetupPreferences.load() == .three)
    }

    @Test
    func englishCricketPreferencesClampWickets() {
        defer { EnglishCricketSetupPreferences.clearStored() }

        EnglishCricketSetupPreferences.save(wicketsPerInnings: 0, endWhenTargetPassed: false)
        let loaded = EnglishCricketSetupPreferences.load()
        #expect(loaded.wicketsPerInnings == 1)
        #expect(loaded.endWhenTargetPassed == false)
    }

    @Test
    func fiftyOneByFivesPreferencesRoundTrip() {
        defer { FiftyOneByFivesSetupPreferences.clearStored() }

        FiftyOneByFivesSetupPreferences.save(targetPoints: 75, mustFinishExact: true)
        let loaded = FiftyOneByFivesSetupPreferences.load()
        #expect(loaded.targetPoints == 75)
        #expect(loaded.mustFinishExact == true)
    }

    @Test
    func footballPreferencesClampGoals() {
        defer { FootballSetupPreferences.clearStored() }

        FootballSetupPreferences.save(goalsToWin: 99, kickoffMode: .twoOuterBulls)
        let loaded = FootballSetupPreferences.load()
        #expect(loaded.goalsToWin == 50)
        #expect(loaded.kickoffMode == .twoOuterBulls)
    }

    @Test
    func golfPreferencesRoundTrip() {
        defer { GolfSetupPreferences.clearStored() }

        GolfSetupPreferences.save(courseLength: .eighteen)
        #expect(GolfSetupPreferences.load() == .eighteen)
    }

    @Test
    func grandNationalPreferencesClampLaps() {
        defer { GrandNationalSetupPreferences.clearStored() }

        GrandNationalSetupPreferences.save(ruleset: .expert, laps: 25)
        let loaded = GrandNationalSetupPreferences.load()
        #expect(loaded.ruleset == .expert)
        #expect(loaded.laps == 10)
    }

    @Test
    func hareAndHoundsPreferencesRoundTrip() {
        defer { HareAndHoundsSetupPreferences.clearStored() }

        HareAndHoundsSetupPreferences.save(houndStart: .segment12)
        #expect(HareAndHoundsSetupPreferences.load() == .segment12)
    }

    @Test
    func knockoutPreferencesClampStrikes() {
        defer { KnockoutSetupPreferences.clearStored() }

        KnockoutSetupPreferences.save(strikesToEliminate: 9)
        #expect(KnockoutSetupPreferences.load() == 5)

        KnockoutSetupPreferences.save(strikesToEliminate: 2)
        #expect(KnockoutSetupPreferences.load() == 2)
    }

    @Test
    func nineLivesPreferencesRoundTrip() {
        defer { NineLivesSetupPreferences.clearStored() }

        NineLivesSetupPreferences.save(startingLives: .three)
        #expect(NineLivesSetupPreferences.load() == .three)
    }

    @Test
    func suddenDeathPreferencesClampVisitsPerRound() {
        defer { SuddenDeathSetupPreferences.clearStored() }

        SuddenDeathSetupPreferences.save(eliminateAllTied: false, visitsPerRound: 5)
        let loaded = SuddenDeathSetupPreferences.load()
        #expect(loaded.eliminateAllTied == false)
        #expect(loaded.visitsPerRound == 2)
    }
}
