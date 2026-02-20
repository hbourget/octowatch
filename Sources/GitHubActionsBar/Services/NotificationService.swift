import AppKit
import Foundation
import UserNotifications

enum NotificationService {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
            _, _ in
        }
    }

    static func sendRunCompleted(run: WorkflowRun) {
        let content = UNMutableNotificationContent()

        let repoName = run.repository?.fullName ?? "unknown"
        let runName = run.displayTitle ?? run.name ?? "Workflow"

        switch run.conclusion {
        case .success:
            content.title = "Workflow Succeeded"
        case .failure:
            content.title = "Workflow Failed"
        case .cancelled:
            content.title = "Workflow Cancelled"
        default:
            content.title = "Workflow Completed"
        }

        content.body = "\(runName) on \(repoName)"
        switch run.conclusion {
        case .success:
            NSSound(named: "Glass")?.play()
        case .failure:
            NSSound(named: "Basso")?.play()
        default:
            break
        }
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "run-\(run.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
