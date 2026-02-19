//
//  AppDelegate.swift
//  HealthyWork
//

import AppKit
import SwiftUI
import SwiftData
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var countdownTimer: Timer?
    private var waterCountdownItem: NSMenuItem?
    private var eyeCountdownItem: NSMenuItem?
    private var movementCountdownItem: NSMenuItem?

    /// Main window reference so we can show it from the menu bar.
    weak var mainWindow: NSWindow?

    /// Set from App.onAppear. Used to show full-screen reminder window.
    var reminderCoordinator: ReminderCoordinator? {
        didSet {
            reminderCoordinator?.onShowReminder = { [weak self] type in
                self?.showFullScreenReminder(type)
            }
        }
    }

    /// Set from App.onAppear so full-screen reminder window can use SwiftData.
    var modelContainer: ModelContainer?

    /// Fallback when instance props are not set yet (e.g. onAppear not run).
    static var sharedModelContainer: ModelContainer?
    static var sharedCoordinator: ReminderCoordinator?

    private var fullScreenReminderWindow: NSWindow?
    private var escapeKeyMonitor: Any?

    /// Countdown seconds per reminder type (drives auto full-screen reminders).
    private var secondsRemainingPerType: [ReminderType: Int] = [:]
    /// Last time we ticked countdowns. Used so sleep/wake still advances based on real elapsed time.
    private var lastTickDate: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        startStatusCountdown()
        UNUserNotificationCenter.current().delegate = self

        // Ask for notification permission and schedule all pending reminders at launch,
        // so the user doesn't have to open Settings to start the schedule.
        let preferences = PreferencesService.load()
        ReminderSchedulingService.requestAuthorization { _ in
            ReminderSchedulingService.rescheduleAll(preferences: preferences)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowReminderNotification(_:)),
            name: .showReminder,
            object: nil
        )
    }

    @objc private func handleShowReminderNotification(_ notification: Notification) {
        guard let raw = notification.userInfo?["type"] as? String,
              let type = ReminderType(rawValue: raw) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.showFullScreenReminder(type)
        }
    }

    func showFullScreenReminder(_ type: ReminderType) {
        closeFullScreenReminderWindow()
        // Ẩn cửa sổ Settings (nếu đang mở) để sau khi tắt reminder
        // không tự động hiện lại Settings. Settings chỉ mở từ menu bar.
        mainWindow?.orderOut(nil)
        let container = modelContainer ?? AppDelegate.sharedModelContainer
        let coordinator = reminderCoordinator ?? AppDelegate.sharedCoordinator
        guard let container = container else { return }
        guard let coordinator = coordinator else { return }
        guard let screen = NSScreen.main else { return }

        coordinator.onDismissWindow = { [weak self] in
            self?.closeFullScreenReminderWindow()
        }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false

        let rootView = FullScreenReminderWindowContent(type: type, coordinator: coordinator)
            .environment(\.locale, PreferencesService.load().language.locale)
            .modelContainer(container)
        window.contentView = NSHostingView(rootView: rootView)

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        fullScreenReminderWindow = window

        let context = container.mainContext
        escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            // Escape luôn đóng full-screen reminder
            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    coordinator.dismiss()
                }
                return nil
            }

            // Xử lý phím tắt nhanh cho Water/Movement
            guard let activeType = coordinator.activeReminder else { return event }
            if self.handleQuickReminderKey(event.keyCode, type: activeType, context: context, coordinator: coordinator) {
                return nil
            }

            return event
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        countdownTimer?.invalidate()
    }

    func closeFullScreenReminderWindow() {
        if let monitor = escapeKeyMonitor {
            NSEvent.removeMonitor(monitor)
            escapeKeyMonitor = nil
        }
        fullScreenReminderWindow?.orderOut(nil)
        fullScreenReminderWindow = nil
    }

    /// Xử lý phím tắt Enter / Space cho các loại reminder full-screen.
    private func handleQuickReminderKey(
        _ keyCode: UInt16,
        type: ReminderType,
        context: ModelContext,
        coordinator: ReminderCoordinator
    ) -> Bool {
        // 36: Return, 76: Keypad Enter, 49: Space
        let enterKeyCodes: Set<UInt16> = [36, 76]
        let spaceKeyCode: UInt16 = 49

        switch type {
        case .water:
            let preferences = PreferencesService.load()
            if enterKeyCodes.contains(keyCode) {
                // Enter: mark drank
                WaterService.addRecord(
                    amountMl: preferences.defaultGlassMl,
                    date: Date(),
                    context: context
                )
                DispatchQueue.main.async {
                    coordinator.dismiss()
                }
                return true
            } else if keyCode == spaceKeyCode {
                // Space: in meeting (snooze)
                ReminderSchedulingService.scheduleSnooze(
                    identifier: "water-snooze-\(UUID().uuidString)",
                    type: .water,
                    in: preferences.snoozeMinutes
                )
                DispatchQueue.main.async {
                    coordinator.dismiss()
                }
                return true
            }

        case .movement:
            let preferences = PreferencesService.load()
            if enterKeyCodes.contains(keyCode) {
                // Enter: mark moved
                StatsService.logReminder(
                    type: .movement,
                    completed: true,
                    context: context
                )
                DispatchQueue.main.async {
                    coordinator.dismiss()
                }
                return true
            } else if keyCode == spaceKeyCode {
                // Space: in meeting (log + snooze)
                StatsService.logReminder(
                    type: .movement,
                    completed: false,
                    context: context
                )
                ReminderSchedulingService.scheduleSnooze(
                    identifier: "movement-snooze-\(UUID().uuidString)",
                    type: .movement,
                    in: preferences.snoozeMinutes
                )
                DispatchQueue.main.async {
                    coordinator.dismiss()
                }
                return true
            }

        case .eyeRest:
            break
        }

        return false
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let id = notification.request.content.categoryIdentifier
        if id == ReminderSchedulingService.waterCategoryIdentifier {
            reminderCoordinator?.show(.water)
        } else if id == ReminderSchedulingService.eyeRestCategoryIdentifier {
            reminderCoordinator?.show(.eyeRest)
        } else if id == ReminderSchedulingService.movementCategoryIdentifier {
            reminderCoordinator?.show(.movement)
        }
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.content.categoryIdentifier
        if id == ReminderSchedulingService.waterCategoryIdentifier {
            reminderCoordinator?.show(.water)
        } else if id == ReminderSchedulingService.eyeRestCategoryIdentifier {
            reminderCoordinator?.show(.eyeRest)
        } else if id == ReminderSchedulingService.movementCategoryIdentifier {
            reminderCoordinator?.show(.movement)
        }
        completionHandler()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(resource: .menuLogo)
        button.toolTip = AppConstants.App.name
        button.title = "" // chỉ hiển thị icon, countdown nằm trong menu

        let menu = NSMenu()

        // Countdown section
        let headerItem = NSMenuItem(title: "Next reminders", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        let waterItem = NSMenuItem(title: "Water — --:--", action: nil, keyEquivalent: "")
        waterItem.isEnabled = false
        menu.addItem(waterItem)
        waterCountdownItem = waterItem

        let eyeItem = NSMenuItem(title: "Eye rest — --:--", action: nil, keyEquivalent: "")
        eyeItem.isEnabled = false
        menu.addItem(eyeItem)
        eyeCountdownItem = eyeItem

        let movementItem = NSMenuItem(title: "Movement — --:--", action: nil, keyEquivalent: "")
        movementItem.isEnabled = false
        menu.addItem(movementItem)
        movementCountdownItem = movementItem

        menu.addItem(NSMenuItem.separator())

        // App actions
        let openItem = NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        self.statusMenu = menu
    }

    /// Start a 1s timer that updates the menu bar title and drives reminder countdowns.
    private func startStatusCountdown() {
        countdownTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateStatusTitle()
        }
        timer.tolerance = 0.5
        RunLoop.current.add(timer, forMode: .common)
        countdownTimer = timer
        updateStatusTitle()
    }

    /// Tick internal reminder countdowns and trigger full-screen reminders when due.
    private func tickInternalReminders(preferences: UserPreferences, now: Date) {
        let (workStart, workEnd) = ReminderSchedulingService.workWindow(for: preferences, on: now)
        let inWorkHours = now >= workStart && now <= workEnd

        // Compute how many seconds have actually passed since last tick.
        let elapsedSeconds: Int
        if let last = lastTickDate {
            elapsedSeconds = max(1, Int(now.timeIntervalSince(last)))
        } else {
            elapsedSeconds = 1
        }
        lastTickDate = now

        for type in [ReminderType.water, ReminderType.eyeRest, ReminderType.movement] {
            let enabled: Bool
            let intervalMinutes: Int

            switch type {
            case .water:
                enabled = preferences.waterReminderEnabled
                intervalMinutes = preferences.waterReminderIntervalMinutes
            case .eyeRest:
                enabled = preferences.eyeReminderEnabled
                intervalMinutes = preferences.eyeReminderIntervalMinutes
            case .movement:
                enabled = preferences.movementReminderEnabled
                intervalMinutes = preferences.movementReminderIntervalMinutes
            }

            // Outside work hours or disabled → clear countdown.
            guard enabled, intervalMinutes > 0, inWorkHours else {
                secondsRemainingPerType[type] = nil
                continue
            }

            let intervalSeconds = intervalMinutes * 60
            var remaining = secondsRemainingPerType[type] ?? intervalSeconds

            // Advance countdown by real elapsed time (so sleep doesn't "pause" progress).
            remaining -= elapsedSeconds

            if remaining <= 0 {
                // Time's up: show reminder if no full-screen window is already visible.
                // Use instance or static fallback so we can show even before main window is built.
                let coordinator = reminderCoordinator ?? AppDelegate.sharedCoordinator
                if fullScreenReminderWindow == nil, let coordinator = coordinator {
                    DispatchQueue.main.async { [weak self] in
                        guard self != nil else { return }
                        coordinator.show(type)
                    }
                }
                remaining = intervalSeconds
                
            } else {
                remaining -= 1
            }

            secondsRemainingPerType[type] = remaining
        }
    }

    private func updateStatusTitle() {
        let preferences = PreferencesService.load()
        let now = Date()

        // Update internal countdowns and show reminders when due.
        tickInternalReminders(preferences: preferences, now: now)

        func timeRemaining(for type: ReminderType) -> Int? {
            return secondsRemainingPerType[type]
        }

        func format(_ seconds: Int) -> String {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d", minutes, secs)
        }

        if let w = timeRemaining(for: .water) {
            waterCountdownItem?.title = "Water — \(format(w))"
        } else {
            waterCountdownItem?.title = "Water — --:--"
        }

        if let e = timeRemaining(for: .eyeRest) {
            eyeCountdownItem?.title = "Eye rest — \(format(e))"
        } else {
            eyeCountdownItem?.title = "Eye rest — --:--"
        }

        if let m = timeRemaining(for: .movement) {
            movementCountdownItem?.title = "Movement — \(format(m))"
        } else {
            movementCountdownItem?.title = "Movement — --:--"
        }
    }

    @objc private func openSettings() {
        // Bring app to foreground and show dock icon when opening Settings from menu bar.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Ưu tiên dùng mainWindow do WindowAccessor gán,
        // nếu nil thì fallback sang bất kỳ window hiện có của app.
        if let window = mainWindow ?? NSApp.windows.first {
            mainWindow = window
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
