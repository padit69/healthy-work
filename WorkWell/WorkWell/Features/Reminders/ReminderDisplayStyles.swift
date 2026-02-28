//
//  ReminderDisplayStyles.swift
//  WorkWell
//
//  Style layer for full-screen reminders (inspired by Health Reminder).
//

import SwiftUI

/// Renders full-screen reminder in the selected display style (Modern / Minimal / Bold).
struct ReminderStyleView: View {
    var displayStyle: ReminderDisplayStyle
    var type: ReminderType
    /// Primary/accent color for this reminder (from preferences or type default).
    var primaryColor: Color
    var countdown: Int?
    var progress: Double
    var primaryButton: (title: String, action: () -> Void)
    var secondaryButton: (title: String, action: () -> Void)?
    /// When true (e.g. focus action), primary button is disabled and not tappable.
    var primaryButtonDisabled: Bool = false
    /// When true (e.g. focus action), secondary button is disabled and not tappable.
    var secondaryButtonDisabled: Bool = false
    /// When true, show a label that focus mode is on (buttons disabled until countdown).
    var focusModeEnabled: Bool = false

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.92
    @State private var breathingScale: CGFloat = 1.0
    @State private var blurRadius: CGFloat = 0

    var body: some View {
        Group {
            switch displayStyle {
            case .modern:
                ModernReminderStyleView(
                    type: type,
                    primaryColor: primaryColor,
                    countdown: countdown,
                    progress: progress,
                    opacity: opacity,
                    scale: scale,
                    breathingScale: breathingScale,
                    blurRadius: blurRadius,
                    primaryButton: primaryButton,
                    secondaryButton: secondaryButton,
                    primaryButtonDisabled: primaryButtonDisabled,
                    secondaryButtonDisabled: secondaryButtonDisabled,
                    focusModeEnabled: focusModeEnabled
                )
            case .minimal:
                MinimalReminderStyleView(
                    type: type,
                    primaryColor: primaryColor,
                    countdown: countdown,
                    progress: progress,
                    opacity: opacity,
                    scale: scale,
                    primaryButton: primaryButton,
                    secondaryButton: secondaryButton,
                    primaryButtonDisabled: primaryButtonDisabled,
                    secondaryButtonDisabled: secondaryButtonDisabled,
                    focusModeEnabled: focusModeEnabled
                )
            case .bold:
                BoldReminderStyleView(
                    type: type,
                    primaryColor: primaryColor,
                    countdown: countdown,
                    progress: progress,
                    opacity: opacity,
                    scale: scale,
                    breathingScale: breathingScale,
                    primaryButton: primaryButton,
                    secondaryButton: secondaryButton,
                    primaryButtonDisabled: primaryButtonDisabled,
                    secondaryButtonDisabled: secondaryButtonDisabled,
                    focusModeEnabled: focusModeEnabled
                )
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
            if displayStyle == .modern || displayStyle == .bold {
                withAnimation(.easeOut(duration: 0.4)) { blurRadius = 24 }
                withAnimation(
                    Animation.easeInOut(duration: 2.8).repeatForever(autoreverses: true)
                ) { breathingScale = 1.12 }
            }
        }
    }
}

// MARK: - Modern Style
private struct ModernReminderStyleView: View {
    let type: ReminderType
    let primaryColor: Color
    let countdown: Int?
    let progress: Double
    let opacity: Double
    let scale: CGFloat
    let breathingScale: CGFloat
    let blurRadius: CGFloat
    let primaryButton: (title: String, action: () -> Void)
    let secondaryButton: (title: String, action: () -> Void)?
    let primaryButtonDisabled: Bool
    let secondaryButtonDisabled: Bool
    let focusModeEnabled: Bool

