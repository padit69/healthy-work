//
//  WindowAccessor.swift
//  HealthyWork
//

import AppKit
import SwiftUI

/// Attaches to the hosting window to hide on close (instead of closing) and registers it with AppDelegate for menu bar "Open Settings".
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowAccessorView {
        WindowAccessorView(delegate: context.coordinator)
    }

    func updateNSView(_ nsView: WindowAccessorView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, NSWindowDelegate {
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            sender.orderOut(nil)
            return false
        }
    }
}

final class WindowAccessorView: NSView {
    private let delegate: NSWindowDelegate?

    init(delegate: NSWindowDelegate?) {
        self.delegate = delegate
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        self.delegate = nil
        super.init(coder: coder)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window = window else { return }
        window.delegate = delegate
        (NSApp.delegate as? AppDelegate)?.mainWindow = window
    }
}
