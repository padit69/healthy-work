//
//  WaterService.swift
//  HealthyWork
//

import Foundation
import SwiftData

/// Water goal calculation and record aggregation.
enum WaterService {

    /// Daily goal in ml (from weight/gender or override).
    static func dailyGoalMl(preferences: UserPreferences) -> Int {
        if let override = preferences.waterGoalMlOverride, override > 0 {
            return override
        }
        // Rough formula: ~30–35 ml per kg; slightly higher for male.
        let base = preferences.weightKg * 32
        let factor: Double = preferences.gender == .male ? 1.1 : 1.0
        return Int(base * factor)
    }

    /// Add a water record and save to context.
    static func addRecord(amountMl: Int, date: Date = Date(), context: ModelContext) {
        let record = WaterRecord(date: date, amountMl: amountMl, loggedAt: Date())
        context.insert(record)
        try? context.save()
    }

    /// Total ml consumed on a given calendar day.
    static func totalMl(for date: Date, in context: ModelContext) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = #Predicate<WaterRecord> { record in
            record.date >= start && record.date < end
        }
        var descriptor = FetchDescriptor<WaterRecord>(predicate: predicate)
        guard let list = try? context.fetch(descriptor) else { return 0 }
        return list.reduce(0) { $0 + $1.amountMl }
    }

    /// Daily totals for the last 7 days (for chart). Ordered oldest first.
    static func dailyTotalsLast7Days(context: ModelContext) -> [(date: Date, ml: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset -> (Date, Int)? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let ml = totalMl(for: day, in: context)
            return (day, ml)
        }
    }
}
