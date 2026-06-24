import SwiftUI

struct SetupHomeStartFooter: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var setupViewModel: MatchSetupViewModel
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            PrimaryActionButton(
                title: setupViewModel.isSubmitting ? L10n.setupStartingButton : L10n.setupStartButton,
                accent: .green,
                isEnabled: setupViewModel.canStart && !setupViewModel.isSubmitting,
                action: onStart
            )
            .accessibilityLabel(L10n.string(setupViewModel.isSubmitting ? "play.setup.startingButton" : "play.setup.startButton"))
            .modifier(OptionalAccessibilityHint(hint: setupStartAccessibilityHint))
            .accessibilityIdentifier("startMatchButton")

            if !GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize) {
                ForEach(setupViewModel.displayValidationErrors, id: \.self) { key in
                    ErrorBanner(messageKey: key)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var setupStartAccessibilityHint: String? {
        guard !setupViewModel.canStart else { return nil }
        if setupViewModel.isRosterEmpty {
            return L10n.string("play.setup.playersEmptyHint")
        }
        if setupViewModel.setupCategory == .party,
           setupViewModel.validationErrors.contains("setup.validation.partyComingSoon") {
            return L10n.string("setup.validation.partyComingSoon")
        }
        return SetupValidationMessages.startButtonAccessibilityHint(
            canStart: setupViewModel.canStart,
            validationErrors: setupViewModel.validationErrors
        )
    }
}
