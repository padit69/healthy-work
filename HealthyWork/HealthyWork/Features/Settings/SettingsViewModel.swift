//
//  SettingsViewModel.swift
//  HealthyWork
//

import Foundation
import SwiftUI

@Observable
final class SettingsViewModel {
    var preferences: UserPreferences

    init() {
        self.preferences = PreferencesService.load()
    }

    func saveAndReschedule() {
        PreferencesService.save(preferences)
        ReminderSchedulingService.rescheduleAll(preferences: preferences)
    }

    func requestNotificationPermission() {
        ReminderSchedulingService.requestAuthorization { _ in }
    }
}
