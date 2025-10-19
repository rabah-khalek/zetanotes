//
//  CustomSidebarView.swift
//  ZetaNotes
//
//  Custom sidebar component for collapsible/resizable sidebars
//  Can be used for left or right panes
//

import SwiftUI

// MARK: - Sidebar Position

enum SidebarPosition {
    case left
    case right
}

// MARK: - Custom Sidebar View

/// A custom sidebar that can be shown/hidden with animation
/// Supports left or right positioning with custom content
struct CustomSidebarView<Content: View>: View {
    let content: Content
    let position: SidebarPosition
    let width: CGFloat
    let isVisible: Bool
    let showBorder: Bool

    init(
        position: SidebarPosition = .left,
        width: CGFloat = 250,
        isVisible: Bool = true,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.position = position
        self.width = width
        self.isVisible = isVisible
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                content
            }
            .frame(width: width)
            .background(AppTheme.Colors.sidebarBackground)
            .overlay(
                Group {
                    if showBorder {
                        Rectangle()
                            .fill(AppTheme.Colors.sidebarBorder)
                            .frame(width: 1)
                    }
                },
                alignment: position == .left ? .trailing : .leading
            )
            .transition(.move(edge: position == .left ? .leading : .trailing).combined(with: .opacity))
        }
    }
}

// MARK: - Sidebar Configuration

/// Configuration for sidebar behavior
struct SidebarConfiguration {
    var defaultWidth: CGFloat = 250
    var minWidth: CGFloat = 200
    var maxWidth: CGFloat = 400
    var isCollapsible: Bool = true
    var isResizable: Bool = true

    static let standard = SidebarConfiguration()
}
