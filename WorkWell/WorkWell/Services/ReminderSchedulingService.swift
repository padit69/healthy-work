//
//  ReminderSchedulingService.swift
//  WorkWell
//

import Foundation
@preconcurrency import UserNotifications
import os

/// A concrete reminder occurrence shared by the menu countdown, the in-app timer,
/// and the macOS notification scheduler.
struct ScheduledReminderOccurrence: Equatable {
    let identifier: String
    let type: ReminderType
    let date: Date
    let isSnooze: Bool
}

/// Schedules and manages local notifications for water, eye rest, and movement.
enum ReminderSchedulingService {

    static let waterCategoryIdentifier = "WATER"
    static let eyeRestCategoryIdentifier = "EYE_REST"
    static let movementCategoryIdentifier = "MOVEMENT"

    private static let regularIdentifierPrefix = "regular."
    private static let snoozeIdentifierPrefix = "snooze."
    private static let snoozeStorageKey = "com.hihiteam.working.care.pendingSnoozes"
    /// Keep below the platform's pending-request ceiling and refresh the rolling
    /// window while the menu-bar app is alive.
    private static let maximumRegularNotificationRequests = 60
    private static var rescheduleRevision = 0

    private struct StoredSnooze: Codable, Equatable {
        let identifier: String
        let typeRawValue: String
        let fireDate: Date

        var type: ReminderType? { ReminderType(rawValue: typeRawValue) }
    }

    // MARK: - Authorization and system scheduling

    /// Request notification permission only when the user has not answered yet.
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async { completion(granted) }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async { completion(true) }
            case .denied:
                DispatchQueue.main.async { completion(false) }
            @unknown default:
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    static func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    /// Replace regular reminder requests while preserving one-off snoozes.
    /// All requests use explicit dates and the same occurrence identifiers as the
    /// in-app timer, so the two delivery paths can be de-duplicated reliably.
    @MainActor
    static func rescheduleAll(preferences: UserPreferences, now: Date = Date()) {
        rescheduleRevision += 1
        let revision = rescheduleRevision
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { pendingRequests in
            DispatchQueue.main.async {
                guard revision == rescheduleRevision else { return }

                let regularIDs = pendingRequests
                    .map(\.identifier)
                    .filter(isRegularNotificationIdentifier)
                if !regularIDs.isEmpty {
                    center.removePendingNotificationRequests(withIdentifiers: regularIDs)
                }

                guard preferences.notificationBanner || preferences.notificationSound else { return }

                let horizon = Calendar.current.date(byAdding: .day, value: 2, to: now)
                    ?? now.addingTimeInterval(2 * 24 * 60 * 60)
                let occurrences = regularOccurrences(
                    preferences: preferences,
                    after: now,
                    through: horizon
                )
                .prefix(maximumRegularNotificationRequests)

                for occurrence in occurrences {
                    center.add(notificationRequest(for: occurrence, preferences: preferences)) { error in
                        if let error {
                            Logger.general.error("Unable to schedule reminder: \(error.localizedDescription, privacy: .public)")
                        }
                    }
                }
            }
        }
    }

