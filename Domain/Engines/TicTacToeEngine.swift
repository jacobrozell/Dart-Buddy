import Foundation

// MARK: - Cell target

/// A single grid cell on the Tic-Tac-Toe dartboard layout. The cell describes
/// what kind of dart claims it; the grid is fixed at setup.
public enum TicTacToeCellTarget: Codable, Equatable, Hashable, Sendable {
    /// 50-point inner bull only.
    case innerBull
    /// 25-point outer bull only.
    case outerBull
    /// Either bull ring (treats inner and outer as the same cell).
    case anyBull
    /// Single (small or large) on the given segment 1…20.
    case single(Int)
    /// Double on the given segment 1…20.
    case double(Int)
    /// Triple on the given segment 1…20.
    case triple(Int)
    /// Any hit on the segment regardless of multiplier (useful for novice handicaps).
    case anySegment(Int)

    /// Whether the given dart claims this cell.
    func matches(_ dart: DartInput) -> Bool {
        guard !dart.isMiss else { return false }
        switch self {
        case .innerBull:
            return dart.segment == .innerBull
        case .outerBull:
            return dart.segment == .outerBull
        case .anyBull:
            return dart.segment == .innerBull || dart.segment == .outerBull
        case let .single(n):
            guard case let .oneToTwenty(value) = dart.segment else { return false }
            return value == n && dart.multiplier == .single
        case let .double(n):
            guard case let .oneToTwenty(value) = dart.segment else { return false }
            return value == n && dart.multiplier == .double
        case let .triple(n):
            guard case let .oneToTwenty(value) = dart.segment else { return false }
            return value == n && dart.multiplier == .triple
        case let .anySegment(n):
            guard case let .oneToTwenty(value) = dart.segment else { return false }
            return value == n
        }
    }
}

// MARK: - Sides and config

public enum TicTacToeSide: String, Codable, CaseIterable, Sendable {
    case x
    case o
}

/// Difficulty preset chosen at setup. Selects the cell layout; both sides play
/// the same grid (v1 — asymmetric handicaps land in a later version).
public enum TicTacToeHandicapPreset: String, Codable, CaseIterable, Sendable {
    case balanced
    case novice
    case expert

    public var cells: [TicTacToeCellTarget] {
        switch self {
        case .balanced:
            return [
                .triple(20), .single(14), .double(2),
                .triple(16), .anyBull,    .triple(18),
                .double(5),  .single(11), .triple(19),
            ]
        case .novice:
            return [
                .anySegment(20), .anySegment(14), .anySegment(2),
                .anySegment(16), .anyBull,        .anySegment(18),
                .anySegment(5),  .anySegment(11), .anySegment(19),
            ]
        case .expert:
            return [
                .triple(20), .double(14), .double(2),
                .triple(16), .innerBull,  .triple(18),
                .double(5),  .double(11), .triple(19),
            ]
        }
    }
}

/// Serialisable configuration for a Tic-Tac-Toe match.
public struct MatchConfigTicTacToe: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1
    public static let gridSize = 9

    public let payloadVersion: Int
    public let presetRaw: String
    public let cells: [TicTacToeCellTarget]

    public var preset: TicTacToeHandicapPreset {
        TicTacToeHandicapPreset(rawValue: presetRaw) ?? .balanced
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        preset: TicTacToeHandicapPreset = .balanced
    ) {
        self.payloadVersion = payloadVersion
        self.presetRaw = preset.rawValue
        self.cells = preset.cells
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        cells: [TicTacToeCellTarget]
    ) {
        precondition(cells.count == Self.gridSize, "Tic-Tac-Toe grid must contain 9 cells")
        self.payloadVersion = payloadVersion
        self.presetRaw = TicTacToeHandicapPreset.balanced.rawValue
        self.cells = cells
    }
}

// MARK: - Events and state

/// Per-dart claim record within a visit.
public struct TicTacToeClaim: Codable, Equatable, Hashable, Sendable {
    public let cellIndex: Int
    public let side: TicTacToeSide

    public init(cellIndex: Int, side: TicTacToeSide) {
        self.cellIndex = cellIndex
        self.side = side
    }
}

/// Immutable record of one visit in a Tic-Tac-Toe match.
public struct TicTacToeVisitEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let side: TicTacToeSide
    public let visitIndex: Int
    public let claimsThisVisit: [TicTacToeClaim]
    public let gridSnapshot: [TicTacToeSide?]
    public let matchCompleted: Bool
    /// Winning line of cell indices if this visit produced a win.
    public let winningLine: [Int]?
    /// `true` when the visit completed the match with a draw.
    public let isDraw: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        side: TicTacToeSide,
        visitIndex: Int,
        claimsThisVisit: [TicTacToeClaim],
        gridSnapshot: [TicTacToeSide?],
        matchCompleted: Bool,
        winningLine: [Int]?,
        isDraw: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.side = side
        self.visitIndex = visitIndex
        self.claimsThisVisit = claimsThisVisit
        self.gridSnapshot = gridSnapshot
        self.matchCompleted = matchCompleted
        self.winningLine = winningLine
        self.isDraw = isDraw
        self.timestamp = timestamp
    }
}

/// Per-player state.
public struct TicTacToePlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public let side: TicTacToeSide

    public init(playerId: UUID, side: TicTacToeSide) {
        self.playerId = playerId
        self.side = side
    }
}

