import SwiftUI
import UIKit

extension DynamicTypeSize {
    /// True for the five accessibility content sizes (AX1–AX5).
    var isAccessibilitySize: Bool {
        switch self {
        case .accessibility1, .accessibility2, .accessibility3,
             .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }

    /// Maps SwiftUI Dynamic Type to UIKit content size for font metric scaling.
    var uiContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }
}

enum ScoringPadLabels {
    /// Visible pad label; full wording is preserved in accessibility labels.
    static func modifierTitle(_ multiplier: DartMultiplier, dynamicTypeSize: DynamicTypeSize) -> String {
        if dynamicTypeSize.isAccessibilitySize {
            switch multiplier {
            case .double: return L10n.string("scoring.pad.double.short")
            case .triple: return L10n.string("scoring.pad.triple.short")
            case .single: return ""
            }
        }
        switch multiplier {
        case .double: return L10n.string("scoring.pad.double")
        case .triple: return L10n.string("scoring.pad.triple")
        case .single: return ""
        }
    }
}
