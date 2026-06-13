import Foundation

/// Continuous bot tuning parameters used by `DartBotEngine`.
public struct BotSkillProfile: Codable, Equatable, Sendable {
    public struct HitChances: Codable, Equatable, Sendable {
        public let single: Double
        public let double: Double
        public let triple: Double

        public init(single: Double, double: Double, triple: Double) {
            self.single = single
            self.double = double
            self.triple = triple
        }
    }

    public struct X01: Codable, Equatable, Sendable {
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
        public let safeRemainingSingleOut: Int
        public let safeRemainingDoubleOut: Int
        public let safeRemainingMasterOut: Int
        /// Nearest preset tier for discrete scoring-segment / multiplier heuristics.
        public let scoringBehaviorTierRaw: String

        public var scoringBehaviorTier: BotDifficulty {
            BotDifficulty(rawValue: scoringBehaviorTierRaw) ?? .medium
        }
    }

    public struct Cricket: Codable, Equatable, Sendable {
        public let hitChances: HitChances
        public let offBoardMissChance: Double
        public let wrongBedChance: Double
        public let innerBullAimChance: Double
        public let tripleOnOpenChance: Double
        public let doubleOnOpenChance: Double
    }

    public let x01: X01
    public let cricket: Cricket

    public var displayProfile: BotDifficultyDisplayProfile {
        BotDifficultyDisplayProfile(
            x01: .init(
                scoringVisitMin: x01.scoringVisitMin,
                scoringVisitMax: x01.scoringVisitMax,
                hitChances: .init(
                    single: x01.hitChances.single,
                    double: x01.hitChances.double,
                    triple: x01.hitChances.triple
                ),
                checkoutAttemptChance: x01.checkoutAttemptChance,
                offBoardMissChance: x01.offBoardMissChance,
                riskyBustChance: x01.riskyBustChance,
                triplePreference: x01.triplePreference,
                checkInHitBoost: x01.checkInHitBoost,
                innerBullAimChance: x01.innerBullAimChance,
                masterInTripleOpenerChance: x01.masterInTripleOpenerChance
            ),
            cricket: .init(
                hitChances: .init(
                    single: cricket.hitChances.single,
                    double: cricket.hitChances.double,
                    triple: cricket.hitChances.triple
                ),
                offBoardMissChance: cricket.offBoardMissChance,
                wrongBedChance: cricket.wrongBedChance
            )
        )
    }
}

public struct TrainingBotSkillSnapshot: Codable, Equatable, Sendable {
    public let profile: BotSkillProfile
    public let linkedPlayerId: UUID
    public let sourcePlayerAvg: Double?
    public let sourcePlayerMPR: Double?
    public let resolvedAt: Date

    public init(
        profile: BotSkillProfile,
        linkedPlayerId: UUID,
        sourcePlayerAvg: Double?,
        sourcePlayerMPR: Double?,
        resolvedAt: Date = Date()
    ) {
        self.profile = profile
        self.linkedPlayerId = linkedPlayerId
        self.sourcePlayerAvg = sourcePlayerAvg
        self.sourcePlayerMPR = sourcePlayerMPR
        self.resolvedAt = resolvedAt
    }

    public static func encode(_ snapshot: TrainingBotSkillSnapshot) throws -> Data {
        try JSONEncoder().encode(snapshot)
    }

    public static func decode(from data: Data) throws -> TrainingBotSkillSnapshot {
        try JSONDecoder().decode(TrainingBotSkillSnapshot.self, from: data)
    }
}

public struct CustomBotSkillSnapshot: Codable, Equatable, Sendable {
    public let profile: BotSkillProfile
    public let x01Average: Double
    public let cricketMPR: Double
    public let configurationSchemaVersion: Int?

    public init(
        profile: BotSkillProfile,
        x01Average: Double,
        cricketMPR: Double,
        configurationSchemaVersion: Int? = nil
    ) {
        self.profile = profile
        self.x01Average = x01Average
        self.cricketMPR = cricketMPR
        self.configurationSchemaVersion = configurationSchemaVersion
    }

    public static func encode(_ snapshot: CustomBotSkillSnapshot) throws -> Data {
        try JSONEncoder().encode(snapshot)
    }

    public static func decode(from data: Data) throws -> CustomBotSkillSnapshot {
        try JSONDecoder().decode(CustomBotSkillSnapshot.self, from: data)
    }
}

public enum BotSkillProfilePayloadDecoder {
    public static func profile(from data: Data) -> BotSkillProfile? {
        if let training = try? TrainingBotSkillSnapshot.decode(from: data) {
            return training.profile
        }
        if let custom = try? CustomBotSkillSnapshot.decode(from: data) {
            return custom.profile
        }
        return nil
    }
}

extension BotDifficulty {
    public var skillProfile: BotSkillProfile {
        let display = displayProfile
        let safe = Self.safeRemainingBuffers(for: self)
        return BotSkillProfile(
            x01: .init(
                scoringVisitMin: display.x01.scoringVisitMin,
                scoringVisitMax: display.x01.scoringVisitMax,
                hitChances: .init(
                    single: display.x01.hitChances.single,
                    double: display.x01.hitChances.double,
                    triple: display.x01.hitChances.triple
                ),
                checkoutAttemptChance: display.x01.checkoutAttemptChance,
                offBoardMissChance: display.x01.offBoardMissChance,
                riskyBustChance: display.x01.riskyBustChance,
                triplePreference: display.x01.triplePreference,
                checkInHitBoost: display.x01.checkInHitBoost,
                innerBullAimChance: display.x01.innerBullAimChance,
                masterInTripleOpenerChance: display.x01.masterInTripleOpenerChance,
                safeRemainingSingleOut: safe.singleOut,
                safeRemainingDoubleOut: safe.doubleOut,
                safeRemainingMasterOut: safe.masterOut,
                scoringBehaviorTierRaw: rawValue
            ),
            cricket: .init(
                hitChances: .init(
                    single: display.cricket.hitChances.single,
                    double: display.cricket.hitChances.double,
                    triple: display.cricket.hitChances.triple
                ),
                offBoardMissChance: display.cricket.offBoardMissChance,
                wrongBedChance: display.cricket.wrongBedChance,
                innerBullAimChance: display.x01.innerBullAimChance,
                tripleOnOpenChance: Self.cricketTripleOnOpenChance(for: self),
                doubleOnOpenChance: Self.cricketDoubleOnOpenChance(for: self)
            )
        )
    }

    fileprivate static func safeRemainingBuffers(for difficulty: BotDifficulty) -> (singleOut: Int, doubleOut: Int, masterOut: Int) {
        switch difficulty {
        case .veryEasy: (6, 4, 8)
        case .easy: (10, 10, 12)
        case .medium: (20, 28, 32)
        case .hard: (28, 38, 40)
        case .pro: (32, 34, 50)
        }
    }

    fileprivate static func cricketTripleOnOpenChance(for difficulty: BotDifficulty) -> Double {
        switch difficulty {
        case .veryEasy, .easy: 0
        case .medium: 0.55
        case .hard: 0.58
        case .pro: 0.68
        }
    }

    fileprivate static func cricketDoubleOnOpenChance(for difficulty: BotDifficulty) -> Double {
        switch difficulty {
        case .veryEasy, .easy: 0
        case .medium: 0.45
        case .hard: 0.55
        case .pro: 0.5
        }
    }
}
