import Foundation

// MARK: - GitHub User

struct GitHubUser: Codable, Sendable {
    let login: String
    let id: Int
    let avatarUrl: String
}

// MARK: - Repository

struct Repository: Codable, Sendable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let owner: RepositoryOwner
    let isPrivate: Bool
    let htmlUrl: String

    private enum CodingKeys: String, CodingKey {
        case id, name, fullName, owner, htmlUrl
        case isPrivate = "private"
    }
}

struct RepositoryOwner: Codable, Sendable {
    let login: String
}

// MARK: - Workflow Runs

struct WorkflowRunsResponse: Codable, Sendable {
    let totalCount: Int
    let workflowRuns: [WorkflowRun]
}

struct WorkflowRun: Codable, Sendable, Identifiable {
    let id: Int64
    let name: String?
    let headBranch: String?
    let status: RunStatus?
    let conclusion: RunConclusion?
    let htmlUrl: String
    let runStartedAt: Date?
    let updatedAt: Date
    let headCommit: HeadCommit?
    let repository: RunRepository?
    let event: String?
    let displayTitle: String?
}

struct HeadCommit: Codable, Sendable {
    let message: String?
    let author: CommitAuthor?
}

struct CommitAuthor: Codable, Sendable {
    let name: String?
}

struct RunRepository: Codable, Sendable {
    let fullName: String
}

// MARK: - Enums

enum RunStatus: String, Codable, Sendable {
    case queued
    case inProgress = "in_progress"
    case completed
    case waiting
    case requested
    case pending
}

enum RunConclusion: String, Codable, Sendable {
    case success
    case failure
    case cancelled
    case skipped
    case timedOut = "timed_out"
    case actionRequired = "action_required"
    case neutral
    case stale
    case startupFailure = "startup_failure"
}

// MARK: - Aggregate Status

enum AggregateStatus: Sendable {
    case idle
    case allGreen
    case inProgress
    case failed
    case mixed

    var iconName: String {
        switch self {
        case .idle: return "circle.dashed"
        case .allGreen: return "checkmark.circle.fill"
        case .inProgress: return "clock.arrow.circlepath"
        case .failed: return "xmark.circle.fill"
        case .mixed: return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Per-Repo Status

struct RepoStatusItem: Identifiable, Sendable, Equatable {
    let repoFullName: String
    let initial: Character
    let status: AggregateStatus
    var id: String { repoFullName }
}
