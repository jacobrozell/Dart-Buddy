import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.integration, .player, .swiftdata, .regression))
func trainingBotRepositoryCreatesAndFetchesLinkedBot() async throws {
    let repos = try makeTrainingBotRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bot = try await repos.player.createTrainingBot(for: alice.id)

    #expect(bot.isTrainingBot)
    #expect(bot.linkedPlayerId == alice.id)
    #expect(bot.botDifficultyRaw == nil)

    let fetched = try await repos.player.fetchTrainingBot(linkedTo: alice.id)
    #expect(fetched?.id == bot.id)
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func trainingBotRepositoryRejectsDuplicateTrainingBot() async throws {
    let repos = try makeTrainingBotRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    _ = try await repos.player.createTrainingBot(for: alice.id)

    do {
        _ = try await repos.player.createTrainingBot(for: alice.id)
        Issue.record("Expected duplicate training bot rejection")
    } catch let error as AppError {
        #expect(error.userMessageKey == "trainingBot.error.duplicate")
    }
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func trainingBotRepositoryResolveSkillRequiresEligibility() async throws {
    let repos = try makeTrainingBotRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bot = try await repos.player.createTrainingBot(for: alice.id)

    do {
        _ = try await repos.player.resolveTrainingBotSkill(for: bot.id, mode: .x01)
        Issue.record("Expected ineligible error without completed games")
    } catch let error as AppError {
        #expect(error.userMessageKey == "trainingBot.error.ineligible")
    }
}

@Test(.tags(.integration, .player, .match, .swiftdata, .regression))
func trainingBotRepositoryResolveSkillAfterCompletedGames() async throws {
    let repos = try makeTrainingBotRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    try await seedCompletedX01Match(alice: alice, bob: bob, repository: repos.match)
    for _ in 0 ..< 4 {
        try await seedCompletedX01Match(alice: alice, bob: bob, repository: repos.match)
    }
    let bot = try await repos.player.createTrainingBot(for: alice.id)
    let profile = try await repos.player.resolveTrainingBotSkill(for: bot.id, mode: .x01)
    #expect(profile.x01.scoringVisitMax > BotDifficulty.veryEasy.skillProfile.x01.scoringVisitMax)
}

private func seedCompletedX01Match(
    alice: PlayerSummary,
    bob: PlayerSummary,
    repository: SwiftDataMatchRepository
) async throws {
    let payload = try CodablePayloadCoder.encode(
        MatchConfigPayload.x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut))
    )
    let matchId = UUID()
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: alice.name),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: bob.name)
    ]
    let created = try await repository.createMatch(type: .x01, configPayload: payload, participants: participants)
    _ = try await repository.completeMatch(matchId: created.id, endedAt: Date(), winnerPlayerId: alice.id)
}

private func makeTrainingBotRepositories() throws -> (
    player: SwiftDataPlayerRepository,
    match: SwiftDataMatchRepository,
    stats: SwiftDataStatsRepository
) {
    let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
    let match = SwiftDataMatchRepository(container: container)
    let stats = SwiftDataStatsRepository(container: container)
    let player = SwiftDataPlayerRepository(container: container, matchRepository: match, statsRepository: stats)
    return (player, match, stats)
}
