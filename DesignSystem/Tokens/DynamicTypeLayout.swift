import SwiftUI

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
