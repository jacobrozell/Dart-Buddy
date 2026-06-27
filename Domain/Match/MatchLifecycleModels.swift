import Foundation

public enum MatchLifecycleStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case completed
    case forfeited
    case abandoned
}

public enum X01CheckoutMode: String, Codable, CaseIterable, Sendable {
    case singleOut
    case doubleOut
    case masterOut

    public var displayName: String {
        switch self {
        case .singleOut: L10n.string("x01.checkout.straightOut")
        case .doubleOut: L10n.string("x01.checkout.doubleOut")
        case .masterOut: L10n.string("x01.checkout.masterOut")
        }
    }
}

public enum X01CheckInMode: String, Codable, CaseIterable, Sendable {
    case straightIn
    case doubleIn
    case masterIn

    public var displayName: String {
        switch self {
        case .straightIn: L10n.string("x01.checkin.straightIn")
        case .doubleIn: L10n.string("x01.checkin.doubleIn")
        case .masterIn: L10n.string("x01.checkin.masterIn")
        }
    }
}

/// How leg/set targets are interpreted. `firstTo` plays until a player reaches
/// the target; `bestOf` plays a fixed number where the majority wins.
public enum X01LegFormat: String, Codable, CaseIterable, Sendable {
    case firstTo
    case bestOf

    public var displayName: String {
        switch self {
        case .firstTo: L10n.string("x01.legFormat.firstTo")
        case .bestOf: L10n.string("x01.legFormat.bestOf")
        }
    }
}

public struct MatchConfigX01: Codable, Equatable, Sendable {
    public let payloadVersion: Int
    public let startScore: Int
    public let legsToWin: Int
    public let setsEnabled: Bool
    public let setsToWin: Int?
    public let checkoutMode: X01CheckoutMode
    // Optional so payloads persisted before these existed still decode; the
    // accessors below supply the historical defaults (straight in / first to).
    public let checkInModeRaw: String?
    public let legFormatRaw: String?

    public var checkInMode: X01CheckInMode {
        checkInModeRaw.flatMap(X01CheckInMode.init(rawValue:)) ?? .straightIn
    }

    public var legFormat: X01LegFormat {
        legFormatRaw.flatMap(X01LegFormat.init(rawValue:)) ?? .firstTo
    }

    public init(
        payloadVersion: Int = 1,
        startScore: Int,
        legsToWin: Int,
        setsEnabled: Bool,
        setsToWin: Int?,
        checkoutMode: X01CheckoutMode,
        checkInMode: X01CheckInMode = .straightIn,
        legFormat: X01LegFormat = .firstTo
    ) {
        self.payloadVersion = payloadVersion
        self.startScore = startScore
        self.legsToWin = legsToWin
        self.setsEnabled = setsEnabled
        self.setsToWin = setsToWin
        self.checkoutMode = checkoutMode
        self.checkInModeRaw = checkInMode.rawValue
        self.legFormatRaw = legFormat.rawValue
    }
}

public enum CricketScoringMode: String, Codable, CaseIterable, Sendable {
    case standard
    case cutThroat

    public var displayName: String {
        switch self {
        case .standard: L10n.string("play.cricket.mode.normal")
        case .cutThroat: L10n.string("play.cricket.mode.cutThroat")
        }
    }
}

