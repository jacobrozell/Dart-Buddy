import Foundation

// MARK: - Colours

public enum SnookerColour: String, Codable, CaseIterable, Sendable {
    case yellow  // 16 — 2 points
    case green   // 17 — 3
    case brown   // 18 — 4
    case blue    // 19 — 5
    case pink    // 20 — 6
    case black   // bull — 7

    public var points: Int {
        switch self {
        case .yellow: return 2
        case .green: return 3
        case .brown: return 4
        case .blue: return 5
        case .pink: return 6
        case .black: return 7
        }
    }

    /// Whether the dart pots this colour. Any ring on the assigned segment
    /// counts; black is any bull (inner or outer).
    public func isHit(by dart: DartInput) -> Bool {
        guard !dart.isMiss else { return false }
        switch self {
        case .yellow:
            if case let .oneToTwenty(value) = dart.segment, value == 16 { return true }
            return false
        case .green:
            if case let .oneToTwenty(value) = dart.segment, value == 17 { return true }
            return false
        case .brown:
            if case let .oneToTwenty(value) = dart.segment, value == 18 { return true }
            return false
        case .blue:
            if case let .oneToTwenty(value) = dart.segment, value == 19 { return true }
            return false
        case .pink:
            if case let .oneToTwenty(value) = dart.segment, value == 20 { return true }
            return false
        case .black:
            return dart.segment == .innerBull || dart.segment == .outerBull
        }
    }
}

// MARK: - Config

public struct MatchConfigSnooker: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1
    public static let redsCount = 15

    public let payloadVersion: Int

    public init(payloadVersion: Int = currentPayloadVersion) {
        self.payloadVersion = payloadVersion
    }
}

// MARK: - State

public enum SnookerPhase: Codable, Equatable, Sendable {
    /// Breaker must pot a red segment (1…15).
    case awaitingRed
    /// Red was potted; breaker must nominate a colour next.
    case awaitingNomination
    /// Nominated colour; breaker must pot it.
    case awaitingColour(SnookerColour)
}

public struct SnookerPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var frameScore: Int
    public var highestBreak: Int

    public init(playerId: UUID, frameScore: Int = 0, highestBreak: Int = 0) {
        self.playerId = playerId
        self.frameScore = frameScore
        self.highestBreak = highestBreak
    }
}

public struct SnookerDartEvent: Codable, Equatable, Identifiable, Sendable {
    public enum BallType: String, Codable, Sendable {
        case red
        case colour
    }

    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let ballType: BallType
    public let nominatedColourRaw: String?
    public let segmentPocketed: Int?
    public let points: Int
    public let breakEnded: Bool
    public let frameCompleted: Bool
    public let scoreAfter: Int
    public let timestamp: Date

    public var nominatedColour: SnookerColour? {
        nominatedColourRaw.flatMap(SnookerColour.init(rawValue:))
    }

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        ballType: BallType,
        nominatedColour: SnookerColour?,
        segmentPocketed: Int?,
        points: Int,
        breakEnded: Bool,
        frameCompleted: Bool,
        scoreAfter: Int,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.ballType = ballType
        self.nominatedColourRaw = nominatedColour?.rawValue
        self.segmentPocketed = segmentPocketed
        self.points = points
        self.breakEnded = breakEnded
        self.frameCompleted = frameCompleted
        self.scoreAfter = scoreAfter
        self.timestamp = timestamp
    }
}

public struct SnookerState: Codable, Equatable, Sendable {
    public let config: MatchConfigSnooker
    public var players: [SnookerPlayerState]
    public var currentBreakerIndex: Int
    public var availableReds: Set<Int>
    public var phase: SnookerPhase
    public var currentBreakPoints: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public var currentBreakerId: UUID { players[currentBreakerIndex].playerId }

