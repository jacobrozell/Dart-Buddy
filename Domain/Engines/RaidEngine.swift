import Foundation

// MARK: - Config

public enum RaidBossTier: String, Codable, CaseIterable, Sendable {
    case challenger
    case standard
    case nightmare

    public var bossMaxHP: Int {
        switch self {
        case .challenger: return 45
        case .standard: return 60
        case .nightmare: return 80
        }
    }

    public var shieldUntilHP: Int {
        switch self {
        case .challenger, .standard: return 40
        case .nightmare: return 50
        }
    }

    public var enrageAtHP: Int {
        switch self {
        case .challenger: return 15
        case .standard: return 20
        case .nightmare: return 25
        }
    }

    public var displayNameKey: String { "play.raid.setup.bossTier.\(rawValue)" }
}

public struct MatchConfigRaid: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let bossTierRaw: String
    public let heroHearts: Int
    public let enrageEnabled: Bool

    public var bossTier: RaidBossTier {
        RaidBossTier(rawValue: bossTierRaw) ?? .standard
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        bossTier: RaidBossTier = .standard,
        heroHearts: Int = 3,
        enrageEnabled: Bool = true
    ) {
        self.payloadVersion = payloadVersion
        self.bossTierRaw = bossTier.rawValue
        self.heroHearts = heroHearts
        self.enrageEnabled = enrageEnabled
    }
}

// MARK: - State

public enum RaidPhase: String, Codable, Sendable {
    case shield
    case expose
}

public struct RaidHeroState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var hearts: Int
    public var damageDealt: Int
    public var isDown: Bool

    public init(playerId: UUID, hearts: Int, damageDealt: Int = 0, isDown: Bool = false) {
        self.playerId = playerId
        self.hearts = hearts
        self.damageDealt = damageDealt
        self.isDown = isDown
    }
}

public struct RaidState: Codable, Equatable, Sendable {
    public let config: MatchConfigRaid
    public let bossParticipantId: UUID
    public var bossHP: Int
    public let bossMaxHP: Int
    public let shieldUntilHP: Int
    public let enrageAtHP: Int
    public var phase: RaidPhase
    public var enrageActive: Bool
    public var teamCricketMarks: [Int: Int]
    public var closedShieldSegments: Set<Int>
    public var heroes: [RaidHeroState]
    public var currentHeroIndex: Int
    public var roundIndex: Int
    public var visitTotalsThisRound: [UUID: Int]
    public var heroesVisitedThisRound: Int
    public var teamVictory: Bool
    public var isComplete: Bool
    public var winnerPlayerId: UUID?

    public init(
        config: MatchConfigRaid,
        bossParticipantId: UUID,
        heroes: [RaidHeroState],
        bossHP: Int,
        bossMaxHP: Int,
        shieldUntilHP: Int,
        enrageAtHP: Int,
        phase: RaidPhase = .shield,
        enrageActive: Bool = false,
        teamCricketMarks: [Int: Int] = [:],
        closedShieldSegments: Set<Int> = [],
        currentHeroIndex: Int = 0,
        roundIndex: Int = 0,
        visitTotalsThisRound: [UUID: Int] = [:],
        heroesVisitedThisRound: Int = 0,
        teamVictory: Bool = false,
        isComplete: Bool = false,
        winnerPlayerId: UUID? = nil
    ) {
        self.config = config
        self.bossParticipantId = bossParticipantId
        self.heroes = heroes
        self.bossHP = bossHP
        self.bossMaxHP = bossMaxHP
        self.shieldUntilHP = shieldUntilHP
        self.enrageAtHP = enrageAtHP
        self.phase = phase
        self.enrageActive = enrageActive
        self.teamCricketMarks = teamCricketMarks
        self.closedShieldSegments = closedShieldSegments
        self.currentHeroIndex = currentHeroIndex
        self.roundIndex = roundIndex
        self.visitTotalsThisRound = visitTotalsThisRound
        self.heroesVisitedThisRound = heroesVisitedThisRound
        self.teamVictory = teamVictory
        self.isComplete = isComplete
        self.winnerPlayerId = winnerPlayerId
    }
}

// MARK: - Events

public struct RaidDartEvent: Codable, Equatable, Sendable {
    public let segmentRaw: String
    public let multiplierRaw: String
    public let isMiss: Bool

    public init(segmentRaw: String, multiplierRaw: String, isMiss: Bool) {
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.isMiss = isMiss
    }
}

