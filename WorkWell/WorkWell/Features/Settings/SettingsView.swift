//
//  SettingsView.swift
//  WorkWell
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

// MARK: - Reminder primary color palette (hex stored in preferences)
private struct ReminderPrimaryColorOption: Identifiable {
    let label: String
    let hex: String?
    var id: String { hex ?? "default" }
    static let all: [ReminderPrimaryColorOption] = [
        ReminderPrimaryColorOption(label: "Default", hex: nil),
        ReminderPrimaryColorOption(label: "Blue", hex: "#007AFF"),
        ReminderPrimaryColorOption(label: "Cyan", hex: "#32ADE6"),
        ReminderPrimaryColorOption(label: "Green", hex: "#34C759"),
        ReminderPrimaryColorOption(label: "Teal", hex: "#5AC8FA"),
        ReminderPrimaryColorOption(label: "Orange", hex: "#FF9500"),
        ReminderPrimaryColorOption(label: "Purple", hex: "#AF52DE"),
        ReminderPrimaryColorOption(label: "Pink", hex: "#FF2D55")
    ]
}

// MARK: - Style option card for Reminder display style
private struct StyleOptionCard: View {
    let style: ReminderDisplayStyle
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? style.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: style.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? style.accentColor : .gray)
                    }
                    VStack(alignment: .center, spacing: 4) {
                        Text(style.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(style.description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    
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
        case .about: return "info.circle"
        }
    }
    
    var name: String { self.rawValue.localizedByKey }
}

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var reminderCoordinator: ReminderCoordinator?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterRecord.loggedAt, order: .reverse) private var waterRecords: [WaterRecord]
    @Query(sort: \ReminderLog.completedAt, order: .reverse) private var reminderLogs: [ReminderLog]
    @State private var selectedSection: SettingsSection = .general

    private var sidebarSections: [SettingsSection] {
        SettingsSection.allCases
    }

    var body: some View {
        NavigationSplitView {
            List(sidebarSections, selection: $selectedSection) { section in
                Label(section.name, systemImage: section.systemImage)
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
            .navigationTitle(selectedSection.name)
        }
        .onChange(of: viewModel.preferences) { _, _ in
            viewModel.saveAndReschedule()
        }
        .onDisappear {
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
        case .about:
            aboutContent
        }
    }

    private var generalContent: some View {
        Group {
            // Dashboard-style overview for today
            Section {
                let waterMl = WaterService.totalMl(for: Date(), in: modelContext)
                let waterGlasses = StatsService.waterCountToday(context: modelContext)
                let eyeCount = StatsService.eyeRestCompletedToday(context: modelContext)
                let moveCount = StatsService.movementCompletedToday(context: modelContext)
                let streakDays = StatsService.currentStreak(context: modelContext)

                HStack(spacing: 12) {
                    DashboardMetricCard(
                        title: "Water today",
                        value: "\(waterMl) ml",
                        subtitle: waterGlasses > 0 ? "\(waterGlasses) glasses" : "No logs yet",
                        systemImage: "drop.fill",
                        tint: .blue
                    )
                    DashboardMetricCard(
                        title: "Eye rest",
                        value: "\(eyeCount)",
                        subtitle: eyeCount > 0 ? "Completed breaks" : "Not yet",
                        systemImage: "eye.fill",
                        tint: .cyan
                    )
                    DashboardMetricCard(
                        title: "Movement",
                        value: "\(moveCount)",
                        subtitle: moveCount > 0 ? "Times moved" : "Not yet",
                        systemImage: "figure.stand",
                        tint: .green
                    )
                    DashboardMetricCard(
                        title: "Streak",
                        value: "\(streakDays)d",
                        subtitle: streakDays > 0 ? "Active days" : "Start today",
                        systemImage: "flame.fill",
                        tint: .orange
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("Today Dashboard")
                    .settingsSectionHeader()
            } footer: {
                Text("Animated overview of your current day and streak.")
                    .settingsSectionFooter()
            }

            // Work hours stay here but visually separated from dashboard
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
                Text("Schedule")
                    .settingsSectionHeader()
            } footer: {
                Text("Enable each reminder and set how often it appears.")
                    .settingsSectionFooter()
            }
            Section {
                LabeledContent {
                    Toggle("", isOn: Binding(
                        get: { viewModel.preferences.fullScreenReminderEnabled ?? true },
                        set: { viewModel.preferences.fullScreenReminderEnabled = $0 }
                    ))
                    .labelsHidden()
                } label: {
                    Label("Full-screen reminder", systemImage: "inset.filled.rectangle.and.person.filled")
                        .font(.system(size: 13))
                }
                LabeledContent {
                    HStack(spacing: 12) {
                        Toggle("", isOn: $viewModel.preferences.notificationBanner)
                            .labelsHidden()
                        if !viewModel.notificationAuthorized {
                            Button("Request permission") {
                                viewModel.requestNotificationPermission()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
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
                    Label("Snooze", systemImage: "timer.circle.fill")
                        .font(.system(size: 13))
                }
            } header: {
                Text("Notifications")
                    .settingsSectionHeader()
            } footer: {
                Text("Full-screen: show overlay when reminder fires. When off, only system notification. Request permission at Banner row when needed.")
                    .settingsSectionFooter()
            }

            // Reminder style (Modern / Minimal / Bold)
            Section {
                HStack(alignment: .top, spacing: 12) {
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
                Text("Reminder style")
                    .settingsSectionHeader()
            } footer: {
                Text("Visual style of full-screen reminders (layout and mood). Background and color per type are in Water / Eye Rest / Movement.")
                    .settingsSectionFooter()
            }

            // Preview
            if let coordinator = reminderCoordinator {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview the full-screen reminder with current settings.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            Button(action: { coordinator.show(.water) }) {
                                Label("Water", systemImage: "drop.fill")
                                    .font(.system(size: 13, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            Button(action: { coordinator.show(.eyeRest) }) {
                                Label("Eye Rest", systemImage: "eye.fill")
                                    .font(.system(size: 13, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            Button(action: { coordinator.show(.movement) }) {
                                Label("Movement", systemImage: "figure.stand")
                                    .font(.system(size: 13, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Preview")
                        .settingsSectionHeader()
                }
            }
        }
        .onAppear {
            viewModel.refreshNotificationStatus()
        }
    }

    private func intervalSlider(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        tint: Color,
        label: String,
        unit: String = "min"
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
                    Text(unit)
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
        Group {
            Section {
                LabeledContent("Weight (kg)") {
                    TextField("60", value: $viewModel.preferences.weightKg, format: .number)
                        .frame(width: 72)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Gender") {
                    Picker("", selection: $viewModel.preferences.gender) {
                        Text("None".localizedByKey).tag(nil as UserPreferences.Gender?)
                        ForEach(UserPreferences.Gender.allCases, id: \.self) { g in
                            Text(g.localizedName).tag(g as UserPreferences.Gender?)
                        }
                    }
                    .labelsHidden()
                }
                LabeledContent("Unit") {
                    Picker("", selection: $viewModel.preferences.waterUnit) {
                        ForEach(UserPreferences.WaterUnit.allCases, id: \.self) { unit in
                            Text(unit.localizedName).tag(unit)
                        }
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
            Section {
                LabeledContent {
                    Toggle("", isOn: Binding(
                        get: { viewModel.preferences.waterFocusActionEnabled ?? false },
                        set: { viewModel.preferences.waterFocusActionEnabled = $0 }
                    ))
                    .labelsHidden()
                } label: {
                    Label("Focus action", systemImage: "lock.fill")
                        .font(.system(size: 13))
                }
                if (viewModel.preferences.waterFocusActionEnabled ?? false) {
                    intervalSlider(
                        value: Binding(
                            get: { Double(viewModel.preferences.waterFocusMinSeconds ?? 30) },
                            set: { viewModel.preferences.waterFocusMinSeconds = Int($0) }
                        ),
                        range: 10...100,
                        step: 5,
                        tint: .blue,
                        label: "Min countdown",
                        unit: "sec"
                    )
                }
            } header: {
                Text("Focus action")
                    .settingsSectionHeader()
            } footer: {
                Text("When on, buttons stay disabled until the countdown (seconds) finishes. Ensures you take a short break before dismissing.")
                    .settingsSectionFooter()
            }
            Section {
                reminderAppearanceRows(
                    backgroundBinding: Binding(
                        get: { viewModel.preferences.reminderWaterBackgroundStyle ?? .blur },
                        set: { viewModel.preferences.reminderWaterBackgroundStyle = $0 }
                    ),
                    primaryColorHexBinding: $viewModel.preferences.reminderWaterPrimaryColorHex
                )
                if let coordinator = reminderCoordinator {
                    Button(action: { coordinator.show(.water) }) {
                        Label("Preview", systemImage: "eye")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            } header: {
                Text("Full-screen reminder style")
                    .settingsSectionHeader()
            } footer: {
                Text("Background and accent color when this reminder appears full-screen.")
                    .settingsSectionFooter()
            }
        }
    }

    private var eyeRestContent: some View {
        Group {
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
            Section {
                LabeledContent {
                    Toggle("", isOn: Binding(
                        get: { viewModel.preferences.eyeRestFocusActionEnabled ?? false },
                        set: { viewModel.preferences.eyeRestFocusActionEnabled = $0 }
                    ))
                    .labelsHidden()
                } label: {
                    Label("Focus action", systemImage: "lock.fill")
                        .font(.system(size: 13))
                }
            } header: {
                Text("Focus action")
                    .settingsSectionHeader()
            } footer: {
                Text("When on, Skip is disabled until the full countdown ends.")
                    .settingsSectionFooter()
            }
            Section {
                reminderAppearanceRows(
                    backgroundBinding: Binding(
                        get: { viewModel.preferences.reminderEyeRestBackgroundStyle ?? .blur },
                        set: { viewModel.preferences.reminderEyeRestBackgroundStyle = $0 }
                    ),
                    primaryColorHexBinding: $viewModel.preferences.reminderEyeRestPrimaryColorHex
                )
                if let coordinator = reminderCoordinator {
                    Button(action: { coordinator.show(.eyeRest) }) {
                        Label("Preview", systemImage: "eye")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            } header: {
                Text("Full-screen reminder style")
                    .settingsSectionHeader()
            } footer: {
                Text("Background and accent color when this reminder appears full-screen.")
                    .settingsSectionFooter()
            }
        }
    }

    private var movementContent: some View {
        Group {
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
            Section {
                LabeledContent {
                    Toggle("", isOn: Binding(
                        get: { viewModel.preferences.movementFocusActionEnabled ?? false },
                        set: { viewModel.preferences.movementFocusActionEnabled = $0 }
                    ))
                    .labelsHidden()
                } label: {
                    Label("Focus action", systemImage: "lock.fill")
                        .font(.system(size: 13))
                }
                if (viewModel.preferences.movementFocusActionEnabled ?? false) {
                    intervalSlider(
                        value: Binding(
                            get: { Double(viewModel.preferences.movementFocusMinSeconds ?? 30) },
                            set: { viewModel.preferences.movementFocusMinSeconds = Int($0) }
                        ),
                        range: 10...100,
                        step: 5,
                        tint: .green,
                        label: "Min countdown",
                        unit: "sec"
                    )
                }
            } header: {
                Text("Focus action")
                    .settingsSectionHeader()
            } footer: {
                Text("When on, buttons stay disabled until the countdown (seconds) finishes.")
                    .settingsSectionFooter()
            }
            Section {
                reminderAppearanceRows(
                    backgroundBinding: Binding(
                        get: { viewModel.preferences.reminderMovementBackgroundStyle ?? .blur },
                        set: { viewModel.preferences.reminderMovementBackgroundStyle = $0 }
                    ),
                    primaryColorHexBinding: $viewModel.preferences.reminderMovementPrimaryColorHex
                )
                if let coordinator = reminderCoordinator {
                    Button(action: { coordinator.show(.movement) }) {
                        Label("Preview", systemImage: "eye")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            } header: {
                Text("Full-screen reminder style")
                    .settingsSectionHeader()
            } footer: {
                Text("Background and accent color when this reminder appears full-screen.")
                    .settingsSectionFooter()
            }
        }
    }

    private var appearanceContent: some View {
        Group {
            // 1. App-wide: theme, language, minimal (đặt trước vì là cấu hình app)
            Section {
                LabeledContent("Theme") {
                    Picker("", selection: $viewModel.preferences.appearance) {
                        ForEach(UserPreferences.Appearance.allCases, id: \.self) { appearance in
                            Text(appearance.localizedName).tag(appearance)
                        }
                    }
                    .labelsHidden()
                }
                LabeledContent("Language") {
                    Picker("", selection: $viewModel.preferences.language) {
                        Text("English").tag(UserPreferences.Language.en)
                        Text("Tiếng Việt").tag(UserPreferences.Language.vi)
                    }
                    .labelsHidden()
                }
            } header: {
                Text("App")
                    .settingsSectionHeader()
            } footer: {
                Text("Theme, language and minimal mode apply to the whole app.")
                    .settingsSectionFooter()
            }
        }
    }

    /// Two rows: Background + Primary color (used inside each reminder type section).
    @ViewBuilder
    private func reminderAppearanceRows(
        backgroundBinding: Binding<ReminderBackgroundStyle>,
        primaryColorHexBinding: Binding<String?>
    ) -> some View {
        LabeledContent("Background") {
            Picker("", selection: backgroundBinding) {
                Text("Clear").tag(ReminderBackgroundStyle.clear)
                Text("Blur").tag(ReminderBackgroundStyle.blur)
                Text("Solid").tag(ReminderBackgroundStyle.solid)
            }
            .labelsHidden()
        }
        LabeledContent("Primary color") {
            Picker("", selection: primaryColorHexBinding) {
                ForEach(ReminderPrimaryColorOption.all) { option in
                    Text(option.label).tag(option.hex as String?)
                }
            }
            .labelsHidden()
        }
    }

// MARK: - Dashboard metric card

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

    private var aboutContent: some View {
        Group {
            Section {
                LabeledContent("App") { Text(AppConstants.App.name) }
                LabeledContent("Version") { Text(appVersionString).foregroundStyle(.secondary) }
                LabeledContent("Build") { Text(appBuildString).foregroundStyle(.secondary) }
                Button {
                    NotificationCenter.default.post(name: .checkForUpdatesRequested, object: nil)
                } label: {
                    Label("Check for Updates".localizedByKey, systemImage: "arrow.down.circle")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
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
