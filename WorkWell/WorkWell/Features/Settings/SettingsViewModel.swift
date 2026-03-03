//
//  SettingsViewModel.swift
//  WorkWell
//

import Foundation
import SwiftUI
import UserNotifications

@Observable
final class SettingsViewModel {
    var preferences: UserPreferences
    /// True when notification authorization is .authorized (or .provisional). Used to show Request button only when needed.
    var notificationAuthorized: Bool = false
    /// Reflects whether the app is currently configured to start at login (from system state).
    var startAtLogin: Bool = false

    var isStartAtLoginAvailable: Bool {
        LoginItemService.isSupported
    }

    init() {
        self.preferences = PreferencesService.load()
        refreshStartAtLogin()
    }

    func saveAndReschedule() {
        PreferencesService.save(preferences)
        ReminderSchedulingService.rescheduleAll(preferences: preferences)
    }

    func refreshNotificationStatus() {
        ReminderSchedulingService.getAuthorizationStatus { [weak self] status in
            self?.notificationAuthorized = (status == .authorized || status == .provisional)
        }
    }

    func requestNotificationPermission() {
        ReminderSchedulingService.requestAuthorization { [weak self] _ in
            self?.refreshNotificationStatus()
        }
    }

    func refreshStartAtLogin() {
        startAtLogin = LoginItemService.isEnabled
    }

    func setStartAtLogin(_ enabled: Bool) {
        guard LoginItemService.isSupported else { return }
        do {
            try LoginItemService.setEnabled(enabled)
            startAtLogin = LoginItemService.isEnabled
        } catch {
            // If registration fails, keep the previous value.
            startAtLogin = LoginItemService.isEnabled
        }
    }
}
