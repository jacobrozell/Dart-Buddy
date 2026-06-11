import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func customBotMetricsRoundTripEncoding() {
    let metrics = CustomBotMetrics(x01Average: 42.5, cricketMPR: 1.75)
    let encoded = metrics.encode()
    let decoded = CustomBotMetrics.decode(botDifficultyRaw: encoded)
    #expect(decoded == metrics)
}

@Test(.tags(.unit, .regression))
func customBotMetricsClampsExtremeInput() {
    let metrics = CustomBotMetrics(x01Average: 200, cricketMPR: 99)
    #expect(metrics.x01Average == CustomBotMetrics.x01AverageRange.upperBound)
    #expect(metrics.cricketMPR == CustomBotMetrics.cricketMPRRange.upperBound)
}

@Test(.tags(.unit, .regression))
func customBotSkillResolverExtrapolatesBeyondPro() {
    let weak = CustomBotSkillResolver.profile(
        for: .x01,
        metrics: CustomBotMetrics(x01Average: 8, cricketMPR: 0.3)
    )
    let strong = CustomBotSkillResolver.profile(
        for: .x01,
        metrics: CustomBotMetrics(x01Average: 105, cricketMPR: 4.5)
    )
    let veryEasy = BotDifficulty.veryEasy.skillProfile
    let pro = BotDifficulty.pro.skillProfile
    #expect(weak.x01.scoringVisitMax < veryEasy.x01.scoringVisitMax)
    #expect(strong.x01.hitChances.triple > pro.x01.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func customBotCombinedDisplayProfileUsesBothModes() {
    let metrics = CustomBotMetrics(x01Average: 55, cricketMPR: 2.2)
    let profile = CustomBotSkillResolver.combinedDisplayProfile(metrics: metrics)
    #expect(profile.x01.hitChances.triple > 0)
    #expect(profile.cricket.hitChances.triple > 0)
}

@Test(.tags(.unit, .regression))
func botSkillProfilePayloadDecoderReadsCustomSnapshot() throws {
    let metrics = CustomBotMetrics(x01Average: 50, cricketMPR: 2.0)
    let profile = CustomBotSkillResolver.profile(for: .cricket, metrics: metrics)
    let snapshot = CustomBotSkillSnapshot(profile: profile, x01Average: metrics.x01Average, cricketMPR: metrics.cricketMPR)
    let data = try CustomBotSkillSnapshot.encode(snapshot)
    #expect(BotSkillProfilePayloadDecoder.profile(from: data) == profile)
}

@Test(.tags(.unit, .regression))
func botSkillProfilePayloadDecoderReadsTrainingSnapshot() throws {
    let linkedPlayerId = UUID()
    let profile = BotDifficulty.medium.skillProfile
    let snapshot = TrainingBotSkillSnapshot(
        profile: profile,
        linkedPlayerId: linkedPlayerId,
        sourcePlayerAvg: 55,
        sourcePlayerMPR: 2.1,
        resolvedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
    let data = try TrainingBotSkillSnapshot.encode(snapshot)
    let decoded = try TrainingBotSkillSnapshot.decode(from: data)
    #expect(decoded == snapshot)
    #expect(BotSkillProfilePayloadDecoder.profile(from: data) == profile)
}

@Test(.tags(.unit, .regression))
func customBotSkillResolverMapsKillerAndShanghaiToX01Profile() {
    let metrics = CustomBotMetrics(x01Average: 55, cricketMPR: 2.0)
    let killer = CustomBotSkillResolver.profile(for: .killer, metrics: metrics)
    let shanghai = CustomBotSkillResolver.profile(for: .shanghai, metrics: metrics)
    let x01 = CustomBotSkillResolver.profile(for: .x01, metrics: metrics)
    #expect(killer.x01.hitChances.triple == x01.x01.hitChances.triple)
    #expect(shanghai.x01.hitChances.triple == x01.x01.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func customBotMetricsDecodeReturnsNilForPresetDifficultyRaw() {
    #expect(CustomBotMetrics.decode(botDifficultyRaw: BotDifficulty.easy.rawValue) == nil)
}

@Test(.tags(.unit, .regression))
func botSkillProfilePayloadDecoderReturnsNilForUnknownPayload() {
    #expect(BotSkillProfilePayloadDecoder.profile(from: Data("{}".utf8)) == nil)
}
