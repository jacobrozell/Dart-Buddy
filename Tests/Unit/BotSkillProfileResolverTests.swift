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
func templateResolverReturnsCanonicalProfileForX01AndCricket() {
    let configuration = CustomBotConfiguration(x01Average: 60, cricketMPR: 2.0)
    let canonical = configuration.resolvedCanonicalProfile()
    let x01Context = BotPlayContext(matchType: .x01, uiTemplate: .checkoutScore)
    let cricketContext = BotPlayContext(matchType: .cricket, uiTemplate: .markBoard)
    #expect(BotSkillProfileResolver.profile(configuration: configuration, context: x01Context) == canonical)
    #expect(BotSkillProfileResolver.profile(configuration: configuration, context: cricketContext) == canonical)
}

@Test(.tags(.unit, .regression))
func legacyPartyModeProfilesRemainAvailableFromCustomBotSkillResolver() {
    let metrics = CustomBotMetrics(x01Average: 55, cricketMPR: 2.0)
    let baseball = CustomBotSkillResolver.profile(for: .baseball, metrics: metrics)
    let x01 = CustomBotSkillResolver.profile(for: .x01, metrics: metrics)
    #expect(baseball.x01.hitChances.triple == x01.x01.hitChances.triple)
}
