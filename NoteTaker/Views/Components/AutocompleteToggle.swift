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
        HStack(spacing: 5) {
            Text("Autocomplete")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isEnabled ? .purple : .secondary)

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(.purple)
                .scaleEffect(0.7)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
