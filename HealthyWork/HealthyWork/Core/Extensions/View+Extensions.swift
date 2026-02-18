//
//  View+Extensions.swift
//  HealthyWork
//
//  Created by Dũng Phùng on 18/2/26.
//

import SwiftUI

extension View {

    /// Conditionally apply a modifier.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
