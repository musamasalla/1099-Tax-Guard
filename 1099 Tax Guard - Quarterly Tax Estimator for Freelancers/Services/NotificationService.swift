//
//  NotificationService.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import Foundation
import Combine
import UserNotifications

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Schedule Quarterly Payment Reminders
    func scheduleQuarterlyReminders() {
        // Cancel existing reminders first
        cancelAllReminders()
        
        let currentYear = QuarterHelper.currentYear()
        let years = [currentYear, currentYear + 1]
        
        for year in years {
            for quarter in 1...4 {
                let dueDate = QuarterHelper.dueDate(for: quarter, year: year)
                
                // Only schedule future reminders
                guard dueDate > Date() else { continue }
                
                // 7 days before
                scheduleReminder(
                    for: quarter,
                    year: year,
                    dueDate: dueDate,
                    daysBefore: 7,
                    title: "Quarterly Tax Reminder",
                    body: "Your Q\(quarter) estimated tax payment is due in 7 days."
                )
                
                // 3 days before
                scheduleReminder(
                    for: quarter,
                    year: year,
                    dueDate: dueDate,
                    daysBefore: 3,
                    title: "Tax Payment Due Soon",
                    body: "Only 3 days until your Q\(quarter) estimated tax payment is due!"
                )
                
                // 1 day before
                scheduleReminder(
                    for: quarter,
                    year: year,
                    dueDate: dueDate,
                    daysBefore: 1,
                    title: "Tax Payment Due Tomorrow!",
                    body: "Your Q\(quarter) estimated tax payment is due tomorrow. Tap to pay now."
                )
                
                // Day of
                scheduleReminder(
                    for: quarter,
                    year: year,
                    dueDate: dueDate,
                    daysBefore: 0,
                    title: "🚨 Tax Payment Due Today",
                    body: "Your Q\(quarter) estimated tax payment is due today. Pay now to avoid penalties."
                )
            }
        }
        
        refreshPendingNotifications()
    }
    
    private func scheduleReminder(
        for quarter: Int,
        year: Int,
        dueDate: Date,
        daysBefore: Int,
        title: String,
        body: String
    ) {
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: dueDate),
              reminderDate > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "quarter": quarter,
            "year": year,
            "type": "quarterly_reminder"
        ]
        
        // Set reminder for 9 AM local time
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let identifier = "tax_reminder_Q\(quarter)_\(year)_\(daysBefore)days"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Reminders
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        refreshPendingNotifications()
    }
    
    func cancelReminder(for quarter: Int, year: Int) {
        let identifiersToRemove = [
            "tax_reminder_Q\(quarter)_\(year)_7days",
            "tax_reminder_Q\(quarter)_\(year)_3days",
            "tax_reminder_Q\(quarter)_\(year)_1days",
            "tax_reminder_Q\(quarter)_\(year)_0days"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        refreshPendingNotifications()
    }
    
    // MARK: - Pending Notifications
    func refreshPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    // MARK: - Custom Reminder
    func scheduleCustomReminder(title: String, body: String, date: Date, identifier: String) {
        guard date > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling custom notification: \(error)")
            }
        }
        
        refreshPendingNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String, type == "quarterly_reminder" {
            // Handle tap on quarterly reminder - could navigate to payment screen
            NotificationCenter.default.post(name: .didTapQuarterlyReminder, object: nil, userInfo: userInfo)
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didTapQuarterlyReminder = Notification.Name("didTapQuarterlyReminder")
}
