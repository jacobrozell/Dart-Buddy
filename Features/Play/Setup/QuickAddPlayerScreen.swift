import SwiftUI

struct QuickAddPlayerScreen: View {
    let repository: any PlayerRepository
    let onCreated: (PlayerSummary) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isSaving = false
    @State private var errorMessageKey: String?
    @State private var createTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("players.detail.identitySection") {
                TextField("players.edit.name", text: $name)
                    .textInputAutocapitalization(.words)
            }
            if let errorMessageKey {
                Section {
                    playLocalizedText(errorMessageKey)
                        .foregroundStyle(DS.ColorRole.danger)
                }
            }
        }
        .navigationTitle(L10n.quickAddTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "common.saving" : "common.save") {
                    createTask?.cancel()
                    createTask = Task { await createPlayer() }
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onDisappear { createTask?.cancel() }
    }

    private func createPlayer() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let created = try await repository.createPlayer(name: name)
            await onCreated(created)
            dismiss()
        } catch let appError as AppError {
            errorMessageKey = appError.userMessageKey
        } catch {
            errorMessageKey = "error.player.create"
        }
    }
}
