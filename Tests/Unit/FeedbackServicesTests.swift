import Testing
@testable import DartsScoreboard

private final class RecordingTurnTotalCaller: TurnTotalCallerService, @unchecked Sendable {
    private(set) var announcedTotals: [Int] = []

    func announceTurnTotal(_ total: Int) {
        announcedTotals.append(total)
    }
}

private final class RecordingAudioFeedback: AudioFeedbackService, @unchecked Sendable {
    private(set) var legFinishedCount = 0
    private(set) var matchFinishedCount = 0

    func playHit() {}
    func playMiss() {}
    func playLegFinished() { legFinishedCount += 1 }
    func playMatchFinished() { matchFinishedCount += 1 }
}

@Test(.tags(.unit, .regression))
func gatedAudioFeedbackRequiresSoundForLegAndMatchFinished() {
    let preferences = FeedbackPreferences()
    let recorder = RecordingAudioFeedback()
    let gated = GatedAudioFeedbackService(underlying: recorder, preferences: preferences)

    preferences.soundEnabled = false
    gated.playLegFinished()
    gated.playMatchFinished()
    #expect(recorder.legFinishedCount == 0)
    #expect(recorder.matchFinishedCount == 0)

    preferences.soundEnabled = true
    gated.playLegFinished()
    gated.playMatchFinished()
    #expect(recorder.legFinishedCount == 1)
    #expect(recorder.matchFinishedCount == 1)
}

@Test(.tags(.unit, .regression))
func gatedTurnTotalCallerRequiresSoundAndSetting() {
    let preferences = FeedbackPreferences()
    let recorder = RecordingTurnTotalCaller()
    let gated = GatedTurnTotalCallerService(underlying: recorder, preferences: preferences)

    gated.announceTurnTotal(60)
    #expect(recorder.announcedTotals.isEmpty)

    preferences.turnTotalCallerEnabled = true
    preferences.soundEnabled = false
    gated.announceTurnTotal(60)
    #expect(recorder.announcedTotals.isEmpty)

    preferences.soundEnabled = true
    gated.announceTurnTotal(60)
    #expect(recorder.announcedTotals == [60])
}
