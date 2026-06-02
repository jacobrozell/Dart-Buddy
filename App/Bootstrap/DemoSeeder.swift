import Foundation

/// Seeds a small set of players and matches for screenshots / manual QA.
/// Only runs when launched with `-seed_demo` and the store has no players yet.
enum DemoSeeder {
    static func seedIfRequested(_ dependencies: AppDependencies) async {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("-ui_test_reset") {
            try? await dependencies.settingsRepository.resetAllLocalData()
            try? await dependencies.settingsRepository.resetPreferencesToDefaults()
        }

        if arguments.contains("-seed_players") {
            await seedPlayersOnly(dependencies)
        }

        if arguments.contains("-snapshot_match_cricket") {
            await seedCricketSnapshot(dependencies)
        }

        if arguments.contains("-snapshot_match_summary") {
            await seedSummarySnapshot(dependencies)
        }

        guard arguments.contains("-seed_demo") else { return }
        do {
            let existing = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
            guard existing.isEmpty else { return }

            let jacob = try await dependencies.playerRepository.createPlayer(name: "Jacob")
            let bot = try await dependencies.playerRepository.createPlayer(name: "DartBot 1")
            let sam = try await dependencies.playerRepository.createPlayer(name: "Sam")

            // Completed X01 game: Jacob beats Sam (301, straight out).
            try await seedX01(
                dependencies: dependencies,
                config: MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut),
                players: [(jacob, "Jacob"), (sam, "Sam")],
                turns: [
                    [d(.triple, 20), d(.triple, 20), d(.triple, 20)],      // Jacob 180 -> 121
                    [d(.triple, 20), d(.single, 20), d(.single, 20)],      // Sam 100 -> 201
                    [d(.triple, 20), d(.triple, 20), d(.single, 1)]        // Jacob 121 -> 0 (win)
                ],
                complete: true
            )

            // In-progress X01 game: Jacob vs DartBot 1 (301, double out).
            try await seedX01(
                dependencies: dependencies,
                config: MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut),
                players: [(jacob, "Jacob"), (bot, "DartBot 1")],
                turns: [
                    [d(.triple, 20), d(.triple, 20), d(.triple, 20)],      // Jacob 180 -> 121
                    [d(.single, 20), d(.single, 20), d(.single, 20)]       // DartBot 60 -> 241
                ],
                complete: false
            )
        } catch {
            dependencies.logger.error(.appLifecycle, eventName: "demo_seed_failed", message: "Demo seed failed: \(error)")
        }
    }

    /// Populates the fixed Cricket match id used by the `-snapshot_match_cricket`
    /// launch route so the board renders with real marks/scores for screenshots.
    private static func seedCricketSnapshot(_ dependencies: AppDependencies) async {
        let matchId = UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID()
        let config = MatchConfigPayload.cricket(MatchConfigCricket())
        let participants = [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Sam", turnOrder: 1)
        ]
        do {
            var session = try MatchLifecycleService.createMatch(
                matchId: matchId,
                type: .cricket,
                config: config,
                participants: participants
            )
            let turns: [[DartInput]] = [
                [d(.triple, 20), d(.triple, 20), d(.single, 19)],   // Jacob: close 20, 1 on 19
                [d(.triple, 19), d(.double, 18), d(.single, 17)],   // Sam: close 19, 2 on 18, 1 on 17
                [d(.triple, 18), d(.single, 20), d(.single, 20)]    // Jacob: close 18, score on 20
            ]
            for darts in turns {
                session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)
            }
            let finalSession = session
            await MainActor.run { dependencies.activeMatchStore.save(finalSession) }
        } catch {
            dependencies.logger.error(.appLifecycle, eventName: "cricket_snapshot_seed_failed", message: "Cricket snapshot seed failed: \(error)")
        }
    }

    /// Populates the fixed match id used by `-snapshot_match_summary` with a
    /// completed X01 leg (Jacob checks out 121) so the summary screen renders
    /// with real per-player stats for screenshots.
    private static func seedSummarySnapshot(_ dependencies: AppDependencies) async {
        let matchId = UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID()
        let config = MatchConfigPayload.x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut))
        let participants = [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Sam", turnOrder: 1)
        ]
        do {
            var session = try MatchLifecycleService.createMatch(
                matchId: matchId,
                type: .x01,
                config: config,
                participants: participants
            )
            session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 180, darts: nil)
            session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 100, darts: nil)
            session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 121, darts: nil)
            let finalSession = session
            await MainActor.run { dependencies.activeMatchStore.save(finalSession) }
        } catch {
            dependencies.logger.error(.appLifecycle, eventName: "summary_snapshot_seed_failed", message: "Summary snapshot seed failed: \(error)")
        }
    }

    private static func seedPlayersOnly(_ dependencies: AppDependencies) async {
        do {
            let existing = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
            guard existing.isEmpty else { return }
            _ = try await dependencies.playerRepository.createPlayer(name: "Alice")
            _ = try await dependencies.playerRepository.createPlayer(name: "Bob")
        } catch {
            dependencies.logger.error(.appLifecycle, eventName: "seed_players_failed", message: "Seed players failed: \(error)")
        }
    }

    private static func d(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
        DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
    }

    private static func seedX01(
        dependencies: AppDependencies,
        config: MatchConfigX01,
        players: [(PlayerSummary, String)],
        turns: [[DartInput]],
        complete: Bool
    ) async throws {
        let payload = MatchConfigPayload.x01(config)
        let encoded = try CodablePayloadCoder.encode(payload)
        let participantSummaries = players.enumerated().map { index, entry in
            MatchParticipantSummary(
                id: UUID(),
                matchId: UUID(),
                playerId: entry.0.id,
                turnOrder: index,
                displayNameAtMatchStart: entry.1,
                avatarStyleAtMatchStart: nil
            )
        }
        let persisted = try await dependencies.matchRepository.createMatch(
            type: .x01,
            configPayload: encoded,
            participants: participantSummaries
        )
        let lifecycleParticipants = players.enumerated().map { index, entry in
            MatchParticipant(playerId: entry.0.id, displayNameAtMatchStart: entry.1, turnOrder: index)
        }
        var session = try MatchLifecycleService.createMatch(
            matchId: persisted.id,
            type: .x01,
            config: payload,
            participants: lifecycleParticipants
        )
        _ = try await dependencies.matchRepository.saveSnapshot(
            matchId: persisted.id,
            snapshotVersion: session.latestSnapshot.payloadVersion,
            snapshotPayload: session.latestSnapshot.payload
        )

        for darts in turns {
            session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: darts)
            if let event = session.events.last {
                let eventPayload = try CodablePayloadCoder.encode(event)
                _ = try await dependencies.matchRepository.appendEvent(
                    matchId: persisted.id,
                    eventTypeRaw: "x01Turn",
                    eventPayload: eventPayload
                )
            }
            _ = try await dependencies.matchRepository.saveSnapshot(
                matchId: persisted.id,
                snapshotVersion: session.latestSnapshot.payloadVersion,
                snapshotPayload: session.latestSnapshot.payload
            )
        }

        if complete, session.runtime.status == .completed {
            _ = try await dependencies.matchRepository.completeMatch(
                matchId: persisted.id,
                endedAt: Date(),
                winnerPlayerId: session.runtime.winnerPlayerId
            )
        }
        let finalSession = session
        await MainActor.run { dependencies.activeMatchStore.save(finalSession) }
    }
}