public struct MatchConfigCricket: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 2

    public let payloadVersion: Int
    public let bullScoreValue: Int
    public let pointsEnabled: Bool
    public let scoringModeRaw: String
    public let legsToWin: Int
    public let setsEnabled: Bool
    public let setsToWin: Int?
    public let legFormatRaw: String

    public var scoringMode: CricketScoringMode {
        CricketScoringMode(rawValue: scoringModeRaw) ?? .standard
    }

    public var legFormat: X01LegFormat {
        X01LegFormat(rawValue: legFormatRaw) ?? .firstTo
    }

    /// True when the in-game board should show set counts (legs are not shown on the cricket board).
    public var showsSetsOnBoard: Bool {
        setsEnabled
    }

    /// Kept for summary/history; cricket board uses `showsSetsOnBoard` only.
    public var showsLegsOrSetsOnBoard: Bool {
        showsSetsOnBoard || legsToWin > 1
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        bullScoreValue: Int = 25,
        pointsEnabled: Bool = true,
        scoringMode: CricketScoringMode = .standard,
        legsToWin: Int = 1,
        setsEnabled: Bool = false,
        setsToWin: Int? = nil,
        legFormat: X01LegFormat = .firstTo
    ) {
        self.payloadVersion = payloadVersion
        self.bullScoreValue = bullScoreValue
        self.pointsEnabled = pointsEnabled
        self.scoringModeRaw = scoringMode.rawValue
        self.legsToWin = legsToWin
        self.setsEnabled = setsEnabled
        self.setsToWin = setsEnabled ? setsToWin : nil
        self.legFormatRaw = legFormat.rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .payloadVersion) ?? 1
        bullScoreValue = try container.decodeIfPresent(Int.self, forKey: .bullScoreValue) ?? 25
        pointsEnabled = try container.decodeIfPresent(Bool.self, forKey: .pointsEnabled) ?? true
        scoringModeRaw = try container.decodeIfPresent(String.self, forKey: .scoringModeRaw)
            ?? CricketScoringMode.standard.rawValue
        legsToWin = try container.decodeIfPresent(Int.self, forKey: .legsToWin) ?? 1
        setsEnabled = try container.decodeIfPresent(Bool.self, forKey: .setsEnabled) ?? false
        setsToWin = try container.decodeIfPresent(Int.self, forKey: .setsToWin)
        legFormatRaw = try container.decodeIfPresent(String.self, forKey: .legFormatRaw)
            ?? X01LegFormat.firstTo.rawValue
        payloadVersion = max(version, Self.currentPayloadVersion)
    }

    private enum CodingKeys: String, CodingKey {
        case payloadVersion
        case bullScoreValue
        case pointsEnabled
        case scoringModeRaw
        case legsToWin
        case setsEnabled
        case setsToWin
        case legFormatRaw
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payloadVersion, forKey: .payloadVersion)
        try container.encode(bullScoreValue, forKey: .bullScoreValue)
        try container.encode(pointsEnabled, forKey: .pointsEnabled)
        try container.encode(scoringModeRaw, forKey: .scoringModeRaw)
        try container.encode(legsToWin, forKey: .legsToWin)
        try container.encode(setsEnabled, forKey: .setsEnabled)
        try container.encodeIfPresent(setsToWin, forKey: .setsToWin)
        try container.encode(legFormatRaw, forKey: .legFormatRaw)
    }
}

public enum MatchConfigPayload: Codable, Equatable, Sendable {
    case x01(MatchConfigX01)
    case cricket(MatchConfigCricket)
    case baseball(MatchConfigBaseball)
    case killer(MatchConfigKiller)
    case shanghai(MatchConfigShanghai)
    case americanCricket(MatchConfigAmericanCricket)
    case mickeyMouse(MatchConfigMickeyMouse)
    case mulligan(MatchConfigMulligan)
    case englishCricket(MatchConfigEnglishCricket)
    case knockout(MatchConfigKnockout)
    case suddenDeath(MatchConfigSuddenDeath)
    case fiftyOneByFives(MatchConfigFiftyOneByFives)
    case golf(MatchConfigGolf)
    case football(MatchConfigFootball)
    case grandNational(MatchConfigGrandNational)
    case hareAndHounds(MatchConfigHareAndHounds)
    case aroundTheClock(MatchConfigAroundTheClock)
    case aroundTheClock180(MatchConfigAroundTheClock180)
    case chaseTheDragon(MatchConfigChaseTheDragon)
    case nineLives(MatchConfigNineLives)
    case fleet(MatchConfigFleet)
    case raid(MatchConfigRaid)
    case bobs27(MatchConfigBobs27)
    case halveIt(MatchConfigHalveIt)
    case scam(MatchConfigScam)
    case snooker(MatchConfigSnooker)
    case ticTacToe(MatchConfigTicTacToe)
    case blindKiller(MatchConfigBlindKiller)
    case followTheLeader(MatchConfigFollowTheLeader)
    case loop(MatchConfigLoop)
    case prisoner(MatchConfigPrisoner)

