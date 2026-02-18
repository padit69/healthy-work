//
//  PrimaryButton.swift
//  HealthyWork
//
//  Created by Dũng Phùng on 18/2/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    PrimaryButton("Add Item", systemImage: "plus") {}
        .padding()
}
