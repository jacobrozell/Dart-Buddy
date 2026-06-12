import Testing
@testable import DartBuddy

@Suite(.tags(.unit))
struct MotionPolicyTests {
    @Test func shouldAnimate_respectsReduceMotionAndPreference() {
        #expect(MotionPolicy.shouldAnimate(reduceMotion: false) == true)
        #expect(MotionPolicy.shouldAnimate(reduceMotion: true) == false)
        #expect(MotionPolicy.shouldAnimate(reduceMotion: false, animationsEnabled: false) == false)
    }

    @Test func standardAnimation_nilWhenReduceMotion() {
        #expect(MotionPolicy.standardAnimation(reduceMotion: true) == nil)
        #expect(MotionPolicy.standardAnimation(reduceMotion: false) != nil)
    }

    @Test func staggerDelay_scalesWithIndex() {
        #expect(MotionPolicy.staggerDelay(for: 0) == .milliseconds(0))
        #expect(MotionPolicy.staggerDelay(for: 2) == .milliseconds(80))
    }
}
