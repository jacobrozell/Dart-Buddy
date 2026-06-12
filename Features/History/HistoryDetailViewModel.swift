import Foundation

@MainActor
final class HistoryDetailViewModel: ObservableObject {
    @Published private(set) var header: HistoryDetailHeader?
    @Published private(set) var timeline: [String] = []
    @Published private(set) var state: String = "loading"
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var dateText = ""
    @Published private(set) var configText = ""
    @Published private(set) var standings: [HistoryStanding] = []
    @Published private(set) var throwsRows: [ThrowStatRow] = []
    @Published private(set) var breakdowns: [PlayerStatBreakdown] = []
    @Published private(set) var matchType: MatchType = .x01
    @Published private(set) var lineScore: BaseballLineScore?
    private let matchId: UUID
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

    var isX01: Bool { matchType == .x01 }
    var isBaseball: Bool { matchType == .baseball }

    var resultAccessibilitySummary: String {
        let players = standings.map { standing in
            MatchConfigText.standingAccessibility(
                name: standing.name,
                isWinner: standing.isWinner,
                score: standing.score
            )
        }.joined(separator: ". ")
        return L10n.format("history.detail.result.accessibilityFormat", dateText, configText, players)
    }

    init(
        matchId: UUID,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.matchId = matchId
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
    }

