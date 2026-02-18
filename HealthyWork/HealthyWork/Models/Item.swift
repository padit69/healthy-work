//
//  Item.swift
//  HealthyWork
//
//  Created by Dũng Phùng on 18/2/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
