import SwiftUI

struct MigrationRecoveryView: View {
    @StateObject private var viewModel: MigrationRecoveryViewModel

    init(
        context: MigrationRecoveryContext,
        retryHandler: @escaping @MainActor () async -> Bool,
        resetHandler: @escaping @MainActor () async -> Bool
    ) {
        _viewModel = StateObject(
            wrappedValue: MigrationRecoveryViewModel(
                context: context,
                retryHandler: retryHandler,
                resetHandler: resetHandler
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.migrationTitle)
                .font(.title2)
                .bold()
            Text(L10n.migrationMessage)
                .foregroundStyle(DS.ColorRole.textSecondary)
            if viewModel.context.options.canRetry {
                Button(L10n.migrationRetry) { viewModel.tapRetry() }
            }
            if viewModel.context.options.canExportDiagnostics {
                Button(L10n.migrationExport) { viewModel.tapExportDiagnostics() }
            }
            if viewModel.context.options.canResetData {
                Button(L10n.migrationReset, role: .destructive) { viewModel.tapResetLocalData() }
            }
            Text(L10n.format("migration.errorKeyFormat", viewModel.context.error.userMessageKey))
                .font(.footnote)
                .foregroundStyle(DS.ColorRole.textSecondary)
            Text(L10n.format("migration.stateFormat", String(describing: viewModel.state)))
                .font(.footnote)
                .foregroundStyle(DS.ColorRole.textSecondary)
            if case let .exportCompleted(path) = viewModel.state {
                Text(L10n.format("migration.diagnosticsExported", path))
                    .font(.footnote)
                    .foregroundStyle(DS.ColorRole.textSecondary)
            }
        }
        .padding(24)
    }
}
