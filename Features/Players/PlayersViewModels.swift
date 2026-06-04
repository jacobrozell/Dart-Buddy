import Foundation

struct EditablePlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var isArchived: Bool
    var notes: String
    var isBot: Bool
    var isTrainingBot: Bool
    var isCustomBot: Bool
    var customX01Average: Double
    var customCricketMPR: Double
    var linkedPlayerId: UUID?
    var botDifficulty: BotDifficulty?
    var avatarStyle: PlayerAvatarStyle
    var colorToken: PlayerColorToken

    static func from(_ summary: PlayerSummary) -> EditablePlayer {
        EditablePlayer(
            id: summary.id,
            name: summary.name,
            isArchived: summary.isArchived,
            notes: summary.notes ?? "",
            isBot: summary.isBot,
            isTrainingBot: summary.isTrainingBot,
            isCustomBot: summary.isCustomBot,
            customX01Average: summary.customBotMetrics?.x01Average ?? CustomBotMetrics.defaultX01Average,
            customCricketMPR: summary.customBotMetrics?.cricketMPR ?? CustomBotMetrics.defaultCricketMPR,
            linkedPlayerId: summary.linkedPlayerId,
            botDifficulty: summary.botDifficulty,
            avatarStyle: summary.avatarStyle,
            colorToken: summary.colorToken
        )
    }
}

