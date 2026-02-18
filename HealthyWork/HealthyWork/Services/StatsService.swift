//
//  StatsService.swift
//  HealthyWork
//

import Foundation
import SwiftData

/// Aggregates stats for water, eye rest, movement and streaks.
enum StatsService {
    private static let calendar = Calendar.current

    static func waterCountToday(context: ModelContext) -> Int {
        let today = calendar.startOfDay(for: Date())
        let predicate = #Predicate<WaterRecord> { record in
            record.date >= today
        }
        var descriptor = FetchDescriptor<WaterRecord>(predicate: predicate)
        guard let list = try? context.fetch(descriptor) else { return 0 }
        return list.count
    }

    static func eyeRestCompletedToday(context: ModelContext) -> Int {
        countReminderLogs(type: .eyeRest, completed: true, context: context)
    }

    static func movementCompletedToday(context: ModelContext) -> Int {
        countReminderLogs(type: .movement, completed: true, context: context)
    }

    private static func countReminderLogs(type: ReminderType, completed: Bool, context: ModelContext) -> Int {
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()
        let raw = type.rawValue
        let predicate = #Predicate<ReminderLog> { log in
            log.typeRaw == raw && log.completed == completed && log.completedAt >= start && log.completedAt < end
        }
        var descriptor = FetchDescriptor<ReminderLog>(predicate: predicate)
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Current streak: consecutive days (going backward from today) with at least one activity.
    static func currentStreak(context: ModelContext) -> Int {
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while true {
            let waterMl = WaterService.totalMl(for: day, in: context)
            let eyeCount = countReminderLogsForDay(type: .eyeRest, completed: true, day: day, context: context)
            let moveCount = countReminderLogsForDay(type: .movement, completed: true, day: day, context: context)
            let hasActivity = waterMl > 0 || eyeCount > 0 || moveCount > 0
            if hasActivity {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else {
                break
            }
        }
        return streak
    }

    private static func countReminderLogsForDay(type: ReminderType, completed: Bool, day: Date, context: ModelContext) -> Int {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let raw = type.rawValue
        let predicate = #Predicate<ReminderLog> { log in
            log.typeRaw == raw && log.completed == completed && log.completedAt >= start && log.completedAt < end
        }
        var descriptor = FetchDescriptor<ReminderLog>(predicate: predicate)
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    static func logReminder(type: ReminderType, completed: Bool, context: ModelContext) {
        let log = ReminderLog(type: type, completedAt: Date(), completed: completed)
        context.insert(log)
        try? context.save()
    }
}
