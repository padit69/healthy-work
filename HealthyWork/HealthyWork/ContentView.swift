//
//  ContentView.swift
//  HealthyWork
//

import SwiftUI
import SwiftData

/// Root content view. Main window shows Settings. Reminders show in a separate full-screen window (above all apps).
struct ContentView: View {
    @State private var settingsViewModel = SettingsViewModel()
    var reminderCoordinator: ReminderCoordinator
    var modelContainer: ModelContainer?

    var body: some View {
        SettingsView(viewModel: settingsViewModel, reminderCoordinator: reminderCoordinator)
            .background(WindowAccessor())
    }
}

#Preview {
    ContentView(reminderCoordinator: ReminderCoordinator(), modelContainer: nil)
}
