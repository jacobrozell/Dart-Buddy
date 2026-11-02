import Foundation

/// Turns per-frame scene motion into a takeout signal. A player walking up to pull
/// darts keeps the frame moving for a second or more; a shadow flicker or the board
/// shaking from an impact does not.
public struct TakeoutDetector: Sendable {
    /// Recent frames considered (about 1 s at 30 fps).
    public var windowFrames = 30
    /// Moving frames within the window that count as a takeout.
    public var motionFramesRequired = 10

    private var recent: [Bool] = []
    private var motionCount = 0

    public init() {}

    /// Feeds one frame; returns `true` once sustained motion is seen.
    public mutating func observe(sceneMotion: Bool) -> Bool {
        recent.append(sceneMotion)
        if sceneMotion { motionCount += 1 }
        if recent.count > windowFrames, recent.removeFirst() {
            motionCount -= 1
        }
        return motionCount >= motionFramesRequired
    }

    public mutating func reset() {
        recent = []
        motionCount = 0
    }
}
