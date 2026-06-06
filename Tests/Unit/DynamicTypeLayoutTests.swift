import SwiftUI
import Testing
@testable import DartBuddy

@Suite("Dynamic type layout", .tags(.unit, .accessibility, .regression))
struct DynamicTypeLayoutTests {
    @Test
    func accessibilityScaleIncreasesWithSize() {
        #expect(DynamicTypeLayout.accessibilityScale(for: .large) == 1)
        #expect(DynamicTypeLayout.accessibilityScale(for: .accessibility1) == 1.15)
        #expect(DynamicTypeLayout.accessibilityScale(for: .accessibility5) == 1.55)
    }

    @Test
    func scoringPadUsesShortModifierLabelsAtAccessibilitySizes() {
        let regularDouble = ScoringPadLabels.modifierTitle(.double, dynamicTypeSize: .large)
        let axDouble = ScoringPadLabels.modifierTitle(.double, dynamicTypeSize: .accessibility3)

        #expect(regularDouble == L10n.string("scoring.pad.double"))
        #expect(axDouble == L10n.string("scoring.pad.double.short"))
        #expect(ScoringPadLabels.modifierTitle(.single, dynamicTypeSize: .accessibility1) == "")
    }
}
