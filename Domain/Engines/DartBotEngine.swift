import Foundation

/// Skill tiers for computer opponents. Each tier adjusts aim quality and
/// checkout consistency while keeping averages in a believable range.
public enum BotDifficulty: String, Codable, CaseIterable, Sendable {
    case veryEasy
    case easy
    case medium
    case hard
    case pro

    public var displayName: String {
        switch self {
        case .veryEasy: L10n.string("bot.difficulty.veryEasy")
        case .easy: L10n.string("bot.difficulty.easy")
        case .medium: L10n.string("bot.difficulty.medium")
        case .hard: L10n.string("bot.difficulty.hard")
        case .pro: L10n.string("bot.difficulty.pro")
        }
    }

    public var rosterName: String { L10n.format("bot.rosterNameFormat", displayName) }

    /// Rough per-visit scoring target when not on a finish.
    fileprivate var scoringVisitRange: ClosedRange<Int> {
        switch self {
        case .veryEasy: 10 ... 22
        case .easy: 18 ... 42
        case .medium: 22 ... 38
        case .hard: 28 ... 44
        case .pro: 34 ... 50
        }
    }

    fileprivate var checkoutAttemptChance: Double {
        switch self {
        case .veryEasy: 0.12
        case .easy: 0.25
        case .medium: 0.40
        case .hard: 0.50
        case .pro: 0.58
        }
    }

    fileprivate func hitChance(intendedMultiplier: DartMultiplier) -> Double {
        switch (self, intendedMultiplier) {
        case (.veryEasy, .triple): return 0.06
        case (.veryEasy, .double): return 0.14
        case (.veryEasy, .single): return 0.30
        case (.easy, .triple): return 0.18
        case (.easy, .double): return 0.28
        case (.easy, .single): return 0.42
        case (.medium, .triple): return 0.34
        case (.medium, .double): return 0.40
        case (.medium, .single): return 0.52
        case (.hard, .triple): return 0.38
        case (.hard, .double): return 0.44
        case (.hard, .single): return 0.54
        case (.pro, .triple): return 0.48
        case (.pro, .double): return 0.54
        case (.pro, .single): return 0.66
        }
    }

    fileprivate var prefersTripleOnScoringSegment: Double {
        switch self {
        case .veryEasy: 0.08
        case .easy: 0.25
        case .medium: 0.32
        case .hard: 0.32
        case .pro: 0.44
        }
    }

    fileprivate var innerBullAimChance: Double {
        switch self {
        case .veryEasy, .easy, .medium: 0
        case .hard: 0.12
        case .pro: 0.28
        }
    }

    fileprivate var masterInTripleOpenerChance: Double {
        switch self {
        case .veryEasy, .easy, .medium: 0
        case .hard: 0.15
        case .pro: 0.32
        }
    }

    /// Extra hit probability when trying to double/triple in at the start of a leg.
    fileprivate var checkInHitBoost: Double {
        switch self {
        case .veryEasy: 0.18
        case .easy: 0.16
        case .medium: 0.12
        case .hard: 0.08
        case .pro: 0.06
        }
    }

    /// Chance a dart completely misses the board after failing the intended target.
    fileprivate var offBoardMissChance: Double {
        switch self {
        case .veryEasy: 0.20
        case .easy: 0.12
        case .medium: 0.09
        case .hard: 0.07
        case .pro: 0.05
        }
    }

    fileprivate func cricketHitChance(intendedMultiplier: DartMultiplier) -> Double {
        switch (self, intendedMultiplier) {
        case (.veryEasy, .triple): return 0.04
        case (.veryEasy, .double): return 0.09
        case (.veryEasy, .single): return 0.20
        case (.easy, .triple): return 0.11
        case (.easy, .double): return 0.17
        case (.easy, .single): return 0.30
        case (.medium, .triple): return 0.20
        case (.medium, .double): return 0.26
        case (.medium, .single): return 0.36
        case (.hard, .triple): return 0.26
        case (.hard, .double): return 0.32
        case (.hard, .single): return 0.42
        case (.pro, .triple): return 0.32
        case (.pro, .double): return 0.38
        case (.pro, .single): return 0.50
        }
    }

    /// Off-board miss after failing the intended Cricket bed (within the miss branch).
    fileprivate var cricketOffBoardMissChance: Double {
        switch self {
        case .veryEasy: 0.34
        case .easy: 0.28
        case .medium: 0.22
        case .hard: 0.18
        case .pro: 0.14
        }
    }

    /// Lands on a non-Cricket segment (1–14) so the visit records zero marks.
    fileprivate var cricketWrongBedChance: Double {
        switch self {
        case .veryEasy: 0.42
        case .easy: 0.36
        case .medium: 0.30
        case .hard: 0.24
        case .pro: 0.20
        }
    }

