//
//  FullScreenReminderOverlay.swift
//  HealthyWork
//

import SwiftUI
import SwiftData

/// Content for the standalone full-screen reminder window (covers entire screen, above all apps).
struct FullScreenReminderWindowContent: View {
    var type: ReminderType
    var coordinator: ReminderCoordinator
    @Environment(\.modelContext) private var modelContext
    @State private var isVisible = false

    var body: some View {
        Group {
            switch type {
            case .water:
                WaterReminderFullScreenView(onDismiss: { coordinator.dismiss() })
            case .eyeRest:
                EyeRestReminderFullScreenView(onDismiss: { coordinator.dismiss() })
            case .movement:
                MovementReminderFullScreenView(onDismiss: { coordinator.dismiss() })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(reminderBackground)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                isVisible = true
            }
        }
        .onKeyPress(.escape) {
            coordinator.dismiss()
            return .handled
        }
    }

    /// Lớp phủ mờ (blur) lên các app phía sau, không phủ full màu.
    private var reminderBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
    }
}

/// Full-screen overlay that shows the appropriate reminder view (Water / Eye Rest / Movement).
struct FullScreenReminderOverlay: View {
    var type: ReminderType
    var coordinator: ReminderCoordinator
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            switch type {
            case .water:
                WaterReminderFullScreenView(onDismiss: { coordinator.dismiss() })
            case .eyeRest:
                EyeRestReminderFullScreenView(onDismiss: { coordinator.dismiss() })
            case .movement:
                MovementReminderFullScreenView(onDismiss: { coordinator.dismiss() })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
