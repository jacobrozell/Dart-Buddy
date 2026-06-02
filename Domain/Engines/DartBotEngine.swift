import Foundation

/// Skill tiers for computer opponents. Each tier adjusts aim quality and
/// checkout consistency while keeping averages in a believable range.
public enum BotDifficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
    case pro

    public var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .pro: return "Pro"
        }
    }

    public var rosterName: String { "DartBot · \(displayName)" }

    /// Rough per-visit scoring target when not on a finish.
    fileprivate var scoringVisitRange: ClosedRange<Int> {
        switch self {
        case .easy: 18 ... 42
        case .medium: 26 ... 48
        case .hard: 34 ... 54
        case .pro: 40 ... 62
        }
    }

    fileprivate var checkoutAttemptChance: Double {
        switch self {
        case .easy: 0.25
        case .medium: 0.40
        case .hard: 0.50
        case .pro: 0.58
        }
    }

    fileprivate func hitChance(intendedMultiplier: DartMultiplier) -> Double {
        switch (self, intendedMultiplier) {
        case (.easy, .triple): return 0.18
        case (.easy, .double): return 0.28
        case (.easy, .single): return 0.42
        case (.medium, .triple): return 0.40
        case (.medium, .double): return 0.46
        case (.medium, .single): return 0.58
        case (.hard, .triple): return 0.44
        case (.hard, .double): return 0.50
        case (.hard, .single): return 0.60
        case (.pro, .triple): return 0.54
        case (.pro, .double): return 0.60
        case (.pro, .single): return 0.72
        }
    }

    fileprivate var prefersTripleOnScoringSegment: Double {
        switch self {
        case .easy: 0.25
        case .medium: 0.40
        case .hard: 0.38
        case .pro: 0.55
        }
    }

    fileprivate var innerBullAimChance: Double {
        switch self {
        case .easy, .medium: 0
        case .hard: 0.12
        case .pro: 0.28
        }
    }

    fileprivate var masterInTripleOpenerChance: Double {
        switch self {
        case .easy, .medium: 0
        case .hard: 0.15
        case .pro: 0.32
        }
    }

    /// Extra hit probability when trying to double/triple in at the start of a leg.
    fileprivate var checkInHitBoost: Double {
        switch self {
        case .easy: 0.16
        case .medium: 0.12
        case .hard: 0.08
        case .pro: 0.06
        }
    }

    /// Chance a dart completely misses the board after failing the intended target.
    fileprivate var offBoardMissChance: Double {
        switch self {
        case .easy: 0.10
        case .medium: 0.07
        case .hard: 0.05
        case .pro: 0.03
        }
    }
}

public enum DartBotEngine {
    public static func botDifficulty(for participant: MatchParticipant) -> BotDifficulty? {
        participant.botDifficultyRaw.flatMap(BotDifficulty.init(rawValue:))
    }

    public static func botDifficulty(
        playerId: UUID,
        in participants: [MatchParticipant]
    ) -> BotDifficulty? {
        participants
            .first { ($0.playerId ?? $0.id) == playerId }
            .flatMap { botDifficulty(for: $0) }
    }

    // MARK: - X01

