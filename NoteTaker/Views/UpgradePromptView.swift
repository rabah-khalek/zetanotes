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
        case chat
        case general

        var title: String {
            switch self {
            case .modelSwitching: return "Unlock Premium AI Models"
            case .promptEditing: return "Customize AI Prompts"
            case .chat: return "Unlock AI Chat"
            case .general: return "Upgrade to NoteTaker Pro"
            }
        }

        var description: String {
            switch self {
            case .modelSwitching:
                return "Access to 8 open-source AI models including Phi-3, Qwen 2.5, Llama 3.2, and Gemma 2."
            case .promptEditing:
                return "Build custom tools tailored to your workflow."
            case .chat:
                return "Have natural conversations with AI using the selected model with customizable parameters."
            case .general:
                return "Access 8 open-source AI models, build custom tools, and chat with AI."
            }
        }

        var icon: String {
            switch self {
            case .modelSwitching: return "cpu.fill"
            case .promptEditing: return "text.alignleft"
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .general: return "bolt.fill"
            }
        }
    }

    let promptType: PromptType

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
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

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                Text("Pro Features:")
                    .font(.headline)
                    .padding(.bottom, 4)

                FeatureRow(
                    icon: "cpu.fill",
                    text: "8 Open-Source AI Models",
                    subtitle: "Phi-3, Qwen 2.5, Llama 3.2, Gemma 2 & more"
                )
                FeatureRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    text: "AI Chat Assistant",
                    subtitle: "Natural conversations with customizable parameters"
                )
                FeatureRow(
                    icon: "wrench.and.screwdriver.fill",
                    text: "Create Custom Tools",
                    subtitle: "Build AI tools tailored to your workflow"
                )
                FeatureRow(
                    icon: "slider.horizontal.3",
                    text: "Customize Existing Tools",
                    subtitle: "Fine-tune built-in tools to match your style"
                )
                FeatureRow(icon: "gift.fill", text: "New Models & Features", subtitle: "Updates added regularly")
            }
            .padding()

            Divider()

            // Pricing
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$10")
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
            VStack(spacing: 12) {
                Button(action: {
                    // Open LemonSqueezy purchase page
                    openLemonSqueezyPage()
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

    private func openLemonSqueezyPage() {
        // DEV_TODO: Replace with your actual LemonSqueezy checkout URL
        // Get this from your LemonSqueezy dashboard after creating the product
        let checkoutURL = "https://offnotes.lemonsqueezy.com/checkout/buy/DEV_VARIANT_ID"
        if let url = URL(string: checkoutURL) {
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

                    Text("Enter your license key from your purchase email")
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
                    Text("Debug: Use email 'admin' and key 'test'")
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
        // Validate inputs first
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            errorMessage = "Please enter your email address."
            return
        }

        if trimmedKey.isEmpty {
            errorMessage = "Please enter your license key."
            return
        }

        // Email validation - allow test credentials in DEBUG mode
        #if DEBUG
        let isTestCredential = trimmedEmail.lowercased() == "admin" && trimmedKey.lowercased() == "test"
        if !trimmedEmail.contains("@"), !isTestCredential {
            errorMessage = "Please enter a valid email address."
            return
        }
        #else
        if !trimmedEmail.contains("@") {
            errorMessage = "Please enter a valid email address."
            return
        }
        #endif

        isValidating = true
        errorMessage = nil

        Task {
            do {
                let success = await licenseManager.validateLicense(key: trimmedKey, email: trimmedEmail)

                await MainActor.run {
                    isValidating = false

                    if success {
                        showSuccess = true
                        // Auto-dismiss after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isPresented = false
                        }
                    } else {
                        errorMessage = "Invalid license key or email. Please double-check your purchase email and license key, then try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    errorMessage = "An error occurred while validating your license. Please try again. Error: \(error.localizedDescription)"
                    print("❌ License validation error: \(error)")
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
