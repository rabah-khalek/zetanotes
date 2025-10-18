//
//  CustomToolbarView.swift
//  NoteTaker
//
//  Custom toolbar component that replaces native macOS toolbar
//  Displays at the top of the window with draggable background
//

import SwiftUI

// MARK: - Custom Toolbar View

/// A custom toolbar that sits at the top of the window
/// Supports left, center, and right item groups with draggable background
struct CustomToolbarView<LeftContent: View, CenterContent: View, RightContent: View>: View {
    let leftContent: LeftContent
    let centerContent: CenterContent
    let rightContent: RightContent
    let height: CGFloat

    init(
        height: CGFloat = 52,
        @ViewBuilder leftContent: () -> LeftContent,
        @ViewBuilder centerContent: () -> CenterContent,
        @ViewBuilder rightContent: () -> RightContent
    ) {
        self.height = height
        self.leftContent = leftContent()
        self.centerContent = centerContent()
        self.rightContent = rightContent()
    }

    var body: some View {
        ZStack {
            // Draggable background layer (for window movement)
            WindowDraggableView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(true)

            // Toolbar content (buttons on top of draggable area)
            HStack(spacing: 0) {
                // Left items
                leftContent
                    .padding(.leading, 16)
                    .allowsHitTesting(true)

                Spacer()
                    .allowsHitTesting(false)

                // Center items
                centerContent
                    .allowsHitTesting(true)

                Spacer()
                    .allowsHitTesting(false)

                // Right items
                rightContent
                    .padding(.trailing, 16)
                    .allowsHitTesting(true)
            }
        }
        .frame(height: height)
        .background(
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.98)
                .background(.ultraThinMaterial)
        )
        .overlay(
            // Bottom border
            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 1),
            alignment: .bottom
        )
        .zIndex(10) // Ensure toolbar stays on top
    }
}

// MARK: - Toolbar Container

/// Container that provides toolbar styling and layout
struct ToolbarContainer<Content: View>: View {
    let content: Content
    let showToolbar: Bool

    init(showToolbar: Bool = true, @ViewBuilder content: () -> Content) {
        self.showToolbar = showToolbar
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            if showToolbar {
                content
            }
            Spacer()
        }
    }
}
