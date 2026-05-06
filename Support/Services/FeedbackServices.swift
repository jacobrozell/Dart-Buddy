import Foundation

public protocol HapticsService: Sendable {
    func playSelection()
}

public protocol AudioFeedbackService: Sendable {
    func playHit()
}

public struct NoopHapticsService: HapticsService {
    public init() {}
    public func playSelection() {}
}

public struct NoopAudioFeedbackService: AudioFeedbackService {
    public init() {}
    public func playHit() {}
}
