//
//  WaterReminderFullScreenView.swift
//  HealthyWork
//

import SwiftUI
import SwiftData


struct WaterReminderFullScreenView: View {
    var onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext

    private var preferences: UserPreferences { PreferencesService.load() }
    private var displayStyle: ReminderDisplayStyle { preferences.reminderDisplayStyle }
    private var primaryColor: Color { ReminderType.water.primaryColor(overrideHex: preferences.reminderPrimaryColorHex(for: .water)) }

    var body: some View {
        ReminderStyleView(
            displayStyle: displayStyle,
            type: .water,
            primaryColor: primaryColor,
            countdown: nil,
            progress: 0,
            primaryButton: ("str_button_i_drank".localizedByKey, handleDrank),
            secondaryButton: ("str_button_skip".localizedByKey, handleSkip)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Shortcuts: Return = primary (I drank), Space = secondary (Skip)
        .onKeyPress(.return) {
            handleDrank()
            return .handled
        }
        .onKeyPress(.space) {
            handleSkip()
            return .handled
        }
    }

    private func handleDrank() {
        WaterService.addRecord(amountMl: preferences.defaultGlassMl, date: Date(), context: modelContext)
        onDismiss()
    }

    private func handleSkip() {
        ReminderSchedulingService.scheduleSnooze(
            identifier: "water-snooze-\(UUID().uuidString)",
            type: .water,
            in: preferences.snoozeMinutes
        )
        onDismiss()
    }
}

#Preview {
    WaterReminderFullScreenView(onDismiss: {})
        .modelContainer(for: [WaterRecord.self], inMemory: true)
}
