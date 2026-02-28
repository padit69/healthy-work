//
//  MovementReminderFullScreenView.swift
//  WorkWell
//

import SwiftUI
import SwiftData

struct MovementReminderFullScreenView: View {
    var onDismiss: () -> Void
    var setFocusBlocksKeyDismiss: ((Bool) -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    private var preferences: UserPreferences { PreferencesService.load() }
    private var displayStyle: ReminderDisplayStyle { preferences.reminderDisplayStyle }
    private var primaryColor: Color { ReminderType.movement.primaryColor(overrideHex: preferences.reminderPrimaryColorHex(for: .movement)) }
    private var focusEnabled: Bool { preferences.movementFocusActionEnabled ?? false }
    private var focusMinSeconds: Int { min(100, max(10, preferences.movementFocusMinSeconds ?? 30)) }

    @State private var focusCountdownRemaining: Int = 0
    @State private var focusCountdownTotal: Int = 0
    @State private var isFocusCounting: Bool = false
    @State private var focusTimer: Timer?

    var body: some View {
        ReminderStyleView(
            displayStyle: displayStyle,
            type: .movement,
            primaryColor: primaryColor,
            countdown: focusEnabled && isFocusCounting ? focusCountdownRemaining : nil,
            progress: focusEnabled && focusCountdownTotal > 0 ? Double(focusCountdownRemaining) / Double(focusCountdownTotal) : 0,
            primaryButton: ("Done".localizedByKey, handleDone),
            secondaryButton: ("In a meeting".localizedByKey, handleInMeeting),
            primaryButtonDisabled: focusEnabled && isFocusCounting,
            secondaryButtonDisabled: focusEnabled && isFocusCounting,
            focusModeEnabled: focusEnabled
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if focusEnabled {
                startFocusCountdown()
                setFocusBlocksKeyDismiss?(true)
            } else {
                setFocusBlocksKeyDismiss?(false)
            }
        }
        .onDisappear {
            focusTimer?.invalidate()
            setFocusBlocksKeyDismiss?(false)
        }
        .onKeyPress(.return) {
            if !(focusEnabled && isFocusCounting) { handleDone() }
            return .handled
        }
        .onKeyPress(.space) {
            if !(focusEnabled && isFocusCounting) { handleInMeeting() }
            return .handled
        }
    }

    private func startFocusCountdown() {
        let total = focusMinSeconds
        focusCountdownTotal = total
        focusCountdownRemaining = total
        isFocusCounting = true
        focusTimer?.invalidate()
        focusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if focusCountdownRemaining > 0 {
                    focusCountdownRemaining -= 1
                } else {
                    focusTimer?.invalidate()
                    focusTimer = nil
                    isFocusCounting = false
                    setFocusBlocksKeyDismiss?(false)
                }
            }
        }
        focusTimer?.tolerance = 0.2
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
