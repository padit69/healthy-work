import Foundation
@preconcurrency import CloudKit
import Security

enum ICloudSyncStatus: Equatable {
    case checking
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case error

    var localizedName: String {
        switch self {
        case .checking: return "Checking…".localizedByKey
        case .available: return "Sync on".localizedByKey
        case .noAccount: return "Sign in to iCloud".localizedByKey
        case .restricted: return "iCloud restricted".localizedByKey
        case .temporarilyUnavailable: return "Temporarily unavailable".localizedByKey
        case .error: return "Sync unavailable".localizedByKey
        }
    }

    var systemImage: String {
        switch self {
        case .checking: return "arrow.triangle.2.circlepath.icloud"
        case .available: return "checkmark.icloud.fill"
        case .noAccount: return "person.crop.circle.badge.exclamationmark"
        case .restricted, .temporarilyUnavailable, .error: return "exclamationmark.icloud.fill"
        }
    }
}

enum ICloudSyncService {
    static let containerIdentifier = AppConstants.App.iCloudContainerIdentifier
    static var isCloudPersistenceEnabled = false

    static var hasRequiredEntitlements: Bool {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
              let task = SecTaskCreateFromSelf(nil),
              let teamIdentifier = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.developer.team-identifier" as CFString,
                nil
              ) as? String,
              !teamIdentifier.isEmpty,
              let identifiers = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.developer.icloud-container-identifiers" as CFString,
                nil
              ) as? [String] else {
            return false
        }
        return identifiers.contains(containerIdentifier)
    }

    static func refreshAccountStatus(completion: @escaping (ICloudSyncStatus) -> Void) {
        guard isCloudPersistenceEnabled else {
            completion(.error)
            return
        }

        CKContainer(identifier: containerIdentifier).accountStatus { status, error in
            let resolvedStatus: ICloudSyncStatus
            if error != nil {
                resolvedStatus = .error
            } else {
                switch status {
                case .available: resolvedStatus = .available
                case .noAccount: resolvedStatus = .noAccount
                case .restricted: resolvedStatus = .restricted
                case .temporarilyUnavailable: resolvedStatus = .temporarilyUnavailable
                case .couldNotDetermine: resolvedStatus = .error
                @unknown default: resolvedStatus = .error
                }
            }

            DispatchQueue.main.async {
                completion(resolvedStatus)
            }
        }
    }
}
