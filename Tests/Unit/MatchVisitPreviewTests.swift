import Testing
@testable import DartBuddy

@Test(.tags(.unit, .match, .regression))
func matchVisitPreviewIncludesHumanPadWhenActive() {
    #expect(
        MatchVisitPreview.includesActiveVisit(
            isActive: true,
            canHumanInput: true,
            isBotPlaying: false,
            isCurrentPlayerBot: false
        )
    )
}

@Test(.tags(.unit, .match, .regression))
func matchVisitPreviewIncludesBotVisitWhileBotIsUp() {
    #expect(
        MatchVisitPreview.includesActiveVisit(
            isActive: true,
            canHumanInput: false,
            isBotPlaying: false,
            isCurrentPlayerBot: true
        )
    )
}

@Test(.tags(.unit, .match, .regression))
func matchVisitPreviewSkipsInactivePlayers() {
    #expect(
        !MatchVisitPreview.includesActiveVisit(
            isActive: false,
            canHumanInput: true,
            isBotPlaying: true,
            isCurrentPlayerBot: true
        )
    )
}
