import Foundation

/// Drives the Settings CSV flows: importing a roster from a user-picked file
/// and producing the downloadable template. Kept separate from
/// `SettingsViewModel` because it depends on the player repository rather than
/// the settings repository.
@MainActor
final class SettingsDataTransferViewModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case importing
        case imported(PlayerImportResult)
        case failed(String)
    }

    @Published private(set) var status: Status = .idle

    private let playerRepository: any PlayerRepository
    private let logger: any AppLogger
    private var importTask: Task<Void, Never>?

    init(playerRepository: any PlayerRepository, logger: any AppLogger) {
        self.playerRepository = playerRepository
        self.logger = logger
    }

    deinit {
        importTask?.cancel()
    }

    /// Localized summary string for the most recent import, or `nil` when idle.
    var resultMessage: String? {
        switch status {
        case .idle:
            return nil
        case .importing:
            return L10n.string("settings.csv.import.inProgress")
        case let .imported(result):
            return L10n.format("settings.csv.import.result", result.imported, result.skipped)
        case let .failed(messageKey):
            return L10n.string(messageKey)
        }
    }

    var isImporting: Bool {
        if case .importing = status { return true }
        return false
    }

    /// Handles the result delivered by SwiftUI's `.fileImporter`.
    func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            startImport(from: url)
        case .failure:
            status = .failed("settings.csv.import.error.read")
        }
    }

    private func startImport(from url: URL) {
        importTask?.cancel()
        status = .importing
        importTask = Task { await self.runImport(from: url) }
    }

    private func runImport(from url: URL) async {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }

        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            status = .failed("settings.csv.import.error.read")
            return
        }

        let rows: [PlayerCSV.ImportRow]
        do {
            rows = try PlayerCSV.parse(text)
        } catch {
            status = .failed("settings.csv.import.error.format")
            return
        }

        guard !rows.isEmpty else {
            status = .failed("settings.csv.import.error.empty")
            return
        }

        do {
            let result = try await playerRepository.importPlayers(rows)
            status = .imported(result)
            logger.info(
                .settings,
                eventName: "settings_csv_import",
                message: "Imported players from CSV.",
                metadata: ["imported": String(result.imported), "skipped": String(result.skipped)]
            )
        } catch is CancellationError {
            status = .idle
        } catch {
            status = .failed("settings.csv.import.error.save")
        }
    }

    /// Writes the CSV template to a temporary file and returns its URL for
    /// sharing. Returns `nil` if the file could not be written.
    func makeTemplateFileURL() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DartBuddy-Players-Template.csv")
        do {
            try PlayerCSV.template().write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            logger.error(
                .settings,
                eventName: "settings_csv_template_write_failed",
                message: "Failed to write CSV template file."
            )
            return nil
        }
    }
}