public struct RaidVisitEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let darts: [RaidDartEvent]
    public let visitTotal: Int
    public let bossHPBefore: Int
    public let bossHPAfter: Int
    public let phaseBefore: RaidPhase
    public let phaseAfter: RaidPhase
    public let enrageActiveAfter: Bool
    public let enrageVictims: [UUID]
    public let teamVictory: Bool
    public let teamDefeat: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        darts: [RaidDartEvent],
        visitTotal: Int,
        bossHPBefore: Int,
        bossHPAfter: Int,
        phaseBefore: RaidPhase,
        phaseAfter: RaidPhase,
        enrageActiveAfter: Bool,
        enrageVictims: [UUID],
        teamVictory: Bool,
        teamDefeat: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.darts = darts
        self.visitTotal = visitTotal
        self.bossHPBefore = bossHPBefore
        self.bossHPAfter = bossHPAfter
        self.phaseBefore = phaseBefore
        self.phaseAfter = phaseAfter
        self.enrageActiveAfter = enrageActiveAfter
        self.enrageVictims = enrageVictims
        self.teamVictory = teamVictory
        self.teamDefeat = teamDefeat
        self.timestamp = timestamp
    }
}

public struct RaidVisitOutcome: Sendable {
    public let updatedState: RaidState
    public let event: RaidVisitEvent
}

// MARK: - Engine

public enum RaidEngine {
    public static let shieldSegments: Set<Int> = [20, 19, 18, 17, 16]
    private static let shieldCloseDamage = 8
    private static let soloEnrageThreshold = 60