    private static func notificationRequest(
        for occurrence: ScheduledReminderOccurrence,
        preferences: UserPreferences
    ) -> UNNotificationRequest {
        let content = notificationContent(for: occurrence.type, preferences: preferences)
        content.userInfo = [
            "type": occurrence.type.rawValue,
            "occurrenceID": occurrence.identifier,
            "isSnooze": occurrence.isSnooze
        ]

        let components = notificationDateComponents(for: occurrence.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(
            identifier: occurrence.identifier,
            content: content,
            trigger: trigger
        )
    }

    private static func notificationContent(
        for type: ReminderType,
        preferences: UserPreferences
    ) -> UNMutableNotificationContent {
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
        content.sound = shouldPlaySound(for: type, preferences: preferences) ? .default : nil
        return content
    }

    static func shouldPlaySound(for type: ReminderType, preferences: UserPreferences) -> Bool {
        preferences.notificationSound && !(type == .eyeRest && preferences.eyeRestSilentMode)
    }

    // MARK: - Snooze

    static func scheduleSnooze(identifier: String, type: ReminderType, in minutes: Int) {
        let safeMinutes = max(1, minutes)
        let fireDate = Date().addingTimeInterval(TimeInterval(safeMinutes * 60))
        let occurrenceID = identifier.hasPrefix(snoozeIdentifierPrefix)
            ? identifier
            : "\(snoozeIdentifierPrefix)\(identifier)"
        let occurrence = ScheduledReminderOccurrence(
            identifier: occurrenceID,
            type: type,
            date: fireDate,
            isSnooze: true
        )

        storeSnooze(occurrence)
        let preferences = PreferencesService.load()
        if preferences.notificationBanner || preferences.notificationSound {
            UNUserNotificationCenter.current().add(
                notificationRequest(for: occurrence, preferences: preferences)
            ) { error in
                if let error {
                    Logger.general.error("Unable to schedule snooze: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    static func removeStoredSnooze(identifier: String) {
        var snoozes = loadStoredSnoozes(referenceDate: Date())
        snoozes.removeAll { $0.identifier == identifier }
        saveStoredSnoozes(snoozes)
    }

    static func dueSnoozes(after start: Date, through end: Date) -> [ScheduledReminderOccurrence] {
        guard end >= start else { return [] }
        return loadStoredSnoozes(referenceDate: end)
            .compactMap { snooze -> ScheduledReminderOccurrence? in
                guard let type = snooze.type,
                      snooze.fireDate > start,
                      snooze.fireDate <= end else { return nil }
                return ScheduledReminderOccurrence(
                    identifier: snooze.identifier,
                    type: type,
                    date: snooze.fireDate,
                    isSnooze: true
                )
            }
            .sorted { $0.date < $1.date }
    }

    private static func storeSnooze(_ occurrence: ScheduledReminderOccurrence) {
        var snoozes = loadStoredSnoozes(referenceDate: Date())
        snoozes.removeAll { $0.identifier == occurrence.identifier }
        snoozes.append(
            StoredSnooze(
                identifier: occurrence.identifier,
                typeRawValue: occurrence.type.rawValue,
                fireDate: occurrence.date
            )
        )
        saveStoredSnoozes(snoozes)
    }

    private static func loadStoredSnoozes(referenceDate: Date) -> [StoredSnooze] {
        guard let data = UserDefaults.standard.data(forKey: snoozeStorageKey),
              let decoded = try? JSONDecoder().decode([StoredSnooze].self, from: data) else {
            return []
        }
        // Old delivered snoozes must never reappear after an app relaunch.
        return decoded.filter { $0.fireDate > referenceDate.addingTimeInterval(-60) }
    }

    private static func saveStoredSnoozes(_ snoozes: [StoredSnooze]) {
        guard let data = try? JSONEncoder().encode(snoozes) else { return }
        UserDefaults.standard.set(data, forKey: snoozeStorageKey)
    }

    // MARK: - Shared schedule calculation

    /// Work window beginning on the calendar day containing `day`. An end time
    /// earlier than or equal to the start time is treated as an overnight shift.
    static func workWindow(for preferences: UserPreferences, on day: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: day)
        let start = date(on: base, matchingTimeOf: preferences.workStartTime, calendar: calendar)
        var end = date(on: base, matchingTimeOf: preferences.workEndTime, calendar: calendar)
        if end <= start {
            end = calendar.date(byAdding: .day, value: 1, to: end)
                ?? end.addingTimeInterval(24 * 60 * 60)
        }
        return (start, end)
    }

    static func isInsideWorkSchedule(_ date: Date, preferences: UserPreferences) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
            ?? today.addingTimeInterval(-24 * 60 * 60)

        for windowDay in [yesterday, today] {
            let window = workWindow(for: preferences, on: windowDay)
            guard date >= window.0, date < window.1 else { continue }
            if let lunch = lunchWindow(for: preferences, workWindow: window),
               date >= lunch.0,
               date < lunch.1 {
                return false
            }
            return true
        }
        return false
    }

    /// All regular occurrences in `(start, end]`, sorted chronologically.
    static func regularOccurrences(
        preferences: UserPreferences,
        after start: Date,
        through end: Date
    ) -> [ScheduledReminderOccurrence] {
        guard end > start else { return [] }

        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        var windowDay = calendar.date(byAdding: .day, value: -1, to: startDay)
            ?? startDay.addingTimeInterval(-24 * 60 * 60)
        let finalDay = calendar.startOfDay(for: end)
        var result: [ScheduledReminderOccurrence] = []

        while windowDay <= finalDay {
            let window = workWindow(for: preferences, on: windowDay)
            let lunch = lunchWindow(for: preferences, workWindow: window)

            for type in ReminderType.allCases {
                guard let intervalMinutes = enabledIntervalMinutes(for: type, preferences: preferences) else {
                    continue
                }

                var fireDate = window.0.addingTimeInterval(TimeInterval(intervalMinutes * 60))
                while fireDate < window.1 {
                    if fireDate > start,
                       fireDate <= end,
                       !isInside(fireDate, interval: lunch) {
                        result.append(
                            ScheduledReminderOccurrence(
                                identifier: regularIdentifier(for: type, date: fireDate),
                                type: type,
                                date: fireDate,
                                isSnooze: false
                            )
                        )
                    }
                    fireDate = fireDate.addingTimeInterval(TimeInterval(intervalMinutes * 60))
                }
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: windowDay) else { break }
            windowDay = nextDay
        }

        return result.sorted {
            if $0.date == $1.date {
                return reminderSortIndex($0.type) < reminderSortIndex($1.type)
            }
            return $0.date < $1.date
        }
    }

    /// Next regular or snoozed occurrence for the menu-bar countdown.
    static func nextScheduledOccurrence(
        for type: ReminderType,
        preferences: UserPreferences,
        from now: Date = Date()
    ) -> ScheduledReminderOccurrence? {
        let horizon = Calendar.current.date(byAdding: .day, value: 2, to: now)
            ?? now.addingTimeInterval(2 * 24 * 60 * 60)
        let regular = regularOccurrences(preferences: preferences, after: now, through: horizon)
            .first { $0.type == type }
        let snooze = loadStoredSnoozes(referenceDate: now)
            .filter { $0.type == type && $0.fireDate > now }
            .min { $0.fireDate < $1.fireDate }
            .flatMap { stored -> ScheduledReminderOccurrence? in
                guard let storedType = stored.type else { return nil }
                return ScheduledReminderOccurrence(
                    identifier: stored.identifier,
                    type: storedType,
                    date: stored.fireDate,
                    isSnooze: true
                )
            }

        switch (regular, snooze) {
        case let (regular?, snooze?): return regular.date <= snooze.date ? regular : snooze
        case let (regular?, nil): return regular
        case let (nil, snooze?): return snooze
        case (nil, nil): return nil
        }
    }

    static func nextScheduledDate(
        for type: ReminderType,
        preferences: UserPreferences,
        from now: Date = Date()
    ) -> Date? {
        nextScheduledOccurrence(for: type, preferences: preferences, from: now)?.date
    }

    static func reminderType(for categoryIdentifier: String) -> ReminderType? {
        switch categoryIdentifier {
        case waterCategoryIdentifier: return .water
        case eyeRestCategoryIdentifier: return .eyeRest
        case movementCategoryIdentifier: return .movement
        default: return nil
        }
    }

    static func regularIdentifier(for type: ReminderType, date: Date) -> String {
        "\(regularIdentifierPrefix)\(type.rawValue).\(Int(date.timeIntervalSince1970.rounded()))"
    }

    static func notificationDateComponents(for date: Date) -> DateComponents {
        var components = Calendar.current.dateComponents(
            [.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second],
            from: date
        )
        components.nanosecond = nil
        return components
    }

    private static func enabledIntervalMinutes(
        for type: ReminderType,
        preferences: UserPreferences
    ) -> Int? {
        let enabled: Bool
        let minutes: Int
        switch type {
        case .water:
            enabled = preferences.waterReminderEnabled
            minutes = preferences.waterReminderIntervalMinutes
        case .eyeRest:
            enabled = preferences.eyeReminderEnabled
            minutes = preferences.eyeReminderIntervalMinutes
        case .movement:
            enabled = preferences.movementReminderEnabled
            minutes = preferences.movementReminderIntervalMinutes
        }
        return enabled && minutes > 0 ? minutes : nil
    }

    private static func lunchWindow(
        for preferences: UserPreferences,
        workWindow: (Date, Date)
    ) -> (Date, Date)? {
        guard let lunchStartTime = preferences.lunchStartTime,
              let lunchEndTime = preferences.lunchEndTime else { return nil }

        let calendar = Calendar.current
        let base = calendar.startOfDay(for: workWindow.0)
        var start = date(on: base, matchingTimeOf: lunchStartTime, calendar: calendar)
        var end = date(on: base, matchingTimeOf: lunchEndTime, calendar: calendar)

        // For an overnight shift, a lunch clock time earlier than the shift start
        // belongs to the following calendar day.
        if workWindow.1 > (calendar.date(byAdding: .day, value: 1, to: base) ?? workWindow.1),
           start < workWindow.0 {
            start = calendar.date(byAdding: .day, value: 1, to: start)
                ?? start.addingTimeInterval(24 * 60 * 60)
            end = calendar.date(byAdding: .day, value: 1, to: end)
                ?? end.addingTimeInterval(24 * 60 * 60)
        }
        if end <= start {
            end = calendar.date(byAdding: .day, value: 1, to: end)
                ?? end.addingTimeInterval(24 * 60 * 60)
        }
        return (start, end)
    }

    private static func date(on day: Date, matchingTimeOf time: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }

    private static func isInside(_ date: Date, interval: (Date, Date)?) -> Bool {
        guard let interval else { return false }
        return date >= interval.0 && date < interval.1
    }

    private static func reminderSortIndex(_ type: ReminderType) -> Int {
        switch type {
        case .water: return 0
        case .eyeRest: return 1
        case .movement: return 2
        }
    }

    nonisolated private static func isRegularNotificationIdentifier(_ identifier: String) -> Bool {
        if identifier.hasPrefix("regular.") { return true }

        // Remove requests created by versions that used water-0 / eye-0 /
        // movement-0 identifiers, without touching UUID-based snoozes.
        let parts = identifier.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, Int(parts[1]) != nil else { return false }
        return parts[0] == "water" || parts[0] == "eye" || parts[0] == "movement"
    }
}