@MainActor
final class PlayersListViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case ready
        case empty
        case searchNoResults
        case error
    }

    @Published var searchText = ""
    @Published private(set) var players: [EditablePlayer] = []
    @Published private(set) var filteredHumans: [EditablePlayer] = []
    @Published private(set) var filteredBots: [EditablePlayer] = []
    @Published private(set) var state: State = .loading
    @Published private(set) var errorMessageKey: String?

    private let repository: any PlayerRepository
    private let matchRepository: any MatchRepository
    private let pendingMatchPlayerSelections: PendingMatchPlayerSelections
    @Published private(set) var summariesByPlayerId: [UUID: PlayerListSummary] = [:]

    init(
        repository: any PlayerRepository,
        matchRepository: any MatchRepository,
        pendingMatchPlayerSelections: PendingMatchPlayerSelections
    ) {
        self.repository = repository
        self.matchRepository = matchRepository
        self.pendingMatchPlayerSelections = pendingMatchPlayerSelections
    }

    func summary(for playerId: UUID) -> PlayerListSummary? {
        summariesByPlayerId[playerId]
    }

    func onAppear() async {
        errorMessageKey = nil
        do {
            let loaded = try await repository.fetchPlayers(includeArchived: true)
            players = loaded.map(EditablePlayer.from)
            summariesByPlayerId = try await MatchStatsLoader.buildPlayerSummaries(matchRepository: matchRepository)
            applySearch()
            state = players.isEmpty ? .empty : .ready
        } catch is CancellationError {
            return
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func applySearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matched: [EditablePlayer]
        if query.isEmpty {
            matched = players
        } else {
            matched = players.filter { $0.name.lowercased().contains(query) }
        }
        filteredHumans = matched
            .filter { !$0.isBot }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        filteredBots = matched
            .filter(\.isBot)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        if players.isEmpty {
            state = .empty
        } else if matched.isEmpty {
            state = .searchNoResults
        } else {
            state = .ready
        }
    }

    func createBot(_ difficulty: BotDifficulty) async {
        do {
            _ = try await repository.createBot(difficulty: difficulty)
            await onAppear()
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func createCustomBot(name: String, metrics: CustomBotMetrics) async {
        do {
            _ = try await repository.createCustomBot(name: name, metrics: metrics)
            await onAppear()
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func archiveToggle(_ id: UUID) async {
        guard let idx = players.firstIndex(where: { $0.id == id }) else { return }
        let nextArchived = !players[idx].isArchived
        do {
            if nextArchived {
                try await repository.archivePlayer(playerId: id)
            } else {
                try await repository.unarchivePlayer(playerId: id)
            }
            players[idx].isArchived = nextArchived
            applySearch()
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func delete(_ id: UUID) async -> Bool {
        guard let idx = players.firstIndex(where: { $0.id == id }) else { return false }
        do {
            try await repository.deletePlayer(playerId: id)
            players.remove(at: idx)
            applySearch()
            return true
        } catch {
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
            return false
        }
    }

    func save(_ player: EditablePlayer) async {
        do {
            if players.contains(where: { $0.id == player.id }) {
                _ = try await repository.updatePlayerProfile(
                    playerId: player.id,
                    name: player.name,
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    notes: player.notes
                )
                if player.isCustomBot {
                    _ = try await repository.updateCustomBotMetrics(
                        playerId: player.id,
                        metrics: CustomBotMetrics(
                            x01Average: player.customX01Average,
                            cricketMPR: player.customCricketMPR
                        )
                    )
                }
            } else {
                let created = try await repository.createPlayer(name: player.name)
                _ = try await repository.updatePlayerProfile(
                    playerId: created.id,
                    name: player.name,
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    notes: player.notes
                )
                pendingMatchPlayerSelections.enqueueForNextMatchSetup(created.id)
            }
            await onAppear()
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func player(id: UUID) -> EditablePlayer? {
        players.first(where: { $0.id == id })
    }

    private func messageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }
}

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
}

@MainActor
final class PlayerEditViewModel: ObservableObject {
    @Published var name = ""
    @Published var notes = ""
    @Published var avatarStyle: PlayerAvatarStyle = .dart
    @Published var colorToken: PlayerColorToken = .green
    @Published private(set) var validationMessage: String?
    @Published private(set) var canSave = false

    let isBot: Bool
    private let existingNames: [String]
    private let editingId: UUID?
    private let originalNormalizedName: String?

    init(existingNames: [String], editing: EditablePlayer?) {
        self.existingNames = existingNames
        self.editingId = editing?.id
        self.isBot = editing?.isBot ?? false
        self.originalNormalizedName = editing.map { Self.normalizedName($0.name) }
        self.name = editing?.name ?? ""
        self.notes = editing?.notes ?? ""
        self.avatarStyle = editing?.avatarStyle ?? .dart
        self.colorToken = editing?.colorToken ?? .green
        validate()
    }

    func validate() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            validationMessage = "player.validation.nameRequired"
            canSave = false
            return
        }
        if trimmed.count > 32 {
            validationMessage = "player.validation.nameTooLong"
            canSave = false
            return
        }
        let normalized = Self.normalizedName(trimmed)
        let duplicateCount = existingNames.reduce(into: 0) { count, existingName in
            if Self.normalizedName(existingName) == normalized {
                count += 1
            }
        }
        if editingId == nil {
            if duplicateCount > 0 {
                validationMessage = "player.validation.duplicateName"
                canSave = false
                return
            }
        } else {
            let isSameAsOriginal = normalized == originalNormalizedName
            let allowedCount = isSameAsOriginal ? 1 : 0
            if duplicateCount > allowedCount {
                validationMessage = "player.validation.duplicateName"
                canSave = false
                return
            }
        }
        validationMessage = nil
        canSave = true
    }

    func buildPlayer(from existing: EditablePlayer?) -> EditablePlayer {
        let id = existing?.id ?? UUID()
        return EditablePlayer(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            isArchived: existing?.isArchived ?? false,
            notes: notes,
            isBot: existing?.isBot ?? false,
            isTrainingBot: existing?.isTrainingBot ?? false,
            isCustomBot: existing?.isCustomBot ?? false,
            customX01Average: existing?.customX01Average ?? CustomBotMetrics.defaultX01Average,
            customCricketMPR: existing?.customCricketMPR ?? CustomBotMetrics.defaultCricketMPR,
            linkedPlayerId: existing?.linkedPlayerId,
            botDifficulty: existing?.botDifficulty,
            avatarStyle: avatarStyle,
            colorToken: colorToken
        )
    }

    private static func normalizedName(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