    public init(
        config: MatchConfigSnooker,
        players: [SnookerPlayerState],
        currentBreakerIndex: Int = 0,
        availableReds: Set<Int>? = nil,
        phase: SnookerPhase = .awaitingRed,
        currentBreakPoints: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentBreakerIndex = currentBreakerIndex
        self.availableReds = availableReds ?? Set(1 ... MatchConfigSnooker.redsCount)
        self.phase = phase
        self.currentBreakPoints = currentBreakPoints
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct SnookerDartOutcome: Sendable {
    public let updatedState: SnookerState
    public let event: SnookerDartEvent
}

// MARK: - Engine

public enum SnookerEngine {

    public static func makeInitialState(
        config: MatchConfigSnooker,
        playerIds: [UUID]
    ) throws -> SnookerState {
        guard playerIds.count == 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.snookerExactTwoPlayers"
            )
        }
        let players = playerIds.map { SnookerPlayerState(playerId: $0) }
        return SnookerState(config: config, players: players)
    }

    /// Nominate the colour to throw at after a red has been potted.
    public static func nominateColour(
        state: SnookerState,
        colour: SnookerColour
    ) throws -> SnookerState {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard case .awaitingNomination = state.phase else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.snooker.nominateOutOfPhase"
            )
        }
        var updated = state
        updated.phase = .awaitingColour(colour)
        return updated
    }

    /// Submit a single dart. Behavior depends on the current phase.
    public static func submitDart(
        state: SnookerState,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> SnookerDartOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        switch state.phase {
        case .awaitingRed:
            return try submitRedDart(state: state, dart: dart, timestamp: timestamp)
        case .awaitingNomination:
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.snooker.mustNominate"
            )
        case let .awaitingColour(colour):
            return try submitColourDart(state: state, dart: dart, colour: colour, timestamp: timestamp)
        }
    }

    private static func submitRedDart(
        state: SnookerState,
        dart: DartInput,
        timestamp: Date
    ) throws -> SnookerDartOutcome {
        var updated = state
        let playerId = state.currentBreakerId
        let potted = redPocketed(by: dart, available: state.availableReds)

        if let pottedSegment = potted {
            updated.availableReds.remove(pottedSegment)
            updated.currentBreakPoints += 1
            updated.players[state.currentBreakerIndex].frameScore += 1
            updated.phase = .awaitingNomination
            let scoreAfter = updated.players[state.currentBreakerIndex].frameScore
            let event = SnookerDartEvent(
                playerId: playerId,
                ballType: .red,
                nominatedColour: nil,
                segmentPocketed: pottedSegment,
                points: 1,
                breakEnded: false,
                frameCompleted: false,
                scoreAfter: scoreAfter,
                timestamp: timestamp
            )
            return SnookerDartOutcome(updatedState: updated, event: event)
        }

        // Missed the red — break ends.
        recordBreakHighlight(&updated, breakerIndex: state.currentBreakerIndex)
        let frameCompleted = endBreak(&updated)
        let event = SnookerDartEvent(
            playerId: playerId,
            ballType: .red,
            nominatedColour: nil,
            segmentPocketed: nil,
            points: 0,
            breakEnded: true,
            frameCompleted: frameCompleted,
            scoreAfter: updated.players[state.currentBreakerIndex].frameScore,
            timestamp: timestamp
        )
        return SnookerDartOutcome(updatedState: updated, event: event)
    }

    private static func submitColourDart(
        state: SnookerState,
        dart: DartInput,
        colour: SnookerColour,
        timestamp: Date
    ) throws -> SnookerDartOutcome {
        var updated = state
        let playerId = state.currentBreakerId
        let isHit = colour.isHit(by: dart)

        if isHit {
            updated.currentBreakPoints += colour.points
            updated.players[state.currentBreakerIndex].frameScore += colour.points
            // Colours respot; reds may now be empty → next is awaitingRed which
            // immediately ends the frame if no reds remain.
            updated.phase = .awaitingRed
            var frameCompleted = false
            if updated.availableReds.isEmpty {
                recordBreakHighlight(&updated, breakerIndex: state.currentBreakerIndex)
                frameCompleted = endFrame(&updated)
            }
            let event = SnookerDartEvent(
                playerId: playerId,
                ballType: .colour,
                nominatedColour: colour,
                segmentPocketed: colour == .black ? 25 : 16 + SnookerColour.allCases.firstIndex(of: colour)!,
                points: colour.points,
                breakEnded: frameCompleted,  // break implicitly ends with the frame
                frameCompleted: frameCompleted,
                scoreAfter: updated.players[state.currentBreakerIndex].frameScore,
                timestamp: timestamp
            )
            return SnookerDartOutcome(updatedState: updated, event: event)
        }

        // Missed the colour — break ends.
        recordBreakHighlight(&updated, breakerIndex: state.currentBreakerIndex)
        let frameCompleted = endBreak(&updated)
        let event = SnookerDartEvent(
            playerId: playerId,
            ballType: .colour,
            nominatedColour: colour,
            segmentPocketed: nil,
            points: 0,
            breakEnded: true,
            frameCompleted: frameCompleted,
            scoreAfter: updated.players[state.currentBreakerIndex].frameScore,
            timestamp: timestamp
        )
        return SnookerDartOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigSnooker,
        playerIds: [UUID],
        events: [SnookerDartEvent]
    ) throws -> SnookerState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            try applyEvent(&state, event: event)
        }
        return state
    }

    private static func applyEvent(_ state: inout SnookerState, event: SnookerDartEvent) throws {
        guard let breakerIndex = state.players.firstIndex(where: { $0.playerId == event.playerId }) else {
            return
        }
        switch event.ballType {
        case .red:
            if let segment = event.segmentPocketed {
                state.availableReds.remove(segment)
                state.currentBreakPoints += 1
                state.players[breakerIndex].frameScore += 1
                state.phase = .awaitingNomination
            } else {
                recordBreakHighlight(&state, breakerIndex: breakerIndex)
                if event.frameCompleted {
                    _ = endFrame(&state)
                } else {
                    _ = endBreak(&state)
                }
            }
        case .colour:
            if let colour = event.nominatedColour {
                if event.points > 0 {
                    state.currentBreakPoints += colour.points
                    state.players[breakerIndex].frameScore += colour.points
                    state.phase = .awaitingRed
                    if event.frameCompleted {
                        recordBreakHighlight(&state, breakerIndex: breakerIndex)
                        _ = endFrame(&state)
                    }
                } else {
                    recordBreakHighlight(&state, breakerIndex: breakerIndex)
                    if event.frameCompleted {
                        _ = endFrame(&state)
                    } else {
                        _ = endBreak(&state)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns the segment number of the red potted by this dart, or `nil` if
    /// no red was potted. Any multiplier on segment 1…15 pots if it is still
    /// on the table.
    static func redPocketed(by dart: DartInput, available: Set<Int>) -> Int? {
        guard !dart.isMiss else { return nil }
        guard case let .oneToTwenty(value) = dart.segment else { return nil }
        guard (1 ... 15).contains(value), available.contains(value) else { return nil }
        return value
    }

    private static func recordBreakHighlight(_ state: inout SnookerState, breakerIndex: Int) {
        let current = state.currentBreakPoints
        if current > state.players[breakerIndex].highestBreak {
            state.players[breakerIndex].highestBreak = current
        }
    }

    /// Ends the current break and rotates. Returns whether the frame ended as a
    /// result (no reds remain when the next breaker would start).
    private static func endBreak(_ state: inout SnookerState) -> Bool {
        state.currentBreakPoints = 0
        state.currentBreakerIndex = (state.currentBreakerIndex + 1) % state.players.count
        state.phase = .awaitingRed
        if state.availableReds.isEmpty {
            return endFrame(&state)
        }
        return false
    }

    private static func endFrame(_ state: inout SnookerState) -> Bool {
        state.isComplete = true
        state.currentBreakPoints = 0
        let sorted = state.players.sorted { $0.frameScore > $1.frameScore }
        if sorted.count >= 2, sorted[0].frameScore > sorted[1].frameScore {
            state.winnerPlayerId = sorted[0].playerId
        } else {
            state.winnerPlayerId = nil  // tie
        }
        return true
    }
}
