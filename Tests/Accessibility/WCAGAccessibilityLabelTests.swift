import Testing
@testable import DartBuddy

/// Unit-level WCAG 2.1 checks for O-2.5.3 (Label in Name) and R-4.1.2 spoken values
/// that UI automation cannot infer from layout alone.
@Suite("WCAG accessibility labels", .tags(.unit, .accessibility, .scoringInput, .regression))
struct WCAGAccessibilityLabelTests {
    @Test("Pad keys use spoken dart names for all multipliers")
    func padKeyLabelsUseSpokenDartNames() {
        #expect(
            DartInput.padKeyAccessibilityLabel(segmentValue: 20, armedMultiplier: .single)
                == L10n.format("scoring.dart.single.accessibility", 20)
        )
        #expect(
            DartInput.padKeyAccessibilityLabel(segmentValue: 20, armedMultiplier: .double)
                == L10n.format("scoring.dart.double.accessibility", 20)
        )
        #expect(
            DartInput.padKeyAccessibilityLabel(segmentValue: 20, armedMultiplier: .triple)
                == L10n.format("scoring.dart.triple.accessibility", 20)
        )
    }

    @Test("Miss and bull pad keys avoid visible-only abbreviations")
    func missAndBullPadLabels() {
        let miss = DartInput.padKeyAccessibilityLabel(segmentValue: 0, armedMultiplier: .single)
        #expect(miss == L10n.string("scoring.segment.miss.accessibility"))
        #expect(miss != "0")

        #expect(
            DartInput.padKeyAccessibilityLabel(segmentValue: 25, armedMultiplier: .single)
                == L10n.string("scoring.segment.outerBull.accessibility")
        )
        #expect(
            DartInput.padKeyAccessibilityLabel(segmentValue: 25, armedMultiplier: .double)
                == L10n.string("scoring.dart.doubleBull.accessibility")
        )
    }

    @Test("Entered darts expose spoken accessibility names")
    func enteredDartSpokenNames() {
        let triple20 = DartInput(multiplier: .triple, segment: .oneToTwenty(20))
        #expect(triple20.spokenAccessibilityName == L10n.format("scoring.dart.triple.accessibility", 20))

        let miss = DartInput(multiplier: .single, segment: .miss)
        #expect(miss.spokenAccessibilityName == L10n.string("scoring.segment.miss.accessibility"))
    }

    @Test("Every scoring segment exposes a non-empty pad label")
    func padLabelsCoverAllSegments() {
        for value in 1 ... 20 {
            #expect(
                !DartInput.padKeyAccessibilityLabel(segmentValue: value, armedMultiplier: .single).isEmpty
            )
            let doubleLabel = DartInput.padKeyAccessibilityLabel(segmentValue: value, armedMultiplier: .double)
            #expect(!doubleLabel.isEmpty)
            #expect(doubleLabel.localizedCaseInsensitiveContains("double"))

            let tripleLabel = DartInput.padKeyAccessibilityLabel(segmentValue: value, armedMultiplier: .triple)
            #expect(!tripleLabel.isEmpty)
            #expect(tripleLabel.localizedCaseInsensitiveContains("triple"))
        }
    }
}
