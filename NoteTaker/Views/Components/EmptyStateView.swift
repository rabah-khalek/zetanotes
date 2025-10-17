//
//  EmptyStateView.swift
//  NoteTaker
//
//  Empty state view when no note is selected
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "note.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Note Selected")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            Text("Select a note or create a new one")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.8))

            Button(action: {
                NotificationCenter.default.post(name: .createNewNote, object: nil)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                    Text("New Note")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
