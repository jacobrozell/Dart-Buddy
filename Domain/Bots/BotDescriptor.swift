import Foundation

/// Roster identity + persistence contract for any computer opponent stored as a player row.
protocol BotDescriptor: Codable, Sendable {
    var botKind: BotKind { get }
}

struct PresetBotDescriptor: BotDescriptor, Equatable {
    let botKind: BotKind = .preset
    let difficulty: BotDifficulty

    init(difficulty: BotDifficulty) {
        self.difficulty = difficulty
    }
}

struct TrainingBotDescriptor: BotDescriptor, Equatable {
    let botKind: BotKind = .training
    let linkedPlayerId: UUID

    init(linkedPlayerId: UUID) {
        self.linkedPlayerId = linkedPlayerId
    }
}

struct CustomBotDescriptor: BotDescriptor, Equatable, BotSkillResolving {
    let botKind: BotKind = .custom
    let configuration: CustomBotConfiguration

    init(configuration: CustomBotConfiguration) {
        self.configuration = configuration
    }

    func skillProfile(context: BotPlayContext) -> BotSkillProfile {
        BotSkillProfileResolver.profile(configuration: configuration, context: context)
    }
}

protocol BotSkillResolving {
    func skillProfile(context: BotPlayContext) -> BotSkillProfile
}

protocol BotMatchParticipantBuilding {
    func skillSnapshotPayload(profile: BotSkillProfile, context: BotPlayContext) throws -> Data
}

extension CustomBotDescriptor: BotMatchParticipantBuilding {
    func skillSnapshotPayload(profile: BotSkillProfile, context: BotPlayContext) throws -> Data {
        _ = context
        let snapshot = CustomBotSkillSnapshot(
            profile: profile,
            x01Average: configuration.x01Average,
            cricketMPR: configuration.cricketMPR,
            configurationSchemaVersion: configuration.schemaVersion
        )
        return try CustomBotSkillSnapshot.encode(snapshot)
    }
}

extension TrainingBotDescriptor: BotMatchParticipantBuilding {
    func skillSnapshotPayload(profile: BotSkillProfile, context: BotPlayContext) throws -> Data {
        _ = context
        let snapshot = TrainingBotSkillSnapshot(
            profile: profile,
            linkedPlayerId: linkedPlayerId,
            sourcePlayerAvg: nil,
            sourcePlayerMPR: nil
        )
        return try TrainingBotSkillSnapshot.encode(snapshot)
    }
}
