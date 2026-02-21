import AppKit
import Foundation
import UserNotifications

@MainActor
enum NotificationService {
    private static var currentSound: NSSound?

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
            _, _ in
        }
    }

    static func sendRunCompleted(run: WorkflowRun, playSound: Bool = true) {
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
        if playSound {
            switch run.conclusion {
            case .success:
                currentSound = NSSound(named: "Glass")
            case .failure:
                currentSound = NSSound(named: "Basso")
            default:
                currentSound = nil
            }
            currentSound?.play()
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
