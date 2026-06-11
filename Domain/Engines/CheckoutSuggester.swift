import Foundation

/// Suggests a checkout route (e.g. `T20 T20 Bull`) for an X01 remaining score.
///
/// Pure and deterministic so it can be unit-tested in isolation. The solver
/// finds the fewest-dart route, preferring a triple-heavy setup and the highest
/// finishing double, which reproduces the conventional routes for the common
/// finishes (170, 167, 100, 98, 60, 40, …) while always returning a *valid*
/// checkout for the chosen mode.
public enum CheckoutSuggester {
    /// Returns the dart labels for a checkout, or `nil` when the score cannot be
    /// finished within `dartsAvailable` darts under the given mode.
    public static func suggestion(
        remaining: Int,
        mode: X01CheckoutMode,
        dartsAvailable: Int = 3
    ) -> [String]? {
        allSuggestions(remaining: remaining, mode: mode, dartsAvailable: dartsAvailable).first
    }

    /// Every fewest-dart checkout route for the score, in preference order (same route
    /// as `suggestion` is always first when one exists).
    public static func allSuggestions(
        remaining: Int,
        mode: X01CheckoutMode,
        dartsAvailable: Int = 3
    ) -> [[String]] {
        guard dartsAvailable >= 1 else { return [] }
        if remaining < 2 {
            if mode == .singleOut, remaining == 1 { return [["1"]] }
            return []
        }
        for darts in 1 ... min(dartsAvailable, 3) {
            let routes = allRoutes(remaining: remaining, darts: darts, mode: mode)
            if routes.isEmpty == false { return routes }
        }
        return []
    }

    private static func allRoutes(remaining: Int, darts: Int, mode: X01CheckoutMode) -> [[String]] {
        switch darts {
        case 1:
            return finishLabel(remaining, mode: mode).map { [[$0]] } ?? []
        case 2:
            var routes: [[String]] = []
            for finisher in finishers(mode: mode) {
                let setup = remaining - finisher.value
                guard setup >= 1, let setupLabel = setupLabel(setup) else { continue }
                routes.append([setupLabel, finisher.label])
            }
            return routes
        default:
            var routes: [[String]] = []
            for opener in setups {
                let rest = remaining - opener.value
                guard rest >= 2 else { continue }
                for tail in allRoutes(remaining: rest, darts: 2, mode: mode) {
                    routes.append([opener.label] + tail)
                }
            }
            return routes
        }
    }

    private static func finishLabel(_ value: Int, mode: X01CheckoutMode) -> String? {
        switch mode {
        case .singleOut:
            return setupLabel(value)
        case .doubleOut:
            if value == 50 { return "Bull" }
            if value % 2 == 0, (1 ... 20).contains(value / 2) { return "D\(value / 2)" }
            return nil
        case .masterOut:
            if value % 2 == 0, (1 ... 20).contains(value / 2) { return "D\(value / 2)" }
            if value % 3 == 0, (1 ... 20).contains(value / 3) { return "T\(value / 3)" }
            if value == 50 { return "Bull" }
            return nil
        }
    }

    /// Best single-dart label for a raw value, preferring triples, then singles,
    /// then doubles, then the bulls.
    private static func setupLabel(_ value: Int) -> String? {
        if value % 3 == 0, (1 ... 20).contains(value / 3) { return "T\(value / 3)" }
        if (1 ... 20).contains(value) { return "\(value)" }
        if value % 2 == 0, (1 ... 20).contains(value / 2) { return "D\(value / 2)" }
        if value == 25 { return "25" }
        if value == 50 { return "Bull" }
        return nil
    }

    /// Finishing darts in preference order. Double-out uses doubles (then bull);
    /// master-out adds triples after the doubles; single-out allows any dart.
    private static func finishers(mode: X01CheckoutMode) -> [(value: Int, label: String)] {
        switch mode {
        case .doubleOut:
            var result = (1 ... 20).reversed().map { (value: $0 * 2, label: "D\($0)") }
            result.append((value: 50, label: "Bull"))
            return result
        case .masterOut:
            var result = (1 ... 20).reversed().map { (value: $0 * 2, label: "D\($0)") }
            result += (1 ... 20).reversed().map { (value: $0 * 3, label: "T\($0)") }
            result.append((value: 50, label: "Bull"))
            return result
        case .singleOut:
            var result: [(Int, String)] = []
            for face in stride(from: 20, through: 1, by: -1) { result.append((face * 3, "T\(face)")) }
            result.append((50, "Bull"))
            result.append((25, "25"))
            for face in stride(from: 20, through: 1, by: -1) { result.append((face * 2, "D\(face)")) }
            for face in stride(from: 20, through: 1, by: -1) { result.append((face, "\(face)")) }
            return result.map { (value: $0.0, label: $0.1) }
        }
    }

    /// Opening darts for a three-dart route, favouring high triples.
    private static let setups: [(value: Int, label: String)] = {
        var result = stride(from: 20, through: 1, by: -1).map { (value: $0 * 3, label: "T\($0)") }
        result.append((value: 50, label: "Bull"))
        result.append((value: 25, label: "25"))
        result += stride(from: 20, through: 1, by: -1).map { (value: $0, label: "\($0)") }
        return result
    }()
}

public extension CheckoutSuggester {
    static func localizedDisplayLabels(for route: [String]) -> [String] {
        route.map { localizedDisplayLabel(for: $0) }
    }

    static func localizedDisplayLabel(for token: String) -> String {
        if token == "Bull" { return L10n.string("scoring.checkout.bull") }
        if token.hasPrefix("T"), let value = Int(token.dropFirst()) {
            return L10n.format("scoring.checkout.tripleFormat", value)
        }
        if token.hasPrefix("D"), let value = Int(token.dropFirst()) {
            return L10n.format("scoring.checkout.doubleFormat", value)
        }
        if let value = Int(token) {
            return "\(value)"
        }
        return token
    }
}