    private enum CodingKeys: String, CodingKey {
        case type
        case x01
        case cricket
        case baseball
        case killer
        case shanghai
        case americanCricket
        case mickeyMouse
        case mulligan
        case englishCricket
        case knockout
        case suddenDeath
        case fiftyOneByFives
        case golf
        case football
        case grandNational
        case hareAndHounds
        case aroundTheClock
        case aroundTheClock180
        case chaseTheDragon
        case nineLives
        case fleet
        case raid
        case bobs27
        case halveIt
        case scam
        case snooker
        case ticTacToe
        case blindKiller
        case followTheLeader
        case loop
        case prisoner
    }

    private enum PayloadType: String, Codable {
        case x01
        case cricket
        case baseball
        case killer
        case shanghai
        case americanCricket
        case mickeyMouse
        case mulligan
        case englishCricket
        case knockout
        case suddenDeath
        case fiftyOneByFives
        case golf
        case football
        case grandNational
        case hareAndHounds
        case aroundTheClock
        case aroundTheClock180
        case chaseTheDragon
        case nineLives
        case fleet
        case raid
        case bobs27
        case halveIt
        case scam
        case snooker
        case ticTacToe
        case blindKiller
        case followTheLeader
        case loop
        case prisoner
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PayloadType.self, forKey: .type)
        switch type {
        case .x01:
            self = .x01(try container.decode(MatchConfigX01.self, forKey: .x01))
        case .cricket:
            self = .cricket(try container.decode(MatchConfigCricket.self, forKey: .cricket))
        case .baseball:
            self = .baseball(try container.decode(MatchConfigBaseball.self, forKey: .baseball))
        case .killer:
            self = .killer(try container.decode(MatchConfigKiller.self, forKey: .killer))
        case .shanghai:
            self = .shanghai(try container.decode(MatchConfigShanghai.self, forKey: .shanghai))
        case .americanCricket:
            self = .americanCricket(try container.decode(MatchConfigAmericanCricket.self, forKey: .americanCricket))
        case .mickeyMouse:
            self = .mickeyMouse(try container.decode(MatchConfigMickeyMouse.self, forKey: .mickeyMouse))
        case .mulligan:
            self = .mulligan(try container.decode(MatchConfigMulligan.self, forKey: .mulligan))
        case .englishCricket:
            self = .englishCricket(try container.decode(MatchConfigEnglishCricket.self, forKey: .englishCricket))
        case .knockout:
            self = .knockout(try container.decode(MatchConfigKnockout.self, forKey: .knockout))
        case .suddenDeath:
            self = .suddenDeath(try container.decode(MatchConfigSuddenDeath.self, forKey: .suddenDeath))
        case .fiftyOneByFives:
            self = .fiftyOneByFives(try container.decode(MatchConfigFiftyOneByFives.self, forKey: .fiftyOneByFives))
        case .golf:
            self = .golf(try container.decode(MatchConfigGolf.self, forKey: .golf))
        case .football:
            self = .football(try container.decode(MatchConfigFootball.self, forKey: .football))
        case .grandNational:
            self = .grandNational(try container.decode(MatchConfigGrandNational.self, forKey: .grandNational))
        case .hareAndHounds:
            self = .hareAndHounds(try container.decode(MatchConfigHareAndHounds.self, forKey: .hareAndHounds))
        case .aroundTheClock:
            self = .aroundTheClock(try container.decode(MatchConfigAroundTheClock.self, forKey: .aroundTheClock))
        case .aroundTheClock180:
            self = .aroundTheClock180(try container.decode(MatchConfigAroundTheClock180.self, forKey: .aroundTheClock180))
        case .chaseTheDragon:
            self = .chaseTheDragon(try container.decode(MatchConfigChaseTheDragon.self, forKey: .chaseTheDragon))
        case .nineLives:
            self = .nineLives(try container.decode(MatchConfigNineLives.self, forKey: .nineLives))
        case .fleet:
            self = .fleet(try container.decode(MatchConfigFleet.self, forKey: .fleet))
        case .raid:
            self = .raid(try container.decode(MatchConfigRaid.self, forKey: .raid))
        case .bobs27:
            self = .bobs27(try container.decode(MatchConfigBobs27.self, forKey: .bobs27))
        case .halveIt:
            self = .halveIt(try container.decode(MatchConfigHalveIt.self, forKey: .halveIt))
        case .scam:
            self = .scam(try container.decode(MatchConfigScam.self, forKey: .scam))
        case .snooker:
            self = .snooker(try container.decode(MatchConfigSnooker.self, forKey: .snooker))
        case .ticTacToe:
            self = .ticTacToe(try container.decode(MatchConfigTicTacToe.self, forKey: .ticTacToe))
        case .blindKiller:
            self = .blindKiller(try container.decode(MatchConfigBlindKiller.self, forKey: .blindKiller))
        case .followTheLeader:
            self = .followTheLeader(try container.decode(MatchConfigFollowTheLeader.self, forKey: .followTheLeader))
        case .loop:
            self = .loop(try container.decode(MatchConfigLoop.self, forKey: .loop))
        case .prisoner:
            self = .prisoner(try container.decode(MatchConfigPrisoner.self, forKey: .prisoner))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .x01(config):
            try container.encode(PayloadType.x01, forKey: .type)
            try container.encode(config, forKey: .x01)
        case let .cricket(config):
            try container.encode(PayloadType.cricket, forKey: .type)
            try container.encode(config, forKey: .cricket)
        case let .baseball(config):
            try container.encode(PayloadType.baseball, forKey: .type)
            try container.encode(config, forKey: .baseball)
        case let .killer(config):
            try container.encode(PayloadType.killer, forKey: .type)
            try container.encode(config, forKey: .killer)
        case let .shanghai(config):
            try container.encode(PayloadType.shanghai, forKey: .type)
            try container.encode(config, forKey: .shanghai)
        case let .americanCricket(config):
            try container.encode(PayloadType.americanCricket, forKey: .type)
            try container.encode(config, forKey: .americanCricket)
        case let .mickeyMouse(config):
            try container.encode(PayloadType.mickeyMouse, forKey: .type)
            try container.encode(config, forKey: .mickeyMouse)
        case let .mulligan(config):
            try container.encode(PayloadType.mulligan, forKey: .type)
            try container.encode(config, forKey: .mulligan)
        case let .englishCricket(config):
            try container.encode(PayloadType.englishCricket, forKey: .type)
            try container.encode(config, forKey: .englishCricket)
        case let .knockout(config):
            try container.encode(PayloadType.knockout, forKey: .type)
            try container.encode(config, forKey: .knockout)
        case let .suddenDeath(config):
            try container.encode(PayloadType.suddenDeath, forKey: .type)
            try container.encode(config, forKey: .suddenDeath)
        case let .fiftyOneByFives(config):
            try container.encode(PayloadType.fiftyOneByFives, forKey: .type)
            try container.encode(config, forKey: .fiftyOneByFives)
        case let .golf(config):
            try container.encode(PayloadType.golf, forKey: .type)
            try container.encode(config, forKey: .golf)
        case let .football(config):
            try container.encode(PayloadType.football, forKey: .type)
            try container.encode(config, forKey: .football)
        case let .grandNational(config):
            try container.encode(PayloadType.grandNational, forKey: .type)
            try container.encode(config, forKey: .grandNational)
        case let .hareAndHounds(config):
            try container.encode(PayloadType.hareAndHounds, forKey: .type)
            try container.encode(config, forKey: .hareAndHounds)
        case let .aroundTheClock(config):
            try container.encode(PayloadType.aroundTheClock, forKey: .type)
            try container.encode(config, forKey: .aroundTheClock)
        case let .aroundTheClock180(config):
            try container.encode(PayloadType.aroundTheClock180, forKey: .type)
            try container.encode(config, forKey: .aroundTheClock180)
        case let .chaseTheDragon(config):
            try container.encode(PayloadType.chaseTheDragon, forKey: .type)
            try container.encode(config, forKey: .chaseTheDragon)
        case let .nineLives(config):
            try container.encode(PayloadType.nineLives, forKey: .type)
            try container.encode(config, forKey: .nineLives)
        case let .fleet(config):
            try container.encode(PayloadType.fleet, forKey: .type)
            try container.encode(config, forKey: .fleet)
        case let .raid(config):
            try container.encode(PayloadType.raid, forKey: .type)
            try container.encode(config, forKey: .raid)
        case let .bobs27(config):
            try container.encode(PayloadType.bobs27, forKey: .type)
            try container.encode(config, forKey: .bobs27)
        case let .halveIt(config):
            try container.encode(PayloadType.halveIt, forKey: .type)
            try container.encode(config, forKey: .halveIt)
        case let .scam(config):
            try container.encode(PayloadType.scam, forKey: .type)
            try container.encode(config, forKey: .scam)
        case let .snooker(config):
            try container.encode(PayloadType.snooker, forKey: .type)
            try container.encode(config, forKey: .snooker)
        case let .ticTacToe(config):
            try container.encode(PayloadType.ticTacToe, forKey: .type)
            try container.encode(config, forKey: .ticTacToe)
        case let .blindKiller(config):
            try container.encode(PayloadType.blindKiller, forKey: .type)
            try container.encode(config, forKey: .blindKiller)
        case let .followTheLeader(config):
            try container.encode(PayloadType.followTheLeader, forKey: .type)
            try container.encode(config, forKey: .followTheLeader)
        case let .loop(config):
            try container.encode(PayloadType.loop, forKey: .type)
            try container.encode(config, forKey: .loop)
        case let .prisoner(config):
            try container.encode(PayloadType.prisoner, forKey: .type)
            try container.encode(config, forKey: .prisoner)
        }
    }
}

