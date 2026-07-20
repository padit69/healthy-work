//
//  PreferencesService.swift
//  WorkWell
//

import Foundation

private let preferencesKey = "com.hihiteam.working.care.userPreferences"
private let legacyPreferencesKey = "com.hihiteam.care.WorkWell.userPreferences"
private let preferencesUpdatedAtKey = "com.hihiteam.working.care.userPreferencesUpdatedAt"
private let iCloudPreferencesKey = "com.hihiteam.working.care.iCloudUserPreferences"

extension Notification.Name {
    static let preferencesDidChangeFromICloud = Notification.Name("PreferencesDidChangeFromICloud")
}

/// Loads and saves user preferences to UserDefaults.
enum PreferencesService {
    private struct SyncedPreferencesEnvelope: Codable {
        let preferences: UserPreferences
        let updatedAt: Date
    }

    private static let defaults = UserDefaults.standard
    private static let iCloudStore = NSUbiquitousKeyValueStore.default
    private static var iCloudObserver: NSObjectProtocol?

    static func startICloudSync() {
        guard ICloudSyncService.hasRequiredEntitlements,
              iCloudObserver == nil else { return }

        iCloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore,
            queue: .main
        ) { _ in
            importICloudPreferences(notify: true, requireNewerTimestamp: false)
        }

        iCloudStore.synchronize()
        if cloudEnvelope() == nil {
            let preferences = loadLocalPreferences() ?? .default
            let now = Date()
            saveLocally(preferences, updatedAt: now)
            saveToICloud(preferences, updatedAt: now)
        } else {
            importICloudPreferences(notify: false)
        }
    }

    static func load() -> UserPreferences {
        if ICloudSyncService.hasRequiredEntitlements {
            importICloudPreferences(notify: false)
        }

        if let preferences = loadLocalPreferences() {
            return preferences
        }

        if let legacyPreferences = decodePreferences(forKey: legacyPreferencesKey) {
            save(legacyPreferences)
            return legacyPreferences
        }

        return .default
    }

    static func save(_ preferences: UserPreferences) {
        let now = Date()
        saveLocally(preferences, updatedAt: now)
        saveToICloud(preferences, updatedAt: now)
    }

    private static func loadLocalPreferences() -> UserPreferences? {
        decodePreferences(forKey: preferencesKey)
    }

    private static func saveLocally(_ preferences: UserPreferences, updatedAt: Date) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: preferencesKey)
        defaults.set(updatedAt, forKey: preferencesUpdatedAtKey)
    }

    private static func saveToICloud(_ preferences: UserPreferences, updatedAt: Date) {
        guard ICloudSyncService.hasRequiredEntitlements else { return }
        let envelope = SyncedPreferencesEnvelope(preferences: preferences, updatedAt: updatedAt)
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        iCloudStore.set(data, forKey: iCloudPreferencesKey)
        iCloudStore.synchronize()
    }

    private static func cloudEnvelope() -> SyncedPreferencesEnvelope? {
        guard let data = iCloudStore.data(forKey: iCloudPreferencesKey) else { return nil }
        return try? JSONDecoder().decode(SyncedPreferencesEnvelope.self, from: data)
    }

    private static func importICloudPreferences(
        notify: Bool,
        requireNewerTimestamp: Bool = true
    ) {
        guard let envelope = cloudEnvelope() else { return }
        let localUpdatedAt = defaults.object(forKey: preferencesUpdatedAtKey) as? Date ?? .distantPast
        guard !requireNewerTimestamp || envelope.updatedAt > localUpdatedAt else { return }

        let preferencesChanged = loadLocalPreferences() != envelope.preferences
        saveLocally(envelope.preferences, updatedAt: envelope.updatedAt)
        if notify && preferencesChanged {
            NotificationCenter.default.post(name: .preferencesDidChangeFromICloud, object: nil)
        }
    }

    private static func decodePreferences(forKey key: String) -> UserPreferences? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserPreferences.self, from: data)
    }
}
