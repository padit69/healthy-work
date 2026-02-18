//
//  ReminderSchedulingService.swift
//  HealthyWork
//

import Foundation
import UserNotifications

/// Schedules and manages local notifications for water, eye rest, and movement.
enum ReminderSchedulingService {

    static let waterCategoryIdentifier = "WATER"
    static let eyeRestCategoryIdentifier = "EYE_REST"
    static let movementCategoryIdentifier = "MOVEMENT"

    /// Request notification permission. Call early (e.g. from Settings or app launch).
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Cancel all pending notifications and reschedule from preferences.
    static func rescheduleAll(preferences: UserPreferences) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let (workStart, workEnd) = workWindow(for: preferences, on: Date())

        if preferences.waterReminderEnabled {
            scheduleWaterReminders(intervalMinutes: preferences.waterReminderIntervalMinutes, from: workStart, to: workEnd)
        }
        if preferences.eyeReminderEnabled {
            scheduleEyeReminders(intervalMinutes: preferences.eyeReminderIntervalMinutes, from: workStart, to: workEnd)
        }
        if preferences.movementReminderEnabled {
            scheduleMovementReminders(intervalMinutes: preferences.movementReminderIntervalMinutes, from: workStart, to: workEnd)
        }
    }

    private static func scheduleWaterReminders(intervalMinutes: Int, from workStart: Date, to workEnd: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Water reminder"
        content.body = "Time to drink some water."
        content.categoryIdentifier = waterCategoryIdentifier
        content.sound = .default
        addRepeatingInWorkHours(intervalMinutes: intervalMinutes, from: workStart, to: workEnd, content: content, idPrefix: "water")
    }

    private static func scheduleEyeReminders(intervalMinutes: Int, from workStart: Date, to workEnd: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Eye rest (20-20-20)"
        content.body = "Look at something 6m away for 20 seconds."
        content.categoryIdentifier = eyeRestCategoryIdentifier
        content.sound = .default
        addRepeatingInWorkHours(intervalMinutes: intervalMinutes, from: workStart, to: workEnd, content: content, idPrefix: "eye")
    }

    private static func scheduleMovementReminders(intervalMinutes: Int, from workStart: Date, to workEnd: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Stand up & move"
        content.body = "Stretch your back, roll your neck, or walk 1–2 minutes."
        content.categoryIdentifier = movementCategoryIdentifier
        content.sound = .default
        addRepeatingInWorkHours(intervalMinutes: intervalMinutes, from: workStart, to: workEnd, content: content, idPrefix: "movement")
    }

    private static func addRepeatingInWorkHours(intervalMinutes: Int, from workStart: Date, to workEnd: Date, content: UNMutableNotificationContent, idPrefix: String) {
        let center = UNUserNotificationCenter.current()
        var date = workStart
        let interval = TimeInterval(intervalMinutes * 60)
        var count = 0
        while date < workEnd && count < 64 {
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date), repeats: false)
            let request = UNNotificationRequest(identifier: "\(idPrefix)-\(count)", content: content, trigger: trigger)
            center.add(request)
            date = date.addingTimeInterval(interval)
            count += 1
        }
    }

    /// Schedule a single snooze notification for a reminder type.
    static func scheduleSnooze(identifier: String, type: ReminderType, in minutes: Int) {
        let content = UNMutableNotificationContent()
        switch type {
        case .water:
            content.title = "Water reminder"
            content.body = "Time to drink some water."
            content.categoryIdentifier = waterCategoryIdentifier
        case .eyeRest:
            content.title = "Eye rest (20-20-20)"
            content.body = "Look at something 6m away for 20 seconds."
            content.categoryIdentifier = eyeRestCategoryIdentifier
        case .movement:
            content.title = "Stand up & move"
            content.body = "Stretch your back, roll your neck, or walk 1–2 minutes."
            content.categoryIdentifier = movementCategoryIdentifier
        }
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Helpers shared with menu bar countdown

    /// Work window (start/end) for a given day based on user preferences.
    static func workWindow(for preferences: UserPreferences, on day: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: day)
        let start = base + TimeInterval(calendar.component(.hour, from: preferences.workStartTime) * 3600
                                        + calendar.component(.minute, from: preferences.workStartTime) * 60)
        let end = base + TimeInterval(calendar.component(.hour, from: preferences.workEndTime) * 3600
                                      + calendar.component(.minute, from: preferences.workEndTime) * 60)
        return (start, end)
    }

    /// Next scheduled date for a reminder type based purely on preferences (work hours + interval).
    /// Does not include one-off snoozes.
    static func nextScheduledDate(for type: ReminderType, preferences: UserPreferences, from now: Date = Date()) -> Date? {
        let enabled: Bool
        let intervalMinutes: Int

        switch type {
        case .water:
            enabled = preferences.waterReminderEnabled
            intervalMinutes = preferences.waterReminderIntervalMinutes
        case .eyeRest:
            enabled = preferences.eyeReminderEnabled
            intervalMinutes = preferences.eyeReminderIntervalMinutes
        case .movement:
            enabled = preferences.movementReminderEnabled
            intervalMinutes = preferences.movementReminderIntervalMinutes
        }

        guard enabled, intervalMinutes > 0 else { return nil }

        let (workStart, workEnd) = workWindow(for: preferences, on: now)
        // If we're past today's work end, there is no next reminder today.
        guard now < workEnd else { return nil }

        let interval = TimeInterval(intervalMinutes * 60)
        var date = workStart

        // If current time is before work start, the first reminder is at workStart.
        if now <= workStart {
            return workStart
        }

        while date < workEnd {
            if date > now {
                return date
            }
            date = date.addingTimeInterval(interval)
        }
        return nil
    }
}
