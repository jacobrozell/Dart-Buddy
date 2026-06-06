import Foundation
import Testing
@testable import DartBuddy

@Suite("Match lifecycle models", .tags(.unit, .x01, .cricket, .regression))
struct MatchLifecycleModelsTests {
    @Test
    func setupModeMapsToMatchType() {
        #expect(MatchSetupViewModel.SetupMode.x01.matchType == .x01)
        #expect(MatchSetupViewModel.SetupMode.cricket.matchType == .cricket)
    }

    @Test
    func x01OptionDisplayNamesAreLocalized() {
        for mode in X01CheckoutMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
        for mode in X01CheckInMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
        for format in X01LegFormat.allCases {
            #expect(!format.displayName.isEmpty)
        }
    }

    @Test
    func cricketScoringModesExposeDisplayNames() {
        for mode in CricketScoringMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
    }

    @Test
    func matchHistoryFilterDefaultsToAllMatches() {
        let filter = MatchHistoryFilter()
        #expect(filter.matchType == nil)
        #expect(filter.startedAfter == nil)
        #expect(filter.participantPlayerId == nil)
    }

    @Test
    func matchTurnSupportMapsRuntimeToSummary() throws {
        let matchId = UUID()
        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let session = try MatchLifecycleService.createMatch(
            matchId: matchId,
            type: .x01,
            config: .x01(MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .doubleOut
            )),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Alice", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Bob", turnOrder: 1)
            ],
            startedAt: startedAt
        )

        let summary = MatchTurnSupport.matchSummary(from: session.runtime)

        #expect(summary.id == matchId)
        #expect(summary.type == .x01)
        #expect(summary.status == MatchStatus.inProgress)
        #expect(summary.startedAt == startedAt)
        #expect(summary.eventCount == session.runtime.eventCount)
    }

    @Test
    func matchTurnSupportBuildsProgressMetadataFromSession() throws {
        let session = try MatchLifecycleService.createMatch(
            type: .cricket,
            config: .cricket(MatchConfigCricket()),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )

        let metadata = MatchTurnSupport.matchProgressMetadata(for: session)

        #expect(metadata["eventCount"] == String(session.runtime.eventCount))
        #expect(metadata["legIndex"] == String(session.runtime.currentLegIndex))
        #expect(metadata["setIndex"] == String(session.runtime.currentSetIndex))
        #expect(metadata["status"] == session.runtime.status.rawValue)
    }

    @Test
    func matchTurnSupportMapsAppErrorsToMetadataAndMessageKeys() {
        let appError = AppError(
            code: .validationFailed,
            layer: .domain,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.match.invalidTurn"
        )
        struct Sample: Error {}
        let generic = Sample()

        #expect(MatchTurnSupport.appErrorMetadata(for: appError) == [
            "errorCode": ErrorCode.validationFailed.rawValue,
            "layer": ErrorLayer.domain.rawValue
        ])
        #expect(MatchTurnSupport.appErrorMetadata(for: generic) == ["errorCode": "unknown"])
        #expect(MatchTurnSupport.errorMessageKey(for: appError, fallback: "error.generic") == "error.match.invalidTurn")
        #expect(MatchTurnSupport.errorMessageKey(for: generic, fallback: "error.generic") == "error.generic")
    }
}
