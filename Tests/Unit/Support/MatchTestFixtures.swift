import Foundation
@testable import DartBuddy

func makePlayer(_ name: String) -> PlayerSummary {
    PlayerSummary(id: UUID(), name: name, isArchived: false, createdAt: Date(), updatedAt: Date())
}

func makeCustomBot(_ name: String) -> PlayerSummary {
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

@MainActor
func makeSetupViewModel(players: [PlayerSummary]) -> MatchSetupViewModel {
    MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
}

@MainActor
func selectAll(_ players: [PlayerSummary], in vm: MatchSetupViewModel) {
    for player in players {
        vm.togglePlayer(player.id)
    }
}

struct TestNoopLogSink: LogSink {
    func write(_: LogEntry) {}
}
