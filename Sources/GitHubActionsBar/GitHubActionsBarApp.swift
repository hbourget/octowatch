import SwiftUI

@main
struct GitHubActionsBarApp: App {
    @State private var viewModel = WorkflowViewModel()

    var body: some Scene {
        MenuBarExtra {
            MainPopoverView(viewModel: viewModel)
                .frame(width: 400, height: 500)
        } label: {
            MenuBarLabel(status: viewModel.aggregateStatus)
        }
        .menuBarExtraStyle(.window)
    }
}
