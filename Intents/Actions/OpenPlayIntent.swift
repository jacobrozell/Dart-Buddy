import AppIntents
import Foundation

struct OpenPlayIntent: AppIntent {
    /// Stable analytics identifier — see `specs/AppIntentsSpec.md` §4.1.
    static let intentName = "open_play"

    static var title: LocalizedStringResource = "intent.openPlay.title"
    static var description = IntentDescription(LocalizedStringResource("intent.openPlay.description"))
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard await IntentRoutingBridge.isEnabled else {
            throw IntentRoutingError.disabled
        }
        _ = await IntentRoutingBridge.route(.play(.home), intentName: Self.intentName)
        return .result()
    }
}