    public static func makeInitialState(
        config: MatchConfigRaid,
        playerIds: [UUID],
        bossParticipantId: UUID = UUID()
    ) throws -> RaidState {
        guard (1 ... 3).contains(playerIds.count) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.raidHeroCount"
            )
        }
        let tier = config.bossTier
        let heroes = playerIds.map {
            RaidHeroState(playerId: $0, hearts: config.heroHearts)
        }
        return RaidState(
            config: config,
            bossParticipantId: bossParticipantId,
            heroes: heroes,
            bossHP: tier.bossMaxHP,
            bossMaxHP: tier.bossMaxHP,
            shieldUntilHP: tier.shieldUntilHP,
            enrageAtHP: tier.enrageAtHP,
            phase: .shield,
            enrageActive: false,
            currentHeroIndex: firstLivingHeroIndex(in: heroes, startingAt: 0) ?? 0
        )
    }

    public static func submitVisit(
        state: RaidState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> RaidVisitOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard darts.count <= 3 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.turn.maxDarts"
            )
        }

        var updated = state
        let heroIndex = updated.currentHeroIndex
        guard updated.heroes.indices.contains(heroIndex) else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.raidUnavailable")
        }
        let hero = updated.heroes[heroIndex]
        guard !hero.isDown else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.notYourTurn")
        }

        let phaseBefore = updated.phase
        let bossHPBefore = updated.bossHP
        var visitDamage = 0

        for dart in darts {
            let damage = damage(for: dart, state: &updated)
            visitDamage += damage
            updated.bossHP = max(0, updated.bossHP - damage)
            updated.heroes[heroIndex].damageDealt += damage
            recomputePhaseAndEnrage(&updated)
        }

        let visitTotal = darts.reduce(0) { $0 + $1.points }

        var enrageVictims: [UUID] = []
        updated.visitTotalsThisRound[hero.playerId] = visitTotal
        updated.heroesVisitedThisRound += 1

        var teamVictory = false
        var teamDefeat = false

        if updated.bossHP == 0 {
            updated.isComplete = true
            updated.teamVictory = true
            updated.winnerPlayerId = nil
            teamVictory = true
        } else {
            let livingCount = updated.heroes.filter { !$0.isDown }.count
            let completedRound = updated.heroesVisitedThisRound >= livingCount && livingCount > 0
            if completedRound {
                if updated.enrageActive {
                    enrageVictims = applyEnrageStrike(&updated)
                }
                updated.roundIndex += 1
                updated.visitTotalsThisRound = [:]
                updated.heroesVisitedThisRound = 0
            }

            if updated.heroes.allSatisfy(\.isDown) {
                updated.isComplete = true
                updated.teamVictory = false
                updated.winnerPlayerId = updated.bossParticipantId
                teamDefeat = true
            } else if !teamVictory {
                advanceToNextHero(&updated)
            }
        }

        let event = RaidVisitEvent(
            playerId: hero.playerId,
            turnIndex: updated.roundIndex,
            darts: darts.map(dartEvent(from:)),
            visitTotal: visitTotal,
            bossHPBefore: bossHPBefore,
            bossHPAfter: updated.bossHP,
            phaseBefore: phaseBefore,
            phaseAfter: updated.phase,
            enrageActiveAfter: updated.enrageActive,
            enrageVictims: enrageVictims,
            teamVictory: teamVictory,
            teamDefeat: teamDefeat,
            timestamp: timestamp
        )

        return RaidVisitOutcome(updatedState: updated, event: event)
    }

    public static func dartInput(from event: RaidDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.isMiss
        )
    }

    // MARK: - Private

    private static func damage(for dart: DartInput, state: inout RaidState) -> Int {
        guard !dart.isMiss else { return 0 }
        if state.phase == .shield {
            guard let segment = segmentValue(for: dart.segment), shieldSegments.contains(segment) else { return 0 }
            guard !state.closedShieldSegments.contains(segment) else { return 0 }
            let marksBefore = state.teamCricketMarks[segment, default: 0]
            let marksAdded = dart.multiplier.markValue
            let marksAfter = marksBefore + marksAdded
            state.teamCricketMarks[segment] = marksAfter
            if marksBefore < 3, marksAfter >= 3 {
                state.closedShieldSegments.insert(segment)
                return shieldCloseDamage
            }
            return 0
        }
        if dart.segment == .outerBull || dart.segment == .innerBull {
            return dart.multiplier == .double || dart.segment == .innerBull ? 2 : 0
        }
        switch dart.multiplier {
        case .double: return 2
        case .triple: return 3
        case .single: return 0
        }
    }

    private static func recomputePhaseAndEnrage(_ state: inout RaidState) {
        state.phase = state.bossHP > state.shieldUntilHP ? .shield : .expose
        state.enrageActive = state.config.enrageEnabled && state.bossHP <= state.enrageAtHP && state.bossHP > 0
    }

    private static func applyEnrageStrike(_ state: inout RaidState) -> [UUID] {
        let living = state.heroes.filter { !$0.isDown }
        guard !living.isEmpty else { return [] }

        let victims: [UUID]
        if living.count == 1 {
            let hero = living[0]
            let total = state.visitTotalsThisRound[hero.playerId] ?? 0
            victims = total < soloEnrageThreshold ? [hero.playerId] : []
        } else {
            let totals = living.map { ($0.playerId, state.visitTotalsThisRound[$0.playerId] ?? 0) }
            let minimum = totals.map(\.1).min() ?? 0
            victims = totals.filter { $0.1 == minimum }.map(\.0)
        }

        for victimId in victims {
            guard let index = state.heroes.firstIndex(where: { $0.playerId == victimId }) else { continue }
            state.heroes[index].hearts = max(0, state.heroes[index].hearts - 1)
            if state.heroes[index].hearts == 0 {
                state.heroes[index].isDown = true
            }
        }
        return victims
    }

    private static func advanceToNextHero(_ state: inout RaidState) {
        guard let next = nextLivingHeroIndex(in: state.heroes, after: state.currentHeroIndex) else { return }
        state.currentHeroIndex = next
    }

    private static func firstLivingHeroIndex(in heroes: [RaidHeroState], startingAt: Int) -> Int? {
        guard !heroes.isEmpty else { return nil }
        for offset in 0 ..< heroes.count {
            let index = (startingAt + offset) % heroes.count
            if !heroes[index].isDown { return index }
        }
        return nil
    }

    private static func nextLivingHeroIndex(in heroes: [RaidHeroState], after index: Int) -> Int? {
        guard !heroes.isEmpty else { return nil }
        for offset in 1 ... heroes.count {
            let candidate = (index + offset) % heroes.count
            if !heroes[candidate].isDown { return candidate }
        }
        return nil
    }

    private static func segmentValue(for segment: DartSegment) -> Int? {
        if case let .oneToTwenty(value) = segment { return value }
        return nil
    }

    private static func dartEvent(from dart: DartInput) -> RaidDartEvent {
        RaidDartEvent(
            segmentRaw: segmentRaw(for: dart.segment),
            multiplierRaw: dart.multiplier.rawValue,
            isMiss: dart.isMiss
        )
    }

    private static func segmentRaw(for segment: DartSegment) -> String {
        switch segment {
        case let .oneToTwenty(value): return String(value)
        case .outerBull: return "outerBull"
        case .innerBull: return "innerBull"
        case .miss: return "miss"
        }
    }

    private static func segment(fromRaw raw: String) -> DartSegment {
        if raw == "outerBull" { return .outerBull }
        if raw == "innerBull" { return .innerBull }
        if raw == "miss" { return .miss }
        if let value = Int(raw) { return .oneToTwenty(value) }
        return .miss
    }
}
