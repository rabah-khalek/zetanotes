//
//  CenteredScrolling.swift
//  ZetaNotes
//
//  A view modifier to conditionally center content within a ScrollView.
//  If the content is narrower than the scroll view, it's centered.
//  If it's wider, it aligns to the leading edge for normal scrolling.
//

import SwiftUI

struct CenteredScrollingModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(minWidth: geometry.size.width)
        }
    }
}

extension View {
    func centeredScrolling() -> some View {
        modifier(CenteredScrollingModifier())
    }
}
