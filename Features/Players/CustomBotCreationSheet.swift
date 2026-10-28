import SwiftUI

struct CustomBotCreationSheet: View {
    let initialMetrics: CustomBotMetrics?
    let onCreate: (String, CustomBotMetrics) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var x01Average = CustomBotMetrics.defaultX01Average
    @State private var cricketMPR = CustomBotMetrics.defaultCricketMPR

    init(
        initialMetrics: CustomBotMetrics? = nil,
        onCreate: @escaping (String, CustomBotMetrics) -> Void
    ) {
        self.initialMetrics = initialMetrics
        self.onCreate = onCreate
        _x01Average = State(initialValue: initialMetrics?.x01Average ?? CustomBotMetrics.defaultX01Average)
        _cricketMPR = State(initialValue: initialMetrics?.cricketMPR ?? CustomBotMetrics.defaultCricketMPR)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.customBotCreateSectionIdentity) {
                    TextField(L10n.customBotNamePlaceholder, text: $name)
                }
                Section {
                    CustomBotMetricsEditor(x01Average: $x01Average, cricketMPR: $cricketMPR)
                } header: {
                    Text(L10n.customBotCreateSectionStats)
                } footer: {
                    Text(L10n.customBotCreateFooter)
                }
            }
            .navigationTitle(L10n.customBotCreateTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.customBotCreateAction) {
                        let metrics = CustomBotMetrics(x01Average: x01Average, cricketMPR: cricketMPR)
                        onCreate(name, metrics)
                        dismiss()
                    }
                }
            }
        }
    }
}
