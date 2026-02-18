//
//  SettingsView.swift
//  HealthyWork
//

import SwiftUI
import SwiftData

// MARK: - Section header/footer style (inspired by Health Reminder)
private struct SettingsSectionHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

private struct SettingsSectionFooter: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11))
    }
}

extension View {
    fileprivate func settingsSectionHeader() -> some View { modifier(SettingsSectionHeader()) }
    fileprivate func settingsSectionFooter() -> some View { modifier(SettingsSectionFooter()) }
}

// MARK: - Style option card for Reminder display style
private struct StyleOptionCard: View {
    let style: ReminderDisplayStyle
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? style.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: style.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? style.accentColor : .gray)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(style.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(style.accentColor)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? style.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case reminders = "Reminders"
    case water = "Water"
    case eyeRest = "Eye Rest"
    case movement = "Movement"
    case appearance = "Appearance"
    case permissions = "Permissions"
    case test = "Test Reminders"
    case about = "About"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .general: return "clock"
        case .reminders: return "bell"
        case .water: return "drop.fill"
        case .eyeRest: return "eye"
        case .movement: return "figure.walk"
        case .appearance: return "paintbrush"
        case .permissions: return "hand.raised"
        case .test: return "play.circle"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var reminderCoordinator: ReminderCoordinator?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterRecord.loggedAt, order: .reverse) private var waterRecords: [WaterRecord]
    @Query(sort: \ReminderLog.completedAt, order: .reverse) private var reminderLogs: [ReminderLog]
    @State private var selectedSection: SettingsSection = .general

    private var sidebarSections: [SettingsSection] {
        var list = SettingsSection.allCases
        if reminderCoordinator == nil {
            list.removeAll { $0 == .test }
        }
        return list
    }

    var body: some View {
        NavigationSplitView {
            List(sidebarSections, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.systemImage)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            Form {
                detailContent(for: selectedSection)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.visible)
            .navigationTitle(selectedSection.rawValue)
        }
        .onChange(of: viewModel.preferences) { _, _ in
            viewModel.saveAndReschedule()
        }
    }

    @ViewBuilder
    private func detailContent(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            generalContent
        case .reminders:
            remindersContent
        case .water:
            waterContent
        case .eyeRest:
            eyeRestContent
        case .movement:
            movementContent
        case .appearance:
            appearanceContent
        case .permissions:
            permissionsContent
        case .test:
            testRemindersContent
        case .about:
            aboutContent
        }
    }

    private var generalContent: some View {
        Group {
            Section {
                LabeledContent("Water today") {
                    Text("\(WaterService.totalMl(for: Date(), in: modelContext)) ml")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Eye rest") {
                    Text("\(StatsService.eyeRestCompletedToday(context: modelContext))")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Movement") {
                    Text("\(StatsService.movementCompletedToday(context: modelContext))")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Streak") {
                    Text("\(StatsService.currentStreak(context: modelContext)) days")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Today")
                    .settingsSectionHeader()
            } footer: {
                Text("Quick overview of your day so far.")
                    .settingsSectionFooter()
            }
            Section {
                DatePicker("Work start", selection: $viewModel.preferences.workStartTime, displayedComponents: .hourAndMinute)
                DatePicker("Work end", selection: $viewModel.preferences.workEndTime, displayedComponents: .hourAndMinute)
            } header: {
                Text("Work Hours")
                    .settingsSectionHeader()
            } footer: {
                Text("Reminders only trigger inside this working window.")
                    .settingsSectionFooter()
            }
        }
    }

    private var remindersContent: some View {
        Group {
            Section {
                LabeledContent {
                    Toggle("", isOn: $viewModel.preferences.waterReminderEnabled)
                        .labelsHidden()
                } label: {
                    Label("Drink Water", systemImage: "drop.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.multicolor)
                }
                if viewModel.preferences.waterReminderEnabled {
                    intervalSlider(
                        value: Binding(
                            get: { Double(viewModel.preferences.waterReminderIntervalMinutes) },
                            set: { viewModel.preferences.waterReminderIntervalMinutes = Int($0) }
                        ),
                        range: 5...60,
                        step: 5,
                        tint: .blue,
                        label: "Interval"
                    )
                }
                LabeledContent {
                    Toggle("", isOn: $viewModel.preferences.eyeReminderEnabled)
                        .labelsHidden()
                } label: {
                    Label("Rest Your Eyes", systemImage: "eye.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.multicolor)
                }
                if viewModel.preferences.eyeReminderEnabled {
                    intervalSlider(
                        value: Binding(
                            get: { Double(viewModel.preferences.eyeReminderIntervalMinutes) },
                            set: { viewModel.preferences.eyeReminderIntervalMinutes = Int($0) }
                        ),
                        range: 5...60,
                        step: 5,
                        tint: .cyan,
                        label: "Interval"
                    )
                }
                LabeledContent {
                    Toggle("", isOn: $viewModel.preferences.movementReminderEnabled)
                        .labelsHidden()
                } label: {
                    Label("Stand Up & Move", systemImage: "figure.stand")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.multicolor)
                }
                if viewModel.preferences.movementReminderEnabled {
                    intervalSlider(
                        value: Binding(
                            get: { Double(viewModel.preferences.movementReminderIntervalMinutes) },
                            set: { viewModel.preferences.movementReminderIntervalMinutes = Int($0) }
                        ),
                        range: 15...60,
                        step: 5,
                        tint: .green,
                        label: "Interval"
                    )
                }
            } header: {
                Text("Reminders")
                    .settingsSectionHeader()
            } footer: {
                Text("Enable reminders and set how often they appear.")
                    .settingsSectionFooter()
            }
            Section {
                LabeledContent {
                    Toggle("", isOn: $viewModel.preferences.notificationBanner)
                        .labelsHidden()
                } label: {
                    Label("Banner", systemImage: "bell.badge.fill")
                        .font(.system(size: 13))
                }
                LabeledContent {
                    Toggle("", isOn: $viewModel.preferences.notificationSound)
                        .labelsHidden()
                } label: {
                    Label("Sound", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 13))
                }
                LabeledContent {
                    Toggle("", isOn: $viewModel.preferences.notificationHaptic)
                        .labelsHidden()
                } label: {
                    Label("Haptic", systemImage: "hand.tap.fill")
                        .font(.system(size: 13))
                }
                LabeledContent {
                    Picker("", selection: $viewModel.preferences.snoozeMinutes) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                    }
                    .labelsHidden()
                } label: {
                    Text("Snooze")
                        .font(.system(size: 13))
                }
            } header: {
                Text("Notifications")
                    .settingsSectionHeader()
            } footer: {
                Text("Play sound and show notifications when reminders appear.")
                    .settingsSectionFooter()
            }
        }
    }

    private func intervalSlider(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        tint: Color,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(Int(value.wrappedValue))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(tint)
                        .monospacedDigit()
                    Text("min")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            Slider(value: value, in: range, step: step)
                .tint(tint)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private var waterContent: some View {
        Section {
            LabeledContent("Weight (kg)") {
                TextField("60", value: $viewModel.preferences.weightKg, format: .number)
                    .frame(width: 72)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("Gender") {
                Picker("", selection: $viewModel.preferences.gender) {
                    Text("None").tag(nil as UserPreferences.Gender?)
                    ForEach(UserPreferences.Gender.allCases, id: \.self) { g in
                        Text(g.rawValue.capitalized).tag(g as UserPreferences.Gender?)
                    }
                }
                .labelsHidden()
            }
            LabeledContent("Unit") {
                Picker("", selection: $viewModel.preferences.waterUnit) {
                    ForEach(UserPreferences.WaterUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
            }
            LabeledContent("Default glass") {
                Picker("", selection: $viewModel.preferences.defaultGlassMl) {
                    Text("200 ml").tag(200)
                    Text("250 ml").tag(250)
                }
                .labelsHidden()
            }
        } header: {
            Text("Hydration")
                .settingsSectionHeader()
        } footer: {
            Text("Daily water goal is calculated from your weight unless you override it.")
                .settingsSectionFooter()
        }
    }

    private var eyeRestContent: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Countdown", systemImage: "timer")
                        .font(.system(size: 13))
                    Spacer()
                    HStack(spacing: 6) {
                        Text("\(viewModel.preferences.eyeRestCountdownSeconds)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.cyan)
                            .monospacedDigit()
                        Text("sec")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                Slider(
                    value: Binding(
                        get: { Double(viewModel.preferences.eyeRestCountdownSeconds) },
                        set: { viewModel.preferences.eyeRestCountdownSeconds = Int($0) }
                    ),
                    in: 10...60,
                    step: 5
                )
                .tint(.cyan)
                .controlSize(.small)
            }
            .padding(.vertical, 4)
            LabeledContent {
                Toggle("", isOn: $viewModel.preferences.eyeRestSilentMode)
                    .labelsHidden()
            } label: {
                Label("Silent (no sound)", systemImage: "speaker.slash.fill")
                    .font(.system(size: 13))
            }
        } header: {
            Text("Eye Rest")
                .settingsSectionHeader()
        } footer: {
            Text("Look at something 20 feet away for 20 seconds to reduce eye strain.")
                .settingsSectionFooter()
        }
    }

    private var movementContent: some View {
        Section {
            LabeledContent {
                Toggle("", isOn: $viewModel.preferences.movementRandomSuggestion)
                    .labelsHidden()
            } label: {
                Label("Random suggestion", systemImage: "shuffle")
                    .font(.system(size: 13))
            }
        } header: {
            Text("Movement")
                .settingsSectionHeader()
        } footer: {
            Text("Show a random stretch or movement suggestion each time.")
                .settingsSectionFooter()
        }
    }

    private var appearanceContent: some View {
        Group {
            Section {
                VStack(spacing: 16) {
                    ForEach(ReminderDisplayStyle.allCases) { style in
                        StyleOptionCard(
                            style: style,
                            isSelected: viewModel.preferences.reminderDisplayStyle == style,
                            onSelect: { viewModel.preferences.reminderDisplayStyle = style }
                        )
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Reminder Display Style")
                    .settingsSectionHeader()
            } footer: {
                Text("Choose how full-screen reminder screens will appear.")
                    .settingsSectionFooter()
            }
            if let coordinator = reminderCoordinator {
                Section {
                    LabeledContent {
                        Menu {
                            Button(action: { coordinator.show(.water) }) {
                                Label("Water Reminder", systemImage: "drop.fill")
                            }
                            Button(action: { coordinator.show(.eyeRest) }) {
                                Label("Eye Rest Reminder", systemImage: "eye.fill")
                            }
                            Button(action: { coordinator.show(.movement) }) {
                                Label("Movement Reminder", systemImage: "figure.stand")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Preview")
                                    .font(.system(size: 12))
                                Image(systemName: "chevron.down.circle.fill")
                                    .font(.system(size: 12))
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    } label: {
                        Label("Test Display Style", systemImage: "play.circle")
                            .font(.system(size: 13))
                    }
                } header: {
                    Text("Preview")
                        .settingsSectionHeader()
                } footer: {
                    Text("Preview how reminders will look with your selected style.")
                        .settingsSectionFooter()
                }
            }
            Section {
                LabeledContent("Theme") {
                    Picker("", selection: $viewModel.preferences.appearance) {
                        ForEach(UserPreferences.Appearance.allCases, id: \.self) {
                            Text($0.rawValue.capitalized).tag($0)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 160)
                }
                LabeledContent("Language") {
                    Picker("", selection: $viewModel.preferences.language) {
                        Text("English").tag(UserPreferences.Language.en)
                        Text("Tiếng Việt").tag(UserPreferences.Language.vi)
                    }
                    .labelsHidden()
                    .frame(maxWidth: 160)
                }
                LabeledContent {
                    Toggle("", isOn: $viewModel.preferences.minimalMode)
                        .labelsHidden()
                } label: {
                    Label("Minimal mode", systemImage: "minus.circle")
                        .font(.system(size: 13))
                }
            } header: {
                Text("Appearance")
                    .settingsSectionHeader()
            } footer: {
                Text("Minimal mode reduces visual noise and notification frequency.")
                    .settingsSectionFooter()
            }
        }
    }

    private var permissionsContent: some View {
        Section {
            Button(action: { viewModel.requestNotificationPermission() }) {
                Label("Request notification permission", systemImage: "bell.badge")
                    .font(.system(size: 13))
            }
        } header: {
            Text("Permissions")
                .settingsSectionHeader()
        }
    }

    private var testRemindersContent: some View {
        Section {
            if let coordinator = reminderCoordinator {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Use these buttons to preview how reminders will look without waiting for the next schedule.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        Button(action: { coordinator.show(.water) }) {
                            Label("Water", systemImage: "drop.fill")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.bordered)
                        Button(action: { coordinator.show(.eyeRest) }) {
                            Label("Eye rest", systemImage: "eye.fill")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.bordered)
                        Button(action: { coordinator.show(.movement) }) {
                            Label("Movement", systemImage: "figure.stand")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Test Reminders")
                .settingsSectionHeader()
        } footer: {
            Text("Preview each reminder type in a full-screen overlay.")
                .settingsSectionFooter()
        }
    }

    private var aboutContent: some View {
        Group {
            Section {
                LabeledContent("App") { Text(AppConstants.App.name) }
                LabeledContent("Version") { Text(appVersionString).foregroundStyle(.secondary) }
                LabeledContent("Build") { Text(appBuildString).foregroundStyle(.secondary) }
            } header: {
                Text("About")
                    .settingsSectionHeader()
            }
            Section {
                Text("WorkWell helps you build healthier work habits with water, eye-rest, and movement reminders.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } header: {
                Text("Description")
                    .settingsSectionHeader()
            }
            Section {
                Text("Your data is stored locally on this device. No sensitive data is collected by default.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } header: {
                Text("Privacy")
                    .settingsSectionHeader()
            }
        }
    }

    private var appVersionString: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }

    private var appBuildString: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "—"
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(), reminderCoordinator: nil)
        .frame(width: 500, height: 400)
}
