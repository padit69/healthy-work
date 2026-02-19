
//
//  UpdateCheckService.swift
//  HealthyWork
//

import Foundation

/// Release info from GitHub API (releases/latest).
struct GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let body: String?
    let assets: [Asset]
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case assets
        case htmlUrl = "html_url"
    }

    struct Asset: Decodable {
        let name: String
        let browserDownloadUrl: String

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
        }
    }

    /// Version string without "v" prefix (e.g. "1.0.9").
    var version: String {
        tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }

    /// Prefer DMG, else first .zip asset for HealthyWork.
    var downloadURL: URL? {
        let dmg = assets.first { $0.name.lowercased().hasSuffix(".dmg") }
        if let urlString = dmg?.browserDownloadUrl, let url = URL(string: urlString) { return url }
        let zip = assets.first { $0.name.lowercased().hasSuffix(".zip") }
        if let urlString = zip?.browserDownloadUrl, let url = URL(string: urlString) { return url }
        return nil
    }

    var isDMG: Bool {
        assets.contains { $0.name.lowercased().hasSuffix(".dmg") }
    }
}

enum UpdateCheckService {

    static var currentVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }

    /// Compare two version strings (e.g. "1.0.8" vs "1.0.9"). Returns true if `newer` > `current`.
    static func isVersion(_ newer: String, greaterThan current: String) -> Bool {
        let n = parseVersion(newer)
        let c = parseVersion(current)
        for i in 0..<max(n.count, c.count) {
            let nVal = i < n.count ? n[i] : 0
            let cVal = i < c.count ? c[i] : 0
            if nVal > cVal { return true }
            if nVal < cVal { return false }
        }
        return false
    }

    private static func parseVersion(_ s: String) -> [Int] {
        let v = s.hasPrefix("v") ? String(s.dropFirst()) : s
        return v.split(separator: ".").compactMap { Int($0) }
    }

    /// Fetch latest release; if newer than current, return release and download URL.
    static func checkForUpdate() async -> GitHubRelease? {
        guard let url = URL(string: AppConstants.Updates.latestReleaseURL) else { return nil }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let release = try JSONDecoder().decode(GithubReleaseDecode.self, from: data)
            let tagVersion = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
            if isVersion(tagVersion, greaterThan: currentVersion), release.downloadURL != nil {
                return GitHubRelease(
                    tagName: release.tagName,
                    name: release.name,
                    body: release.body,
                    assets: release.assets.map { GitHubRelease.Asset(name: $0.name, browserDownloadUrl: $0.browserDownloadUrl) },
                    htmlUrl: release.htmlUrl
                )
            }
            return nil
        } catch {
            print("Update error:", error)
            return nil
        }
    }

    /// Decodable mirror to get optional downloadURL from assets.
    private struct GithubReleaseDecode: Decodable {
        let tagName: String
        let name: String?
        let body: String?
        let assets: [AssetDecode]
        let htmlUrl: String
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case body
            case assets
            case htmlUrl = "html_url"
        }
        struct AssetDecode: Decodable {
            let name: String
            let browserDownloadUrl: String
            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadUrl = "browser_download_url"
            }
        }
        var downloadURL: URL? {
            let dmg = assets.first { $0.name.lowercased().hasSuffix(".dmg") }
            if let s = dmg?.browserDownloadUrl { return URL(string: s) }
            let zip = assets.first { $0.name.lowercased().hasSuffix(".zip") }
            if let s = zip?.browserDownloadUrl { return URL(string: s) }
            return nil
        }
    }
}