    @State private var iconOffset: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.18, blue: 0.35).opacity(0.96),
                    Color(red: 0.16, green: 0.22, blue: 0.38).opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: blurRadius)

            VStack(spacing: 24) {
                Spacer()
                iconSection
                    .offset(y: iconOffset)
                if focusModeEnabled {
                    focusModeBadge
                }
                titleSection
                centerSection
                Spacer()
                buttonSection
                shortcutHint
                Spacer().frame(height: 32)
            }
            .padding(40)
            .scaleEffect(scale)
        }
        .onAppear {
            let amplitude: CGFloat
            switch type {
            case .water:
                amplitude = 10
            case .movement:
                amplitude = 14
            case .eyeRest:
                amplitude = 8
            }

            withAnimation(
                .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
            ) {
                iconOffset = -amplitude
            }
        }
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryColor.opacity(0.2),
                            primaryColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)
                .scaleEffect(breathingScale)
            Image(systemName: type.icon)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [primaryColor.opacity(0.9), primaryColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(breathingScale)
                .shadow(color: primaryColor.opacity(0.3), radius: 15, x: 0, y: 0)
        }
    }

    private var focusModeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("str_focus_mode_on".localizedByKey)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(primaryColor.opacity(0.85)))
    }

    private var titleSection: some View {
        VStack(spacing: 10) {
            Text(type.title)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            Text(type.subtitle)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            Text(type.helper)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var centerSection: some View {
        if let countdown = countdown {
            countdownRing(countdown: countdown)
        } else {
            Spacer().frame(height: 24)
        }
    }

    private func countdownRing(countdown: Int) -> some View {
        ZStack {
            Circle()
                .stroke(primaryColor.opacity(0.12), lineWidth: 3)
                .frame(width: 160, height: 160)
                .blur(radius: 6)
            Circle()
                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            primaryColor.opacity(0.9),
                            primaryColor.opacity(0.7),
                            primaryColor.opacity(0.9)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: countdown)
            VStack(spacing: 6) {
                Text("\(countdown)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.95), .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())
                Text("str_seconds")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
        .padding(.vertical, 20)
    }

    private var buttonSection: some View {
        HStack(spacing: 14) {
            if let secondary = secondaryButton {
                Button(action: secondary.action) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                        Text(secondary.title)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(secondaryButtonDisabled)
                .opacity(secondaryButtonDisabled ? 0.5 : 1)
            }
            Button(action: primaryButton.action) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text(primaryButton.title)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(primaryColor)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .disabled(primaryButtonDisabled)
            .opacity(primaryButtonDisabled ? 0.5 : 1)
        }
    }

    @ViewBuilder
    private var shortcutHint: some View {
        switch type {
        case .water, .movement:
            Text("str_shortcut_hint")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        case .eyeRest:
            Text("str_shortcut_hint_eye_rest")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
    }
}

// MARK: - Minimal Style
private struct MinimalReminderStyleView: View {
    let type: ReminderType
    let primaryColor: Color
    let countdown: Int?
    let progress: Double
    let opacity: Double
    let scale: CGFloat
    let primaryButton: (title: String, action: () -> Void)
    let secondaryButton: (title: String, action: () -> Void)?
    let primaryButtonDisabled: Bool
    let secondaryButtonDisabled: Bool
    let focusModeEnabled: Bool

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.03)],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: type.icon)
                    .font(.system(size: 76, weight: .regular))
                    .foregroundColor(primaryColor.opacity(0.85))
                if focusModeEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("str_focus_mode_on".localizedByKey)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(primaryColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(primaryColor.opacity(0.18)))
                }
                VStack(spacing: 12) {
                    Text(type.title.localizedByKey)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    Text(type.subtitle.localizedByKey)
                        .font(.system(size: 17))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                }
                if let countdown = countdown {
                    VStack(spacing: 16) {
                        Text("\(countdown)")
                            .font(.system(size: 72, weight: .light, design: .rounded))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                            .contentTransition(.numericText())
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(primaryColor.opacity(0.8))
                                    .frame(width: max(6, g.size.width * progress), height: 6)
                                    .animation(.linear(duration: 1), value: countdown)
                            }
                        }
                        .frame(width: 280, height: 6)
                    }
                } else {
                    Spacer().frame(height: 16)
                }
                Spacer()
                HStack(spacing: 12) {
                    if let secondary = secondaryButton {
                        Button(action: secondary.action) {
                            Text(secondary.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .padding(.horizontal, 26)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 50)
                                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                                        .background(RoundedRectangle(cornerRadius: 50).fill(Color.white.opacity(0.5)))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(secondaryButtonDisabled)
                        .opacity(secondaryButtonDisabled ? 0.5 : 1)
                    }
                    Button(action: primaryButton.action) {
                        Text(primaryButton.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(primaryColor))
                    }
                    .buttonStyle(.plain)
                    .disabled(primaryButtonDisabled)
                    .opacity(primaryButtonDisabled ? 0.5 : 1)
                }
                shortcutHint
                Spacer().frame(height: 32)
            }
            .scaleEffect(scale)
        }
    }

    @ViewBuilder
    private var shortcutHint: some View {
        switch type {
        case .water, .movement:
            Text("str_shortcut_hint")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        case .eyeRest:
            Text("str_shortcut_hint_eye_rest")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }
}

