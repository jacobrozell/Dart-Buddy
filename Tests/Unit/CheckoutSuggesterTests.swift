import Foundation
import Testing
@testable import DartBuddy

/// Validates checkout suggestions are correct (sum to the score, finish legally)
/// and match the conventional routes for the well-known finishes.
private func value(of label: String) -> Int {
    if label == "Bull" { return 50 }
    if label == "25" { return 25 }
    if let rest = label.dropFirstIfPrefixed("T") { return (Int(rest) ?? 0) * 3 }
    if let rest = label.dropFirstIfPrefixed("D") { return (Int(rest) ?? 0) * 2 }
    return Int(label) ?? 0
}

private extension String {
    func dropFirstIfPrefixed(_ prefix: String) -> Substring? {
        hasPrefix(prefix) ? dropFirst(prefix.count) : nil
    }
}

private func isDoubleFinish(_ label: String) -> Bool {
    label == "Bull" || label.hasPrefix("D")
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutAllSuggestionsIncludesEveryFewestDartRoute() {
    let routes = CheckoutSuggester.allSuggestions(remaining: 60, mode: .doubleOut)
    #expect(routes.count >= 2)
    #expect(routes.first == ["20", "D20"])
    for route in routes {
        #expect(route.count == 2)
        #expect(route.reduce(0) { $0 + value(of: $1) } == 60)
        #expect(isDoubleFinish(route.last ?? ""))
    }
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutAllSuggestionsMatchesPrimarySuggestion() {
    for remaining in 2 ... 170 {
        let primary = CheckoutSuggester.suggestion(remaining: remaining, mode: .doubleOut)
        let all = CheckoutSuggester.allSuggestions(remaining: remaining, mode: .doubleOut)
        if let primary {
            #expect(all.first == primary)
            #expect(all.isEmpty == false)
        } else {
            #expect(all.isEmpty)
        }
    }
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutSuggestsStandardMarqueeFinishes() {
    #expect(CheckoutSuggester.suggestion(remaining: 170, mode: .doubleOut) == ["T20", "T20", "Bull"])
    #expect(CheckoutSuggester.suggestion(remaining: 167, mode: .doubleOut) == ["T20", "T19", "Bull"])
    #expect(CheckoutSuggester.suggestion(remaining: 100, mode: .doubleOut) == ["T20", "D20"])
    #expect(CheckoutSuggester.suggestion(remaining: 98, mode: .doubleOut) == ["T20", "D19"])
    #expect(CheckoutSuggester.suggestion(remaining: 60, mode: .doubleOut) == ["20", "D20"])
    #expect(CheckoutSuggester.suggestion(remaining: 40, mode: .doubleOut) == ["D20"])
    #expect(CheckoutSuggester.suggestion(remaining: 50, mode: .doubleOut) == ["Bull"])
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutDoubleOutResultsAreAlwaysValid() {
    for remaining in 2 ... 170 {
        guard let route = CheckoutSuggester.suggestion(remaining: remaining, mode: .doubleOut) else { continue }
        #expect(route.count <= 3)
        #expect(route.reduce(0) { $0 + value(of: $1) } == remaining, "Route for \(remaining) must sum correctly")
        #expect(isDoubleFinish(route.last ?? ""), "Route for \(remaining) must finish on a double")
    }
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutRejectsImpossibleAndOverflowScores() {
    // Classic double-out impossibilities and anything above 170.
    for impossible in [169, 168, 166, 165, 163, 162, 159, 171, 200] {
        #expect(CheckoutSuggester.suggestion(remaining: impossible, mode: .doubleOut) == nil)
    }
    // A bare 1 can never be a double-out finish.
    #expect(CheckoutSuggester.suggestion(remaining: 1, mode: .doubleOut) == nil)
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutRespectsDartsAvailable() {
    // 100 needs two darts, so a single remaining dart yields no suggestion.
    #expect(CheckoutSuggester.suggestion(remaining: 100, mode: .doubleOut, dartsAvailable: 1) == nil)
    // 40 is a one-dart finish.
    #expect(CheckoutSuggester.suggestion(remaining: 40, mode: .doubleOut, dartsAvailable: 1) == ["D20"])
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutSingleOutAllowsAnyFinishingDart() {
    #expect(CheckoutSuggester.suggestion(remaining: 20, mode: .singleOut, dartsAvailable: 1) == ["20"])
    #expect(CheckoutSuggester.suggestion(remaining: 1, mode: .singleOut, dartsAvailable: 1) == ["1"])
    let route = CheckoutSuggester.suggestion(remaining: 170, mode: .singleOut)
    #expect(route != nil)
    #expect((route ?? []).reduce(0) { $0 + value(of: $1) } == 170)
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutMasterOutAllowsTripleFinishes() {
    #expect(CheckoutSuggester.suggestion(remaining: 60, mode: .masterOut) == ["T20"])
    #expect(CheckoutSuggester.suggestion(remaining: 40, mode: .masterOut) == ["D20"])
    #expect(CheckoutSuggester.suggestion(remaining: 50, mode: .masterOut) == ["Bull"])
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutMasterOutResultsAreAlwaysValid() {
    for remaining in 2 ... 170 {
        guard let route = CheckoutSuggester.suggestion(remaining: remaining, mode: .masterOut) else { continue }
        #expect(route.count <= 3)
        #expect(route.reduce(0) { $0 + value(of: $1) } == remaining)
        let last = route.last ?? ""
        let validFinish = last == "Bull" || last.hasPrefix("D") || last.hasPrefix("T") || Int(last) != nil
        #expect(validFinish)
    }
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutLocalizedDisplayLabelsFormatTokens() {
    let labels = CheckoutSuggester.localizedDisplayLabels(for: ["T20", "D16", "Bull", "20"])
    #expect(labels.count == 4)
    #expect(labels[2] == L10n.string("scoring.checkout.bull"))
    #expect(labels[3] == "20")
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutAllSuggestionsRespectsZeroDartsAvailable() {
    #expect(CheckoutSuggester.allSuggestions(remaining: 40, mode: .doubleOut, dartsAvailable: 0).isEmpty)
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutAllSuggestionsFindsOneDartRouteWhenNeeded() {
    let routes = CheckoutSuggester.allSuggestions(remaining: 32, mode: .doubleOut, dartsAvailable: 1)
    #expect(routes == [["D16"]])
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutDoubleOutEveryValidScoreHasPrimarySuggestion() {
    for remaining in 2 ... 170 {
        let suggestion = CheckoutSuggester.suggestion(remaining: remaining, mode: .doubleOut)
        if [169, 168, 166, 165, 163, 162, 159].contains(remaining) {
            #expect(suggestion == nil, "Score \(remaining) should be impossible")
        } else if remaining <= 170 {
            #expect(suggestion != nil, "Score \(remaining) should have a route")
        }
    }
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutMasterOutEveryValidScoreHasPrimarySuggestion() {
    for remaining in 2 ... 170 {
        let suggestion = CheckoutSuggester.suggestion(remaining: remaining, mode: .masterOut)
        if suggestion != nil {
            #expect(suggestion!.reduce(0) { $0 + value(of: $1) } == remaining)
        }
    }
}

@Test(.tags(.unit, .x01, .regression, .offline))
func checkoutLocalizedDisplayLabelPassesThroughUnknownToken() {
    #expect(CheckoutSuggester.localizedDisplayLabel(for: "unknown") == "unknown")
}
