import Foundation

extension BotSkillProfile {
    func x01HitChance(intendedMultiplier: DartMultiplier) -> Double {
        switch intendedMultiplier {
        case .single: x01.hitChances.single
        case .double: x01.hitChances.double
        case .triple: x01.hitChances.triple
        }
    }

    func cricketHitChance(intendedMultiplier: DartMultiplier) -> Double {
        switch intendedMultiplier {
        case .single: cricket.hitChances.single
        case .double: cricket.hitChances.double
        case .triple: cricket.hitChances.triple
        }
    }
}
