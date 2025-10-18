//
//  CustomToolbar.swift
//  NoteTaker
//
//  Reusable toolbar styling components
//

import SwiftUI

// MARK: - Toolbar Styling Constants

/// Centralized toolbar styling configuration
enum ToolbarStyle {
    /// Spacing between toolbar items (buttons, dividers, etc.)
    static let itemSpacing: CGFloat = 8

    /// Horizontal padding for toolbar groups
    static let horizontalPadding: CGFloat = 8

    /// Vertical padding for toolbar groups
    static let verticalPadding: CGFloat = 0

    /// Height of vertical dividers
    static let dividerHeight: CGFloat = 14

    /// Divider color opacity
    static let dividerOpacity: CGFloat = 0.2
}

// MARK: - Components

/// A vertical divider for use in toolbars
struct ToolbarDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(ToolbarStyle.dividerOpacity))
            .frame(width: 1, height: ToolbarStyle.dividerHeight)
    }
}

/// A container for toolbar items that controls spacing between them
struct ToolbarGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: ToolbarStyle.itemSpacing) {
            content
        }
        .padding(.horizontal, ToolbarStyle.horizontalPadding)
        .padding(.vertical, ToolbarStyle.verticalPadding)
        .controlSize(.small)
    }
}
