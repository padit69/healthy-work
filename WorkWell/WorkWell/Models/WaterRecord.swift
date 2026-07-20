//
//  WaterRecord.swift
//  WorkWell
//

import Foundation
import SwiftData

@Model
final class WaterRecord {
    var date: Date = Date()
    var amountMl: Int = 0
    var loggedAt: Date = Date()

    init(date: Date, amountMl: Int, loggedAt: Date = Date()) {
        self.date = date
        self.amountMl = amountMl
        self.loggedAt = loggedAt
    }
}
