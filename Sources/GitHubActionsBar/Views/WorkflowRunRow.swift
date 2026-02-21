import SwiftUI

struct WorkflowRunRow: View {
    let run: WorkflowRun
    var now: Date = Date()

    private static let timeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        Button(action: openInBrowser) {
            HStack(spacing: 10) {
                statusDot
                    .frame(width: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(run.displayTitle ?? run.name ?? "Workflow")
                        .font(.callout.weight(.medium))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let repoName = run.repository?.fullName {
                            Text(repoName)
                                .foregroundStyle(.secondary)
                        }
                        if let branch = run.headBranch {
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Text(branch)
                                .foregroundStyle(.secondary)
                        }
                        if let duration = formattedDuration {
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Text(duration)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .font(.caption)
                    .lineLimit(1)
                }

                Spacer()

                Text(
                    Self.timeFormatter.localizedString(
                        for: run.updatedAt, relativeTo: now)
                )
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var formattedDuration: String? {
        guard let startedAt = run.runStartedAt else { return nil }
        let endDate = run.status == .completed ? run.updatedAt : now
        let seconds = Int(endDate.timeIntervalSince(startedAt))
        guard seconds >= 0 else { return nil }
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes < 60 {
            return remainingSeconds > 0 ? "\(minutes)m \(remainingSeconds)s" : "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
    }

    @ViewBuilder
    private var statusDot: some View {
        switch (run.status, run.conclusion) {
        case (.completed, .success):
            Circle().fill(.green).frame(width: 8, height: 8)
        case (.completed, .failure), (.completed, .timedOut):
            Circle().fill(.red).frame(width: 8, height: 8)
        case (.completed, .cancelled):
            Circle().fill(.gray).frame(width: 8, height: 8)
        case (.inProgress, _), (.queued, _), (.waiting, _), (.pending, _), (.requested, _):
            Circle().fill(.orange).frame(width: 8, height: 8)
        default:
            Circle().fill(.secondary).frame(width: 8, height: 8)
        }
    }

    private func openInBrowser() {
        if let url = URL(string: run.htmlUrl) {
            NSWorkspace.shared.open(url)
        }
    }
}
