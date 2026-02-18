//
//  MovementReminderFullScreenView.swift
//  HealthyWork
//

import SwiftUI
import SwiftData

struct MovementReminderFullScreenView: View {
    var onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    private var preferences: UserPreferences { PreferencesService.load() }
    private var displayStyle: ReminderDisplayStyle { preferences.reminderDisplayStyle }

    var body: some View {
        ReminderStyleView(
            displayStyle: displayStyle,
            type: .movement,
            countdown: nil,
            progress: 0,
            primaryButton: ("Done", handleDone),
            secondaryButton: ("In a meeting", handleInMeeting)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onKeyPress(.return) {
            handleDone()
            return .handled
        }
        .onKeyPress(.space) {
            handleInMeeting()
            return .handled
        }
    }

    private func handleDone() {
        StatsService.logReminder(type: .movement, completed: true, context: modelContext)
        onDismiss()
    }

    private func handleInMeeting() {
        StatsService.logReminder(type: .movement, completed: false, context: modelContext)
        ReminderSchedulingService.scheduleSnooze(
            identifier: "movement-snooze-\(UUID().uuidString)",
            type: .movement,
            in: preferences.snoozeMinutes
        )
        onDismiss()
    }
}

#Preview {
    MovementReminderFullScreenView(onDismiss: {})
        .modelContainer(for: [ReminderLog.self], inMemory: true)
}
