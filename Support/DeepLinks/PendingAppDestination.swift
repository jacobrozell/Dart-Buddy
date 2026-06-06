import Combine
import Foundation

@MainActor
final class PendingAppDestination: ObservableObject {
    @Published private(set) var changeCount = 0
    private var pending: AppDestination?

    func enqueue(_ destination: AppDestination) {
        pending = destination
        changeCount += 1
    }

    func consumeIfReady(bootstrapReady: Bool, onboardingComplete: Bool) -> AppDestination? {
        guard bootstrapReady, onboardingComplete, let destination = pending else { return nil }
        pending = nil
        return destination
    }

    var hasPending: Bool { pending != nil }
}
