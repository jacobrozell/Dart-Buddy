import Foundation

enum BotNaming {
    static func nextDefaultName(difficulty: BotDifficulty, existingNames: [String]) -> String {
        let prefix = L10n.format("bot.namePrefixFormat", difficulty.displayName)
        let numbers = existingNames.compactMap { name -> Int? in
            guard name.hasPrefix(prefix) else { return nil }
            return Int(name.dropFirst(prefix.count))
        }
        return "\(prefix)\((numbers.max() ?? 0) + 1)"
    }
}
