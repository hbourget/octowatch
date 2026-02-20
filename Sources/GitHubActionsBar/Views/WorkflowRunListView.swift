import SwiftUI

struct WorkflowRunListView: View {
    let runs: [WorkflowRun]
    var isLoading: Bool

    var body: some View {
        if runs.isEmpty && !isLoading {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "tray")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("No workflow runs")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(runs) { run in
                            WorkflowRunRow(run: run, now: context.date)
                            if run.id != runs.last?.id {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
        }
    }
}
