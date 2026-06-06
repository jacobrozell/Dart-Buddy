import Foundation
import Testing
@testable import DartBuddy

@Suite("Pending app destination", .tags(.unit, .navigation, .regression))
@MainActor
struct PendingAppDestinationTests {
    @Test
    func consumeReturnsDestinationWhenReady() {
        let pending = PendingAppDestination()
        pending.enqueue(.play(.home))

        let consumed = pending.consumeIfReady(bootstrapReady: true, onboardingComplete: true)

        #expect(consumed == .play(.home))
        #expect(pending.hasPending == false)
    }

    @Test
    func consumeDefersWhenOnboardingIncomplete() {
        let pending = PendingAppDestination()
        pending.enqueue(.tab(.play))

        let consumed = pending.consumeIfReady(bootstrapReady: true, onboardingComplete: false)

        #expect(consumed == nil)
        #expect(pending.hasPending == true)
    }

    @Test
    func consumeDefersWhenBootstrapNotReady() {
        let pending = PendingAppDestination()
        pending.enqueue(.play(.resumeActive))

        let consumed = pending.consumeIfReady(bootstrapReady: false, onboardingComplete: true)

        #expect(consumed == nil)
        #expect(pending.hasPending == true)
    }

    @Test
    func secondEnqueueReplacesPendingDestination() {
        let pending = PendingAppDestination()
        pending.enqueue(.tab(.settings))
        pending.enqueue(.play(.home))

        let consumed = pending.consumeIfReady(bootstrapReady: true, onboardingComplete: true)

        #expect(consumed == .play(.home))
    }

    @Test
    func enqueueIncrementsChangeCount() {
        let pending = PendingAppDestination()
        #expect(pending.changeCount == 0)

        pending.enqueue(.play(.home))
        #expect(pending.changeCount == 1)

        pending.enqueue(.tab(.modes))
        #expect(pending.changeCount == 2)
    }

    @Test
    func consumeClearsPendingWithoutIncrementingChangeCount() {
        let pending = PendingAppDestination()
        pending.enqueue(.play(.home))
        let countAfterEnqueue = pending.changeCount

        _ = pending.consumeIfReady(bootstrapReady: true, onboardingComplete: true)

        #expect(pending.hasPending == false)
        #expect(pending.changeCount == countAfterEnqueue)
    }
}
