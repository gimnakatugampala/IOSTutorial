//
//  NotificationService.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//
//  Thin wrapper around UNUserNotificationCenter for the daily challenge
//  reminder. Kept as static functions — this is a stateless bridge to the
//  framework, not something that needs its own instance/lifecycle.

import Foundation
import UserNotifications

enum NotificationService {

    static let dailyReminderID = "daily-challenge-reminder"
    static let testNotificationID = "test-notification"

    /// Requests notification permission. Calls back on the main thread with
    /// whether it was actually granted, so the caller can roll a toggle back
    /// off if the user denies (or had already denied previously).
    static func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Reflects the *real* system permission state — used on appear so the
    /// Settings toggle doesn't stay "on" if the user revoked permission from
    /// the iOS Settings app after enabling it in ours.
    static func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    /// Schedules (or reschedules) a repeating daily reminder at the given
    /// time. Always clears any previously pending reminder first so there's
    /// never more than one in flight.
    static func scheduleDaily(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        let content = UNMutableNotificationContent()
        content.title = "Daily Challenge"
        content.body = "Your streak is waiting — play a quick round before the day's over!"
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: time)
        dateComponents.minute = calendar.component(.minute, from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        center.add(request)
    }

    /// Cancels the daily reminder — called when the user flips the toggle off.
    static func cancelDaily() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }

    /// Fires a one-off notification a few seconds out, so the feature can be
    /// demoed/verified immediately instead of waiting for the scheduled time.
    static func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is what your daily reminder will look like!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: testNotificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

/// Lets notification banners/sounds appear while the app is in the
/// foreground. Without this, tapping "Send Test Notification" while sitting
/// in Settings would silently do nothing until the app is backgrounded.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    private override init() {}

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
