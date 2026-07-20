//
//  ContentView.swift
//  WorkWell
//

import SwiftUI
import SwiftData

/// Root content view. Main window shows Settings. Reminders show in a separate full-screen window (above all apps).
/// Preferences are persisted via PreferencesService (UserDefaults) so data survives app restart/update.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var settingsViewModel = SettingsViewModel()
    var reminderCoordinator: ReminderCoordinator
    var modelContainer: ModelContainer?

    var body: some View {
        SettingsView(viewModel: settingsViewModel, reminderCoordinator: reminderCoordinator)
            .environment(\.locale, settingsViewModel.preferences.language.locale)
            .preferredColorScheme(settingsViewModel.preferences.appearance.colorScheme)
            .background(WindowAccessor())
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    settingsViewModel.saveAndReschedule()
                }
            }
    }
}

#Preview {
    ContentView(reminderCoordinator: ReminderCoordinator(), modelContainer: nil)
}
