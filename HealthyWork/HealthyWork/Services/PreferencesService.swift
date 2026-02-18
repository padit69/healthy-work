//
//  PreferencesService.swift
//  HealthyWork
//

import Foundation

private let preferencesKey = "com.hihiteam.care.HealthyWork.userPreferences"

/// Loads and saves user preferences to UserDefaults.
enum PreferencesService {
    private static let defaults = UserDefaults.standard

    static func load() -> UserPreferences {
        guard let data = defaults.data(forKey: preferencesKey),
              let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return .default
        }
        return decoded
    }

    static func save(_ preferences: UserPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: preferencesKey)
    }
}
