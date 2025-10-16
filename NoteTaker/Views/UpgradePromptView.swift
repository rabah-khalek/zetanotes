//
//  UpgradePromptView.swift
//  NoteTaker
//
//  Beautiful upgrade prompt for Pro features
//

import SwiftUI

struct UpgradePromptView: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    @Binding var isPresented: Bool

    enum PromptType {
        case modelSwitching
        case promptEditing
        case general

        var title: String {
            switch self {
            case .modelSwitching: return "Unlock Premium AI Models"
            case .promptEditing: return "Customize AI Prompts"
            case .general: return "Upgrade to NoteTaker Pro"
            }
        }

        var description: String {
            switch self {
            case .modelSwitching:
                return "Get access to Phi-3, Qwen 2.5, Llama 3.2, and more premium models for better AI quality."
            case .promptEditing:
                return "Customize how the AI responds to your needs. Fine-tune prompts for perfect results."
            case .general:
                return "Unlock all premium AI models and advanced customization options."
            }
        }

        var icon: String {
            switch self {
            case .modelSwitching: return "cpu.fill"
            case .promptEditing: return "text.alignleft"
            case .general: return "star.fill"
            }
        }
    }

    let promptType: PromptType

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: promptType.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(promptType.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(promptType.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)

                Spacer()
            }
            .padding()

            Divider()

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                Text("Pro Features:")
                    .font(.headline)
                    .padding(.bottom, 4)

                FeatureRow(icon: "cpu.fill", text: "All Premium AI Models", subtitle: "Phi-3, Qwen 2.5, Llama 3.2 & more")
                FeatureRow(icon: "text.alignleft", text: "Custom Prompt Editing", subtitle: "Fine-tune AI responses")
                FeatureRow(icon: "sparkles", text: "Better AI Quality", subtitle: "Larger models = smarter results")
                FeatureRow(icon: "arrow.down.circle.fill", text: "Download Any Model", subtitle: "Switch between models anytime")
                FeatureRow(icon: "gift.fill", text: "Future Updates", subtitle: "All new AI features included")
            }
            .padding()

            Divider()

            // Pricing
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$29")
                        .font(.system(size: 36, weight: .bold))
                    Text("one-time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("No subscription, lifetime access")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Actions
            HStack(spacing: 12) {
                Button("Maybe Later") {
                    isPresented = false
                    AnalyticsManager.shared.trackEvent(.upgradePromptDismissed)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    // Open Gumroad purchase page
                    openGumroadPage()
                    AnalyticsManager.shared.trackEvent(.upgradeButtonClicked)
                }) {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Upgrade to Pro")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()

            // Already purchased link
            Button(action: {
                showLicenseActivation()
            }) {
                Text("Already purchased? Enter license key")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .padding(.bottom)
        }
        .frame(width: 500)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
    }

    private func openGumroadPage() {
        // TODO: Replace with your actual Gumroad product URL
        let gumroadURL = "https://notetaker.gumroad.com/l/notetaker-pro"
        if let url = URL(string: gumroadURL) {
            NSWorkspace.shared.open(url)
        }
    }

    private func showLicenseActivation() {
        isPresented = false
        // Post notification to show license activation
        NotificationCenter.default.post(name: .showLicenseActivation, object: nil)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

// MARK: - License Activation View

struct LicenseActivationView: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    @Binding var isPresented: Bool

    @State private var email: String = ""
    @State private var licenseKey: String = ""
    @State private var isValidating: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccess: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "key.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Activate Pro License")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter your license key from Gumroad")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)

                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if showSuccess {
                // Success state
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Pro Activated! 🎉")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("You now have access to all premium features")
                        .foregroundColor(.secondary)

                    Button("Get Started") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(40)
            } else {
                // Input form
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        TextField("your@email.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("License Key")
                            .font(.headline)
                        TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    #if DEBUG
                    Text("Debug: Use 'TEST-XXXX-XXXX-XXXX' with any email")
                        .font(.caption)
                        .foregroundColor(.orange)
                    #endif
                }
                .padding()

                Divider()

                // Actions
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(action: activateLicense) {
                        if isValidating {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal)
                        } else {
                            Text("Activate License")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || licenseKey.isEmpty || isValidating)
                }
                .padding()
            }
        }
        .frame(width: 450)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
    }

    private func activateLicense() {
        isValidating = true
        errorMessage = nil

        Task {
            let success = await licenseManager.validateLicense(key: licenseKey, email: email)

            await MainActor.run {
                isValidating = false

                if success {
                    showSuccess = true
                    // Auto-dismiss after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isPresented = false
                    }
                } else {
                    errorMessage = "Invalid license key. Please check your email and try again."
                }
            }
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let showLicenseActivation = Notification.Name("showLicenseActivation")
}

// MARK: - Preview

#if DEBUG
struct UpgradePromptView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UpgradePromptView(isPresented: .constant(true), promptType: .modelSwitching)
                .previewDisplayName("Model Switching")

            UpgradePromptView(isPresented: .constant(true), promptType: .promptEditing)
                .previewDisplayName("Prompt Editing")

            LicenseActivationView(isPresented: .constant(true))
                .previewDisplayName("License Activation")
        }
    }
}
#endif
