//
//  AutocompleteToggle.swift
//  NoteTaker
//
//  Autocomplete toggle switch component
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
            HStack(spacing: 4) {
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
            .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