    public static func generateX01Turn(
        remaining: Int,
        difficulty: BotDifficulty,
        checkoutMode: X01CheckoutMode,
        checkInMode: X01CheckInMode,
        isCheckedIn: Bool,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var simulatedRemaining = remaining
        var checkedIn = isCheckedIn

        while darts.count < 3, simulatedRemaining > 0 {
            let dartsLeft = 3 - darts.count
            let intended = intendedX01Dart(
                remaining: simulatedRemaining,
                dartsLeft: dartsLeft,
                difficulty: difficulty,
                checkoutMode: checkoutMode,
                checkInMode: checkInMode,
                checkedIn: checkedIn,
                rng: &rng
            )

            let hitBoost = checkedIn ? 0 : difficulty.checkInHitBoost
            let resolved = resolveDart(
                intended: intended,
                difficulty: difficulty,
                hitBoost: hitBoost,
                rng: &rng
            )
            let points = scoredPoints(
                for: resolved,
                checkInMode: checkInMode,
                checkedIn: checkedIn
            )

            if checkedIn == false, points > 0 {
                checkedIn = true
            }

            if checkedIn, wouldBust(
                remaining: simulatedRemaining,
                points: points,
                checkoutMode: checkoutMode
            ) {
                let safe = safeScoringDart(
                    remaining: simulatedRemaining,
                    checkoutMode: checkoutMode,
                    rng: &rng
                )
                darts.append(safe)
                simulatedRemaining -= safe.points
            } else {
                darts.append(resolved)
                if checkedIn {
                    simulatedRemaining -= points
                    if simulatedRemaining == 0 { break }
                }
            }
        }

        return darts
    }

    // MARK: - Cricket

    public static func generateCricketTurn(
        state: CricketState,
        playerIndex: Int,
        difficulty: BotDifficulty,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var marksSnapshot = state.players[playerIndex].marks

        while darts.count < 3 {
            let intended = intendedCricketDart(
                state: state,
                playerIndex: playerIndex,
                marksSnapshot: marksSnapshot,
                difficulty: difficulty,
                rng: &rng
            )
            let resolved = resolveDart(intended: intended, difficulty: difficulty, rng: &rng)
            darts.append(resolved)

            if let targetRaw = resolved.segment.cricketTargetRaw {
                let incoming = cricketMarks(for: resolved)
                let before = marksSnapshot[targetRaw] ?? 0
                marksSnapshot[targetRaw] = min(3, before + incoming)
            }
        }

        return darts
    }

    // MARK: - Internals

    private static func intendedX01Dart(
        remaining: Int,
        dartsLeft: Int,
        difficulty: BotDifficulty,
        checkoutMode: X01CheckoutMode,
        checkInMode: X01CheckInMode,
        checkedIn: Bool,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        if checkedIn,
           CheckoutSuggester.suggestion(remaining: remaining, mode: checkoutMode, dartsAvailable: dartsLeft) != nil,
           Double.random(in: 0 ... 1, using: &rng) < difficulty.checkoutAttemptChance,
           let route = CheckoutSuggester.suggestion(remaining: remaining, mode: checkoutMode, dartsAvailable: dartsLeft),
           let first = route.first,
           let dart = dart(fromCheckoutLabel: first) {
            return dart
        }

        if checkedIn == false {
            return openerDart(for: checkInMode, difficulty: difficulty, rng: &rng)
        }

        let targetTotal = min(
            remaining - safeRemainingBuffer(checkoutMode: checkoutMode, difficulty: difficulty),
            Int.random(in: difficulty.scoringVisitRange, using: &rng)
        )
        let segment = preferredScoringSegment(difficulty: difficulty, rng: &rng)
        let multiplier = preferredScoringMultiplier(
            targetTotal: max(1, targetTotal),
            segment: segment,
            difficulty: difficulty,
            rng: &rng
        )
        return DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
    }

    private static func openerDart(
        for mode: X01CheckInMode,
        difficulty: BotDifficulty,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch mode {
        case .straightIn:
            return intendedX01Dart(
                remaining: 501,
                dartsLeft: 3,
                difficulty: difficulty,
                checkoutMode: .doubleOut,
                checkInMode: .straightIn,
                checkedIn: true,
                rng: &rng
            )
        case .doubleIn:
            let faces = [16, 8, 4, 20, 12, 18]
            let face = faces.randomElement(using: &rng) ?? 16
            return DartInput(multiplier: .double, segment: .oneToTwenty(face))
        case .masterIn:
            if Double.random(in: 0 ... 1, using: &rng) < difficulty.masterInTripleOpenerChance {
                return DartInput(multiplier: .triple, segment: .oneToTwenty(20))
            }
            let faces = [16, 8, 20, 12, 18, 4]
            let face = faces.randomElement(using: &rng) ?? 16
            return DartInput(multiplier: .double, segment: .oneToTwenty(face))
        }
    }

