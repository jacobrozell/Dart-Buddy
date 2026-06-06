import AppIntents
import Foundation

struct DartBuddyShortcutsProvider: AppShortcutsProvider {
    /// Registered phrases and gating — see `specs/AppIntentsSpec.md` §4.1 and §6.
    static var appShortcuts: [AppShortcut] {
        guard LocalFeatureFlagsProvider().isEnabled(.enableAppIntents) else {
            return []
        }

        return [
            AppShortcut(
                intent: OpenPlayIntent(),
                phrases: [
                    "Open \(.applicationName)",
                    "Open Play in \(.applicationName)",
                ],
                shortTitle: LocalizedStringResource("intent.openPlay.title"),
                systemImageName: "target"
            ),
            AppShortcut(
                intent: ResumeActiveMatchIntent(),
                phrases: [
                    "Resume my dart game in \(.applicationName)",
                    "Resume my game in \(.applicationName)",
                ],
                shortTitle: LocalizedStringResource("intent.resumeActiveMatch.title"),
                systemImageName: "play.fill"
            ),
        ]
    }
}
