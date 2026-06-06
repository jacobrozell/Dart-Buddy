import Testing
@testable import DartBuddy

private final class RecordingHaptics: HapticsService, @unchecked Sendable {
    private(set) var selectionCount = 0
    private(set) var impactCount = 0
    private(set) var successCount = 0

    func playSelection() { selectionCount += 1 }
    func playImpact() { impactCount += 1 }
    func playSuccess() { successCount += 1 }
}

private final class RecordingTurnTotalCaller: TurnTotalCallerService, @unchecked Sendable {
    private(set) var announcedTotals: [Int] = []

    func announceTurnTotal(_ total: Int) {
        announcedTotals.append(total)
    }
}

private final class RecordingAudioFeedback: AudioFeedbackService, @unchecked Sendable {
    private(set) var hitCount = 0
    private(set) var missCount = 0
    private(set) var legFinishedCount = 0
    private(set) var matchFinishedCount = 0

    func playHit() { hitCount += 1 }
    func playMiss() { missCount += 1 }
    func playLegFinished() { legFinishedCount += 1 }
    func playMatchFinished() { matchFinishedCount += 1 }
}

@Test(.tags(.unit, .regression))
func gatedHapticsRequirePreferenceToggle() {
    let preferences = FeedbackPreferences()
    preferences.hapticsEnabled = false
    let recorder = RecordingHaptics()
    let gated = GatedHapticsService(underlying: recorder, preferences: preferences)

    gated.playSelection()
    gated.playImpact()
    gated.playSuccess()
    #expect(recorder.selectionCount == 0)
    #expect(recorder.impactCount == 0)
    #expect(recorder.successCount == 0)

    preferences.hapticsEnabled = true
    gated.playSelection()
    gated.playImpact()
    gated.playSuccess()
    #expect(recorder.selectionCount == 1)
    #expect(recorder.impactCount == 1)
    #expect(recorder.successCount == 1)
}

@Test(.tags(.unit, .regression))
func gatedAudioFeedbackRequiresSoundForHitAndMiss() {
    let preferences = FeedbackPreferences()
    let recorder = RecordingAudioFeedback()
    let gated = GatedAudioFeedbackService(underlying: recorder, preferences: preferences)

    preferences.soundEnabled = false
    gated.playHit()
    gated.playMiss()
    #expect(recorder.hitCount == 0)
    #expect(recorder.missCount == 0)

    preferences.soundEnabled = true
    gated.playHit()
    gated.playMiss()
    #expect(recorder.hitCount == 1)
    #expect(recorder.missCount == 1)
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
