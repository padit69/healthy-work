//
//  EyeRestReminderFullScreenView.swift
//  HealthyWork
//

import SwiftUI
import SwiftData

struct EyeRestReminderFullScreenView: View {
    var onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var remainingSeconds: Int = 20
    @State private var isCounting = false
    @State private var timer: Timer?

    private var preferences: UserPreferences { PreferencesService.load() }
    private var countdownSeconds: Int { preferences.eyeRestCountdownSeconds }
    private var displayStyle: ReminderDisplayStyle { preferences.reminderDisplayStyle }
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
            }
            .onDisappear { timer?.invalidate() }
            .onKeyPress(.escape) {
                if isCounting { timer?.invalidate(); isCounting = false }
                skipAndDismiss()
                return .handled
            }
    }

    @ViewBuilder
    private var reminderContent: some View {
        if isCounting {
            ReminderStyleView(
                displayStyle: displayStyle,
                type: .eyeRest,
                countdown: remainingSeconds,
                progress: progress,
                primaryButton: ("str_button_skip".localizedByKey, skipAndDismiss),
                secondaryButton: nil
            )
        } else {
            ReminderStyleView(
                displayStyle: displayStyle,
                type: .eyeRest,
                countdown: countdownSeconds,
                progress: progress,
                primaryButton: ("str_button_skip".localizedByKey, skipAndDismiss),
                secondaryButton: nil
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
