//
//  HealthyWorkApp.swift
//  HealthyWork
//

import SwiftUI
import SwiftData
import AppKit

@main
struct HealthyWorkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var reminderCoordinator = ReminderCoordinator()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WaterRecord.self,
            ReminderLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // Set coordinator and container on AppDelegate as soon as Scene runs (first frame),
        // so timer can show full-screen reminder even before main window is built.
        let _ = {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.reminderCoordinator = reminderCoordinator
                appDelegate.modelContainer = sharedModelContainer
            }
            AppDelegate.sharedModelContainer = sharedModelContainer
            AppDelegate.sharedCoordinator = reminderCoordinator
        }()
        return WindowGroup {
            RootView(reminderCoordinator: reminderCoordinator, modelContainer: sharedModelContainer)
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Sets AppDelegate and static refs as soon as the view is created (before onAppear), so "Test" works immediately.
private struct RootView: View {
    let reminderCoordinator: ReminderCoordinator
    let modelContainer: ModelContainer

    init(reminderCoordinator: ReminderCoordinator, modelContainer: ModelContainer) {
        self.reminderCoordinator = reminderCoordinator
        self.modelContainer = modelContainer
        AppDelegate.sharedModelContainer = modelContainer
        AppDelegate.sharedCoordinator = reminderCoordinator
        (NSApp.delegate as? AppDelegate)?.reminderCoordinator = reminderCoordinator
        (NSApp.delegate as? AppDelegate)?.modelContainer = modelContainer
    }

    var body: some View {
        ContentView(reminderCoordinator: reminderCoordinator, modelContainer: modelContainer)
    }
}
