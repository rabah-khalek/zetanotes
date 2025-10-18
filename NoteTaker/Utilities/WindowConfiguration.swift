//
//  WindowConfiguration.swift
//  NoteTaker
//
//  Centralized window configuration for disabling native macOS UI elements
//  and enabling custom chrome (toolbar, titlebar, etc.)
//

import SwiftUI
import AppKit

// MARK: - Window Configuration

/// Configures an NSWindow to use custom chrome (no native titlebar/toolbar)
struct WindowConfiguration {
    /// Apply custom window configuration to disable native UI
    static func configureCustomChrome(window: NSWindow) {
        // Hide native title and titlebar
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        // Remove native toolbar
        window.toolbar = nil

        // Allow content to occupy full window (including titlebar area)
        window.styleMask.insert(.fullSizeContentView)

        // Enable window dragging by background
        window.isMovableByWindowBackground = true

        // Keep standard window buttons visible
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
    }
}

// MARK: - Window Accessor (NSViewRepresentable)

/// SwiftUI helper to access and configure NSWindow
struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Window Draggable View

/// Helper to make a view draggable for window movement
struct WindowDraggableView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Enable mouseDown passthrough for window dragging
        nsView.window?.isMovableByWindowBackground = true
    }
}

// MARK: - Custom Window Container

/// Container that wraps content with custom window configuration
struct CustomWindowContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(WindowAccessor { window in
                WindowConfiguration.configureCustomChrome(window: window)
            })
            .ignoresSafeArea(.all)
    }
}