public struct MatchParticipant: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let playerId: UUID?
    public let displayNameAtMatchStart: String
    public let turnOrder: Int
    /// Present when this participant is a preset-tier computer opponent.
    public let botDifficultyRaw: String?
    /// `preset` or `training`; nil for humans and legacy bot rows that only set `botDifficultyRaw`.
    public let botKindRaw: String?
    /// JSON snapshot for training bots (`TrainingBotSkillSnapshot`).
    public let botSkillProfilePayload: Data?
    /// Preset ladder tier for bot-tier achievements, frozen at match start (`BotAchievementTierResolver`).
    public let botEffectiveTierRaw: String?
    /// Snapshot of roster identity color at match start; optional for legacy in-progress matches.
    public let preferredColorTokenAtMatchStart: String?

    public var botDifficulty: BotDifficulty? {
        botDifficultyRaw.flatMap(BotDifficulty.init(rawValue:))
    }

    public var botEffectiveTier: BotDifficulty? {
        botEffectiveTierRaw.flatMap(BotDifficulty.init(rawValue:))
    }

    public var botKind: BotKind? {
        botKindRaw.flatMap(BotKind.init(rawValue:))
    }

    public var isBot: Bool {
        botKind != nil || botDifficulty != nil || botSkillProfilePayload != nil
    }

    public var colorToken: PlayerColorToken {
        if let raw = preferredColorTokenAtMatchStart {
            return PlayerColorToken.resolved(raw: raw)
        }
        return PlayerColorToken.defaultForPlayer(id: playerId ?? id)
    }

    public init(
        id: UUID = UUID(),
        playerId: UUID?,
        displayNameAtMatchStart: String,
        turnOrder: Int,
        botDifficultyRaw: String? = nil,
        botKindRaw: String? = nil,
        botSkillProfilePayload: Data? = nil,
        botEffectiveTierRaw: String? = nil,
        preferredColorTokenAtMatchStart: String? = nil
    ) {
        self.id = id
        self.playerId = playerId
        self.displayNameAtMatchStart = displayNameAtMatchStart
        self.turnOrder = turnOrder
        self.botDifficultyRaw = botDifficultyRaw
        self.botKindRaw = botKindRaw
        self.botSkillProfilePayload = botSkillProfilePayload
        self.botEffectiveTierRaw = botEffectiveTierRaw
        self.preferredColorTokenAtMatchStart = preferredColorTokenAtMatchStart
    }
}

public struct MatchSnapshot: Codable, Sendable {
    public let payloadVersion: Int
    public let eventCount: Int
    public let createdAt: Date
    public let payload: Data

    public init(payloadVersion: Int = 1, eventCount: Int, createdAt: Date, payload: Data) {
        self.payloadVersion = payloadVersion
        self.eventCount = eventCount
        self.createdAt = createdAt
        self.payload = payload
    }
}
