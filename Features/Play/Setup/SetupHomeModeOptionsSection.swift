import SwiftUI

struct SetupHomeModeOptionsSection: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel

    private var activeMatchType: MatchType? {
        SetupHomeModeContext.activeMatchTypeForSetupOptions(for: setupViewModel)
    }

    var body: some View {
        switch activeMatchType {
        case .x01:
            SetupX01OptionChips(setupViewModel: setupViewModel)
        case .cricket:
            SetupCricketOptionChips(setupViewModel: setupViewModel)
        case .americanCricket:
            SetupAmericanCricketOptionChips(setupViewModel: setupViewModel)
        case .baseball:
            SetupBaseballOptionChips(setupViewModel: setupViewModel)
        case .killer:
            SetupKillerOptionChips(setupViewModel: setupViewModel)
        case .shanghai:
            SetupShanghaiOptionChips(setupViewModel: setupViewModel)
        case .englishCricket:
            SetupEnglishCricketOptionChips(setupViewModel: setupViewModel)
        case .knockout:
            SetupKnockoutOptionChips(setupViewModel: setupViewModel)
        case .suddenDeath:
            SetupSuddenDeathOptionChips(setupViewModel: setupViewModel)
        case .fiftyOneByFives:
            SetupFiftyOneByFivesOptionChips(setupViewModel: setupViewModel)
        case .golf:
            SetupGolfOptionChips(setupViewModel: setupViewModel)
        case .football:
            SetupFootballOptionChips(setupViewModel: setupViewModel)
        case .fleet:
            SetupFleetOptionChips(setupViewModel: setupViewModel)
        case .raid:
            SetupRaidOptionChips(setupViewModel: setupViewModel)
        case .grandNational:
            SetupGrandNationalOptionChips(setupViewModel: setupViewModel)
        case .hareAndHounds:
            SetupHareAndHoundsOptionChips(setupViewModel: setupViewModel)
        case .aroundTheClock:
            SetupAroundTheClockOptionChips(setupViewModel: setupViewModel)
        case .aroundTheClock180:
            SetupAroundTheClock180OptionChips(setupViewModel: setupViewModel)
        case .chaseTheDragon:
            SetupChaseTheDragonOptionChips(setupViewModel: setupViewModel)
        case .nineLives:
            SetupNineLivesOptionChips(setupViewModel: setupViewModel)
        case .mickeyMouse, .mulligan,
             .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt, .none:
            EmptyView()
        }
    }
}
