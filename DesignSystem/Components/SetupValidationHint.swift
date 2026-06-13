import SwiftUI

/// Compact setup validation message for accessibility Dynamic Type sizes.
struct SetupValidationHint: View {
    let messageKey: String

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textOnAccent)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(SetupValidationMessages.displayKey(for: messageKey)))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textOnAccent)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s2)
        .background(Brand.redAccent, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(messageKey)))
        .accessibilityIdentifier("setupValidationHint")
        .motionBannerEntrance()
    }
}

enum SetupValidationMessages {
    /// Shorter copy at AX sizes; full `messageKey` text is used for VoiceOver.
    static func displayKey(for messageKey: String) -> String {
        switch messageKey {
        case "setup.validation.minimumPlayers": return "setup.validation.minimumPlayers.short"
        case "setup.validation.requiresHuman": return "setup.validation.requiresHuman.short"
        case "setup.validation.invalidStartScore": return "setup.validation.invalidStartScore.short"
        case "setup.validation.invalidLegs": return "setup.validation.invalidLegs.short"
        case "setup.validation.invalidSets": return "setup.validation.invalidSets.short"
        case "setup.validation.partyComingSoon": return "setup.validation.partyComingSoon.short"
        case "setup.validation.coopComingSoon": return "setup.validation.coopComingSoon.short"
        case "setup.validation.partyMinimumPlayers": return "setup.validation.partyMinimumPlayers.short"
        case "setup.validation.partyKillerMinimumPlayers": return "setup.validation.partyKillerMinimumPlayers.short"
        case "setup.validation.killerBotsPresetOnly": return "setup.validation.killerBotsPresetOnly.short"
        case "setup.validation.baseballBotsPresetOnly": return "setup.validation.baseballBotsPresetOnly.short"
        case "setup.validation.shanghaiBotsPresetOnly": return "setup.validation.shanghaiBotsPresetOnly.short"
        default: return messageKey
        }
    }

    /// VoiceOver hint for disabled START; prefers the first validation message when present.
    static func startButtonAccessibilityHint(canStart: Bool, validationErrors: [String]) -> String? {
        guard !canStart else { return nil }
        if let first = validationErrors.first {
            return L10n.string(first)
        }
        return L10n.string("play.setup.start.disabledHint")
    }
}
