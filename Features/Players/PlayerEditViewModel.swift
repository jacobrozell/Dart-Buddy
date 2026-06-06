import Foundation

@MainActor
final class PlayerEditViewModel: ObservableObject {
    @Published var name = ""
    @Published var notes = ""
    @Published var avatarStyle: PlayerAvatarStyle = .dart
    @Published var colorToken: PlayerColorToken = .green
    @Published private(set) var validationMessage: String?
    @Published private(set) var canSave = false

    let isBot: Bool
    private let existingNames: [String]
    private let editingId: UUID?
    private let originalNormalizedName: String?

    init(existingNames: [String], editing: EditablePlayer?) {
        self.existingNames = existingNames
        self.editingId = editing?.id
        self.isBot = editing?.isBot ?? false
        self.originalNormalizedName = editing.map { Self.normalizedName($0.name) }
        self.name = editing?.name ?? ""
        self.notes = editing?.notes ?? ""
        self.avatarStyle = editing?.avatarStyle ?? .dart
        self.colorToken = editing?.colorToken ?? .green
        validate()
    }

    func validate() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            validationMessage = "player.validation.nameRequired"
            canSave = false
            return
        }
        if trimmed.count > 32 {
            validationMessage = "player.validation.nameTooLong"
            canSave = false
            return
        }
        let normalized = Self.normalizedName(trimmed)
        let duplicateCount = existingNames.reduce(into: 0) { count, existingName in
            if Self.normalizedName(existingName) == normalized {
                count += 1
            }
        }
        if editingId == nil {
            if duplicateCount > 0 {
                validationMessage = "player.validation.duplicateName"
                canSave = false
                return
            }
        } else {
            let isSameAsOriginal = normalized == originalNormalizedName
            let allowedCount = isSameAsOriginal ? 1 : 0
            if duplicateCount > allowedCount {
                validationMessage = "player.validation.duplicateName"
                canSave = false
                return
            }
        }
        validationMessage = nil
        canSave = true
    }

    func buildPlayer(from existing: EditablePlayer?) -> EditablePlayer {
        let id = existing?.id ?? UUID()
        return EditablePlayer(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            isArchived: existing?.isArchived ?? false,
            notes: notes,
            isBot: existing?.isBot ?? false,
            isTrainingBot: existing?.isTrainingBot ?? false,
            isCustomBot: existing?.isCustomBot ?? false,
            customX01Average: existing?.customX01Average ?? CustomBotMetrics.defaultX01Average,
            customCricketMPR: existing?.customCricketMPR ?? CustomBotMetrics.defaultCricketMPR,
            linkedPlayerId: existing?.linkedPlayerId,
            botDifficulty: existing?.botDifficulty,
            avatarStyle: avatarStyle,
            colorToken: colorToken
        )
    }

    private static func normalizedName(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
