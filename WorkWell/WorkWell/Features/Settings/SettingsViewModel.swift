//
//  SettingsViewModel.swift
//  WorkWell
//

import Foundation
import SwiftUI
import UserNotifications

extension Notification.Name {
    static let reminderScheduleChanged = Notification.Name("ReminderScheduleChanged")
}

@Observable
final class SettingsViewModel {
    var preferences: UserPreferences
    /// True when notification authorization is .authorized (or .provisional). Used to show Request button only when needed.
    var notificationAuthorized: Bool = false
    /// Reflects whether the app is currently configured to start at login (from system state).
    var startAtLogin: Bool = false
    private var lastScheduledPreferences: UserPreferences
    @ObservationIgnored private var rescheduleTask: Task<Void, Never>?

    var isStartAtLoginAvailable: Bool {
        LoginItemService.isSupported
    }

    init() {
        let loadedPreferences = PreferencesService.load()
        self.preferences = loadedPreferences
        self.lastScheduledPreferences = loadedPreferences
        refreshStartAtLogin()
    }

    func saveAndReschedule() {
        PreferencesService.save(preferences)
        guard scheduleConfigurationChanged(from: lastScheduledPreferences, to: preferences) else { return }
        lastScheduledPreferences = preferences
        NotificationCenter.default.post(name: .reminderScheduleChanged, object: nil)

        let preferencesToSchedule = preferences
        rescheduleTask?.cancel()
        rescheduleTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            ReminderSchedulingService.rescheduleAll(preferences: preferencesToSchedule)
            self?.rescheduleTask = nil
        }
    }

    func refreshNotificationStatus() {
        ReminderSchedulingService.getAuthorizationStatus { [weak self] status in
            self?.notificationAuthorized = (status == .authorized || status == .provisional)
        }
    }

    func requestNotificationPermission() {
        ReminderSchedulingService.requestAuthorization { [weak self] _ in
            self?.refreshNotificationStatus()
            guard let self else { return }
            ReminderSchedulingService.rescheduleAll(preferences: self.preferences)
        }
    }

    private func scheduleConfigurationChanged(
        from old: UserPreferences,
        to new: UserPreferences
    ) -> Bool {
        old.workStartTime != new.workStartTime
            || old.workEndTime != new.workEndTime
            || old.lunchStartTime != new.lunchStartTime
            || old.lunchEndTime != new.lunchEndTime
            || old.waterReminderEnabled != new.waterReminderEnabled
            || old.eyeReminderEnabled != new.eyeReminderEnabled
            || old.movementReminderEnabled != new.movementReminderEnabled
            || old.waterReminderIntervalMinutes != new.waterReminderIntervalMinutes
            || old.eyeReminderIntervalMinutes != new.eyeReminderIntervalMinutes
            || old.movementReminderIntervalMinutes != new.movementReminderIntervalMinutes
            || old.notificationBanner != new.notificationBanner
            || old.notificationSound != new.notificationSound
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
