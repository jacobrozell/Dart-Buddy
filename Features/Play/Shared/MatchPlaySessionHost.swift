import Foundation

@MainActor
protocol MatchPlaySessionHost: AnyObject, ObservableObject {
    var matchId: UUID { get }
    var session: MatchLifecycleSession? { get set }
    var isBotTurnBlocking: Bool { get }
    var hostMatchRepository: any MatchRepository { get }
    var hostMatchStore: ActiveMatchStore { get }
    var hostMatchLogger: any AppLogger { get }
    var hostMatchType: MatchType { get }

    func loadSessionIfNeeded() async
    func recoverBotPlaybackIfNeeded()
    func onDisappear()
}

enum MatchForfeitParticipantSupport {
    static func humanParticipantIds(in session: MatchLifecycleSession) -> [UUID] {
        session.runtime.participants
            .filter { !$0.isBot }
            .map { $0.playerId ?? $0.id }
    }

    static func displayName(for playerId: UUID, in session: MatchLifecycleSession) -> String {
        session.runtime.participants
            .first { ($0.playerId ?? $0.id) == playerId }?
            .displayNameAtMatchStart ?? playerId.uuidString.prefix(6).description
    }

    static func sanitizedPickerIdentifier(for name: String) -> String {
        let sanitized = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        return sanitized.isEmpty ? "player" : sanitized
    }
}