    private static func intendedCricketDart(
        state: CricketState,
        playerIndex: Int,
        marksSnapshot: [String: Int],
        difficulty: BotDifficulty,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let ownOpen = CricketTarget.allCases.filter { (marksSnapshot[$0.rawValue] ?? 0) < 3 }
        if let target = ownOpen.first ?? CricketTarget.allCases.randomElement(using: &rng) {
            if target == .bull {
                if Double.random(in: 0 ... 1, using: &rng) < difficulty.innerBullAimChance {
                    return DartInput(multiplier: .single, segment: .innerBull)
                }
                return DartInput(multiplier: .single, segment: .outerBull)
            }
            let segment = target.points
            switch difficulty {
            case .easy:
                return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
            case .medium:
                if Double.random(in: 0 ... 1, using: &rng) < 0.45 {
                    return DartInput(multiplier: .double, segment: .oneToTwenty(segment))
                }
                return DartInput(multiplier: .triple, segment: .oneToTwenty(segment))
            case .hard, .pro:
                return DartInput(multiplier: .triple, segment: .oneToTwenty(segment))
            }
        }
        return boardGlanceDart(near: DartInput(multiplier: .single, segment: .oneToTwenty(20)), rng: &rng)
    }

    private static func resolveDart(
        intended: DartInput,
        difficulty: BotDifficulty,
        hitBoost: Double = 0,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard intended.isMiss == false else {
            return intended
        }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(
            0.95,
            difficulty.hitChance(intendedMultiplier: intended.multiplier) + hitBoost
        )
        if roll < hitChance {
            return intended
        }

        let downgradeBand = 0.28
        if roll < hitChance + downgradeBand {
            return downgrade(intended: intended, rng: &rng)
        }

        if roll < hitChance + downgradeBand + difficulty.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }

