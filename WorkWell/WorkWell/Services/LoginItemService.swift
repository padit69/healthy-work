//
//  LoginItemService.swift
//  WorkWell
//

import Foundation
import ServiceManagement

enum LoginItemService {
    static var isSupported: Bool {
        if #available(macOS 13, *) {
            true
        } else {
            false
        }
    }

    static var isEnabled: Bool {
        guard isSupported else { return false }
        if #available(macOS 13, *) {
            let status = SMAppService.mainApp.status
            switch status {
            case .enabled:
                return true
            default:
                return false
            }
        } else {
            return false
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard isSupported else { return }
        if #available(macOS 13, *) {
            let service = SMAppService.mainApp
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        }
    }
}

