import Foundation

struct OnboardingRosterDraft: Equatable, Sendable {
    var name: String
    var avatarStyle: PlayerAvatarStyle
    var colorToken: PlayerColorToken
    var botDifficulty: BotDifficulty
}

extension BotDifficulty {
    static let onboardingOrder: [BotDifficulty] = [.veryEasy, .easy, .medium, .hard, .pro]

    var showsOnboardingRulesIntro: Bool {
        self == .veryEasy || self == .easy
    }

    static func fromOnboardingSliderIndex(_ index: Int) -> BotDifficulty {
        onboardingOrder[min(max(index, 0), onboardingOrder.count - 1)]
    }

    var onboardingSliderIndex: Int {
        Self.onboardingOrder.firstIndex(of: self) ?? 1
    }
}
