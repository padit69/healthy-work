//
//  UpdateInstallerService.swift
//  HealthyWork
//

import AppKit
import Foundation

/// Downloads the release asset (DMG or ZIP), installs the app to /Applications, then quits and relaunches.
enum UpdateInstallerService {

    enum InstallError: LocalizedError {
        case noDownloadURL
        case downloadFailed
        case dmgMountFailed
        case appNotFoundInDMG
        case copyFailed
        case scriptFailed

        var errorDescription: String? {
            switch self {
            case .noDownloadURL: return "No download URL"
            case .downloadFailed: return "Download failed"
            case .dmgMountFailed: return "Could not open installer"
            case .appNotFoundInDMG: return "App not found in installer"
            case .copyFailed: return "Could not prepare update"
            case .scriptFailed: return "Could not start installer"
            }
        }
    }

    /// Download to temp file and install: mount DMG (or unzip), copy app to temp, run post-quit script to replace and relaunch.
    static func downloadAndInstall(release: GitHubRelease, progress: @escaping (String) -> Void) async throws {
        guard let downloadURL = release.downloadURL else { throw InstallError.noDownloadURL }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("HealthyWorkUpdate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        // Do not remove tempDir here; the post-quit script copies from it then deletes it.

        let ext = downloadURL.pathExtension.lowercased()
        let downloadedFile = tempDir.appendingPathComponent("asset.\(ext)")

        progress("Downloading...")
        let (data, response) = try await URLSession.shared.data(from: downloadURL)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw InstallError.downloadFailed }
        try data.write(to: downloadedFile)

        let newAppURL: URL
        if ext == "dmg" {
            progress("Opening installer...")
            newAppURL = try mountDMGAndCopyApp(dmgURL: downloadedFile, to: tempDir)
        } else if ext == "zip" {
            progress("Extracting...")
            newAppURL = try unzipAndCopyApp(zipURL: downloadedFile, to: tempDir)
        } else {
            throw InstallError.downloadFailed
        }

        progress("Preparing to install...")
        let appToInstall = tempDir.appendingPathComponent("HealthyWork-new.app")
        if newAppURL != appToInstall {
            if FileManager.default.fileExists(atPath: appToInstall.path) { try FileManager.default.removeItem(at: appToInstall) }
            try FileManager.default.copyItem(at: newAppURL, to: appToInstall)
        }

        try runReplaceAndRelaunchScript(appSource: appToInstall, tempDir: tempDir)
    }

    private static func mountDMGAndCopyApp(dmgURL: URL, to tempDir: URL) throws -> URL {
        let mountPoint = tempDir.appendingPathComponent("mnt", isDirectory: true)
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["attach", dmgURL.path, "-nobrowse", "-mountpoint", mountPoint.path, "-quiet"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw InstallError.dmgMountFailed }

        defer {
            let detach = Process()
            detach.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            detach.arguments = ["detach", mountPoint.path, "-quiet"]
            try? detach.run()
            detach.waitUntilExit()
        }

        // Volume may contain "HealthyWork.app" or "HealthyWork v1.0.9/HealthyWork.app"
        let contents = (try? FileManager.default.contentsOfDirectory(at: mountPoint, includingPropertiesForKeys: nil)) ?? []
        if let app = contents.first(where: { $0.lastPathComponent == "HealthyWork.app" }) {
            let dest = tempDir.appendingPathComponent("HealthyWork.app")
            if FileManager.default.fileExists(atPath: dest.path) { try? FileManager.default.removeItem(at: dest) }
            try FileManager.default.copyItem(at: app, to: dest)
            return dest
        }
        if let subdir = contents.first(where: { $0.hasDirectoryPath }) {
            let app = subdir.appendingPathComponent("HealthyWork.app")
            if FileManager.default.fileExists(atPath: app.path) {
                let dest = tempDir.appendingPathComponent("HealthyWork.app")
                if FileManager.default.fileExists(atPath: dest.path) { try? FileManager.default.removeItem(at: dest) }
                try FileManager.default.copyItem(at: app, to: dest)
                return dest
            }
        }
        throw InstallError.appNotFoundInDMG
    }

    private static func unzipAndCopyApp(zipURL: URL, to tempDir: URL) throws -> URL {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", zipURL.path, "-d", tempDir.path]
        process.currentDirectoryURL = tempDir
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw InstallError.copyFailed }

        // Find HealthyWork.app in extracted tree
        let enumerator = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: [.isDirectoryKey])!
        while let url = enumerator.nextObject() as? URL {
            if url.lastPathComponent == "HealthyWork.app" {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    return url
                }
            }
        }
        throw InstallError.appNotFoundInDMG
    }

    /// Write a script that waits for us to quit, replaces /Applications/HealthyWork.app, then opens the new app. Run script and quit.
    private static func runReplaceAndRelaunchScript(appSource: URL, tempDir: URL) throws {
        let script = """
        #!/bin/bash
        sleep 3
        killall "HealthyWork" 2>/dev/null || true
        sleep 1
        rm -rf "/Applications/HealthyWork.app"
        cp -R "\(appSource.path)" "/Applications/HealthyWork.app"
        rm -rf "\(tempDir.path)"
        open -a "/Applications/HealthyWork.app"
        """
        let scriptURL = FileManager.default.temporaryDirectory.appendingPathComponent("HealthyWork-Install-\(UUID().uuidString).sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        process.standardInput = nil
        try process.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }
}
