import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: WorkflowViewModel
    let onBack: () -> Void

    private let intervals: [(label: String, value: TimeInterval)] = [
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Settings")
                    .font(.headline)

                Spacer()

                // Invisible balance element
                Label("Back", systemImage: "chevron.left")
                    .hidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Polling interval
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Polling Interval")
                            .font(.callout.bold())

                        Picker("", selection: Binding(
                            get: { viewModel.pollingInterval },
                            set: { viewModel.pollingInterval = $0 }
                        )) {
                            ForEach(intervals, id: \.value) { interval in
                                Text(interval.label).tag(interval.value)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    Divider()

                    // Repo selection
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Repositories")
                                .font(.callout.bold())

                            Spacer()

                            Text("\(viewModel.selectedRepoFullNames.count) selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if viewModel.repos.isEmpty {
                            Text("No repositories found.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.repos) { repo in
                                Toggle(isOn: Binding(
                                    get: {
                                        viewModel.selectedRepoFullNames.contains(repo.fullName)
                                    },
                                    set: { enabled in
                                        if enabled {
                                            viewModel.selectedRepoFullNames.insert(repo.fullName)
                                        } else {
                                            viewModel.selectedRepoFullNames.remove(repo.fullName)
                                        }
                                    }
                                )) {
                                    VStack(alignment: .leading) {
                                        Text(repo.fullName)
                                            .font(.callout)
                                        if repo.isPrivate {
                                            Text("Private")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}
