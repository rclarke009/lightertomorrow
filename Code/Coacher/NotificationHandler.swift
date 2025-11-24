import Foundation
import UserNotifications
import SwiftUI

class NotificationHandler: NSObject, ObservableObject {
    static let shared = NotificationHandler()
    
    @Published var shouldNavigateToSection: String?
    @Published var shouldShowTab: Int = 0 // 0 = Today, 1 = Coach, 2 = History, 3 = Settings
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        if let destination = userInfo["destination"] as? String {
            switch destination {
            case "nightPrep":
                shouldNavigateToSection = "nightPrep"
                shouldShowTab = 0 // Today tab
            case "morningFocus":
                shouldNavigateToSection = "morningFocus"
                shouldShowTab = 0 // Today tab
            default:
                break
            }
        }
    }
}

extension NotificationHandler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleNotificationResponse(response)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
