import SwiftUI

/// Shared `@StateObject` host for match route screens.
struct MatchRouteScreen<VM: ObservableObject, Content: View>: View {
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: VM
    private let content: (VM, MatchLifecycleChromeDependencies) -> Content

    init(
        matchId: UUID,
        dependencies: AppDependencies,
        onShowSummary: @escaping () -> Void,
        makeViewModel: @escaping () -> VM,
        @ViewBuilder content: @escaping (VM, MatchLifecycleChromeDependencies) -> Content
    ) {
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(wrappedValue: makeViewModel())
        self.content = content
    }

    var body: some View {
        let lifecycle = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        content(viewModel, lifecycle)
    }
}
