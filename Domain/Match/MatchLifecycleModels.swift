import Foundation

public enum MatchLifecycleStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case completed
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

    /// True when the match format tracks legs or sets beyond a single leg.
    public var showsLegsOrSetsOnBoard: Bool {
        setsEnabled || legsToWin > 1
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

    private enum CodingKeys: String, CodingKey {
        case type
        case x01
        case cricket
    }

    private enum PayloadType: String, Codable {
        case x01
        case cricket
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PayloadType.self, forKey: .type)
        switch type {
        case .x01:
            self = .x01(try container.decode(MatchConfigX01.self, forKey: .x01))
        case .cricket:
            self = .cricket(try container.decode(MatchConfigCricket.self, forKey: .cricket))
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
    /// Snapshot of roster identity color at match start; optional for legacy in-progress matches.
    public let preferredColorTokenAtMatchStart: String?

    public var botDifficulty: BotDifficulty? {
        botDifficultyRaw.flatMap(BotDifficulty.init(rawValue:))
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
        preferredColorTokenAtMatchStart: String? = nil
    ) {
        self.id = id
        self.playerId = playerId
        self.displayNameAtMatchStart = displayNameAtMatchStart
        self.turnOrder = turnOrder
        self.botDifficultyRaw = botDifficultyRaw
        self.botKindRaw = botKindRaw
        self.botSkillProfilePayload = botSkillProfilePayload
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
