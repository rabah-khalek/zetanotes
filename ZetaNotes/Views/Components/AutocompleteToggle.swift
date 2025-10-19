//
//  AutocompleteToggle.swift
//  ZetaNotes
//
//  Autocomplete toggle switch component with keyboard shortcut
//

import SwiftUI

struct AutocompleteToggle: View {
    @Binding var isEnabled: Bool
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEnabled.toggle()
            }
        }) {
            HStack(spacing: 3) {
                // Square with ⌘Q
                HStack(spacing: 1) {
                    Text("⌘")
                        .font(.system(size: 8, weight: .medium))
                    Text("Q")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isEnabled ? Color.purple.opacity(0.85) : Color.secondary.opacity(0.6))
                )

                // "Auto" label
                Text("Auto")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isEnabled ? .purple : .secondary.opacity(0.8))

                // Compact toggle switch
                ZStack {
                    // Background pill
                    Capsule()
                        .fill(isEnabled ? Color.purple.opacity(0.3) : Color.secondary.opacity(0.15))
                        .frame(width: 22, height: 12)

                    // Moving circle indicator
                    Circle()
                        .fill(isEnabled ? Color.purple : Color.secondary.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(x: isEnabled ? 5 : -5)
                }
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
