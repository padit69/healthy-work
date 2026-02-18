//
//  WaterRecord.swift
//  HealthyWork
//

import Foundation
import SwiftData

@Model
final class WaterRecord {
    var date: Date
    var amountMl: Int
    var loggedAt: Date

    init(date: Date, amountMl: Int, loggedAt: Date = Date()) {
        self.date = date
        self.amountMl = amountMl
        self.loggedAt = loggedAt
    }
}
