# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Octowatch is a native macOS menu bar application (SwiftUI) that monitors GitHub Actions workflow runs across multiple repositories. It uses a GitHub Personal Access Token for authentication, stores it in the macOS Keychain, and polls the GitHub REST API at configurable intervals.

## Build & Run Commands

A `Makefile` is provided for convenience:

```bash
make build    # Debug build
make release  # Release build
make bundle   # Build .app bundle (release)
make run      # Build bundle and launch the app
make open     # Launch existing bundle (no rebuild)
make clean    # Remove build artifacts and .app bundle
```

There are no tests, linter, or formatter configured in this project.

## Architecture

**MVVM pattern** with a single `WorkflowViewModel` (@Observable, @MainActor) as the central state manager.

### Data Flow

```
GitHubActionsBarApp (@main)
└── MenuBarExtra
    ├── MenuBarLabel ← reads aggregateStatus
    └── MainPopoverView ← owns WorkflowViewModel
        ├── SignInView (unauthenticated)
        ├── SettingsView (polling interval, repo selection)
        └── Authenticated content (header, run list, footer)
```

### Key Components

- **WorkflowViewModel** (`ViewModels/WorkflowViewModel.swift`): Single source of truth. Manages auth state, polling loop, API calls, notification triggers, and persisted settings (UserDefaults for preferences, Keychain for PAT).
- **GitHubAPIClient** (`Services/GitHubAPIClient.swift`): Swift `actor` wrapping GitHub REST API calls. Uses `TaskGroup` for parallel multi-repo fetching.
- **KeychainService** (`Services/KeychainService.swift`): Static methods for secure PAT storage. Service ID: `com.hugobourget.Octowatch`.
- **NotificationService** (`Services/NotificationService.swift`): Sends macOS notifications when workflow runs complete.
- **Models** (`Models/WorkflowRun.swift`): All data models in one file — `WorkflowRun`, `Repository`, `GitHubUser`, status/conclusion enums, and `AggregateStatus`.

### Key Patterns

- Swift 6.0 strict concurrency (`actor` for API client, `@MainActor` for ViewModel, `Sendable` models)
- Zero external dependencies — only Swift stdlib, Foundation, SwiftUI, and UserNotifications
- `LSUIElement: true` in Info.plist (menu bar only, no dock icon)
- macOS 14.0+ minimum deployment target
