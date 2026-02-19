//
//  UserPreferences.swift
//  HealthyWork
//

import Foundation
import SwiftUI

/// How the full-screen reminder overlay is styled (inspired by Health Reminder).
enum ReminderDisplayStyle: String, Codable, CaseIterable, Identifiable {
    case modern = "Modern"
    case minimal = "Minimal"
    case bold = "Bold"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .modern:
            return "Soft gradients with gentle glow - easy on the eyes".localizedByKey
        case .minimal:
            return "Warm, clean design with reduced brightness".localizedByKey
        case .bold:
            return "Rich colors - attention-grabbing yet eye-friendly".localizedByKey
        }
    }

    var icon: String {
        switch self {
        case .modern: return "sparkles"
        case .minimal: return "minus.circle"
        case .bold: return "bolt.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .modern: return .blue
        case .minimal: return .gray
        case .bold: return .orange
        }
    }
}

/// User preferences for reminders, work hours, water, and UI. Persisted via UserDefaults.
struct UserPreferences: Codable, Equatable {

    // MARK: - Work hours
    var workStartTime: Date
    var workEndTime: Date
    var lunchStartTime: Date?
    var lunchEndTime: Date?

    // MARK: - Reminders on/off
    var waterReminderEnabled: Bool
    var eyeReminderEnabled: Bool
    var movementReminderEnabled: Bool

    // MARK: - Reminder frequency (minutes)
    var waterReminderIntervalMinutes: Int
    var eyeReminderIntervalMinutes: Int
    var movementReminderIntervalMinutes: Int

    // MARK: - Notification style
    var notificationBanner: Bool
    var notificationSound: Bool
    var notificationHaptic: Bool
    var snoozeMinutes: Int

    // MARK: - Water
    var weightKg: Double
    var gender: Gender?
    var waterGoalMlOverride: Int? // nil = auto from weight
    var waterUnit: WaterUnit
    var defaultGlassMl: Int

    // MARK: - Eye rest
    var eyeRestCountdownSeconds: Int
    var eyeRestSilentMode: Bool

    // MARK: - Movement
    var movementExercisesEnabled: [String] // exercise ids
    var movementRandomSuggestion: Bool

    // MARK: - UI
    var appearance: Appearance
    var language: Language
    var minimalMode: Bool
    /// Full-screen reminder visual style (Modern / Minimal / Bold).
    var reminderDisplayStyle: ReminderDisplayStyle

    enum Gender: String, Codable, CaseIterable {
        case male
        case female

        var localizedName: String {
            switch self {
            case .male:
                return "Male".localizedByKey
            case .female:
                return "Female".localizedByKey
            }
        }
    }

    enum WaterUnit: String, Codable, CaseIterable {
        case ml
        case oz

        var localizedName: String {
            switch self {
            case .ml:
                return "ml".localizedByKey
            case .oz:
                return "oz".localizedByKey
            }
        }
    }

    enum Appearance: String, Codable, CaseIterable {
        case light
        case dark
        case system

        var localizedName: String {
            switch self {
            case .light:
                return "Light".localizedByKey
            case .dark:
                return "Dark".localizedByKey
            case .system:
                return "System".localizedByKey
            }
        }
    }

    enum Language: String, Codable, CaseIterable {
        case vi
        case en

        var locale: Locale {
            switch self {
            case .en: return Locale(identifier: "en")
            case .vi: return Locale(identifier: "vi")
            }
        }
    }

    static let defaultWorkStart: Date = {
        var c = Calendar.current
        c.timeZone = TimeZone.current
        return c.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    }()

    static let defaultWorkEnd: Date = {
        var c = Calendar.current
        c.timeZone = TimeZone.current
        return c.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    }()

    static var `default`: UserPreferences {
        UserPreferences(
            workStartTime: defaultWorkStart,
            workEndTime: defaultWorkEnd,
            lunchStartTime: nil,
            lunchEndTime: nil,
            waterReminderEnabled: true,
            eyeReminderEnabled: true,
            movementReminderEnabled: true,
            waterReminderIntervalMinutes: 30,
            eyeReminderIntervalMinutes: 20,
            movementReminderIntervalMinutes: 45,
            notificationBanner: true,
            notificationSound: true,
            notificationHaptic: false,
            snoozeMinutes: 5,
            weightKg: 60,
            gender: nil,
            waterGoalMlOverride: nil,
            waterUnit: .ml,
            defaultGlassMl: 250,
            eyeRestCountdownSeconds: 20,
            eyeRestSilentMode: true,
            movementExercisesEnabled: ["stretch_back", "neck_roll", "walk"],
            movementRandomSuggestion: true,
            appearance: .system,
            language: .en,
            minimalMode: false,
            reminderDisplayStyle: .modern
        )
    }
}
