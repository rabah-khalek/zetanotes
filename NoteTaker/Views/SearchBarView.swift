//
//  SearchBarView.swift
//  NoteTaker
//
//  Search bar with semantic and keyword search
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchQuery: String
    @Binding var isSearching: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search notes...", text: $searchQuery)
                .textFieldStyle(.plain)

            if !searchQuery.isEmpty {
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else {
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SearchBarView(searchQuery: .constant(""), isSearching: .constant(false))
            SearchBarView(searchQuery: .constant("test query"), isSearching: .constant(false))
            SearchBarView(searchQuery: .constant("searching..."), isSearching: .constant(true))
        }
        .padding()
    }
}
