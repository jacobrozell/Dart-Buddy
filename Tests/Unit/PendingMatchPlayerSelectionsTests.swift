import Foundation
import Testing
@testable import DartBuddy

@Suite("Pending match player selections", .tags(.unit, .setupFlow, .regression))
@MainActor
struct PendingMatchPlayerSelectionsTests {
    @Test
    func enqueueAndDequeueOnlyReturnsIdsPresentInRoster() {
        let store = PendingMatchPlayerSelections()
        let alice = UUID()
        let bob = UUID()
        let carol = UUID()

        store.enqueueForNextMatchSetup(alice)
        store.enqueueForNextMatchSetup(bob)
        store.enqueueForNextMatchSetup(carol)

        let firstPass = store.dequeueIdsPresent(in: [alice, bob])
        #expect(firstPass == [alice, bob])

        let secondPass = store.dequeueIdsPresent(in: [alice, bob, carol])
        #expect(secondPass == [carol])

        let thirdPass = store.dequeueIdsPresent(in: [alice])
        #expect(thirdPass.isEmpty)
    }

    @Test
    func practiceEnqueueSetsPreferredMatchTypeAndPlayers() {
        let store = PendingMatchPlayerSelections()
        let human = UUID()
        let bot = UUID()

        store.enqueuePractice(humanId: human, trainingBotId: bot, mode: .cricket)

        #expect(store.consumePreferredMatchType() == .cricket)
        #expect(store.dequeueIdsPresent(in: [human, bot]) == [human, bot])
    }

    @Test
    func modeSelectionIsConsumedOnce() {
        let store = PendingMatchPlayerSelections()
        let selection = PendingModeSelection(
            setupCategory: .party,
            mode: nil,
            partyGame: .killer,
            matchType: .killer
        )

        store.enqueueModeSelection(selection)
        #expect(store.consumeModeSelection() == selection)
        #expect(store.consumeModeSelection() == nil)
    }

    @Test
    func clearAllResetsPendingState() {
        let store = PendingMatchPlayerSelections()
        let player = UUID()

        store.enqueueForNextMatchSetup(player)
        store.enqueuePractice(humanId: player, trainingBotId: UUID(), mode: .x01)
        store.enqueueModeSelection(
            PendingModeSelection(
                setupCategory: .standard,
                mode: .x01,
                partyGame: nil,
                matchType: .x01
            )
        )

        store.clearAll()

        #expect(store.consumePreferredMatchType() == nil)
        #expect(store.consumeModeSelection() == nil)
        #expect(store.dequeueIdsPresent(in: [player]).isEmpty)
    }
}
