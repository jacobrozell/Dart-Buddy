import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case appearance
    case startingMode
    case matchDefaults
    case x01Defaults
    case duringPlay
    case botOpponents
    case data
    case help
    case about

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .appearance: L10n.appearanceSection
        case .startingMode: L10n.settingsStartingModeSection
        case .matchDefaults: L10n.settingsMatchDefaultsSection
        case .x01Defaults: L10n.x01DefaultsSection
        case .duringPlay: L10n.settingsDuringPlaySection
        case .botOpponents: L10n.settingsBotOpponentsSection
        case .data: L10n.dataSection
        case .help: L10n.settingsHelpAndFeedbackSection
        case .about: L10n.aboutSection
        }
    }

    var systemImage: String {
        switch self {
        case .appearance: "paintbrush.fill"
        case .startingMode: "sportscourt.fill"
        case .matchDefaults: "slider.horizontal.3"
        case .x01Defaults: "number.circle.fill"
        case .duringPlay: "hand.tap.fill"
        case .botOpponents: "cpu.fill"
        case .data: "externaldrive.fill"
        case .help: "questionmark.circle.fill"
        case .about: "info.circle.fill"
        }
    }
}
