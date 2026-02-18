//
//  Logger.swift
//  HealthyWork
//
//  Created by Dũng Phùng on 18/2/26.
//

import Foundation
import os.log

enum Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "HealthyWork"
    static let general = os.Logger(subsystem: subsystem, category: "general")
    static let ui = os.Logger(subsystem: subsystem, category: "ui")
}
