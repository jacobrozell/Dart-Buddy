import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(UIKit)
import UIKit
#endif

public protocol HapticsService: Sendable {
    func playSelection()
    func playImpact()
    func playSuccess()
}

public protocol AudioFeedbackService: Sendable {
    /// Plays a random dart-hit sound (for a scoring dart).
    func playHit()
    /// Plays the miss sound (for a missed / zero-scoring dart).
    func playMiss()
    /// Plays a short leg-checkout sound when the match continues.
    func playLegFinished()
    /// Plays the match-finished fanfare when the entire match ends.
    func playMatchFinished()
}

public struct NoopHapticsService: HapticsService {
    public init() {}
    public func playSelection() {}
    public func playImpact() {}
    public func playSuccess() {}
}

public struct NoopAudioFeedbackService: AudioFeedbackService {
    public init() {}
    public func playHit() {}
    public func playMiss() {}
    public func playLegFinished() {}
    public func playMatchFinished() {}
}

public final class GatedHapticsService: HapticsService, @unchecked Sendable {
    private let underlying: any HapticsService
    private let preferences: FeedbackPreferences

    public init(underlying: any HapticsService, preferences: FeedbackPreferences) {
        self.underlying = underlying
        self.preferences = preferences
    }

    public func playSelection() {
        guard preferences.hapticsEnabled else { return }
        underlying.playSelection()
    }

    public func playImpact() {
        guard preferences.hapticsEnabled else { return }
        underlying.playImpact()
    }

    public func playSuccess() {
        guard preferences.hapticsEnabled else { return }
        underlying.playSuccess()
    }
}

public protocol TurnTotalCallerService: Sendable {
    /// Speaks the visit total after a turn is submitted.
    func announceTurnTotal(_ total: Int)
}

public struct NoopTurnTotalCallerService: TurnTotalCallerService {
    public init() {}
    public func announceTurnTotal(_ total: Int) {}
}

public struct TurnTotalCallerSignal: Equatable, Sendable {
    public let token: Int
    public let total: Int

    public init(token: Int, total: Int) {
        self.token = token
        self.total = total
    }
}

public final class GatedTurnTotalCallerService: TurnTotalCallerService, @unchecked Sendable {
    private let underlying: any TurnTotalCallerService
    private let preferences: FeedbackPreferences

    public init(underlying: any TurnTotalCallerService, preferences: FeedbackPreferences) {
        self.underlying = underlying
        self.preferences = preferences
    }

    public func announceTurnTotal(_ total: Int) {
        guard preferences.soundEnabled, preferences.turnTotalCallerEnabled else { return }
        underlying.announceTurnTotal(total)
    }
}

public final class GatedAudioFeedbackService: AudioFeedbackService, @unchecked Sendable {
    private let underlying: any AudioFeedbackService
    private let preferences: FeedbackPreferences

    public init(underlying: any AudioFeedbackService, preferences: FeedbackPreferences) {
        self.underlying = underlying
        self.preferences = preferences
    }

    public func playHit() {
        guard preferences.soundEnabled else { return }
        underlying.playHit()
    }

    public func playMiss() {
        guard preferences.soundEnabled else { return }
        underlying.playMiss()
    }

    public func playLegFinished() {
        guard preferences.soundEnabled else { return }
        underlying.playLegFinished()
    }

    public func playMatchFinished() {
        guard preferences.soundEnabled else { return }
        underlying.playMatchFinished()
    }
}

#if canImport(UIKit)
/// Real haptics backed by UIKit feedback generators. Generators must be used on
/// the main thread, so every call hops to main.
public final class SystemHapticsService: HapticsService, @unchecked Sendable {
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let successGenerator = UINotificationFeedbackGenerator()

    public init() {
        runOnMain {
            self.selectionGenerator.prepare()
            self.impactGenerator.prepare()
            self.successGenerator.prepare()
        }
    }

    public func playSelection() {
        runOnMain {
            self.selectionGenerator.selectionChanged()
            self.selectionGenerator.prepare()
        }
    }

    public func playImpact() {
        runOnMain {
            self.impactGenerator.impactOccurred()
            self.impactGenerator.prepare()
        }
    }

    public func playSuccess() {
        runOnMain {
            self.successGenerator.notificationOccurred(.success)
            self.successGenerator.prepare()
        }
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}
#endif

#if canImport(AVFoundation) && canImport(UIKit)
private enum FeedbackAudioSession {
    static func configureIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}

/// Plays sound effects loaded from the `Resources/Media.xcassets` data assets. Players are
/// preloaded once and reused; playback is dispatched to the main thread.
public final class BundledAudioFeedbackService: AudioFeedbackService, @unchecked Sendable {
    private static let hitAssetNames = ["dart_hit_1", "dart_hit_2", "dart_hit_3"]
    private static let missAssetName = "dart_miss"
    private static let legFinishedAssetName = "leg_finished"
    private static let finishedAssetName = "game_finished"

    private let players: [String: AVAudioPlayer]

    public init() {
        FeedbackAudioSession.configureIfNeeded()
        var loaded: [String: AVAudioPlayer] = [:]
        for name in Self.hitAssetNames + [Self.missAssetName, Self.legFinishedAssetName, Self.finishedAssetName] {
            guard let data = NSDataAsset(name: name)?.data,
                  let player = try? AVAudioPlayer(data: data) else { continue }
            player.prepareToPlay()
            loaded[name] = player
        }
        players = loaded
    }

    public func playHit() {
        play(Self.hitAssetNames.randomElement())
    }

    public func playMiss() {
        play(Self.missAssetName)
    }

    public func playLegFinished() {
        play(Self.legFinishedAssetName)
    }

    public func playMatchFinished() {
        play(Self.finishedAssetName)
    }

    private func play(_ name: String?) {
        guard let name, let player = players[name] else { return }
        let work = {
            player.currentTime = 0
            player.play()
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}

/// Speaks visit totals using the system voice. Respects the device silent switch
/// via the ambient audio session configured for bundled sound effects.
public final class SpeechTurnTotalCallerService: TurnTotalCallerService, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()

    public init() {
        FeedbackAudioSession.configureIfNeeded()
    }

    public func announceTurnTotal(_ total: Int) {
        let utterance = AVSpeechUtterance(string: "\(total)")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        let work = { self.synthesizer.speak(utterance) }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}
#endif