        return boardGlanceDart(near: intended, rng: &rng)
    }

    private static func downgrade(
        intended: DartInput,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch intended.segment {
        case let .oneToTwenty(value):
            switch intended.multiplier {
            case .triple:
                if Double.random(in: 0 ... 1, using: &rng) < 0.55 {
                    return DartInput(multiplier: .single, segment: .oneToTwenty(value))
                }
                return DartInput(multiplier: .double, segment: .oneToTwenty(value))
            case .double:
                return DartInput(multiplier: .single, segment: .oneToTwenty(value))
            case .single:
                let neighbor = max(1, min(20, value + Int.random(in: -2 ... 2, using: &rng)))
                return DartInput(multiplier: .single, segment: .oneToTwenty(neighbor))
            }
        case .innerBull:
            return DartInput(multiplier: .single, segment: .outerBull)
        case .outerBull:
            let face = Int.random(in: 16 ... 20, using: &rng)
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        case .miss:
            return intended
        }
    }

    /// Lands on a nearby scoring segment when the bot misses the intended target.
    private static func boardGlanceDart(
        near intended: DartInput,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch intended.segment {
        case let .oneToTwenty(value):
            let neighbor = max(1, min(20, value + Int.random(in: -3 ... 3, using: &rng)))
            return DartInput(multiplier: .single, segment: .oneToTwenty(neighbor))
        case .innerBull, .outerBull:
            let face = Int.random(in: 1 ... 20, using: &rng)
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        case .miss:
            let face = Int.random(in: 1 ... 20, using: &rng)
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        }
    }

    /// Picks a single that cannot bust when a planned dart would overshoot.
    private static func safeScoringDart(
        remaining: Int,
        checkoutMode: X01CheckoutMode,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let candidates = (1 ... 20).filter { value in
            !wouldBust(remaining: remaining, points: value, checkoutMode: checkoutMode)
        }
        let segment = candidates.randomElement(using: &rng) ?? 1
        return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
    }

    private static func scoredPoints(
        for dart: DartInput,
        checkInMode: X01CheckInMode,
        checkedIn: Bool
    ) -> Int {
        if checkedIn { return dart.points }
        switch checkInMode {
        case .straightIn:
            return dart.points
        case .doubleIn:
            return dart.multiplier == .double ? dart.points : 0
        case .masterIn:
            return dart.multiplier == .double || dart.multiplier == .triple ? dart.points : 0
        }
    }

    private static func wouldBust(
        remaining: Int,
        points: Int,
        checkoutMode: X01CheckoutMode
    ) -> Bool {
        let next = remaining - points
        if next < 0 { return true }
        if next == 1, checkoutMode != .singleOut { return true }
        return false
    }

    private static func safeRemainingBuffer(
        checkoutMode: X01CheckoutMode,
        difficulty: BotDifficulty
    ) -> Int {
        switch (checkoutMode, difficulty) {
        case (.singleOut, .easy): 10
        case (.singleOut, .medium): 20
        case (.singleOut, .hard): 28
        case (.singleOut, .pro): 32
        case (.doubleOut, .easy): 12
        case (.doubleOut, .medium): 36
        case (.doubleOut, .hard): 52
        case (.doubleOut, .pro): 48
        case (.masterOut, .easy): 12
        case (.masterOut, .medium): 32
        case (.masterOut, .hard): 40
        case (.masterOut, .pro): 50
        }
    }

    private static func preferredScoringSegment(
        difficulty: BotDifficulty,
        rng: inout some RandomNumberGenerator
    ) -> Int {
        switch difficulty {
        case .easy:
            return Int.random(in: 5 ... 20, using: &rng)
        case .medium:
            return [16, 17, 18, 19, 20].randomElement(using: &rng) ?? 19
        case .hard:
            return Double.random(in: 0 ... 1, using: &rng) < 0.45 ? 20 : 19
        case .pro:
            return Double.random(in: 0 ... 1, using: &rng) < 0.58 ? 20 : 19
        }
    }

    private static func preferredScoringMultiplier(
        targetTotal: Int,
        segment: Int,
        difficulty: BotDifficulty,
        rng: inout some RandomNumberGenerator
    ) -> DartMultiplier {
        switch difficulty {
        case .easy:
            return Double.random(in: 0 ... 1, using: &rng) < 0.75 ? .single : .double
        case .medium:
            if targetTotal >= segment * 3, Double.random(in: 0 ... 1, using: &rng) < 0.65 { return .triple }
            if Double.random(in: 0 ... 1, using: &rng) < 0.40 { return .triple }
            return .double
        case .hard, .pro:
            if targetTotal >= segment * 3 { return .triple }
            return Double.random(in: 0 ... 1, using: &rng) < difficulty.prefersTripleOnScoringSegment ? .triple : .double
        }
    }

    private static func cricketMarks(for dart: DartInput) -> Int {
        guard dart.isMiss == false else { return 0 }
        switch dart.segment {
        case .innerBull: return 2
        case .outerBull: return 1
        case .oneToTwenty: return dart.multiplier.markValue
        case .miss: return 0
        }
    }

    static func dart(fromCheckoutLabel label: String) -> DartInput? {
        if label == "Bull" {
            return DartInput(multiplier: .single, segment: .innerBull)
        }
        if label == "25" {
            return DartInput(multiplier: .single, segment: .outerBull)
        }
        if label.hasPrefix("T"), let value = Int(label.dropFirst()), (1 ... 20).contains(value) {
            return DartInput(multiplier: .triple, segment: .oneToTwenty(value))
        }
        if label.hasPrefix("D"), let value = Int(label.dropFirst()), (1 ... 20).contains(value) {
            return DartInput(multiplier: .double, segment: .oneToTwenty(value))
        }
        if let value = Int(label), (1 ... 20).contains(value) {
            return DartInput(multiplier: .single, segment: .oneToTwenty(value))
        }
        return nil
    }
}
