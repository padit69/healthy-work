//
//  ReminderLog.swift
//  HealthyWork
//

import Foundation
import SwiftData
import SwiftUI

/// Log of a completed or snoozed reminder (eye rest or movement) for stats and streaks.
@Model
final class ReminderLog {
    var typeRaw: String
    var completedAt: Date
    var completed: Bool // true = user completed, false = snoozed/skipped

    var type: ReminderType {
        get { ReminderType(rawValue: typeRaw) ?? .eyeRest }
        set { typeRaw = newValue.rawValue }
    }

    init(type: ReminderType, completedAt: Date = Date(), completed: Bool) {
        self.typeRaw = type.rawValue
        self.completedAt = completedAt
        self.completed = completed
    }
}

enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case water
    case eyeRest
    case movement

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .eyeRest: return "eye.fill"
        case .movement: return "figure.stand"
        }
    }

    var color: Color {
        switch self {
        case .water: return .blue
        case .eyeRest: return .cyan
        case .movement: return .green
        }
    }

    var title: String {
        switch self {
        case .water: return "Time to Drink Water".localizedByKey
        case .eyeRest: return "Time to Rest Your Eyes".localizedByKey
        case .movement: return "Time to Stand Up".localizedByKey
        }
    }

    var subtitle: String {
        switch self {
        case .water: return "Stay hydrated for better health".localizedByKey
        case .eyeRest: return "Look at something 20 feet away".localizedByKey
        case .movement: return "Stretch and move around".localizedByKey
        }
    }

    var helper: String {
        switch self {
        case .water: return "Keep your body hydrated".localizedByKey
        case .eyeRest: return "Give your eyes a break".localizedByKey
        case .movement: return "Improve your circulation".localizedByKey
        }
    }

    /// Resolved primary/accent color: custom hex from preferences or type default.
    func primaryColor(overrideHex: String?) -> Color {
        if let hex = overrideHex, let custom = Color(hex: hex) { return custom }
        return color
    }
}
