//
//  EyeRestReminderFullScreenView.swift
//  WorkWell
//

import SwiftUI
import SwiftData

struct EyeRestReminderFullScreenView: View {
    var onDismiss: () -> Void
    var setFocusBlocksKeyDismiss: ((Bool) -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @State private var remainingSeconds: Int = 20
    @State private var isCounting = false
    @State private var timer: Timer?

    private var preferences: UserPreferences { PreferencesService.load() }
    private var countdownSeconds: Int { preferences.eyeRestCountdownSeconds }
    private var displayStyle: ReminderDisplayStyle { preferences.reminderDisplayStyle }
    private var primaryColor: Color { ReminderType.eyeRest.primaryColor(overrideHex: preferences.reminderPrimaryColorHex(for: .eyeRest)) }
    /// When true, Skip is disabled until full countdown finishes (focus action).
    private var focusEnabled: Bool { preferences.eyeRestFocusActionEnabled ?? false }
    private var progress: Double {
        guard countdownSeconds > 0 else { return 0 }
        return isCounting
            ? Double(remainingSeconds) / Double(countdownSeconds)
            : 1.0
    }

    var body: some View {
        reminderContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if !isCounting {
                    startCountdown()
                }
                if focusEnabled {
                    setFocusBlocksKeyDismiss?(true)
                } else {
                    setFocusBlocksKeyDismiss?(false)
                }
            }
            .onDisappear {
                timer?.invalidate()
                setFocusBlocksKeyDismiss?(false)
            }
            // Enter / Space / Esc are handled in AppDelegate (NSEvent monitor) so they work reliably.
    }

    @ViewBuilder
    private var reminderContent: some View {
        if isCounting {
            ReminderStyleView(
                displayStyle: displayStyle,
                type: .eyeRest,
                primaryColor: primaryColor,
                countdown: remainingSeconds,
                progress: progress,
                primaryButton: ("str_button_skip".localizedByKey, skipAndDismiss),
                secondaryButton: nil,
                primaryButtonDisabled: focusEnabled && isCounting,
                secondaryButtonDisabled: false,
                focusModeEnabled: focusEnabled
            )
        } else {
            ReminderStyleView(
                displayStyle: displayStyle,
                type: .eyeRest,
                primaryColor: primaryColor,
                countdown: countdownSeconds,
                progress: progress,
                primaryButton: ("str_button_skip".localizedByKey, skipAndDismiss),
                secondaryButton: nil,
                primaryButtonDisabled: false,
                secondaryButtonDisabled: false,
                focusModeEnabled: focusEnabled
            )
        }
    }

    private func skipAndDismiss() {
        StatsService.logReminder(type: .eyeRest, completed: false, context: modelContext)
        onDismiss()
    }

    private func startCountdown() {
        remainingSeconds = countdownSeconds
        isCounting = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    timer?.invalidate()
                    timer = nil
                    isCounting = false
                    setFocusBlocksKeyDismiss?(false)
                    StatsService.logReminder(type: .eyeRest, completed: true, context: modelContext)
                    onDismiss()
                }
            }
        }
        timer?.tolerance = 0.2
    }
}

#Preview {
    EyeRestReminderFullScreenView(onDismiss: {})
        .modelContainer(for: [ReminderLog.self], inMemory: true)
        .frame(width: 500, height: 700)
}
