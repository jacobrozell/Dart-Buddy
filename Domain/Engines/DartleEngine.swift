import Foundation

// MARK: - Targets and seed

/// Targets the Dartle pool draws from: segments 1…20 + bull (any ring).
public enum DartleTarget: Codable, Equatable, Hashable, Sendable {
    case segment(Int)   // 1…20
    case bull

    public var displayValue: Int {
        switch self {
        case let .segment(n): return n
        case .bull: return 25
        }
    }

    /// Whether the given dart counts as a hit on this target. Any ring on the
    /// segment counts; inner and outer bull both satisfy `.bull`.
    public func isHit(by dart: DartInput) -> Bool {
        guard !dart.isMiss else { return false }
        switch self {
        case let .segment(n):
            guard case let .oneToTwenty(value) = dart.segment else { return false }
            return value == n
        case .bull:
            return dart.segment == .innerBull || dart.segment == .outerBull
        }
    }
}

/// A `LocalDate` value the engine can serialize without dragging a calendar
/// dependency into the domain. Always interpreted in the user's local timezone.
public struct DartlePuzzleDate: Codable, Equatable, Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year ?? 1970
        self.month = components.month ?? 1
        self.day = components.day ?? 1
    }

    /// `YYYYMMDD` form used for the seed.
    public var compactValue: Int {
        year * 10_000 + month * 100 + day
    }
}

// MARK: - Configuration

public struct MatchConfigDartle: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1
    public static let sequenceLength = 6
    public static let dartCap = 18
    public static let seedVersion = "dartle_v1"

    public let payloadVersion: Int
    public let puzzleDate: DartlePuzzleDate

    public init(
        payloadVersion: Int = currentPayloadVersion,
        puzzleDate: DartlePuzzleDate
    ) {
        self.payloadVersion = payloadVersion
        self.puzzleDate = puzzleDate
    }
}

// MARK: - State and events

public enum DartleStatus: String, Codable, Sendable {
    case inProgress
    case solved
    case dnf
}

public struct DartleCellResult: Codable, Equatable, Sendable {
    public let target: DartleTarget
    public var attempts: Int
    public var dartsToHit: Int?

    public init(target: DartleTarget, attempts: Int = 0, dartsToHit: Int? = nil) {
        self.target = target
        self.attempts = attempts
        self.dartsToHit = dartsToHit
    }

    public var isSolved: Bool { dartsToHit != nil }
}

public struct DartleDartEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let dartIndex: Int
    public let targetCellIndex: Int
    public let target: DartleTarget
    public let wasHit: Bool
    public let dartsUsedAfter: Int
    public let currentIndexAfter: Int
    public let status: DartleStatus
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        dartIndex: Int,
        targetCellIndex: Int,
        target: DartleTarget,
        wasHit: Bool,
        dartsUsedAfter: Int,
        currentIndexAfter: Int,
        status: DartleStatus,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.dartIndex = dartIndex
        self.targetCellIndex = targetCellIndex
        self.target = target
        self.wasHit = wasHit
        self.dartsUsedAfter = dartsUsedAfter
        self.currentIndexAfter = currentIndexAfter
        self.status = status
        self.timestamp = timestamp
    }
}

public struct DartleState: Codable, Equatable, Sendable {
    public let config: MatchConfigDartle
    public let playerId: UUID
    public let sequence: [DartleTarget]
    public var currentIndex: Int
    public var dartsUsed: Int
    public var cells: [DartleCellResult]
    public var status: DartleStatus

    public var currentTarget: DartleTarget? {
        guard currentIndex < sequence.count else { return nil }
        return sequence[currentIndex]
    }

    public var dartsRemaining: Int {
        max(0, MatchConfigDartle.dartCap - dartsUsed)
    }

    public init(
        config: MatchConfigDartle,
        playerId: UUID,
        sequence: [DartleTarget],
        currentIndex: Int = 0,
        dartsUsed: Int = 0,
        cells: [DartleCellResult]? = nil,
        status: DartleStatus = .inProgress
    ) {
        self.config = config
        self.playerId = playerId
        self.sequence = sequence
        self.currentIndex = currentIndex
        self.dartsUsed = dartsUsed
        self.cells = cells ?? sequence.map { DartleCellResult(target: $0) }
        self.status = status
    }
}