    func onAppear() async {
        errorMessageKey = nil
        do {
            guard let match = try await matchRepository.fetchMatch(matchId: matchId) else {
                timeline = []
                state = "error"
                errorMessageKey = "error.match.notFound"
                return
            }
            let participants = try await matchRepository.fetchParticipants(matchId: matchId)
            let events = try await statsRepository.fetchEvents(matchId: matchId)
            let envelopes = try events
                .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
                .sorted { $0.eventIndex < $1.eventIndex }
            let participantNames = Dictionary(
                uniqueKeysWithValues: participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) }
            )
            timeline = envelopes.map { envelope in
                switch envelope.payload {
                case let .x01Turn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return L10n.format(
                        "history.timeline.x01TurnFormat",
                        turn.turnIndex + 1,
                        name,
                        turn.appliedTotal
                    )
                case let .cricketTurn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return L10n.format(
                        "history.timeline.cricketTurnFormat",
                        turn.turnIndex + 1,
                        name,
                        turn.totalPointsAdded
                    )
                case let .baseballTurn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return L10n.format(
                        "history.timeline.baseballTurnFormat",
                        turn.inning,
                        name,
                        turn.runsThisVisit
                    )
                case let .killerPick(pick):
                    let name = participantNames[pick.playerId] ?? String(pick.playerId.uuidString.prefix(6))
                    if let number = pick.assignedNumber {
                        return L10n.format("history.timeline.killerPickFormat", name, number)
                    }
                    return L10n.format("history.timeline.killerPickRetakeFormat", name)
                case let .killerTurn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return L10n.format("history.timeline.killerTurnFormat", turn.turnIndex + 1, name)
                case let .shanghaiTurn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return L10n.format(
                        "history.timeline.shanghaiTurnFormat",
                        turn.round,
                        name,
                        turn.pointsThisVisit
                    )
                }
            }
            matchType = match.type
            header = buildHeader(match: match, participants: participants, envelopes: envelopes)
            dateText = Self.detailDateFormatter.string(from: match.startedAt)
            await computeStandingsAndThrows(
                match: match,
                participants: participants,
                envelopes: envelopes,
                participantNames: participantNames
            )
            lineScore = await buildLineScore(
                match: match,
                participants: participants,
                envelopes: envelopes
            )
            breakdowns = StatsService.breakdowns(
                from: [
                    MatchStatsInput(
                        type: match.type,
                        participantKeys: participants.map { $0.playerId ?? $0.id },
                        winnerKey: match.winnerPlayerId,
                        events: envelopes
                    )
                ],
                nameById: participantNames
            )
            state = "ready"
        } catch is CancellationError {
            return
        } catch {
            header = nil
            timeline = []
            state = "error"
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    private func buildLineScore(
        match: MatchSummary,
        participants: [MatchParticipantSummary],
        envelopes: [MatchEventEnvelope]
    ) async -> BaseballLineScore? {
        guard match.type == .baseball else { return nil }
        var scheduledInningCount = 9
        if let snapshot = try? await matchRepository.fetchLatestSnapshot(matchId: match.id),
           let runtime = try? CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshot.snapshotPayload),
           let baseball = runtime.baseballState {
            scheduledInningCount = baseball.config.inningCount
        }
        let turns = envelopes.compactMap { envelope -> BaseballTurnEvent? in
            if case let .baseballTurn(turn) = envelope.payload { return turn }
            return nil
        }
        let roster = participants.map { participant in
            (
                playerId: participant.playerId ?? participant.id,
                name: MatchConfigText.playerName(participant.displayNameAtMatchStart),
                turnOrder: participant.turnOrder
            )
        }
        return BaseballLineScoreBuilder.build(
            turns: turns,
            participants: roster,
            scheduledInningCount: scheduledInningCount
        )
    }

    private func buildHeader(
        match: MatchSummary,
        participants: [MatchParticipantSummary],
        envelopes: [MatchEventEnvelope]
    ) -> HistoryDetailHeader {
        let winnerDisplayName = participants
            .first(where: { ($0.playerId ?? $0.id) == match.winnerPlayerId })?
            .displayNameAtMatchStart ?? NSLocalizedString("common.unknown", comment: "")
        let winnerText: String = {
            if match.status == .forfeited {
                return L10n.format("history.detail.winnerForfeitFormat", winnerDisplayName)
            }
            return winnerDisplayName
        }()
        let forfeitSubtitle: String? = {
            guard match.status == .forfeited,
                  let forfeitedBy = match.forfeitedByPlayerId,
                  let name = participants.first(where: { ($0.playerId ?? $0.id) == forfeitedBy })?.displayNameAtMatchStart else {
                return nil
            }
            return L10n.format("history.detail.forfeitSubtitleFormat", name)
        }()
        let modeText = MatchConfigText.modeLabel(for: match.type)
        let dateText = DateFormatter.localizedString(from: match.startedAt, dateStyle: .medium, timeStyle: .short)
        let durationText: String = {
            guard let end = match.endedAt else { return NSLocalizedString("common.unknown", comment: "") }
            let minutes = Int(max(0, end.timeIntervalSince(match.startedAt)) / 60)
            return L10n.format("history.detail.durationFormat", minutes)
        }()
        let participantsText = participants.map(\.displayNameAtMatchStart).joined(separator: ", ")
        let modeSpecificSummaryText: String = {
            switch match.type {
            case .x01:
                let turns = envelopes.compactMap { envelope -> X01TurnEvent? in
                    if case let .x01Turn(turn) = envelope.payload { return turn }
                    return nil
                }
                let total = turns.reduce(0) { $0 + $1.appliedTotal }
                let busts = turns.filter(\.isBust).count
                return L10n.format("history.detail.x01SummaryFormat", total, busts)
            case .cricket:
                let turns = envelopes.compactMap { envelope -> CricketTurnEvent? in
                    if case let .cricketTurn(turn) = envelope.payload { return turn }
                    return nil
                }
                let points = turns.reduce(0) { $0 + $1.totalPointsAdded }
                return L10n.format("history.detail.cricketSummaryFormat", points, turns.count)
            case .baseball:
                let turns = envelopes.compactMap { envelope -> BaseballTurnEvent? in
                    if case let .baseballTurn(turn) = envelope.payload { return turn }
                    return nil
                }
                let runs = turns.reduce(0) { $0 + $1.runsThisVisit }
                return L10n.format("history.detail.baseballSummaryFormat", runs, turns.count)
            case .killer:
                let turns = envelopes.compactMap { envelope -> KillerTurnEvent? in
                    if case let .killerTurn(turn) = envelope.payload { return turn }
                    return nil
                }
                return L10n.format("history.detail.killerSummaryFormat", turns.count)
            case .shanghai:
                let turns = envelopes.compactMap { envelope -> ShanghaiTurnEvent? in
                    if case let .shanghaiTurn(turn) = envelope.payload { return turn }
                    return nil
                }
                let points = turns.reduce(0) { $0 + $1.pointsThisVisit }
                return L10n.format("history.detail.shanghaiSummaryFormat", points, turns.count)
            }
        }()
        return HistoryDetailHeader(
            modeText: modeText,
            winnerText: forfeitSubtitle.map { "\(winnerText) · \($0)" } ?? winnerText,
            dateText: dateText,
            durationText: durationText,
            participantsText: participantsText,
            modeSpecificSummaryText: modeSpecificSummaryText
        )
    }

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()

    private func computeStandingsAndThrows(
        match: MatchSummary,
        participants: [MatchParticipantSummary],
        envelopes: [MatchEventEnvelope],
        participantNames: [UUID: String]
    ) async {
        if let snapshot = try? await matchRepository.fetchLatestSnapshot(matchId: match.id),
           let runtime = try? CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshot.snapshotPayload) {
            if let s = runtime.x01State {
                configText = MatchConfigText.x01CardConfig(from: s.config)
                standings = sortStandings(s.players.map {
                    HistoryStanding(
                        id: $0.playerId,
                        name: MatchConfigText.playerName(participantNames[$0.playerId]),
                        isWinner: $0.playerId == runtime.winnerPlayerId,
                        sets: $0.setsWon,
                        legs: $0.legsWon,
                        score: $0.remainingScore
                    )
                })
            } else if let c = runtime.cricketState {
                configText = MatchConfigText.modeLabel(for: .cricket)
                standings = sortStandings(c.players.map {
                    HistoryStanding(
                        id: $0.playerId,
                        name: MatchConfigText.playerName(participantNames[$0.playerId]),
                        isWinner: $0.playerId == runtime.winnerPlayerId,
                        sets: 0,
                        legs: 0,
                        score: $0.score
                    )
                })
            } else if let b = runtime.baseballState {
                configText = MatchConfigText.modeLabel(for: .baseball)
                standings = sortStandings(b.players.map {
                    HistoryStanding(
                        id: $0.playerId,
                        name: MatchConfigText.playerName(participantNames[$0.playerId]),
                        isWinner: $0.playerId == runtime.winnerPlayerId,
                        sets: 0,
                        legs: 0,
                        score: $0.cumulativeRuns
                    )
                })
            } else if let k = runtime.killerState {
                configText = MatchConfigText.modeLabel(for: .killer)
                standings = sortStandings(k.players.map {
                    HistoryStanding(
                        id: $0.playerId,
                        name: MatchConfigText.playerName(participantNames[$0.playerId]),
                        isWinner: $0.playerId == runtime.winnerPlayerId,
                        sets: 0,
                        legs: 0,
                        score: $0.lives
                    )
                })
            } else if let s = runtime.shanghaiState {
                configText = MatchConfigText.modeLabel(for: .shanghai)
                standings = sortStandings(s.players.map {
                    HistoryStanding(
                        id: $0.playerId,
                        name: MatchConfigText.playerName(participantNames[$0.playerId]),
                        isWinner: $0.playerId == runtime.winnerPlayerId,
                        sets: 0,
                        legs: 0,
                        score: $0.cumulativePoints
                    )
                })
            }
        }

        var throwsByPlayer: [UUID: Int] = [:]
        var doublesByPlayer: [UUID: Int] = [:]
        var triplesByPlayer: [UUID: Int] = [:]
        for envelope in envelopes {
            switch envelope.payload {
            case let .x01Turn(turn):
                for dart in turn.darts {
                    throwsByPlayer[turn.playerId, default: 0] += 1
                    if dart.multiplierRaw == DartMultiplier.double.rawValue { doublesByPlayer[turn.playerId, default: 0] += 1 }
                    if dart.multiplierRaw == DartMultiplier.triple.rawValue { triplesByPlayer[turn.playerId, default: 0] += 1 }
                }
            case let .cricketTurn(turn):
                for touch in turn.targetsTouched {
                    throwsByPlayer[turn.playerId, default: 0] += 1
                    if touch.multiplierRaw == DartMultiplier.double.rawValue { doublesByPlayer[turn.playerId, default: 0] += 1 }
                    if touch.multiplierRaw == DartMultiplier.triple.rawValue { triplesByPlayer[turn.playerId, default: 0] += 1 }
                }
            case let .baseballTurn(turn):
                for dart in turn.darts {
                    throwsByPlayer[turn.playerId, default: 0] += 1
                    if dart.multiplierRaw == DartMultiplier.double.rawValue { doublesByPlayer[turn.playerId, default: 0] += 1 }
                    if dart.multiplierRaw == DartMultiplier.triple.rawValue { triplesByPlayer[turn.playerId, default: 0] += 1 }
                }
            case let .killerPick(pick):
                throwsByPlayer[pick.playerId, default: 0] += 1
                if pick.multiplierRaw == DartMultiplier.double.rawValue { doublesByPlayer[pick.playerId, default: 0] += 1 }
                if pick.multiplierRaw == DartMultiplier.triple.rawValue { triplesByPlayer[pick.playerId, default: 0] += 1 }
            case let .killerTurn(turn):
                for dart in turn.darts {
                    throwsByPlayer[turn.playerId, default: 0] += 1
                    if dart.multiplierRaw == DartMultiplier.double.rawValue { doublesByPlayer[turn.playerId, default: 0] += 1 }
                    if dart.multiplierRaw == DartMultiplier.triple.rawValue { triplesByPlayer[turn.playerId, default: 0] += 1 }
                }
            case let .shanghaiTurn(turn):
                for dart in turn.darts {
                    throwsByPlayer[turn.playerId, default: 0] += 1
                    if dart.multiplierRaw == DartMultiplier.double.rawValue { doublesByPlayer[turn.playerId, default: 0] += 1 }
                    if dart.multiplierRaw == DartMultiplier.triple.rawValue { triplesByPlayer[turn.playerId, default: 0] += 1 }
                }
            }
        }
        throwsRows = standings.map { standing in
            let total = throwsByPlayer[standing.id] ?? 0
            let doubles = doublesByPlayer[standing.id] ?? 0
            let triples = triplesByPlayer[standing.id] ?? 0
            return ThrowStatRow(
                id: standing.id,
                name: standing.name,
                throwCount: total,
                doublePercent: total > 0 ? Double(doubles) / Double(total) * 100 : 0,
                triplePercent: total > 0 ? Double(triples) / Double(total) * 100 : 0
            )
        }
    }

    func deleteMatch() async -> Bool {
        do {
            try await matchRepository.deleteMatch(matchId: matchId)
            return true
        } catch {
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
            return false
        }
    }

    private func sortStandings(_ standings: [HistoryStanding]) -> [HistoryStanding] {
        standings.sorted { lhs, rhs in
            if lhs.isWinner != rhs.isWinner { return lhs.isWinner }
            return lhs.score < rhs.score
        }
    }

    private func messageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }
}
