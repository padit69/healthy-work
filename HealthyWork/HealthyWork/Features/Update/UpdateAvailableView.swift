//
//  UpdateAvailableView.swift
//  HealthyWork
//

import SwiftUI

/// Shown when a new version is available: release info + Update button. Update triggers download & install then quit.
struct UpdateAvailableView: View {
    let release: GitHubRelease
    let onDismiss: () -> Void
    @State private var statusMessage: String = ""
    @State private var isInstalling: Bool = false
    @State private var installError: String?

    private var releaseNotes: String {
        release.body ?? "Bug fixes and improvements."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Update Available".localizedByKey)
                        .font(.headline)
                    Text("Version \(release.version) is available. You have \(UpdateCheckService.currentVersion).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if !releaseNotes.isEmpty {
                Text(releaseNotes)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let err = installError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if !statusMessage.isEmpty {
                HStack(spacing: 6) {
                    if isInstalling {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Button("Later".localizedByKey) {
                    onDismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("Update".localizedByKey) {
                    startUpdate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isInstalling)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(width: 420, alignment: .leading)
    }

    private func startUpdate() {
        isInstalling = true
        installError = nil
        statusMessage = ""

        Task { @MainActor in
            do {
                try await UpdateInstallerService.downloadAndInstall(release: release) { msg in
                    Task { @MainActor in
                        statusMessage = msg
                    }
                }
            } catch {
                installError = error.localizedDescription
                isInstalling = false
            }
        }
    }
}
