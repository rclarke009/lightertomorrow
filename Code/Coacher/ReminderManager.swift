import Foundation
import UserNotifications
import SwiftUI

class ReminderManager: ObservableObject {
    static let shared = ReminderManager()
    
    @AppStorage("nightPrepReminder") private var nightPrepReminder = true
    @AppStorage("morningFocusReminder") private var morningFocusReminder = true
    private var nightPrepTime: Date {
        get { UserDefaults.standard.object(forKey: "nightPrepTime") as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "nightPrepTime") }
    }
    
    private var morningFocusTime: Date {
        get { UserDefaults.standard.object(forKey: "morningFocusTime") as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "morningFocusTime") }
    }
    
    // Get user's name from onboarding
    var userName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "there"
    }
    
    private init() {
        // Set default times if they haven't been set yet
        if UserDefaults.standard.object(forKey: "nightPrepTime") == nil {
            let calendar = Calendar.current
            let nightTime = calendar.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
            UserDefaults.standard.set(nightTime, forKey: "nightPrepTime")
        }
        
        if UserDefaults.standard.object(forKey: "morningFocusTime") == nil {
            let calendar = Calendar.current
            let morningTime = calendar.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
            UserDefaults.standard.set(morningTime, forKey: "morningFocusTime")
        }
    }
    
    func requestNotificationPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
    
    func scheduleReminders() async {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()

        // Schedule night prep reminder
        if nightPrepReminder {
            await scheduleNightPrepReminder()
        }
        
        // Schedule morning focus reminder
        if morningFocusReminder {
            await scheduleMorningFocusReminder()
        }
    }
    
    private func scheduleNightPrepReminder() async {
        // Check if night prep has already been completed today
        let today = Calendar.current.startOfDay(for: Date())
        if let savedDate = UserDefaults.standard.object(forKey: "nightPrepCompletedDate") as? Date,
           Calendar.current.isDate(savedDate, inSameDayAs: today) {
            // Night prep already completed today, don't schedule reminder
            return
        }
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Time for Evening Prep! 🌙"
        content.body = "Hi \(userName)! Plan your tomorrow and set yourself up for success"
        content.sound = .default
        content.userInfo = ["destination": "nightPrep"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: nightPrepTime)
        
        var trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Ensure the trigger is valid
        if trigger.nextTriggerDate() == nil {
            // If the time has passed today, schedule for tomorrow
            var tomorrow = Date()
            tomorrow = calendar.date(byAdding: .day, value: 1, to: tomorrow) ?? tomorrow
            let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            let combinedComponents = DateComponents(
                year: tomorrowComponents.year,
                month: tomorrowComponents.month,
                day: tomorrowComponents.day,
                hour: components.hour,
                minute: components.minute
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: combinedComponents, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: "nightPrepReminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            // Handle error silently
        }
    }
    
    private func scheduleMorningFocusReminder() async {
        // Check if morning flow has already been completed today
        let today = Calendar.current.startOfDay(for: Date())
        if let savedDate = UserDefaults.standard.object(forKey: "morningCompletedDate") as? Date,
           Calendar.current.isDate(savedDate, inSameDayAs: today) {
            // Morning flow already completed today, don't schedule reminder
            return
        }
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Morning Focus Time! ☀️"
        content.body = "Hi \(userName)! Review your plan and set your intentions for the day"
        content.sound = .default
        content.userInfo = ["destination": "morningFocus"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: morningFocusTime)
        
        var trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Ensure the trigger is valid
        if trigger.nextTriggerDate() == nil {
            // If the time has passed today, schedule for tomorrow
            var tomorrow = Date()
            tomorrow = calendar.date(byAdding: .day, value: 1, to: tomorrow) ?? tomorrow
            let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            let combinedComponents = DateComponents(
                year: tomorrowComponents.year,
                month: tomorrowComponents.month,
                day: tomorrowComponents.day,
                hour: components.hour,
                minute: components.minute
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: combinedComponents, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: "morningFocusReminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            // Handle error silently
        }
    }
    
    func updateReminders() async {
        await scheduleReminders()
    }
    
    func cancelMorningReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["morningFocusReminder"])
    }
    
    func cancelNightPrepReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["nightPrepReminder"])
    }
    
    func rescheduleNightPrepReminderForTomorrow() async {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Time for Evening Prep! 🌙"
        content.body = "Hi \(userName)! Plan your tomorrow and set yourself up for success"
        content.sound = .default
        content.userInfo = ["destination": "nightPrep"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: nightPrepTime)
        
        // Schedule for tomorrow at the same time
        var tomorrow = Date()
        tomorrow = calendar.date(byAdding: .day, value: 1, to: tomorrow) ?? tomorrow
        let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        let combinedComponents = DateComponents(
            year: tomorrowComponents.year,
            month: tomorrowComponents.month,
            day: tomorrowComponents.day,
            hour: components.hour,
            minute: components.minute
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: combinedComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "nightPrepReminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            // Handle error silently
        }
    }

}