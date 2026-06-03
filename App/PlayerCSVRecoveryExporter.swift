import Foundation
import SwiftData

/// Best-effort exporter used on the Recovery Required screen. When the app
/// fails to bootstrap we may still be able to open the store read-only and
/// rescue the player roster to a CSV file before the user resets local data.
public enum PlayerCSVRecoveryExporter {
    public enum ExportError: Error {
        case storeUnavailable
        case noPlayers
        case writeFailed
    }

    /// Attempts to read every player record directly from the on-disk store and
    /// write them to a temporary CSV file, returning its URL.
    public static func exportRoster() throws -> URL {
        guard let container = try? ModelContainerFactory.makeContainer(mode: .appDefault) else {
            throw ExportError.storeUnavailable
        }

        let context = ModelContext(container)
        let records: [SchemaV1.PlayerRecord]
        do {
            records = try context.fetch(
                FetchDescriptor<SchemaV1.PlayerRecord>(sortBy: [SortDescriptor(\.name, order: .forward)])
            )
        } catch {
            throw ExportError.storeUnavailable
        }

        guard !records.isEmpty else {
            throw ExportError.noPlayers
        }

        let rows = records.map { record in
            PlayerCSV.ImportRow(
                name: record.name,
                isBot: record.isBot ?? false,
                botDifficultyRaw: record.botDifficultyRaw,
                avatarStyleRaw: record.avatarStyleRaw,
                colorTokenRaw: record.preferredColorToken,
                notes: record.notes
            )
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DartBuddy-Players-Export.csv")
        do {
            try PlayerCSV.serialize(rows: rows).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.writeFailed
        }
        return url
    }
}
