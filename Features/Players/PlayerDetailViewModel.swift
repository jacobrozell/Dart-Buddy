import Foundation

@MainActor
final class PlayerDetailViewModel: ObservableObject {
    @Published private(set) var x01: PlayerStatBreakdown?
    @Published private(set) var cricket: PlayerStatBreakdown?
    @Published private(set) var x01TrendPoints: [StatsTrendPoint] = []
    @Published private(set) var recentMatches: [RecentMatchSummary] = []
    @Published private(set) var lastPlayedAt: Date?
    @Published private(set) var isLoading = true
    @Published private(set) var trainingBot: PlayerSummary?
    @Published private(set) var x01Eligibility = TrainingBotEligibility(isEligible: false, gamesPlayed: 0, mode: .x01)
    @Published private(set) var cricketEligibility = TrainingBotEligibility(isEligible: false, gamesPlayed: 0, mode: .cricket)
    @Published private(set) var isCreatingTrainingBot = false
    @Published var trainingBotErrorKey: String?
    @Published private(set) var isExporting = false

    private let playerId: UUID
    private let playerName: String
    private let playerRepository: any PlayerRepository
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

    init(
        playerId: UUID,
        playerName: String,
        playerRepository: any PlayerRepository,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.playerId = playerId
        self.playerName = playerName
        self.playerRepository = playerRepository
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
    }

    var hasAnyGames: Bool {
        (x01?.games ?? 0) + (cricket?.games ?? 0) > 0
    }

    var lastPlayedText: String? {
        guard let lastPlayedAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return L10n.format("players.detail.lastPlayed", formatter.localizedString(for: lastPlayedAt, relativeTo: Date()))
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let x01Result = MatchStatsLoader.load(
                matchRepository: matchRepository,
                statsRepository: statsRepository,
                request: MatchStatsLoadRequest(matchType: .x01, participantPlayerId: playerId)
            )
            async let cricketResult = MatchStatsLoader.load(
                matchRepository: matchRepository,
                statsRepository: statsRepository,
                request: MatchStatsLoadRequest(matchType: .cricket, participantPlayerId: playerId)
            )
            async let recent = MatchStatsLoader.recentMatches(for: playerId, matchRepository: matchRepository)

            let names = [playerId: playerName]
            let loadedX01 = try await x01Result
            let loadedCricket = try await cricketResult
            x01 = StatsService.breakdowns(from: loadedX01.inputs, nameById: names).first { $0.playerId == playerId }
            x01TrendPoints = StatsService.x01TrendPoints(from: loadedX01.inputs, playerId: playerId)
            cricket = StatsService.breakdowns(from: loadedCricket.inputs, nameById: names).first { $0.playerId == playerId }
            recentMatches = try await recent
            lastPlayedAt = recentMatches.first?.playedAt
            trainingBot = try await playerRepository.fetchTrainingBot(linkedTo: playerId)
            if let x01 {
                x01Eligibility = TrainingBotEligibilityService.eligibility(breakdown: x01, mode: .x01)
            }
            if let cricket {
                cricketEligibility = TrainingBotEligibilityService.eligibility(breakdown: cricket, mode: .cricket)
            }
        } catch {
            x01 = nil
            x01TrendPoints = []
            cricket = nil
            recentMatches = []
            lastPlayedAt = nil
        }
    }

    func createTrainingBot() async {
        guard trainingBot == nil, !isCreatingTrainingBot else { return }
        isCreatingTrainingBot = true
        trainingBotErrorKey = nil
        defer { isCreatingTrainingBot = false }
        do {
            trainingBot = try await playerRepository.createTrainingBot(for: playerId)
        } catch {
            trainingBotErrorKey = (error as? AppError)?.userMessageKey ?? "error.repository.storage"
        }
    }

    func calibratedSummary(for mode: MatchType) -> String? {
        let breakdown = mode == .x01 ? x01 : cricket
        guard let breakdown else { return nil }
        let profile = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: mode)
        if mode == .x01 {
            let avg = Double(profile.x01.scoringVisitMin + profile.x01.scoringVisitMax) / 2.0
            return L10n.format("trainingBot.calibrated.x01Format", avg)
        }
        let mpr = (profile.cricket.hitChances.triple + profile.cricket.hitChances.double) * 2.0
        return L10n.format("trainingBot.calibrated.cricketFormat", mpr)
    }

    func exportBundle(playerName: String) async throws -> URL {
        guard !isExporting else {
            throw AppError(
                code: .conflict,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "players.detail.export.error",
                debugContext: ["reason": "exportInProgress"]
            )
        }
        isExporting = true
        defer { isExporting = false }
        return try await PlayerExportService.exportFile(
            anchorPlayerId: playerId,
            playerName: playerName,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            playerRepository: playerRepository
        )
    }
}