    /// When a planned dart would bust, chance the bot throws it anyway instead of
    /// substituting a safe single (higher tiers still bust less often).
    fileprivate var riskyDartWhenWouldBustChance: Double {
        switch self {
        case .veryEasy: 0.70
        case .easy: 0.40
        case .medium: 0.20
        case .hard: 0.16
        case .pro: 0.12
        }
    }

    public var displayProfile: BotDifficultyDisplayProfile {
        BotDifficultyDisplayProfile(
            x01: .init(
                scoringVisitMin: scoringVisitRange.lowerBound,
                scoringVisitMax: scoringVisitRange.upperBound,
                hitChances: .init(
                    single: hitChance(intendedMultiplier: .single),
                    double: hitChance(intendedMultiplier: .double),
                    triple: hitChance(intendedMultiplier: .triple)
                ),
                checkoutAttemptChance: checkoutAttemptChance,
                offBoardMissChance: offBoardMissChance,
                riskyBustChance: riskyDartWhenWouldBustChance,
                triplePreference: prefersTripleOnScoringSegment,
                checkInHitBoost: checkInHitBoost,
                innerBullAimChance: innerBullAimChance,
                masterInTripleOpenerChance: masterInTripleOpenerChance
            ),
            cricket: .init(
                hitChances: .init(
                    single: cricketHitChance(intendedMultiplier: .single),
                    double: cricketHitChance(intendedMultiplier: .double),
                    triple: cricketHitChance(intendedMultiplier: .triple)
                ),
                offBoardMissChance: cricketOffBoardMissChance,
                wrongBedChance: cricketWrongBedChance
            )
        )
    }
}

public struct BotDifficultyDisplayProfile: Equatable, Sendable {
    public struct HitChances: Equatable, Sendable {
        public let single: Double
        public let double: Double
        public let triple: Double
    }

    public struct X01: Equatable, Sendable {
        public let scoringVisitMin: Int
        public let scoringVisitMax: Int
        public let hitChances: HitChances
        public let checkoutAttemptChance: Double
        public let offBoardMissChance: Double
        public let riskyBustChance: Double
        public let triplePreference: Double
        public let checkInHitBoost: Double
        public let innerBullAimChance: Double
        public let masterInTripleOpenerChance: Double
    }

    public struct Cricket: Equatable, Sendable {
        public let hitChances: HitChances
        public let offBoardMissChance: Double
        public let wrongBedChance: Double
    }

    public let x01: X01
    public let cricket: Cricket

    public static func percent(_ value: Double, signed: Bool = false) -> String {
        let formatted = String(format: "%.0f%%", value * 100)
        if signed, value > 0 { return "+\(formatted)" }
        return formatted
    }

    public static func range(_ min: Int, _ max: Int) -> String {
        "\(min)–\(max)"
    }
}

public enum DartBotEngine {
    public static func botDifficulty(for participant: MatchParticipant) -> BotDifficulty? {
        participant.botDifficultyRaw.flatMap(BotDifficulty.init(rawValue:))
    }

    public static func botSkillProfile(for participant: MatchParticipant) -> BotSkillProfile? {
        if let payload = participant.botSkillProfilePayload,
           let snapshot = try? TrainingBotSkillSnapshot.decode(from: payload) {
            return snapshot.profile
        }
        return participant.botDifficulty?.skillProfile
    }

    public static func botDifficulty(
        playerId: UUID,
        in participants: [MatchParticipant]
    ) -> BotDifficulty? {
        participants
            .first { ($0.playerId ?? $0.id) == playerId }
            .flatMap { botDifficulty(for: $0) }
    }

    public static func botSkillProfile(
        playerId: UUID,
        in participants: [MatchParticipant]
    ) -> BotSkillProfile? {
        participants
            .first { ($0.playerId ?? $0.id) == playerId }
            .flatMap { botSkillProfile(for: $0) }
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
        generateX01Turn(
            remaining: remaining,
            profile: difficulty.skillProfile,
            checkoutMode: checkoutMode,
            checkInMode: checkInMode,
            isCheckedIn: isCheckedIn,
            rng: &rng
        )
    }

    public static func generateX01Turn(
        remaining: Int,
        profile: BotSkillProfile,
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
                profile: profile,
                checkoutMode: checkoutMode,
                checkInMode: checkInMode,
                checkedIn: checkedIn,
                rng: &rng
            )

