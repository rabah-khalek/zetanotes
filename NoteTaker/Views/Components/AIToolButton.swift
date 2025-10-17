//
//  AIToolButton.swift
//  NoteTaker
//
//  AI Tool button component with keyboard shortcut display
//

import SwiftUI

struct AIToolButton: View {
    let icon: String
    let label: String
    let shortcut: String
    let color: Color
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

                // Square with ⌘ + first letter
                HStack(spacing: 1) {
                    Text("⌘")
                        .font(.system(size: 8, weight: .medium))
                    Text(String(label.prefix(1)))
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 3)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(foregroundColor.opacity(0.4), lineWidth: 0.5)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(foregroundColor.opacity(isHovered && isEnabled ? 0.08 : 0.03))
                        )
                )

                // Rest of label
                if label.count > 1 {
                    Text(String(label.dropFirst()))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(foregroundColor)
                }
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
            return color.opacity(0.85)
        }
        if isHovered {
            return color
        }
        return color.opacity(0.8)
    }
}
