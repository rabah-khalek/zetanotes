//
//  AppTheme.swift
//  ZetaNotes
//
//  Global color theme and styling constants for consistent UI across the app
//

import SwiftUI

// MARK: - App Theme

enum AppTheme {
    // MARK: - Colors

    enum Colors {
        // Background colors (semantic - auto-adapt to light/dark mode)
        static let windowBackground = Color(nsColor: .windowBackgroundColor)
        static let controlBackground = Color(nsColor: .controlBackgroundColor)
        static let textBackground = Color(nsColor: .textBackgroundColor)

        // Content area background (unified for edit and preview)
        static let contentBackground = Color(nsColor: .textBackgroundColor)

        // Note editor background (unified)
        static let editorBackground = Color(nsColor: .textBackgroundColor)

        // Toolbar colors
        static let toolbarBackground = windowBackground
        static let toolbarBackgroundOpacity: CGFloat = 0.98
        static let toolbarBorder = Color.secondary.opacity(0.15)

        // Sidebar colors
        static let sidebarBackground = controlBackground
        static let sidebarBorder = Color.secondary.opacity(0.15)

        // Accent colors
        static let accentBlue = Color.blue
        static let accentPurple = Color.purple
        static let accentOrange = Color.orange
        static let accentGreen = Color.green
        static let accentRed = Color.red
        static let accentIndigo = Color.indigo

        // Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary

        // Status colors
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        static let info = Color.blue
    }

    // MARK: - Spacing

    enum Spacing {
        // Toolbar
        static let toolbarHeight: CGFloat = 52
        static let toolbarHorizontalPadding: CGFloat = 16
        static let toolbarItemSpacing: CGFloat = 8

        // Sidebar
        static let sidebarDefaultWidth: CGFloat = 250
        static let sidebarMinWidth: CGFloat = 250
        static let sidebarMaxWidth: CGFloat = 400

        // Chat
        static let chatDefaultWidth: CGFloat = 350
        static let chatMinWidth: CGFloat = 350
        static let chatMaxWidth: CGFloat = 500

        // Status bar
        static let statusBarHeight: CGFloat = 32
        static let statusBarVerticalPadding: CGFloat = 4 // Reduced from 6
        static let statusBarHorizontalPadding: CGFloat = 8

        // Content padding
        static let contentTopPadding: CGFloat = 52 // For toolbar
        static let contentBottomPadding: CGFloat = 28 // For status bar (reduced from 32)

        // Note title
        static let noteTitleTopPadding: CGFloat = 8 // Reduced from 12
        static let noteTitleBottomPadding: CGFloat = 4 // Reduced for tighter spacing to content
        static let noteTitleTopPaddingWhileSearching: CGFloat = 80 // When search bar is visible

        // Search bar
        static let searchBarTopPadding: CGFloat = 40 // For title bar area
        static let searchBarHorizontalPadding: CGFloat = 12
        static let searchBarBottomPadding: CGFloat = 6

        // Chat
        static let chatWidth: CGFloat = 350
        static let chatHeaderTopPadding: CGFloat = 16
        static let chatHeaderBottomPadding: CGFloat = 8
    }

    // MARK: - Typography

    enum Typography {
        static let toolbarIconSize: CGFloat = 14
        static let toolbarButtonSize: CGFloat = 11

        static let statusIconSize: CGFloat = 9
        static let statusTextSize: CGFloat = 10

        static let chatTitleSize: CGFloat = 14
        static let chatIconSize: CGFloat = 14
    }

    // MARK: - Effects

    enum Effects {
        static let toolbarMaterial: Material = .ultraThinMaterial
        static let sidebarMaterial: Material? = nil // Use solid color

        static let borderWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 8

        static let standardShadow = Color.black.opacity(0.1)
        static let shadowRadius: CGFloat = 8
        static let shadowY: CGFloat = 4
    }

    // MARK: - Animation

    enum Animation {
        static let standard = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let quick = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.9)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
    }

    // MARK: - Responsive Layout

    enum Layout {
        // Window size constraints
        static let defaultWindowWidth: CGFloat = 1000
        static let defaultWindowHeight: CGFloat = 700
        static let minWindowWidth: CGFloat = 1000
        static let minWindowHeight: CGFloat = 700

        // Window size breakpoints
        static let compactWidth: CGFloat = 1000 // Below this, compact mode
        static let regularWidth: CGFloat = 1400 // Above this, spacious mode

        // Responsive helpers
        static func isCompact(width: CGFloat) -> Bool {
            return width < compactWidth
        }

        static func isRegular(width: CGFloat) -> Bool {
            return width >= regularWidth
        }

        // Adaptive sidebar width based on window size
        static func adaptiveSidebarWidth(windowWidth: CGFloat, isOpen: Bool) -> CGFloat {
            guard isOpen else { return 0 }

            if windowWidth < compactWidth {
                return Spacing.sidebarMinWidth
            } else if windowWidth < regularWidth {
                return Spacing.sidebarDefaultWidth
            } else {
                return min(Spacing.sidebarDefaultWidth, windowWidth * 0.2)
            }
        }

        // Adaptive chat width based on window size
        static func adaptiveChatWidth(windowWidth: CGFloat, isOpen: Bool) -> CGFloat {
            guard isOpen else { return 0 }

            if windowWidth < compactWidth {
                return Spacing.chatMinWidth
            } else if windowWidth < regularWidth {
                return Spacing.chatDefaultWidth
            } else {
                return min(Spacing.chatDefaultWidth, windowWidth * 0.25)
            }
        }
    }
}
