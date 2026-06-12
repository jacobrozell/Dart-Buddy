import AppIntents
import Foundation

struct ResumeActiveMatchIntent: AppIntent {
    /// Stable analytics identifier — see `specs/AppIntentsSpec.md` §4.1.
    static let intentName = "resume_active_match"

    static var title: LocalizedStringResource = "intent.resumeActiveMatch.title"
    static var description = IntentDescription(LocalizedStringResource("intent.resumeActiveMatch.description"))
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard await IntentRoutingBridge.isEnabled else {
            throw IntentRoutingError.disabled
        }

        if await IntentRoutingBridge.isRoutingReady {
            if await IntentRoutingBridge.fetchResumableActiveMatch() != nil {
                _ = await IntentRoutingBridge.route(.play(.resumeActive), intentName: Self.intentName)
                return .result(dialog: IntentDialog(LocalizedStringResource("intent.resumeActiveMatch.resuming")))
            }
            _ = await IntentRoutingBridge.route(.play(.home), intentName: Self.intentName, succeeded: false)
            return .result(dialog: IntentDialog(LocalizedStringResource("play.home.noActiveMatch")))
        }

        _ = await IntentRoutingBridge.route(.play(.resumeActive), intentName: Self.intentName)
        return .result(dialog: IntentDialog(LocalizedStringResource("intent.resumeActiveMatch.resuming")))
    }
}
