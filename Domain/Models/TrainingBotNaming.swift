import Foundation

enum TrainingBotNaming {
    static func defaultName(linkedPlayerName: String) -> String {
        L10n.format("trainingBot.nameFormat", linkedPlayerName)
    }
}
