//
//  WaterReminderFullScreenView.swift
//  WorkWell
//

import SwiftUI
import SwiftData

struct WaterReminderFullScreenView: View {
    var onDismiss: () -> Void
    var setFocusBlocksKeyDismiss: ((Bool) -> Void)? = nil
    @Environment(\.modelContext) private var modelContext

    private var preferences: UserPreferences { PreferencesService.load() }
    private var displayStyle: ReminderDisplayStyle { preferences.reminderDisplayStyle }
    private var primaryColor: Color { ReminderType.water.primaryColor(overrideHex: preferences.reminderPrimaryColorHex(for: .water)) }
    private var focusEnabled: Bool { preferences.waterFocusActionEnabled ?? false }
    private var focusMinSeconds: Int { min(100, max(10, preferences.waterFocusMinSeconds ?? 30)) }

    @State private var focusCountdownRemaining: Int = 0
    @State private var focusCountdownTotal: Int = 0
    @State private var isFocusCounting: Bool = false
    @State private var focusTimer: Timer?

    var body: some View {
        ReminderStyleView(
            displayStyle: displayStyle,
            type: .water,
            primaryColor: primaryColor,
            countdown: focusEnabled && isFocusCounting ? focusCountdownRemaining : nil,
            progress: focusEnabled && focusCountdownTotal > 0 ? Double(focusCountdownRemaining) / Double(focusCountdownTotal) : 0,
            primaryButton: ("str_button_i_drank".localizedByKey, handleDrank),
            secondaryButton: ("str_button_skip".localizedByKey, handleSkip),
            primaryButtonDisabled: focusEnabled && isFocusCounting,
            secondaryButtonDisabled: focusEnabled && isFocusCounting
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
            if !(focusEnabled && isFocusCounting) { handleDrank() }
            return .handled
        }
        .onKeyPress(.space) {
            if !(focusEnabled && isFocusCounting) { handleSkip() }
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
