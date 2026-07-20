//
//  WaterService.swift
//  WorkWell
//

import Foundation
import SwiftData

/// Water goal calculation and record aggregation.
enum WaterService {
    static let millilitersPerOunce = 29.5735

    /// Daily goal in ml (from weight/gender or override).
    static func dailyGoalMl(preferences: UserPreferences) -> Int {
        if let override = preferences.waterGoalMlOverride, override > 0 {
            return override
        }
        // Rough formula: ~30–35 ml per kg; slightly higher for male.
        guard preferences.weightKg.isFinite, preferences.weightKg > 0 else { return 0 }
        let safeWeight = min(preferences.weightKg, 500)
        let base = safeWeight * 32
        let factor: Double = preferences.gender == .male ? 1.1 : 1.0
        return Int(base * factor)
    }

    static func displayValue(forMl amountMl: Int, unit: UserPreferences.WaterUnit) -> Double {
        switch unit {
        case .ml: return Double(amountMl)
        case .oz: return Double(amountMl) / millilitersPerOunce
        }
    }

    static func milliliters(from value: Double, unit: UserPreferences.WaterUnit) -> Int {
        guard value.isFinite, value > 0 else { return 0 }
        switch unit {
        case .ml: return Int(value.rounded())
        case .oz: return Int((value * millilitersPerOunce).rounded())
        }
    }

    static func formattedAmount(
        _ amountMl: Int,
        unit: UserPreferences.WaterUnit,
        locale: Locale = .current
    ) -> String {
        switch unit {
        case .ml:
            return "\(amountMl) ml"
        case .oz:
            return String(format: "%.1f oz", locale: locale, displayValue(forMl: amountMl, unit: unit))
        }
    }

    /// Add a water record and save to context.
    static func addRecord(amountMl: Int, date: Date = Date(), context: ModelContext) {
        guard amountMl > 0 else { return }
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
        let descriptor = FetchDescriptor<WaterRecord>(predicate: predicate)
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
