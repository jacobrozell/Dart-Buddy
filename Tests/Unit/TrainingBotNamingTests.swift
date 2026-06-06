import Testing
@testable import DartBuddy

@Suite("Training bot naming", .tags(.unit, .player, .regression))
struct TrainingBotNamingTests {
    @Test
    func defaultNameEmbedsLinkedPlayer() {
        let name = TrainingBotNaming.defaultName(linkedPlayerName: "Jacob")
        #expect(name == L10n.format("trainingBot.nameFormat", "Jacob"))
        #expect(name.contains("Jacob"))
    }
}
