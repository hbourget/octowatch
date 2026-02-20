import Foundation
import SwiftUI

@Observable
@MainActor
final class WorkflowViewModel {
    // MARK: - State

    var isAuthenticated = false
    var username = ""
    var runs: [WorkflowRun] = []
    var repos: [Repository] = []
    var isLoading = false
    var errorMessage: String?
    var showSettings = false
    var aggregateStatus: AggregateStatus = .idle
    var repoStatuses: [RepoStatusItem] = []
    var pulsePhase: Bool = false

    // MARK: - Settings (persisted)

    var pollingInterval: TimeInterval {
        get { UserDefaults.standard.double(forKey: "pollingInterval").nonZero ?? 15 }
        set {
            UserDefaults.standard.set(newValue, forKey: "pollingInterval")
            restartPolling()
        }
    }

    var selectedRepoFullNames: Set<String> {
        get {
            guard let data = UserDefaults.standard.string(forKey: "selectedRepos"),
                let names = try? JSONDecoder().decode(Set<String>.self, from: Data(data.utf8))
            else { return [] }
            return names
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
                let str = String(data: data, encoding: .utf8)
            {
                UserDefaults.standard.set(str, forKey: "selectedRepos")
            }
        }
    }

    // MARK: - Private

    private let apiClient = GitHubAPIClient()
    private var pollingTask: Task<Void, Never>?
    private var pulseTask: Task<Void, Never>?
    private var previousInProgressIds: Set<Int64> = []
    private var token: String?

    // MARK: - Init

    init() {
        if let pat = KeychainService.retrievePAT() {
            token = pat
            isAuthenticated = true
            Task { await loadInitialData() }
        }
    }

    // MARK: - Auth

    func signIn(pat: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await apiClient.fetchAuthenticatedUser(token: pat)
            try KeychainService.savePAT(pat)
            token = pat
            username = user.login
            isAuthenticated = true
            NotificationService.requestPermission()
            await loadInitialData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        stopPolling()
        stopPulse()
        KeychainService.deletePAT()
        token = nil
        isAuthenticated = false
        username = ""
        runs = []
        repos = []
        aggregateStatus = .idle
        repoStatuses = []
        showSettings = false
        errorMessage = nil
    }

    // MARK: - Data Loading

    func loadInitialData() async {
        guard let token else { return }
        isLoading = true
        errorMessage = nil
        do {
            let user = try await apiClient.fetchAuthenticatedUser(token: token)
            username = user.login

            repos = try await apiClient.fetchUserRepos(token: token)

            // Select all repos by default if none selected
            if selectedRepoFullNames.isEmpty {
                selectedRepoFullNames = Set(repos.map(\.fullName))
            }

            await fetchRuns()
            startPolling()
            startPulse()
        } catch {
            handleError(error)
        }
        isLoading = false
    }

    func fetchRuns() async {
        guard let token else { return }
        errorMessage = nil

        let activeRepos = repos.filter { selectedRepoFullNames.contains($0.fullName) }
        let repoTuples = activeRepos.map { (owner: $0.owner.login, repo: $0.name) }

        guard !repoTuples.isEmpty else {
            runs = []
            aggregateStatus = .idle
            repoStatuses = []
            return
        }

        do {
            let newRuns = try await apiClient.fetchAllWorkflowRuns(
                repos: repoTuples, token: token)
            detectCompletions(newRuns: newRuns)
            runs = newRuns
            aggregateStatus = computeAggregateStatus(newRuns)
            repoStatuses = computeRepoStatuses(newRuns)

            if let remaining = await apiClient.rateLimitRemaining, remaining < 100 {
                errorMessage = "Rate limit low: \(remaining) requests remaining"
            }
        } catch {
            handleError(error)
        }
    }

    func refresh() {
        Task { await fetchRuns() }
    }

    // MARK: - Polling

    func startPolling() {
        stopPolling()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(pollingInterval))
                guard !Task.isCancelled else { break }
                await fetchRuns()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func restartPolling() {
        if isAuthenticated {
            startPolling()
        }
    }

    // MARK: - Notifications

    private func detectCompletions(newRuns: [WorkflowRun]) {
        let newInProgressIds = Set(
            newRuns
                .filter { $0.status == .inProgress || $0.status == .queued }
                .map(\.id)
        )

        for run in newRuns where run.status == .completed {
            if previousInProgressIds.contains(run.id) {
                NotificationService.sendRunCompleted(run: run)
            }
        }

        previousInProgressIds = newInProgressIds
    }

    // MARK: - Helpers

    private func computeRepoStatuses(_ runs: [WorkflowRun]) -> [RepoStatusItem] {
        var grouped: [String: [WorkflowRun]] = [:]
        for run in runs {
            guard let fullName = run.repository?.fullName else { continue }
            grouped[fullName, default: []].append(run)
        }

        return grouped.keys.sorted().compactMap { fullName in
            guard let repoRuns = grouped[fullName] else { return nil }
            let repoName = fullName.split(separator: "/").last.map(String.init) ?? fullName
            guard let initial = repoName.first?.uppercased().first else { return nil }
            let status = computeAggregateStatus(repoRuns)
            return RepoStatusItem(repoFullName: fullName, initial: initial, status: status)
        }
    }

    private func startPulse() {
        stopPulse()
        pulseTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { break }
                pulsePhase.toggle()
            }
        }
    }

    private func stopPulse() {
        pulseTask?.cancel()
        pulseTask = nil
    }

    private func latestRunPerWorkflow(_ runs: [WorkflowRun]) -> [WorkflowRun] {
        var seen: Set<String> = []
        return runs
            .sorted { $0.updatedAt > $1.updatedAt }
            .filter { run in
                guard let name = run.name else { return true }
                return seen.insert(name).inserted
            }
    }

    private func computeAggregateStatus(_ runs: [WorkflowRun]) -> AggregateStatus {
        let latest = latestRunPerWorkflow(runs)
        guard !latest.isEmpty else { return .idle }

        let hasInProgress = latest.contains {
            $0.status == .inProgress || $0.status == .queued
        }
        let hasFailed = latest.contains {
            $0.conclusion == .failure || $0.conclusion == .timedOut
        }
        let hasSuccess = latest.contains { $0.conclusion == .success }

        if hasInProgress { return .inProgress }
        if hasFailed && hasSuccess { return .mixed }
        if hasFailed { return .failed }
        if hasSuccess { return .allGreen }
        return .idle
    }

    private func handleError(_ error: Error) {
        if let apiError = error as? APIError, apiError.isAuthError {
            signOut()
            errorMessage = "Session expired. Please sign in again."
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Double Extension

extension Double {
    var nonZero: Double? {
        self == 0 ? nil : self
    }
}
