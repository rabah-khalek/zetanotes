//
//  UpgradePromptView.swift
//  ZetaNotes
//
//  Beautiful upgrade prompt for Pro features
//

import SwiftUI

struct UpgradePromptView: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    @Binding var isPresented: Bool
    @State private var selectedTier: String = "lifetime" // "monthly", "annual", "lifetime"

    enum PromptType {
        case modelSwitching
        case promptEditing
        case chat
        case general

        var title: String {
            switch self {
            case .modelSwitching: return "Unlock Open-Source AI Models"
            case .promptEditing: return "Customize AI Prompts"
            case .chat: return "Unlock AI Chat"
            case .general: return "Upgrade to ZetaNotes Pro"
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

            // Pricing Options
            VStack(spacing: 12) {
                Text("Choose Your Plan")
                    .font(.headline)

                HStack(spacing: 12) {
                    // Monthly option
                    CompactPricingCard(
                        title: "Monthly",
                        price: "$1",
                        period: "/mo",
                        badge: nil,
                        isSelected: selectedTier == "monthly",
                        action: { selectedTier = "monthly" }
                    )

                    // Annual option
                    CompactPricingCard(
                        title: "Annual",
                        price: "$6",
                        period: "/yr",
                        badge: nil,
                        isSelected: selectedTier == "annual",
                        action: { selectedTier = "annual" }
                    )

                    // Lifetime option
                    CompactPricingCard(
                        title: "Lifetime",
                        price: "$20",
                        period: "once",
                        badge: nil,
                        isSelected: selectedTier == "lifetime",
                        action: { selectedTier = "lifetime" }
                    )
                }

                Text("All plans include full access to Pro features")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    // Open Paddle purchase page
                    openPaddlePage()
                    // Note: Analytics tracking removed to avoid import issues
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
        .frame(width: 600)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
    }

    private func openPaddlePage() {
        // DEV_TODO: Replace with your actual Paddle checkout URLs for each tier
        // Get these from your Paddle dashboard after creating the products
        let checkoutURL: String

        switch selectedTier {
        case "monthly":
            checkoutURL = "https://buy.paddle.com/product/DEV_MONTHLY_PRICE_ID"
        case "annual":
            checkoutURL = "https://buy.paddle.com/product/DEV_ANNUAL_PRICE_ID"
        case "lifetime":
            checkoutURL = "https://buy.paddle.com/product/DEV_LIFETIME_PRICE_ID"
        default:
            checkoutURL = "https://buy.paddle.com/product/DEV_LIFETIME_PRICE_ID"
        }

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

// MARK: - Compact Pricing Card

struct CompactPricingCard: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Badge at top if exists
                if let badge = badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green)
                        .cornerRadius(4)
                } else {
                    // Spacer to keep alignment
                    Text(" ")
                        .font(.caption2)
                        .opacity(0)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)

                VStack(spacing: 2) {
                    Text(price)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(period)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .secondary)
                    .font(.title3)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pricing Option Row

struct PricingOptionRow: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(isSelected ? .white : .primary)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(3)
                        }
                    }
                    Text(period)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                Text(price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .secondary)
                    .font(.title3)
            }
            .padding()
            .background(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row

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

                    Text("You now have access to all open-source features")
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
