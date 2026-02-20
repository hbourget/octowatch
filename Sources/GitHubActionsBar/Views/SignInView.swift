import SwiftUI

struct SignInView: View {
    @Bindable var viewModel: WorkflowViewModel
    @State private var pat = ""

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Octowatch")
                .font(.title2.bold())

            Text("Enter a Personal Access Token\nwith **repo** and **workflow** scopes.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("ghp_...", text: $pat)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
                .onSubmit { signIn() }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 40)
            }

            Button(action: signIn) {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(pat.isEmpty || viewModel.isLoading)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func signIn() {
        let trimmed = pat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task { await viewModel.signIn(pat: trimmed) }
    }
}
