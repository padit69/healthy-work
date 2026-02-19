//
//  AppDelegate.swift
//  HealthyWork
//

import AppKit
import SwiftUI
import SwiftData
import UserNotifications

extension Notification.Name {
    static let checkForUpdatesRequested = Notification.Name("CheckForUpdatesRequested")
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var nextRemindersHeaderItem: NSMenuItem?
    private var openSettingsMenuItem: NSMenuItem?
    private var checkForUpdatesMenuItem: NSMenuItem?
    private var quitMenuItem: NSMenuItem?
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
                Task { @MainActor in
                    self?.showFullScreenReminder(type)
                }
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
    private var updateAvailableWindow: NSWindow?

    /// Countdown seconds per reminder type (drives auto full-screen reminders).
    private var secondsRemainingPerType: [ReminderType: Int] = [:]
    /// Last time we ticked countdowns. Reset on wake so countdown does not advance while system is sleeping.
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCheckForUpdatesRequested(_:)),
            name: .checkForUpdatesRequested,
            object: nil
        )

        // Khi Mac wake từ sleep: reset lastTickDate để countdown không trừ cả thời gian ngủ.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWakeFromSleep(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWakeFromSleep(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.lastTickDate = Date()
        }
    }

    @objc private func handleShowReminderNotification(_ notification: Notification) {
        guard let raw = notification.userInfo?["type"] as? String,
              let type = ReminderType(rawValue: raw) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.showFullScreenReminder(type)
        }
    }
    
    @MainActor
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
        NSWorkspace.shared.notificationCenter.removeObserver(self)
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
            // Enter / Space: skip (log + dismiss); countdown stops when window closes
            if enterKeyCodes.contains(keyCode) || keyCode == spaceKeyCode {
                StatsService.logReminder(type: .eyeRest, completed: false, context: context)
                DispatchQueue.main.async {
                    coordinator.dismiss()
                }
                return true
            }
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

        // Countdown section (localized)
        let headerItem = NSMenuItem(title: "Next reminders".localizedByKey, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        nextRemindersHeaderItem = headerItem

        let waterLabel = "Water".localizedByKey
        let waterItem = NSMenuItem(title: "\(waterLabel) — --:--", action: nil, keyEquivalent: "")
        waterItem.isEnabled = false
        menu.addItem(waterItem)
        waterCountdownItem = waterItem

        let eyeLabel = "Eye rest".localizedByKey
        let eyeItem = NSMenuItem(title: "\(eyeLabel) — --:--", action: nil, keyEquivalent: "")
        eyeItem.isEnabled = false
        menu.addItem(eyeItem)
        eyeCountdownItem = eyeItem

        let movementLabel = "Movement".localizedByKey
        let movementItem = NSMenuItem(title: "\(movementLabel) — --:--", action: nil, keyEquivalent: "")
        movementItem.isEnabled = false
        menu.addItem(movementItem)
        movementCountdownItem = movementItem

        menu.addItem(NSMenuItem.separator())

        // App actions
        let openItem = NSMenuItem(title: "Open Settings".localizedByKey, action: #selector(openSettings), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        openSettingsMenuItem = openItem

        let checkUpdateItem = NSMenuItem(title: "Check for Updates".localizedByKey, action: #selector(checkForUpdates), keyEquivalent: "")
        checkUpdateItem.target = self
        if let checkUpdateImage = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Check for Updates") {
            checkUpdateImage.isTemplate = true
            checkUpdateItem.image = checkUpdateImage
        }
        menu.addItem(checkUpdateItem)
        checkForUpdatesMenuItem = checkUpdateItem

        let quitItem = NSMenuItem(title: "Quit".localizedByKey, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        if let quitImage = NSImage(systemSymbolName: "rectangle.portrait.and.arrow.right", accessibilityDescription: "Quit") {
            quitImage.isTemplate = true
            quitItem.image = quitImage
        }
        menu.addItem(quitItem)
        quitMenuItem = quitItem

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

            // Advance countdown by elapsed time since last tick. On wake from sleep we reset lastTickDate so this is ~1s only (countdown paused while sleeping).
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

        // Keep menu bar labels in sync with current language
        nextRemindersHeaderItem?.title = "Next reminders".localizedByKey
        openSettingsMenuItem?.title = "Open Settings".localizedByKey
        checkForUpdatesMenuItem?.title = "Check for Updates".localizedByKey
        quitMenuItem?.title = "Quit".localizedByKey

        let waterLabel = "Water".localizedByKey
        let eyeLabel = "Eye rest".localizedByKey
        let movementLabel = "Movement".localizedByKey

        if let w = timeRemaining(for: .water) {
            waterCountdownItem?.title = "\(waterLabel) — \(format(w))"
        } else {
            waterCountdownItem?.title = "\(waterLabel) — --:--"
        }

        if let e = timeRemaining(for: .eyeRest) {
            eyeCountdownItem?.title = "\(eyeLabel) — \(format(e))"
        } else {
            eyeCountdownItem?.title = "\(eyeLabel) — --:--"
        }

        if let m = timeRemaining(for: .movement) {
            movementCountdownItem?.title = "\(movementLabel) — \(format(m))"
        } else {
            movementCountdownItem?.title = "\(movementLabel) — --:--"
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

    @objc private func handleCheckForUpdatesRequested(_ notification: Notification) {
        checkForUpdates()
    }

    @objc private func checkForUpdates() {
        Task { @MainActor in
            guard let release = await UpdateCheckService.checkForUpdate() else {
                let alert = NSAlert()
                alert.messageText = "You're up to date".localizedByKey
                alert.informativeText = "You have the latest version (\(UpdateCheckService.currentVersion))."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK".localizedByKey)
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                alert.runModal()
                return
            }
            showUpdateAvailableWindow(release: release)
        }
    }
    

    @MainActor
    private func showUpdateAvailableWindow(release: GitHubRelease) {
        updateAvailableWindow?.orderOut(nil)
        updateAvailableWindow = nil

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let content = UpdateAvailableView(release: release) { [weak self] in
            self?.updateAvailableWindow?.orderOut(nil)
            self?.updateAvailableWindow = nil
        }
        let hosting = NSHostingView(rootView: content)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(AppConstants.App.name) — Update"
        window.contentView = hosting
        window.center()
        window.isReleasedWhenClosed = false
        updateAvailableWindow = window
        window.makeKeyAndOrderFront(nil)
    }
}
