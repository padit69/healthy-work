//
//  ReminderCoordinator.swift
//  HealthyWork
//

import Foundation

extension Notification.Name {
    static let showReminder = Notification.Name("ShowReminder")
}

/// Coordinates which full-screen reminder is currently shown. Updated by notification delegate or from Settings "Test".
@Observable
final class ReminderCoordinator {
    var activeReminder: ReminderType?

    /// Called when a reminder should be shown (e.g. open full-screen window).
    var onShowReminder: ((ReminderType) -> Void)?
    /// Called when reminder is dismissed so the window can be closed.
    var onDismissWindow: (() -> Void)?

    func show(_ type: ReminderType) {
        activeReminder = type
        onShowReminder?(type)
        NotificationCenter.default.post(name: .showReminder, object: nil, userInfo: ["type": type.rawValue])
    }

    func dismiss() {
        activeReminder = nil
        onDismissWindow?()
        onDismissWindow = nil
    }
}
