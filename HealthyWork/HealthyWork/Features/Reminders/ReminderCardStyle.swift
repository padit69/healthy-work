//
//  ReminderCardStyle.swift
//  HealthyWork
//

import SwiftUI

/// Shared layout and style for full-screen reminder content (card + footer).
struct ReminderCard<Content: View>: View {
    var accentColor: Color
    @ViewBuilder var content: () -> Content
    @State private var cardAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60)
            content()
                .padding(.horizontal, 40)
                .padding(.vertical, 32)
                .frame(maxWidth: 460)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.white.opacity(0.94))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(accentColor.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 30, y: 10)
                .opacity(cardAppeared ? 1 : 0)
                .scaleEffect(cardAppeared ? 1 : 0.92)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.35).delay(0.08)) {
                        cardAppeared = true
                    }
                }
            Spacer(minLength: 60)
            Text("Press Esc to close")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.bottom, 28)
        }
    }
}

/// Icon container with tint background.
struct ReminderIconView: View {
    var systemName: String
    var color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.25),
                            color.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
            Image(systemName: systemName)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 108, height: 108)
    }
}