            let hitBoost = checkedIn ? 0 : profile.x01.checkInHitBoost
            let resolved = resolveDart(
                intended: intended,
                profile: profile,
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
                let playsRisky = Double.random(in: 0 ... 1, using: &rng) < profile.x01.riskyBustChance
                if playsRisky {
                    darts.append(resolved)
                    if checkedIn {
                        simulatedRemaining -= points
                        if turnEndsAfterSimulatedDart(
                            remaining: simulatedRemaining,
                            checkoutMode: checkoutMode
                        ) {
                            break
                        }
                    }
                } else {
                    let safe = safeScoringDart(
                        remaining: simulatedRemaining,
                        checkoutMode: checkoutMode,
                        rng: &rng
                    )
                    darts.append(safe)
                    simulatedRemaining -= safe.points
                    if turnEndsAfterSimulatedDart(
                        remaining: simulatedRemaining,
                        checkoutMode: checkoutMode
                    ) {
                        break
                    }
                }
            } else {
                darts.append(resolved)
                if checkedIn {
                    simulatedRemaining -= points
                    if turnEndsAfterSimulatedDart(
                        remaining: simulatedRemaining,
                        checkoutMode: checkoutMode
                    ) {
                        break
                    }
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
        generateCricketTurn(
            state: state,
            playerIndex: playerIndex,
            profile: difficulty.skillProfile,
            rng: &rng
        )
    }

    public static func generateCricketTurn(
        state: CricketState,
        playerIndex: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var marksSnapshot = state.players[playerIndex].marks

        while darts.count < 3 {
            let intended = intendedCricketDart(
                state: state,
                playerIndex: playerIndex,
                marksSnapshot: marksSnapshot,
                profile: profile,
                rng: &rng
            )
            let resolved = resolveCricketDart(intended: intended, profile: profile, rng: &rng)
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
        profile: BotSkillProfile,
        checkoutMode: X01CheckoutMode,
        checkInMode: X01CheckInMode,
        checkedIn: Bool,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        if checkedIn,
           CheckoutSuggester.suggestion(remaining: remaining, mode: checkoutMode, dartsAvailable: dartsLeft) != nil,
           Double.random(in: 0 ... 1, using: &rng) < profile.x01.checkoutAttemptChance,
           let route = CheckoutSuggester.suggestion(remaining: remaining, mode: checkoutMode, dartsAvailable: dartsLeft),
           let first = route.first,
           let dart = dart(fromCheckoutLabel: first) {
            return dart
        }

        if checkedIn == false {
            return openerDart(for: checkInMode, profile: profile, rng: &rng)
        }

        let visitRange = profile.x01.scoringVisitMin ... profile.x01.scoringVisitMax
        let targetTotal = min(
            remaining - safeRemainingBuffer(checkoutMode: checkoutMode, profile: profile),
            Int.random(in: visitRange, using: &rng)
        )
        let segment = preferredScoringSegment(profile: profile, rng: &rng)
        let multiplier = preferredScoringMultiplier(
            targetTotal: max(1, targetTotal),
            segment: segment,
            profile: profile,
            rng: &rng
        )
        return DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
    }

    private static func openerDart(
        for mode: X01CheckInMode,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch mode {
        case .straightIn:
            return intendedX01Dart(
                remaining: 501,
                dartsLeft: 3,
                profile: profile,
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
            if Double.random(in: 0 ... 1, using: &rng) < profile.x01.masterInTripleOpenerChance {
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
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let target = cricketAimTarget(
            state: state,
            playerIndex: playerIndex,
            marksSnapshot: marksSnapshot,
            rng: &rng
        )
        guard let target else {
            return boardGlanceDart(near: DartInput(multiplier: .single, segment: .oneToTwenty(20)), rng: &rng)
        }
        return cricketDartInput(for: target, profile: profile, rng: &rng)
    }

    private static func cricketAimTarget(
        state: CricketState,
        playerIndex: Int,
        marksSnapshot: [String: Int],
        rng: inout some RandomNumberGenerator
    ) -> CricketTarget? {
        let ownOpen = CricketTarget.allCases.filter { (marksSnapshot[$0.rawValue] ?? 0) < 3 }
        if let closeTarget = ownOpen.max(by: { $0.points < $1.points }) {
            return closeTarget
        }

        if state.config.pointsEnabled,
           state.config.scoringMode == .cutThroat,
           let punishTarget = cutThroatPunishTargets(
               state: state,
               playerIndex: playerIndex,
               marksSnapshot: marksSnapshot
           ).max(by: { $0.points < $1.points }) {
            return punishTarget
        }

        return CricketTarget.allCases.randomElement(using: &rng)
    }

    private static func cutThroatPunishTargets(
        state: CricketState,
        playerIndex: Int,
        marksSnapshot: [String: Int]
    ) -> [CricketTarget] {
        CricketTarget.allCases.filter { target in
            guard (marksSnapshot[target.rawValue] ?? 0) >= 3 else { return false }
            return state.players.enumerated().contains { index, player in
                index != playerIndex && (player.marks[target.rawValue] ?? 0) < 3
            }
        }
    }

    private static func cricketDartInput(
        for target: CricketTarget,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        if target == .bull {
            if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.innerBullAimChance {
                return DartInput(multiplier: .single, segment: .innerBull)
            }
            return DartInput(multiplier: .single, segment: .outerBull)
        }
        let segment = target.points
        let tier = profile.x01.scoringBehaviorTier
        if tier == .veryEasy || tier == .easy {
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.tripleOnOpenChance {
            return DartInput(multiplier: .triple, segment: .oneToTwenty(segment))
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.doubleOnOpenChance {
            return DartInput(multiplier: .double, segment: .oneToTwenty(segment))
        }
        return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
    }

    private static func resolveCricketDart(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard intended.isMiss == false else {
            return intended
        }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: intended.multiplier))
        if roll < hitChance {
            return intended
        }

        let missRoll = Double.random(in: 0 ... 1, using: &rng)
        if missRoll < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        if missRoll < profile.cricket.offBoardMissChance + profile.cricket.wrongBedChance {
            return cricketWrongBedDart(rng: &rng)
        }

        return cricketPartialMissDart(intended: intended, rng: &rng)
    }

    private static func cricketWrongBedDart(rng: inout some RandomNumberGenerator) -> DartInput {
        let face = Int.random(in: 1 ... 14, using: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(face))
    }

    /// Near-miss that may still clip a Cricket bed, but often wastes the dart.
    private static func cricketPartialMissDart(
        intended: DartInput,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        if Double.random(in: 0 ... 1, using: &rng) < 0.55 {
            return cricketWrongBedDart(rng: &rng)
        }

        switch intended.segment {
        case let .oneToTwenty(value):
            let cricketNeighbors = (15 ... 20).filter { $0 != value }
            if let neighbor = cricketNeighbors.randomElement(using: &rng) {
                return DartInput(multiplier: .single, segment: .oneToTwenty(neighbor))
            }
            return DartInput(multiplier: .single, segment: .oneToTwenty(value))
        case .innerBull, .outerBull:
            let face = Int.random(in: 1 ... 14, using: &rng)
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        case .miss:
            return intended
        }
    }

    private static func resolveDart(
        intended: DartInput,
        profile: BotSkillProfile,
        hitBoost: Double = 0,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard intended.isMiss == false else {
            return intended
        }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(
            0.95,
            profile.x01HitChance(intendedMultiplier: intended.multiplier) + hitBoost
        )
        if roll < hitChance {
            return intended
        }

        let downgradeBand = 0.28
        if roll < hitChance + downgradeBand {
            return downgrade(intended: intended, rng: &rng)
        }

        if roll < hitChance + downgradeBand + profile.x01.offBoardMissChance {
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

    private static func turnEndsAfterSimulatedDart(
        remaining: Int,
        checkoutMode: X01CheckoutMode
    ) -> Bool {
        if remaining == 0 { return true }
        if remaining < 0 { return true }
        if remaining == 1, checkoutMode != .singleOut { return true }
        return false
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
        profile: BotSkillProfile
    ) -> Int {
        switch checkoutMode {
        case .singleOut: profile.x01.safeRemainingSingleOut
        case .doubleOut: profile.x01.safeRemainingDoubleOut
        case .masterOut: profile.x01.safeRemainingMasterOut
        }
    }

    private static func preferredScoringSegment(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> Int {
        switch profile.x01.scoringBehaviorTier {
        case .veryEasy:
            return Int.random(in: 1 ... 16, using: &rng)
        case .easy:
            return Int.random(in: 5 ... 20, using: &rng)
        case .medium:
            return [16, 17, 18, 19, 20].randomElement(using: &rng) ?? 19
        case .hard:
            if Double.random(in: 0 ... 1, using: &rng) < 0.35 { return 20 }
            return [18, 19].randomElement(using: &rng) ?? 19
        case .pro:
            return Double.random(in: 0 ... 1, using: &rng) < 0.46 ? 20 : 19
        }
    }

    private static func preferredScoringMultiplier(
        targetTotal: Int,
        segment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartMultiplier {
        switch profile.x01.scoringBehaviorTier {
        case .veryEasy:
            return Double.random(in: 0 ... 1, using: &rng) < 0.92 ? .single : .double
        case .easy:
            return Double.random(in: 0 ... 1, using: &rng) < 0.75 ? .single : .double
        case .medium:
            if targetTotal >= segment * 3, Double.random(in: 0 ... 1, using: &rng) < 0.48 { return .triple }
            if Double.random(in: 0 ... 1, using: &rng) < 0.28 { return .triple }
            return .double
        case .hard, .pro:
            if targetTotal >= segment * 3 { return .triple }
            return Double.random(in: 0 ... 1, using: &rng) < profile.x01.triplePreference ? .triple : .double
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