// MARK: - Bold Style
private struct BoldReminderStyleView: View {
    let type: ReminderType
    let primaryColor: Color
    let countdown: Int?
    let progress: Double
    let opacity: Double
    let scale: CGFloat
    let breathingScale: CGFloat
    let primaryButton: (title: String, action: () -> Void)
    let secondaryButton: (title: String, action: () -> Void)?
    let primaryButtonDisabled: Bool
    let secondaryButtonDisabled: Bool
    let focusModeEnabled: Bool

    @State private var iconRotation: Double = 0
    @State private var iconVerticalOffset: CGFloat = 0

    var body: some View {
        ZStack {
            primaryColor.opacity(0.85)
                .ignoresSafeArea()
            LinearGradient(
                colors: [
                    primaryColor.opacity(0.7),
                    primaryColor.opacity(0.65),
                    primaryColor.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            Color.black.opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.15 - Double(i) * 0.04))
                            .frame(width: 120 + CGFloat(i * 36), height: 120 + CGFloat(i * 36))
                            .blur(radius: 28)
                            .scaleEffect(breathingScale)
                    }
                    Image(systemName: type.icon)
                        .font(.system(size: 82, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .scaleEffect(breathingScale)
                        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                }
                .rotationEffect(.degrees(iconRotation))
                .offset(y: iconVerticalOffset)

                if focusModeEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("str_focus_mode_on".localizedByKey)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(primaryColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.95)))
                }

                VStack(spacing: 12) {
                    Text(type.title)
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .textCase(.uppercase)
                        .tracking(1)
                    Text(type.subtitle)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                }
                .multilineTextAlignment(.center)

                if let countdown = countdown {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 14)
                            .frame(width: 180, height: 180)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: countdown)
                        VStack(spacing: 4) {
                            Text("\(countdown)")
                                .font(.system(size: 64, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                            Text("str_sec")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(3)
                        }
                    }
                    .padding(.vertical, 16)
                } else {
                    Spacer().frame(height: 20)
                }

                Spacer()

                HStack(spacing: 14) {
                    if let secondary = secondaryButton {
                        Button(action: secondary.action) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text(secondary.title.uppercased())
                                    .font(.system(size: 16, weight: .black))
                                    .tracking(2)
                            }
                            .foregroundColor(primaryColor.opacity(0.9))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.white.opacity(0.9)))
                        }
                        .buttonStyle(.plain)
                        .disabled(secondaryButtonDisabled)
                        .opacity(secondaryButtonDisabled ? 0.5 : 1)
                    }
                    Button(action: primaryButton.action) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text(primaryButton.title.uppercased())
                                .font(.system(size: 16, weight: .black))
                                .tracking(2)
                        }
                        .foregroundColor(primaryColor)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.white))
                        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(primaryButtonDisabled)
                    .opacity(primaryButtonDisabled ? 0.5 : 1)
                }

                shortcutHint
                Spacer().frame(height: 32)
            }
            .padding(40)
            .scaleEffect(scale)
        }
        .onAppear {
            switch type {
            case .movement:
                withAnimation(
                    .easeInOut(duration: 1.4)
                        .repeatForever(autoreverses: true)
                ) {
                    iconRotation = 6
                }
            case .water:
                withAnimation(
                    .easeInOut(duration: 1.9)
                        .repeatForever(autoreverses: true)
                ) {
                    iconVerticalOffset = -10
                }
            case .eyeRest:
                withAnimation(
                    .easeInOut(duration: 2.1)
                        .repeatForever(autoreverses: true)
                ) {
                    iconVerticalOffset = -6
                }
            }
        }
    }

    @ViewBuilder
    private var shortcutHint: some View {
        switch type {
        case .water, .movement:
            Text("str_shortcut_hint")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.86))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        case .eyeRest:
            Text("str_shortcut_hint_eye_rest")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.86))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }
}

#Preview("Modern") {
    ReminderStyleView(
        displayStyle: .minimal,
        type: .eyeRest,
        primaryColor: ReminderType.eyeRest.color,
        countdown: 18,
        progress: 0.1,
        primaryButton: ("Start", {}),
        secondaryButton: ("Skip", {})
    )
    .frame(width: 400, height: 600)
}
