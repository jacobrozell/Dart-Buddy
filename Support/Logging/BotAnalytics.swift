import Foundation

/// Product-health telemetry for computer-opponent usage in matches.
///
/// Emits preset/training/custom **kinds** and difficulty **tiers** only — never
/// `displayNameAtMatchStart` or other roster labels.
enum BotAnalytics {
    static func metadata(for participants: [MatchParticipant]) -> [String: String] {
        let bots = participants.filter(\.isBot)
        let humanCount = participants.count - bots.count

        guard !bots.isEmpty else {
            return [
                "hasBot": "false",
                "botCount": "0",
                "humanCount": String(humanCount),
                "isBot": "false"
            ]
        }

        var result: [String: String] = [
            "hasBot": "true",
            "botCount": String(bots.count),
            "humanCount": String(humanCount),
            "isBot": "true"
        ]

        let difficulties = sortedUnique(bots.compactMap(\.botDifficultyRaw))
        if !difficulties.isEmpty {
            result["botDifficulties"] = difficulties.joined(separator: ",")
        }

        let kinds = sortedUnique(bots.compactMap(\.botKindRaw))
        if !kinds.isEmpty {
            result["botKinds"] = kinds.joined(separator: ",")
        }

        let effectiveTiers = sortedUnique(bots.compactMap(\.botEffectiveTierRaw))
        if !effectiveTiers.isEmpty {
            result["botEffectiveTiers"] = effectiveTiers.joined(separator: ",")
        }

        if bots.count == 1, let bot = bots.first {
            if let difficulty = bot.botDifficultyRaw {
                result["botDifficulty"] = difficulty
            }
            if let kind = bot.botKindRaw {
                result["botKind"] = kind
            }
            if let tier = bot.botEffectiveTierRaw {
                result["botEffectiveTier"] = tier
            }
        }

        return result
    }

    private static func sortedUnique(_ values: [String]) -> [String] {
        Array(Set(values)).sorted()
    }
}