public struct DartleDartOutcome: Sendable {
    public let updatedState: DartleState
    public let event: DartleDartEvent
}

// MARK: - Engine

public enum DartleEngine {

    /// The full pool of pickable targets for the daily puzzle.
    public static let pool: [DartleTarget] = (1 ... 20).map { .segment($0) } + [.bull]

    public static func makeInitialState(
        config: MatchConfigDartle,
        playerIds: [UUID]
    ) throws -> DartleState {
        guard playerIds.count == 1 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.dartleSoloOnly"
            )
        }
        let sequence = generateSequence(for: config.puzzleDate)
        return DartleState(config: config, playerId: playerIds[0], sequence: sequence)
    }

    /// Submit a single dart. Dartle is dart-at-a-time rather than visit-at-a-time
    /// — the grid UI marks each attempt immediately.
    public static func submitDart(
        state: DartleState,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> DartleDartOutcome {
        guard state.status == .inProgress else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard let target = state.currentTarget else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }

        var updated = state
        let cellIndex = updated.currentIndex
        let wasHit = target.isHit(by: dart)

        updated.dartsUsed += 1
        updated.cells[cellIndex].attempts += 1

        if wasHit {
            updated.cells[cellIndex].dartsToHit = updated.cells[cellIndex].attempts
            updated.currentIndex += 1
        }

        if updated.currentIndex >= updated.sequence.count {
            updated.status = .solved
        } else if updated.dartsUsed >= MatchConfigDartle.dartCap {
            updated.status = .dnf
        }

        let event = DartleDartEvent(
            playerId: state.playerId,
            dartIndex: state.dartsUsed,
            targetCellIndex: cellIndex,
            target: target,
            wasHit: wasHit,
            dartsUsedAfter: updated.dartsUsed,
            currentIndexAfter: updated.currentIndex,
            status: updated.status,
            timestamp: timestamp
        )
        return DartleDartOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigDartle,
        playerIds: [UUID],
        events: [DartleDartEvent]
    ) throws -> DartleState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            state.cells[event.targetCellIndex].attempts += 1
            if event.wasHit {
                state.cells[event.targetCellIndex].dartsToHit = state.cells[event.targetCellIndex].attempts
            }
            state.dartsUsed = event.dartsUsedAfter
            state.currentIndex = event.currentIndexAfter
            state.status = event.status
        }
        return state
    }

    // MARK: - Sequence generation

    /// Generates the 6-target sequence for a given puzzle date. The result is
    /// deterministic across processes and devices so all players see the same
    /// puzzle on the same calendar day.
    public static func generateSequence(for date: DartlePuzzleDate) -> [DartleTarget] {
        let seed = seedValue(for: date)
        var rng = SplitMix64(state: seed)
        var bag = pool
        var result: [DartleTarget] = []
        result.reserveCapacity(MatchConfigDartle.sequenceLength)
        for _ in 0 ..< MatchConfigDartle.sequenceLength {
            let pick = Int(rng.next() % UInt64(bag.count))
            result.append(bag.remove(at: pick))
        }
        return result
    }

    /// Stable seed derived from the date and the spec's seed version tag. Uses
    /// FNV-1a so the value does not depend on Swift's per-process `Hasher` salt.
    static func seedValue(for date: DartlePuzzleDate) -> UInt64 {
        let payload = "\(date.compactValue)\(MatchConfigDartle.seedVersion)"
        return fnv1a64(payload)
    }

    static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001B3
        }
        return hash
    }
}

// MARK: - Deterministic PRNG

/// Pure-Swift SplitMix64 used to draw the Dartle sequence. Public so callers
/// (and tests) can seed reproducible runs without depending on the system RNG.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    public var state: UInt64

    public init(state: UInt64) {
        self.state = state
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
