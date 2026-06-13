import SwiftUI

struct PlayerEditSheet: View {
    @ObservedObject var viewModel: PlayerEditViewModel
    let existing: EditablePlayer?
    let onSave: (EditablePlayer) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                TextField("players.edit.name", text: $viewModel.name)
                    .accessibilityLabel(L10n.string("players.edit.name.accessibility"))
                    .accessibilityIdentifier("playerEdit_name")
                    .onChange(of: viewModel.name) { _, _ in viewModel.validate() }
                Section(L10n.playersEditAvatar) {
                    AvatarStylePicker(selection: $viewModel.avatarStyle)
                }
                Section(L10n.playersEditColor) {
                    PlayerColorTokenPicker(selection: $viewModel.colorToken)
                }
                if viewModel.showsPrimaryToggle {
                    Section {
                        Toggle(L10n.playersPrimaryLabel, isOn: $viewModel.isPrimaryPlayer)
                            .accessibilityIdentifier("playerEdit_primaryToggle")
                    } footer: {
                        Text(L10n.playersPrimaryHint)
                    }
                }
                if viewModel.isBot, let difficulty = existing?.botDifficulty {
                    Section(L10n.botDifficultyLabel) {
                        BotDifficultyBadge(difficulty: difficulty)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowBackground(Brand.card)
                    }
                    Section(L10n.botStatsSection) {
                        BotDifficultyStatsSection(profile: difficulty.displayProfile, showsHeader: false)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(Color.clear)
                    }
                }
                TextField("players.edit.notes", text: $viewModel.notes, axis: .vertical)
                    .accessibilityLabel(L10n.string("players.edit.notes.accessibility"))
                if let message = viewModel.validationMessage {
                    Text(message).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle(
                existing == nil
                    ? L10n.addPlayerTitle
                    : (existing?.isBot == true ? L10n.editBotTitle : L10n.editPlayerTitle)
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        saveTask?.cancel()
                        saveTask = Task {
                            await onSave(viewModel.buildPlayer(from: existing))
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityLabel(L10n.string("players.edit.save.accessibility"))
                    .accessibilityIdentifier("playerEdit_save")
                }
            }
            .onDisappear { saveTask?.cancel() }
        }
    }
}
