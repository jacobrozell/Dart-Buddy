import Foundation

/// Pure, dependency-free helpers for serializing and parsing player rosters as
/// CSV. Used by the Settings import/template/export flows and the migration
/// recovery export. Kept free of persistence types so it stays trivially
/// testable.
public enum PlayerCSV {
    /// Canonical column order for exports and the downloadable template.
    public static let columns = ["name", "isBot", "botDifficulty", "avatarStyle", "colorToken", "notes"]

    /// Header line shared by exports and the template.
    public static let header = columns.joined(separator: ",")

    /// A single decoded roster row. Only `name` is required; everything else is
    /// optional and falls back to sensible defaults at import time.
    public struct ImportRow: Equatable, Sendable {
        public let name: String
        public let isBot: Bool
        public let botDifficultyRaw: String?
        public let avatarStyleRaw: String?
        public let colorTokenRaw: String?
        public let notes: String?

        public init(
            name: String,
            isBot: Bool = false,
            botDifficultyRaw: String? = nil,
            avatarStyleRaw: String? = nil,
            colorTokenRaw: String? = nil,
            notes: String? = nil
        ) {
            self.name = name
            self.isBot = isBot
            self.botDifficultyRaw = botDifficultyRaw
            self.avatarStyleRaw = avatarStyleRaw
            self.colorTokenRaw = colorTokenRaw
            self.notes = notes
        }
    }

    public enum ParseError: Error, Equatable {
        /// The file had no content rows under the header.
        case empty
        /// The header row did not contain a `name` column.
        case missingNameColumn
    }

    // MARK: - Template

    /// A ready-to-edit template with the header and two example rows: one human
    /// player and one bot. Distributed via the Settings "Download CSV Template"
    /// action.
    public static func template() -> String {
        let examples = [
            ImportRow(
                name: "Jane Smith",
                isBot: false,
                avatarStyleRaw: "dart",
                colorTokenRaw: "green",
                notes: "Lefty, prefers double 16"
            ),
            ImportRow(
                name: "Practice Bot",
                isBot: true,
                botDifficultyRaw: "medium"
            )
        ]
        return serialize(rows: examples)
    }

    // MARK: - Export

    /// Serializes summaries (typically the full roster) into CSV text.
    public static func export(_ players: [PlayerSummary]) -> String {
        let rows = players.map { player in
            ImportRow(
                name: player.name,
                isBot: player.isBot,
                botDifficultyRaw: player.botDifficultyRaw,
                avatarStyleRaw: player.avatarStyleRaw,
                colorTokenRaw: player.preferredColorToken,
                notes: player.notes
            )
        }
        return serialize(rows: rows)
    }

    /// Serializes import rows directly. Always emits the canonical header.
    public static func serialize(rows: [ImportRow]) -> String {
        var lines = [header]
        for row in rows {
            let fields = [
                row.name,
                row.isBot ? "true" : "false",
                row.botDifficultyRaw ?? "",
                row.avatarStyleRaw ?? "",
                row.colorTokenRaw ?? "",
                row.notes ?? ""
            ]
            lines.append(fields.map(escapeField).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - Parse

    /// Parses CSV text into import rows. Column order is taken from the header,
    /// so files with extra columns or a different ordering still import
    /// correctly as long as a `name` column is present. Rows without a usable
    /// name are skipped.
    public static func parse(_ text: String) throws -> [ImportRow] {
        let records = tokenize(text)
        guard let headerFields = records.first else {
            throw ParseError.empty
        }

        let keys = headerFields.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard let nameIndex = keys.firstIndex(of: "name") else {
            throw ParseError.missingNameColumn
        }

        let isBotIndex = keys.firstIndex(of: "isbot")
        let botDifficultyIndex = keys.firstIndex(of: "botdifficulty")
        let avatarIndex = keys.firstIndex(of: "avatarstyle")
        let colorIndex = keys.firstIndex(of: "colortoken")
        let notesIndex = keys.firstIndex(of: "notes")

        func field(_ record: [String], _ index: Int?) -> String? {
            guard let index, index < record.count else { return nil }
            let value = record[index].trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }

        var rows: [ImportRow] = []
        for record in records.dropFirst() {
            // Skip fully blank lines produced by trailing newlines.
            if record.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                continue
            }
            guard let name = field(record, nameIndex) else { continue }
            rows.append(
                ImportRow(
                    name: name,
                    isBot: parseBool(field(record, isBotIndex)),
                    botDifficultyRaw: field(record, botDifficultyIndex),
                    avatarStyleRaw: field(record, avatarIndex),
                    colorTokenRaw: field(record, colorIndex),
                    notes: field(record, notesIndex)
                )
            )
        }
        return rows
    }

    // MARK: - Helpers

    private static func parseBool(_ value: String?) -> Bool {
        guard let value = value?.lowercased() else { return false }
        return value == "true" || value == "yes" || value == "1" || value == "y"
    }

    /// Quotes a field per RFC 4180 when it contains a comma, quote, or newline.
    private static func escapeField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") else {
            return value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    /// Splits CSV text into records of fields, honoring RFC 4180 quoting
    /// (quoted fields may contain commas, escaped quotes, and newlines).
    private static func tokenize(_ text: String) -> [[String]] {
        var records: [[String]] = []
        var currentRecord: [String] = []
        var currentField = ""
        var inQuotes = false
        var sawAnyContent = false

        let characters = Array(text)
        var i = 0
        while i < characters.count {
            let char = characters[i]
            if inQuotes {
                if char == "\"" {
                    if i + 1 < characters.count, characters[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    currentField.append(char)
                }
            } else {
                switch char {
                case "\"":
                    inQuotes = true
                    sawAnyContent = true
                case ",":
                    currentRecord.append(currentField)
                    currentField = ""
                    sawAnyContent = true
                case "\n", "\r":
                    // Collapse \r\n into a single record break.
                    if char == "\r", i + 1 < characters.count, characters[i + 1] == "\n" {
                        i += 1
                    }
                    if sawAnyContent || !currentField.isEmpty || !currentRecord.isEmpty {
                        currentRecord.append(currentField)
                        records.append(currentRecord)
                    }
                    currentRecord = []
                    currentField = ""
                    sawAnyContent = false
                default:
                    currentField.append(char)
                    sawAnyContent = true
                }
            }
            i += 1
        }

        if !currentField.isEmpty || !currentRecord.isEmpty {
            currentRecord.append(currentField)
            records.append(currentRecord)
        }
        return records
    }
}
