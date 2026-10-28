import SwiftUI

struct SettingsSectionFooter: View {
    let key: LocalizedStringKey
    let usesBrand: Bool

    init(_ key: LocalizedStringKey, usesBrand: Bool) {
        self.key = key
        self.usesBrand = usesBrand
    }

    var body: some View {
        Text(key)
            .font(.footnote)
            .foregroundStyle(usesBrand ? Brand.textSecondary : Color.secondary)
    }
}

struct SettingsDuringPlaySection: View {
    @ObservedObject var viewModel: SettingsViewModel
    let showsDartEntryPresentationPicker: Bool
    let usesBrand: Bool

    var body: some View {
        Section {
            if showsDartEntryPresentationPicker {
                Picker("settings.dartEntryPresentation.label", selection: Binding(
                    get: {
                        DartEntryPresentation(
                            rawValueOrDefault: viewModel.settings?.defaultDartEntryPresentationRaw
                        ).rawValue
                    },
                    set: { viewModel.queueDartEntryPresentationUpdate($0) }
                )) {
                    Text("settings.dartEntryPresentation.numberPad")
                        .tag(DartEntryPresentation.numberPad.rawValue)
                    Text("settings.dartEntryPresentation.visualBoard")
                        .tag(DartEntryPresentation.visualBoard.rawValue)
                }
                .accessibilityIdentifier("settings_dartEntryPresentationPicker")
                .accessibilityHint(L10n.string("settings.dartEntryPresentation.hint"))
            }
            Toggle("settings.feedback.haptics", isOn: Binding(
                get: { viewModel.settings?.hapticsEnabled ?? true },
                set: { viewModel.queueFeedbackUpdate(haptics: $0) }
            ))
            .accessibilityIdentifier("settings_hapticsToggle")
            Toggle("settings.feedback.sound", isOn: Binding(
                get: { viewModel.settings?.soundEnabled ?? true },
                set: { viewModel.queueFeedbackUpdate(sound: $0) }
            ))
            .accessibilityIdentifier("settings_soundToggle")
            Toggle("settings.feedback.turnTotalCaller", isOn: Binding(
                get: { viewModel.settings?.turnTotalCallerEnabled ?? false },
                set: { viewModel.queueFeedbackUpdate(turnTotalCaller: $0) }
            ))
            .accessibilityIdentifier("settings_turnTotalCallerToggle")
            .accessibilityHint(L10n.string("settings.feedback.turnTotalCaller.hint"))
            Toggle("settings.feedback.instantBotTurns", isOn: Binding(
                get: { viewModel.settings?.instantBotTurnsEnabled ?? false },
                set: { viewModel.queueFeedbackUpdate(instantBotTurns: $0) }
            ))
            .accessibilityIdentifier("settings_instantBotTurnsToggle")
            .accessibilityHint(L10n.string("settings.feedback.instantBotTurns.accessibilityHint"))
        } header: {
            Text(L10n.settingsDuringPlaySection)
        } footer: {
            SettingsSectionFooter(L10n.settingsDuringPlayFooter, usesBrand: usesBrand)
        }
        .brandFormRowBackground(when: usesBrand)
    }
}

struct SettingsBotOpponentsSection: View {
    @ObservedObject var viewModel: SettingsViewModel
    let usesBrand: Bool

    var body: some View {
        let instantBotTurnsOn = viewModel.settings?.instantBotTurnsEnabled ?? false
        Section {
            Toggle("settings.feedback.botStagger", isOn: Binding(
                get: { viewModel.settings?.botStaggerEnabled ?? true },
                set: { viewModel.queueBotPacingUpdate(stagger: $0) }
            ))
            .accessibilityIdentifier("settings_botStaggerToggle")
            .disabled(instantBotTurnsOn)
            Toggle("settings.feedback.botDartHaptics", isOn: Binding(
                get: { viewModel.settings?.botDartHapticsEnabled ?? true },
                set: { viewModel.queueBotPacingUpdate(dartHaptics: $0) }
            ))
            .accessibilityIdentifier("settings_botDartHapticsToggle")
            .accessibilityHint(L10n.string("settings.feedback.botDartHaptics.hint"))
            .disabled(instantBotTurnsOn)
        } header: {
            Text(L10n.settingsBotOpponentsSection)
        } footer: {
            SettingsSectionFooter(
                instantBotTurnsOn
                    ? L10n.settingsBotOpponentsInstantOverridesFooter
                    : L10n.settingsBotOpponentsFooter,
                usesBrand: usesBrand
            )
        }
        .brandFormRowBackground(when: usesBrand)
    }
}
