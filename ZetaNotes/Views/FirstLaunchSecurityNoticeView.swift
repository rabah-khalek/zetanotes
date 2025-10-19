//
//  FirstLaunchSecurityNoticeView.swift
//  ZetaNotes
//
//  Shows a one-time notice about how to bypass macOS security warnings
//  for unsigned apps. Only shown if user somehow managed to open the app
//  without right-clicking (e.g., via terminal).
//

import SwiftUI

struct FirstLaunchSecurityNoticeView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasSeenSecurityNotice") private var hasSeenSecurityNotice = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Security Notice")
                .font(.title)
                .bold()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("ZetaNotes is not signed with an Apple Developer certificate.")
                    .foregroundColor(.secondary)
                
                Text("If you see a security warning:")
                    .bold()
                
                HStack(alignment: .top, spacing: 12) {
                    Text("1.")
                        .bold()
                    Text("Right-click (⌃-click) on ZetaNotes in Applications")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Text("2.")
                        .bold()
                    Text("Select \"Open\" from the context menu")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Text("3.")
                        .bold()
                    Text("Click \"Open\" in the security dialog")
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("This is only required the first time you launch the app.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Your data is 100% private and stays on your Mac.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Button(action: {
                hasSeenSecurityNotice = true
                isPresented = false
            }) {
                Text("Got It")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
        .frame(width: 500)
    }
}

// Extension to show this conditionally
extension View {
    func showSecurityNoticeIfNeeded() -> some View {
        self.modifier(SecurityNoticeModifier())
    }
}

struct SecurityNoticeModifier: ViewModifier {
    @AppStorage("hasSeenSecurityNotice") private var hasSeenSecurityNotice = false
    @State private var showNotice = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Only show if this is truly the first launch
                // (If they got here, they probably bypassed it correctly, but just in case)
                if !hasSeenSecurityNotice {
                    // Wait a moment before showing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showNotice = true
                    }
                }
            }
            .sheet(isPresented: $showNotice) {
                FirstLaunchSecurityNoticeView(isPresented: $showNotice)
            }
    }
}

#Preview {
    FirstLaunchSecurityNoticeView(isPresented: .constant(true))
}
