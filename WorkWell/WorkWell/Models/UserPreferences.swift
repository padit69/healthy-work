//
//  UserPreferences.swift
//  WorkWell
//

import Foundation
import SwiftUI

/// Background appearance for full-screen reminder overlay (per reminder type).
enum ReminderBackgroundStyle: String, Codable, CaseIterable, Identifiable {
    case clear
    case blur
    case solid

    var id: String { rawValue }
}

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
    /// When true, show full-screen reminder when a notification fires; when false, only system notification (nil = true for backward compat).
    var fullScreenReminderEnabled: Bool?

    // MARK: - Focus action (per reminder: when on, buttons disabled until condition)
    /// When true, water reminder requires waiting min countdown before allowing I drank / Skip.
    var waterFocusActionEnabled: Bool?
    /// Seconds to wait when focus is on before enabling water reminder buttons (10–100).
    var waterFocusMinSeconds: Int?
    /// When true, eye rest reminder requires waiting full countdown before allowing Skip.
    var eyeRestFocusActionEnabled: Bool?
    /// When true, movement reminder requires waiting min countdown before allowing Done / In a meeting.
    var movementFocusActionEnabled: Bool?
    /// Seconds to wait when focus is on before enabling movement reminder buttons (10–100).
    var movementFocusMinSeconds: Int?

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

    // MARK: - Reminder appearance (per type)
    /// Background style for full-screen reminder: clear, blur, or solid (nil = .blur for backward compat).
    var reminderWaterBackgroundStyle: ReminderBackgroundStyle?
    var reminderEyeRestBackgroundStyle: ReminderBackgroundStyle?
    var reminderMovementBackgroundStyle: ReminderBackgroundStyle?
    /// Primary/accent color override per type (hex "#RRGGBB"). Nil = use type default.
    var reminderWaterPrimaryColorHex: String?
    var reminderEyeRestPrimaryColorHex: String?
    var reminderMovementPrimaryColorHex: String?

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
            fullScreenReminderEnabled: true, // optional in struct for backward compat; default true
            waterFocusActionEnabled: false,
            waterFocusMinSeconds: 30,
            eyeRestFocusActionEnabled: false,
            movementFocusActionEnabled: false,
            movementFocusMinSeconds: 30,
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
            reminderDisplayStyle: .modern,
            reminderWaterBackgroundStyle: .blur,
            reminderEyeRestBackgroundStyle: .blur,
            reminderMovementBackgroundStyle: .blur,
            reminderWaterPrimaryColorHex: nil,
            reminderEyeRestPrimaryColorHex: nil,
            reminderMovementPrimaryColorHex: nil
        )
    }

    /// Resolved background style for a reminder type (nil prefs → .blur).
    func reminderBackgroundStyle(for type: ReminderType) -> ReminderBackgroundStyle {
        switch type {
        case .water: return reminderWaterBackgroundStyle ?? .blur
        case .eyeRest: return reminderEyeRestBackgroundStyle ?? .blur
        case .movement: return reminderMovementBackgroundStyle ?? .blur
        }
    }

    /// Primary color override hex for a reminder type. Nil = use type default.
    func reminderPrimaryColorHex(for type: ReminderType) -> String? {
        switch type {
        case .water: return reminderWaterPrimaryColorHex
        case .eyeRest: return reminderEyeRestPrimaryColorHex
        case .movement: return reminderMovementPrimaryColorHex
        }
    }
}
