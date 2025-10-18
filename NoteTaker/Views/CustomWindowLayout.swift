//
//  CustomWindowLayout.swift
//  NoteTaker
//
//  Custom window layout that orchestrates toolbar, sidebars, and main content
//  Replaces NavigationSplitView with full control over layout
//

import SwiftUI

// MARK: - Custom Window Layout

/// A custom window layout with toolbar, optional left/right sidebars, and main content
/// This replaces NavigationSplitView for full control over the window chrome
struct CustomWindowLayout<Toolbar: View, LeftSidebar: View, Content: View, RightSidebar: View>: View {
    // Toolbar
    let toolbar: Toolbar

    // Left sidebar
    let leftSidebar: LeftSidebar
    let showLeftSidebar: Bool
    let leftSidebarWidth: CGFloat

    // Main content
    let content: Content

    // Right sidebar
    let rightSidebar: RightSidebar
    let showRightSidebar: Bool
    let rightSidebarWidth: CGFloat

    // Spacing
    let toolbarHeight: CGFloat

    init(
        toolbarHeight: CGFloat = 52,
        showLeftSidebar: Bool = true,
        leftSidebarWidth: CGFloat = 250,
        showRightSidebar: Bool = false,
        rightSidebarWidth: CGFloat = 350,
        @ViewBuilder toolbar: () -> Toolbar,
        @ViewBuilder leftSidebar: () -> LeftSidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder rightSidebar: () -> RightSidebar
    ) {
        self.toolbarHeight = toolbarHeight
        self.showLeftSidebar = showLeftSidebar
        self.leftSidebarWidth = leftSidebarWidth
        self.showRightSidebar = showRightSidebar
        self.rightSidebarWidth = rightSidebarWidth
        self.toolbar = toolbar()
        self.leftSidebar = leftSidebar()
        self.content = content()
        self.rightSidebar = rightSidebar()
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left sidebar
                CustomSidebarView(
                    position: .left,
                    width: leftSidebarWidth,
                    isVisible: showLeftSidebar
                ) {
                    leftSidebar
                }

                // Main content area with toolbar
                ZStack(alignment: .top) {
                    // Background
                    Color(nsColor: .windowBackgroundColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.all)

                    // Content with padding for toolbar
                    VStack(spacing: 0) {
                        content
                            .padding(.top, toolbarHeight)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Toolbar overlay at top
                    VStack(spacing: 0) {
                        toolbar
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Right sidebar
                CustomSidebarView(
                    position: .right,
                    width: rightSidebarWidth,
                    isVisible: showRightSidebar
                ) {
                    rightSidebar
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea(.all)
        }
        .ignoresSafeArea(.all)
    }
}
