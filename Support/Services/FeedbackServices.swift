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
    /// Plays the match-finished fanfare.
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
/// Plays sound effects loaded from the `Media.xcassets` data assets. Players are
/// preloaded once and reused; playback is dispatched to the main thread.
public final class BundledAudioFeedbackService: AudioFeedbackService, @unchecked Sendable {
    private static let hitAssetNames = ["dart_hit_1", "dart_hit_2", "dart_hit_3"]
    private static let missAssetName = "dart_miss"
    private static let finishedAssetName = "game_finished"

    private let players: [String: AVAudioPlayer]

    public init() {
        BundledAudioFeedbackService.configureAudioSession()
        var loaded: [String: AVAudioPlayer] = [:]
        for name in Self.hitAssetNames + [Self.missAssetName, Self.finishedAssetName] {
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

    private static func configureAudioSession() {
        // Ambient mixes with other audio and respects the silent switch, which
        // is the friendly default for a scorekeeping app's sound effects.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
#endif
