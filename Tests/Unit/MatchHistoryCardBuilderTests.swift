import Foundation
import Testing
@testable import DartBuddy

@Suite
struct MatchHistoryCardBuilderTests {
    @Test(.tags(.history, .x01))
    func buildsX01HistoryCardFromRuntime() throws {
        let alice = UUID()
        let bob = UUID()
        var runtime = MatchRuntimeState(
            matchId: UUID(),
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 501, legsToWin: 3, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)),
            participants: [],
            status: .completed,
            startedAt: Date(),
            endedAt: Date(),
            winnerPlayerId: alice,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 1,
            x01State: nil,
            cricketState: nil,
            baseballState: nil,
            killerState: nil,
            shanghaiState: nil
        )
        runtime.x01State = X01State(
            config: MatchConfigX01(startScore: 501, legsToWin: 3, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut),
            players: [
                X01PlayerState(playerId: alice, remainingScore: 0, legsWon: 2, setsWon: 0),
                X01PlayerState(playerId: bob, remainingScore: 120, legsWon: 1, setsWon: 0)
            ],
            currentPlayerIndex: 0,
            legIndex: 0,
            setIndex: 0,
            turnIndex: 0,
            winnerPlayerId: alice,
            isComplete: true
        )

        let payload = MatchHistoryCardBuilder.build(
            from: runtime,
            nameById: [alice: "Alice", bob: "Bob"]
        )

        #expect(payload.standings.count == 2)
        #expect(payload.standings.first?.isWinner == true)
        #expect(payload.standings.first?.name == "Alice")
        #expect(payload.configText.contains("501"))
    }

    @Test(.tags(.history, .cricket))
    func buildsCricketHistoryCardFromRuntime() throws {
        let alice = UUID()
        let bob = UUID()
        var runtime = MatchRuntimeState(
            matchId: UUID(),
            type: .cricket,
            config: .cricket(MatchConfigCricket()),
            participants: [],
            status: .completed,
            startedAt: Date(),
            endedAt: Date(),
            winnerPlayerId: alice,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 1,
            x01State: nil,
            cricketState: nil,
            baseballState: nil,
            killerState: nil,
            shanghaiState: nil
        )
        runtime.cricketState = CricketState(
            config: MatchConfigCricket(),
            players: [
                CricketPlayerState(playerId: alice, score: 40, marks: [:], legsWon: 1, setsWon: 0),
                CricketPlayerState(playerId: bob, score: 20, marks: [:], legsWon: 0, setsWon: 0)
            ],
            currentPlayerIndex: 0,
            roundIndex: 0,
            turnIndex: 0,
            legIndex: 0,
            setIndex: 0,
            winnerPlayerId: alice,
            isComplete: true
        )

        let payload = MatchHistoryCardBuilder.build(
            from: runtime,
            nameById: [alice: "Alice", bob: "Bob"]
        )

        #expect(payload.standings.count == 2)
        #expect(payload.standings.first?.isWinner == true)
        #expect(payload.standings.first?.name == "Alice")
        #expect(payload.standings.first?.score == 40)
        #expect(!payload.configText.isEmpty)
    }

    @Test(.tags(.history, .regression))
    func encodesAndDecodesHistoryCardPayload() throws {
        let payload = MatchHistoryCardPayload(
            configText: "501 · Double Out",
            standings: [
                MatchHistoryCardStanding(
                    playerId: UUID(),
                    name: "Alice",
                    isWinner: true,
                    sets: 0,
                    legs: 2,
                    score: 0
                )
            ]
        )

        let data = try CodablePayloadCoder.encode(payload)
        let decoded = try CodablePayloadCoder.decode(MatchHistoryCardPayload.self, from: data)

        #expect(decoded == payload)
        #expect(decoded.payloadVersion == MatchHistoryCardPayload.currentPayloadVersion)
    }
}
