//
//  PreferencesService.swift
//  WorkWell
//

import Foundation

private let preferencesKey = "com.hihiteam.working.care.userPreferences"
private let legacyPreferencesKey = "com.hihiteam.care.WorkWell.userPreferences"

/// Loads and saves user preferences to UserDefaults.
enum PreferencesService {
    private static let defaults = UserDefaults.standard

    static func load() -> UserPreferences {
        if let preferences = decodePreferences(forKey: preferencesKey) {
            return preferences
        }

        if let legacyPreferences = decodePreferences(forKey: legacyPreferencesKey) {
            save(legacyPreferences)
            return legacyPreferences
        }

        return .default
    }

    static func save(_ preferences: UserPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: preferencesKey)
    }

    private static func decodePreferences(forKey key: String) -> UserPreferences? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserPreferences.self, from: data)
    }
}
