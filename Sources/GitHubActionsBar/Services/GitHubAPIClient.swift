import Foundation

actor GitHubAPIClient {
    private let session: URLSession
    private let baseURL = "https://api.github.com"
    private(set) var rateLimitRemaining: Int?
    private var etagCache: [URL: (etag: String, data: Data)] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - User

    func fetchAuthenticatedUser(token: String) async throws -> GitHubUser {
        let request = makeRequest(path: "/user", token: token)
        return try await perform(request)
    }

    // MARK: - Repos

    func fetchUserRepos(token: String) async throws -> [Repository] {
        let request = makeRequest(
            path: "/user/repos",
            queryItems: [
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "sort", value: "pushed"),
            ],
            token: token
        )
        return try await perform(request)
    }

    // MARK: - Workflow Runs

    func fetchWorkflowRuns(owner: String, repo: String, token: String) async throws
        -> WorkflowRunsResponse
    {
        let request = makeRequest(
            path: "/repos/\(owner)/\(repo)/actions/runs",
            queryItems: [
                URLQueryItem(name: "per_page", value: "15")
            ],
            token: token
        )
        return try await perform(request)
    }

    func fetchAllWorkflowRuns(repos: [(owner: String, repo: String)], token: String) async throws
        -> [WorkflowRun]
    {
        try await withThrowingTaskGroup(of: [WorkflowRun].self) { group in
            for (owner, repo) in repos {
                group.addTask {
                    let response = try await self.fetchWorkflowRuns(
                        owner: owner, repo: repo, token: token)
                    return response.workflowRuns
                }
            }

            var allRuns: [WorkflowRun] = []
            for try await runs in group {
                allRuns.append(contentsOf: runs)
            }
            return allRuns.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    // MARK: - Helpers

    private func makeRequest(
        path: String, queryItems: [URLQueryItem] = [], token: String
    ) -> URLRequest {
        var components = URLComponents(string: baseURL + path)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }

    private func perform<T: Decodable & Sendable>(_ request: URLRequest) async throws -> T {
        var request = request
        request.cachePolicy = .reloadIgnoringLocalCacheData

        if let url = request.url, let cached = etagCache[url] {
            request.setValue(cached.etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        if let httpResponse = response as? HTTPURLResponse {
            if let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining") {
                rateLimitRemaining = Int(remaining)
            }

            if httpResponse.statusCode == 304, let url = request.url, let cached = etagCache[url] {
                return try decoder.decode(T.self, from: cached.data)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }

            if let url = request.url,
                let etag = httpResponse.value(forHTTPHeaderField: "ETag")
            {
                etagCache[url] = (etag: etag, data: data)
            }
        }

        return try decoder.decode(T.self, from: data)
    }
}

enum APIError: LocalizedError {
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .httpError(401):
            return "Invalid or expired token. Please sign in again."
        case .httpError(403):
            return "Rate limit exceeded or insufficient permissions."
        case .httpError(let code):
            return "GitHub API error (HTTP \(code))"
        }
    }

    var isAuthError: Bool {
        if case .httpError(401) = self { return true }
        return false
    }
}
