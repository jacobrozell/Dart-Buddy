import Foundation
import Testing
@testable import DartBuddy

@Suite("Match forfeit participant support", .tags(.unit, .match, .regression))
struct MatchForfeitParticipantSupportTests {
    @Test
    func humanParticipantIdsExcludeBots() throws {
        let human = UUID()
        let bot = UUID()
        let session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: human, displayNameAtMatchStart: "Alice", turnOrder: 0),
                MatchParticipant(
                    playerId: bot,
                    displayNameAtMatchStart: "Bot",
                    turnOrder: 1,
                    botDifficultyRaw: BotDifficulty.medium.rawValue,
                    botKindRaw: BotKind.preset.rawValue
                )
            ]
        )

        let ids = MatchForfeitParticipantSupport.humanParticipantIds(in: session)
        #expect(ids == [human])
    }

    @Test
    func displayNameFallsBackToParticipantLabel() throws {
        let player = UUID()
        let session = try MatchLifecycleService.createMatch(
            type: .cricket,
            config: .cricket(MatchConfigCricket()),
            participants: [
                MatchParticipant(playerId: player, displayNameAtMatchStart: "Carol", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Bob", turnOrder: 1)
            ]
        )

        #expect(MatchForfeitParticipantSupport.displayName(for: player, in: session) == "Carol")
    }

    @Test
    func sanitizedPickerIdentifierNormalizesSpacesAndPunctuation() {
        #expect(MatchForfeitParticipantSupport.sanitizedPickerIdentifier(for: "Bob O'Brien") == "bob_obrien")
        #expect(MatchForfeitParticipantSupport.sanitizedPickerIdentifier(for: "!!!") == "player")
        #expect(MatchForfeitParticipantSupport.sanitizedPickerIdentifier(for: "P1") == "p1")
    }
}
