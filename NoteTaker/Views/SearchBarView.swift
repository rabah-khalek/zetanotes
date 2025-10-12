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
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.7))

            TextField("Search", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))

            if !searchQuery.isEmpty {
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                } else {
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
        .cornerRadius(6)
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
