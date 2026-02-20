import SwiftUI

struct MainPopoverView: View {
    @Bindable var viewModel: WorkflowViewModel

    var body: some View {
        Group {
            if !viewModel.isAuthenticated {
                SignInView(viewModel: viewModel)
            } else if viewModel.showSettings {
                SettingsView(viewModel: viewModel) {
                    viewModel.showSettings = false
                    viewModel.refresh()
                }
            } else {
                authenticatedContent
            }
        }
        .background(.ultraThinMaterial)
    }

    private var authenticatedContent: some View {
        VStack(spacing: 0) {
            HeaderView(
                onRefresh: { viewModel.refresh() },
                onSettings: { viewModel.showSettings = true },
                isLoading: viewModel.isLoading
            )

            Divider()

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            WorkflowRunListView(
                runs: viewModel.runs,
                isLoading: viewModel.isLoading
            )

            Divider()

            FooterView(
                username: viewModel.username,
                onSignOut: { viewModel.signOut() }
            )
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .lineLimit(2)
            Spacer()
            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.yellow.opacity(0.1))
    }
}
