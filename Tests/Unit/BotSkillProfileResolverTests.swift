import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func templateResolverSameConfigAllShippedTemplatesSucceeds() {
    let configuration = CustomBotConfiguration(x01Average: 45, cricketMPR: 1.8)
    let templates = BotSkillProfileResolver.allShippedTemplates()
    #expect(!templates.isEmpty)
    for template in templates {
        guard let matchType = GameModeCatalog.available.first(where: { $0.uiTemplate == template })?.matchType else {
            continue
        }
        let context = BotPlayContext(matchType: matchType, uiTemplate: template)
        let profile = BotSkillProfileResolver.profile(configuration: configuration, context: context)
        #expect(profile.x01.scoringVisitMax > 0)
        #expect(profile.cricket.hitChances.triple >= 0)
    }
}

@Test(.tags(.unit, .regression))
func templateResolverUsesX01AverageForCheckoutTemplate() {
    let configuration = CustomBotConfiguration(x01Average: 30, cricketMPR: 3.0)
    let checkout = BotSkillProfileResolver.profile(
        configuration: configuration,
        context: BotPlayContext(matchType: .x01, uiTemplate: .checkoutScore)
    )
    #expect(checkout.x01.scoringBehaviorTier == .veryEasy)
}

@Test(.tags(.unit, .regression))
func templateResolverUsesCricketMPRForMarkBoardTemplate() {
    let configuration = CustomBotConfiguration(x01Average: 30, cricketMPR: 3.0)
    let markBoard = BotSkillProfileResolver.profile(
        configuration: configuration,
        context: BotPlayContext(matchType: .cricket, uiTemplate: .markBoard)
    )
    #expect(markBoard.x01.scoringBehaviorTier != .veryEasy)
}

@Test(.tags(.unit, .regression))
func templateResolverCompatibleTemplatesAreUniqueAndSorted() {
    let templates = BotSkillProfileResolver.compatibleTemplates()
    #expect(templates == templates.sorted { $0.rawValue < $1.rawValue })
    #expect(templates.count == Set(templates).count)
    #expect(templates.contains(.checkoutScore))
    #expect(templates.contains(.markBoard))
}

@Test(.tags(.unit, .regression))
func legacyPartyModeProfilesRemainAvailableFromCustomBotSkillResolver() {
    let metrics = CustomBotMetrics(x01Average: 55, cricketMPR: 2.0)
    let baseball = CustomBotSkillResolver.profile(for: .baseball, metrics: metrics)
    let x01 = CustomBotSkillResolver.profile(for: .x01, metrics: metrics)
    #expect(baseball.x01.hitChances.triple == x01.x01.hitChances.triple)
}
