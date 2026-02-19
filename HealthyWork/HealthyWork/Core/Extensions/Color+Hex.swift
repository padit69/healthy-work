//
//  Color+Hex.swift
//  HealthyWork
//

import SwiftUI

extension Color {
    /// Creates a Color from hex string "#RRGGBB" or "RRGGBB". Returns nil if invalid.
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }
        guard hexSanitized.count == 6,
              let r = UInt8(hexSanitized.prefix(2), radix: 16),
              let g = UInt8(hexSanitized.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(hexSanitized.suffix(2), radix: 16) else { return nil }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
