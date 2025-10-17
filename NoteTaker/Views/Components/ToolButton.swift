//
//  ToolButton.swift
//  NoteTaker
//
//  Custom tool button component
//

import SwiftUI

struct ToolButton: View {
    let tool: AITool
    let isLoading: Bool
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                // Loading spinner if active
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 10, height: 10)
                        .padding(.trailing, 2)
                }

                // Square with ⌘ + keyboard shortcut letter
                HStack(spacing: 1) {
                    Text("⌘")
                        .font(.system(size: 8, weight: .medium))
                    Text(tool.keyboardShortcut)
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(foregroundColor.opacity(0.4), lineWidth: 0.5)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(foregroundColor.opacity(isHovered && isEnabled ? 0.08 : 0.03))
                        )
                )

                // Full tool name
                Text(tool.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(foregroundColor)
            }
            .scaleEffect(isHovered && isEnabled ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return .secondary.opacity(0.3)
        }
        if isLoading {
            return tool.color.color.opacity(0.85)
        }
        if isHovered {
            return tool.color.color
        }
        return tool.color.color.opacity(0.8)
    }
}
