//
//  AppDelegate.swift
//  WorkWell
//

import AppKit
import SwiftUI
import SwiftData
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private struct ReminderPresentationRequest: Equatable {
        let identifier: String
        let type: ReminderType
    }

    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var nextRemindersHeaderItem: NSMenuItem?
    private var openSettingsMenuItem: NSMenuItem?
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
                    self?.handleCoordinatorShow(type)
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

    private var queuedPresentations: [ReminderPresentationRequest] = []
    private var currentPresentation: ReminderPresentationRequest?
    private var recentlyPresented: [String: Date] = [:]
    private var lastScheduleEvaluationDate: Date?
    private var lastNotificationRefreshDate: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        startStatusCountdown()
        UNUserNotificationCenter.current().delegate = self

        // Ask for notification permission and schedule all pending reminders at launch,
        // so the user doesn't have to open Settings to start the schedule.
        let preferences = PreferencesService.load()
        ReminderSchedulingService.requestAuthorization { [weak self] _ in
            self?.refreshSystemSchedule(preferences: preferences, now: Date(), force: true)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReminderScheduleChanged(_:)),
            name: .reminderScheduleChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClockOrTimeZoneChanged(_:)),
            name: .NSSystemClockDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClockOrTimeZoneChanged(_:)),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )

        // On wake, start evaluation from the current instant so missed reminders
        // are left to macOS instead of being replayed as a burst of overlays.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWakeFromSleep(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWakeFromSleep(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let now = Date()
            self.lastScheduleEvaluationDate = now
            self.refreshSystemSchedule(
                preferences: PreferencesService.load(),
                now: now,
                force: true
            )
        }
    }

    @objc private func handleReminderScheduleChanged(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let now = Date()
            self.lastScheduleEvaluationDate = now
            self.lastNotificationRefreshDate = now
        }
    }

    @objc private func handleClockOrTimeZoneChanged(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let now = Date()
            self.lastScheduleEvaluationDate = now
            self.refreshSystemSchedule(
                preferences: PreferencesService.load(),
                now: now,
                force: true
            )
        }
    }

    @MainActor
    private func handleCoordinatorShow(_ type: ReminderType) {
        if currentPresentation == nil {
            currentPresentation = ReminderPresentationRequest(
                identifier: "preview.\(type.rawValue).\(UUID().uuidString)",
                type: type
            )
        }
        showFullScreenReminder(type)
    }
    
    @MainActor
    func showFullScreenReminder(_ type: ReminderType) {
        closeFullScreenReminderWindow()
        // Ẩn cửa sổ Settings (nếu đang mở) để sau khi tắt reminder
        // không tự động hiện lại Settings. Settings chỉ mở từ menu bar.
        mainWindow?.orderOut(nil)
        let container = modelContainer ?? AppDelegate.sharedModelContainer
        let coordinator = reminderCoordinator ?? AppDelegate.sharedCoordinator
        guard let container,
              let coordinator,
              let screen = NSScreen.main else {
            currentPresentation = nil
            DispatchQueue.main.async { [weak self] in
                self?.presentNextQueuedReminder()
            }
            return
        }

        coordinator.onDismissWindow = { [weak self] in
            guard let self else { return }
            self.closeFullScreenReminderWindow()
            self.currentPresentation = nil
            DispatchQueue.main.async { [weak self] in
                self?.presentNextQueuedReminder()
            }
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

    @MainActor
    private func requestFullScreenPresentation(
        type: ReminderType,
        identifier: String,
        preferences: UserPreferences
    ) {
        guard preferences.fullScreenReminderEnabled ?? true else { return }

        let now = Date()
        recentlyPresented = recentlyPresented.filter { now.timeIntervalSince($0.value) < 10 }
        if let lastPresented = recentlyPresented[identifier],
           now.timeIntervalSince(lastPresented) < 5 {
            return
        }

        let request = ReminderPresentationRequest(identifier: identifier, type: type)
        guard currentPresentation != request,
              currentPresentation?.type != type,
              !queuedPresentations.contains(request),
              !queuedPresentations.contains(where: { $0.type == type }) else { return }

        if fullScreenReminderWindow != nil || currentPresentation != nil {
            queuedPresentations.append(request)
            return
        }

        guard let coordinator = reminderCoordinator ?? AppDelegate.sharedCoordinator else { return }
        currentPresentation = request
        recentlyPresented[identifier] = now
        coordinator.show(type)
    }

    @MainActor
    private func presentNextQueuedReminder() {
        guard fullScreenReminderWindow == nil,
              currentPresentation == nil,
              !queuedPresentations.isEmpty else { return }

        let next = queuedPresentations.removeFirst()
        guard let coordinator = reminderCoordinator ?? AppDelegate.sharedCoordinator else { return }
        currentPresentation = next
        recentlyPresented[next.identifier] = Date()
        coordinator.show(next.type)
    }

    /// Xử lý phím tắt Enter / Space cho các loại reminder full-screen.
    private func handleQuickReminderKey(
        _ keyCode: UInt16,
        type: ReminderType,
        context: ModelContext,
        coordinator: ReminderCoordinator
    ) -> Bool {
        if coordinator.focusActionBlocksKeyDismiss {
            return false
        }
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
                // Space: remind again in 1 minute (dismiss now, show again in 1 min)
                ReminderSchedulingService.scheduleSnooze(
                    identifier: "water-remind-\(UUID().uuidString)",
                    type: .water,
                    in: 1
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
        let prefs = PreferencesService.load()
        handleDeliveredNotification(notification, preferences: prefs)

        var options: UNNotificationPresentationOptions = []
        if prefs.notificationBanner {
            options.insert(.banner)
            options.insert(.list)
        }
        if prefs.notificationSound {
            options.insert(.sound)
        }
        completionHandler(options)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let prefs = PreferencesService.load()
        handleDeliveredNotification(response.notification, preferences: prefs)
        completionHandler()
    }

    private func handleDeliveredNotification(
        _ notification: UNNotification,
        preferences: UserPreferences
    ) {
        let category = notification.request.content.categoryIdentifier
        guard let type = ReminderSchedulingService.reminderType(for: category) else { return }

        let identifier = notification.request.content.userInfo["occurrenceID"] as? String
            ?? notification.request.identifier
        if notification.request.content.userInfo["isSnooze"] as? Bool == true {
            ReminderSchedulingService.removeStoredSnooze(identifier: identifier)
        }

        requestFullScreenPresentation(type: type, identifier: identifier, preferences: preferences)
        refreshSystemSchedule(preferences: preferences, now: Date(), force: false)
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

    /// Start a 1s timer that renders the shared absolute schedule and presents due reminders.
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

    private func processDueReminders(preferences: UserPreferences, now: Date) {
        defer { lastScheduleEvaluationDate = now }
        guard let lastEvaluation = lastScheduleEvaluationDate else { return }

        let elapsed = now.timeIntervalSince(lastEvaluation)
        guard elapsed >= 0 else { return }
        // A long gap is normally sleep. macOS owns delivery of notifications that
        // became due during that gap; do not flood the user with catch-up overlays.
        guard elapsed <= 60 else { return }

        var due = ReminderSchedulingService.regularOccurrences(
            preferences: preferences,
            after: lastEvaluation,
            through: now
        )
        due.append(contentsOf: ReminderSchedulingService.dueSnoozes(after: lastEvaluation, through: now))
        due.sort { $0.date < $1.date }

        for occurrence in due {
            if occurrence.isSnooze {
                ReminderSchedulingService.removeStoredSnooze(identifier: occurrence.identifier)
            }
            requestFullScreenPresentation(
                type: occurrence.type,
                identifier: occurrence.identifier,
                preferences: preferences
            )
        }

        if !due.isEmpty {
            refreshSystemSchedule(preferences: preferences, now: now, force: false)
        }
    }

    private func refreshSystemSchedule(
        preferences: UserPreferences,
        now: Date,
        force: Bool
    ) {
        if !force,
           let lastRefresh = lastNotificationRefreshDate,
           now.timeIntervalSince(lastRefresh) < 10 * 60 {
            return
        }
        lastNotificationRefreshDate = now
        ReminderSchedulingService.rescheduleAll(preferences: preferences, now: now)
    }

    private func updateStatusTitle() {
        let preferences = PreferencesService.load()
        let now = Date()

        processDueReminders(preferences: preferences, now: now)
        refreshSystemSchedule(preferences: preferences, now: now, force: false)

        func timeRemaining(for type: ReminderType) -> Int? {
            guard let date = ReminderSchedulingService.nextScheduledDate(
                for: type,
                preferences: preferences,
                from: now
            ) else { return nil }
            return max(0, Int(ceil(date.timeIntervalSince(now))))
        }

        func format(_ seconds: Int) -> String {
            if seconds >= 3600 {
                let hours = seconds / 3600
                let minutes = (seconds % 3600) / 60
                let secs = seconds % 60
                return String(format: "%02d:%02d:%02d", hours, minutes, secs)
            }
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d", minutes, secs)
        }

        // Keep menu bar labels in sync with current language
        nextRemindersHeaderItem?.title = "Next reminders".localizedByKey
        openSettingsMenuItem?.title = "Open Settings".localizedByKey
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
}