/// Complete mutable state for a Tic-Tac-Toe match.
public struct TicTacToeState: Codable, Equatable, Sendable {
    public let config: MatchConfigTicTacToe
    public var players: [TicTacToePlayerState]
    public var grid: [TicTacToeSide?]
    public var currentPlayerIndex: Int
    public var visitIndex: Int
    public var winnerPlayerId: UUID?
    public var winningLine: [Int]?
    public var isComplete: Bool
    public var isDraw: Bool

    public var currentSide: TicTacToeSide { players[currentPlayerIndex].side }

    public init(
        config: MatchConfigTicTacToe,
        players: [TicTacToePlayerState],
        grid: [TicTacToeSide?]? = nil,
        currentPlayerIndex: Int = 0,
        visitIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        winningLine: [Int]? = nil,
        isComplete: Bool = false,
        isDraw: Bool = false
    ) {
        self.config = config
        self.players = players
        self.grid = grid ?? Array(repeating: nil, count: MatchConfigTicTacToe.gridSize)
        self.currentPlayerIndex = currentPlayerIndex
        self.visitIndex = visitIndex
        self.winnerPlayerId = winnerPlayerId
        self.winningLine = winningLine
        self.isComplete = isComplete
        self.isDraw = isDraw
    }
}

public struct TicTacToeTurnOutcome: Sendable {
    public let updatedState: TicTacToeState
    public let event: TicTacToeVisitEvent
}

// MARK: - Engine

public enum TicTacToeEngine {

    /// The eight winning lines on a 3×3 grid.
    public static let winningLines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],   // rows
        [0, 3, 6], [1, 4, 7], [2, 5, 8],   // cols
        [0, 4, 8], [2, 4, 6],              // diagonals
    ]

    public static func makeInitialState(
        config: MatchConfigTicTacToe,
        playerIds: [UUID]
    ) throws -> TicTacToeState {
        guard playerIds.count == 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.ticTacToeExactTwoPlayers"
            )
        }
        let players = [
            TicTacToePlayerState(playerId: playerIds[0], side: .x),
            TicTacToePlayerState(playerId: playerIds[1], side: .o),
        ]
        return TicTacToeState(config: config, players: players)
    }

    public static func submitTurn(
        state: TicTacToeState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> TicTacToeTurnOutcome {
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
        let playerIndex = state.currentPlayerIndex
        let player = state.players[playerIndex]
        var claims: [TicTacToeClaim] = []
        var winningLine: [Int]?

        for dart in darts {
            // Each dart claims the first unclaimed cell it matches. A cell is
            // either open or held by a side; already-claimed cells are skipped.
            guard let cellIndex = firstMatchingOpenCell(for: dart, state: updated) else {
                continue
            }
            updated.grid[cellIndex] = player.side
            claims.append(TicTacToeClaim(cellIndex: cellIndex, side: player.side))
            if let line = winningLineForSide(player.side, grid: updated.grid) {
                winningLine = line
                updated.winnerPlayerId = player.playerId
                updated.winningLine = line
                updated.isComplete = true
                break
            }
        }

        let isDraw: Bool = {
            guard !updated.isComplete else { return false }
            return updated.grid.allSatisfy { $0 != nil }
        }()
        if isDraw {
            updated.isComplete = true
            updated.isDraw = true
        }

        updated.visitIndex += 1
        if !updated.isComplete {
            updated.currentPlayerIndex = (playerIndex + 1) % updated.players.count
        }

        let event = TicTacToeVisitEvent(
            playerId: player.playerId,
            side: player.side,
            visitIndex: state.visitIndex,
            claimsThisVisit: claims,
            gridSnapshot: updated.grid,
            matchCompleted: updated.isComplete,
            winningLine: winningLine,
            isDraw: isDraw,
            timestamp: timestamp
        )
        return TicTacToeTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigTicTacToe,
        playerIds: [UUID],
        events: [TicTacToeVisitEvent]
    ) throws -> TicTacToeState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            state.grid = event.gridSnapshot
            state.visitIndex += 1
            if event.matchCompleted {
                state.isComplete = true
                state.isDraw = event.isDraw
                state.winningLine = event.winningLine
                if !event.isDraw,
                   let winnerIndex = state.players.firstIndex(where: { $0.playerId == event.playerId }) {
                    state.winnerPlayerId = event.playerId
                    state.currentPlayerIndex = winnerIndex
                }
            } else {
                state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.players.count
            }
        }
        return state
    }

    // MARK: - Helpers

    /// Returns the index of the first open cell whose target the dart matches,
    /// or `nil` if no open cell matches.
    static func firstMatchingOpenCell(for dart: DartInput, state: TicTacToeState) -> Int? {
        for (index, cell) in state.config.cells.enumerated() {
            guard state.grid[index] == nil else { continue }
            if cell.matches(dart) { return index }
        }
        return nil
    }

    /// Returns the winning line for `side` on `grid`, or `nil` if none.
    static func winningLineForSide(_ side: TicTacToeSide, grid: [TicTacToeSide?]) -> [Int]? {
        for line in winningLines {
            if line.allSatisfy({ grid[$0] == side }) { return line }
        }
        return nil
    }
}
