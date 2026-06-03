import Testing
@testable import DartBuddy

@Suite("Setup validation messages", .tags(.unit, .accessibility, .setupFlow, .regression))
struct SetupValidationMessagesTests {
    @Test
    func displayKeyMapsKnownValidationKeysToShortCopy() {
        #expect(
            SetupValidationMessages.displayKey(for: "setup.validation.minimumPlayers")
                == "setup.validation.minimumPlayers.short"
        )
        #expect(
            SetupValidationMessages.displayKey(for: "setup.validation.requiresHuman")
                == "setup.validation.requiresHuman.short"
        )
        #expect(
            SetupValidationMessages.displayKey(for: "setup.validation.invalidStartScore")
                == "setup.validation.invalidStartScore.short"
        )
        #expect(
            SetupValidationMessages.displayKey(for: "setup.validation.invalidLegs")
                == "setup.validation.invalidLegs.short"
        )
        #expect(
            SetupValidationMessages.displayKey(for: "setup.validation.invalidSets")
                == "setup.validation.invalidSets.short"
        )
    }

    @Test
    func displayKeyPassesThroughUnknownKeys() {
        #expect(SetupValidationMessages.displayKey(for: "setup.error.load") == "setup.error.load")
    }

    @Test
    func shortMinimumPlayersCopyIsShorterThanFullMessage() {
        let full = L10n.string("setup.validation.minimumPlayers")
        let short = L10n.string(SetupValidationMessages.displayKey(for: "setup.validation.minimumPlayers"))
        #expect(short.count < full.count)
        #expect(short == L10n.string("setup.validation.minimumPlayers.short"))
    }

    @Test
    func startButtonHintUsesFirstValidationErrorWhenStartIsBlocked() {
        let hint = SetupValidationMessages.startButtonAccessibilityHint(
            canStart: false,
            validationErrors: ["setup.validation.minimumPlayers"]
        )
        #expect(hint == L10n.string("setup.validation.minimumPlayers"))
    }

    @Test
    func startButtonHintFallsBackWhenStartIsBlockedWithoutValidationErrors() {
        let hint = SetupValidationMessages.startButtonAccessibilityHint(canStart: false, validationErrors: [])
        #expect(hint == L10n.string("play.setup.start.disabledHint"))
    }

    @Test
    func startButtonHintIsNilWhenStartIsAllowed() {
        #expect(
            SetupValidationMessages.startButtonAccessibilityHint(
                canStart: true,
                validationErrors: ["setup.validation.minimumPlayers"]
            ) == nil
        )
    }
}
