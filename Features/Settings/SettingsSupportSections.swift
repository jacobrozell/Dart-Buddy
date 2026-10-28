import SwiftUI

struct SettingsDataSection: View {
    let usesBrand: Bool
    let onRequestReset: () -> Void

    var body: some View {
        Section(L10n.dataSection) {
            Button(L10n.resetAllData, role: .destructive, action: onRequestReset)
                .accessibilityLabel(L10n.string("settings.reset.accessibility"))
                .accessibilityIdentifier("settings_resetAllDataButton")
        }
        .brandFormRowBackground(when: usesBrand)
    }
}

struct SettingsHelpAndFeedbackSection: View {
    let usesBrand: Bool

    var body: some View {
        Section {
            Link(destination: AppLinks.support) {
                Label(L10n.settingsSupportFAQ, systemImage: "questionmark.circle")
            }
            .accessibilityLabel(L10n.settingsSupportFAQAccessibility)
            .accessibilityIdentifier("settings_supportFAQLink")

            NavigationLink {
                FeedbackFormView()
            } label: {
                Label(L10n.settingsSupportFeedback, systemImage: "lightbulb")
            }
            .accessibilityLabel(L10n.settingsSupportFeedbackAccessibility)
            .accessibilityHint(L10n.settingsSupportFeedbackHint)
            .accessibilityIdentifier("settings_feedbackForm")

            Link(destination: AppLinks.appStoreReview) {
                Label(L10n.settingsSupportRate, systemImage: "star")
            }
            .accessibilityLabel(L10n.settingsSupportRateAccessibility)
            .accessibilityIdentifier("settings_rateAppLink")

            if ProductSurface.showsAccessibilityMarketing {
                Link(destination: AppLinks.accessibility) {
                    Label(L10n.settingsSupportAccessibility, systemImage: "accessibility")
                }
                .accessibilityLabel(L10n.settingsSupportAccessibilityLabel)
                .accessibilityIdentifier("settings_accessibilityLink")
            }

            Link(destination: AppLinks.privacy) {
                Label(L10n.settingsSupportPrivacy, systemImage: "hand.raised")
            }
            .accessibilityLabel(L10n.settingsSupportPrivacyAccessibility)
            .accessibilityIdentifier("settings_privacyPolicyLink")
        } header: {
            Text(L10n.settingsHelpAndFeedbackSection)
        }
        .brandFormRowBackground(when: usesBrand)
    }
}

struct SettingsAboutSection: View {
    let usesBrand: Bool
    let onViewOnboarding: () -> Void

    var body: some View {
        Section {
            Button(action: onViewOnboarding) {
                Label(L10n.settingsViewOnboarding, systemImage: "book.pages")
            }
            .accessibilityLabel(L10n.settingsViewOnboardingAccessibility)
            .accessibilityIdentifier("settings_viewOnboardingButton")

            Text(AppSupport.versionLabel)
                .foregroundStyle(usesBrand ? Brand.textSecondary : DS.ColorRole.textSecondary)
                .accessibilityLabel(AppSupport.versionLabel)
                .accessibilityIdentifier("settings_aboutVersion")
        } header: {
            Text(L10n.aboutSection)
        }
        .brandFormRowBackground(when: usesBrand)
    }
}
