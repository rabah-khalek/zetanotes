//
//  UpgradePromptView.swift
//  ZetaNotes
//
//  Beautiful upgrade prompt for Pro features with StoreKit 2
//

import SwiftUI
import StoreKit

struct UpgradePromptView: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    @ObservedObject var storeKit = StoreKitManager.shared
    @Binding var isPresented: Bool
    @State private var selectedProductID: ProductID = .lifetime
    @State private var isPurchasing = false
    @State private var errorMessage: String?

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

                if storeKit.products.isEmpty {
                    ProgressView("Loading products...")
                        .padding()
                } else {
                    HStack(spacing: 12) {
                        // Monthly option
                        if let monthlyProduct = storeKit.product(for: .monthly) {
                            CompactPricingCard(
                                title: "Monthly",
                                price: monthlyProduct.displayPrice,
                                period: "/mo",
                                badge: nil,
                                isSelected: selectedProductID == .monthly,
                                action: { selectedProductID = .monthly }
                            )
                        }

                        // Annual option
                        if let annualProduct = storeKit.product(for: .annual) {
                            CompactPricingCard(
                                title: "Annual",
                                price: annualProduct.displayPrice,
                                period: "/yr",
                                badge: "Best Value",
                                isSelected: selectedProductID == .annual,
                                action: { selectedProductID = .annual }
                            )
                        }

                        // Lifetime option
                        if let lifetimeProduct = storeKit.product(for: .lifetime) {
                            CompactPricingCard(
                                title: "Lifetime",
                                price: lifetimeProduct.displayPrice,
                                period: "once",
                                badge: nil,
                                isSelected: selectedProductID == .lifetime,
                                action: { selectedProductID = .lifetime }
                            )
                        }
                    }

                    Text("All plans include full access to Pro features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider()

            // Legal Links (Apple Requirement)
            HStack(spacing: 4) {
                Text("By purchasing, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Link("Terms of Use", destination: URL(string: "https://www.zetanotes.com/terms.html")!)
                    .font(.caption)

                Text("and")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Link("Privacy Policy", destination: URL(string: "https://www.zetanotes.com/privacy.html")!)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Error message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await purchaseSelected()
                    }
                }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "cart.fill")
                            Text("Upgrade to Pro")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPurchasing || storeKit.products.isEmpty)

                Button(action: {
                    Task {
                        await restorePurchases()
                    }
                }) {
                    Text("Restore Purchases")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(isPurchasing)
            }
            .padding()
        }
        .frame(width: 600)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
        .task {
            // Load products when view appears
            await storeKit.loadProducts()
        }
    }

    private func purchaseSelected() async {
        errorMessage = nil
        isPurchasing = true

        do {
            try await licenseManager.purchase(selectedProductID)
            // Success - close the view
            isPresented = false
        } catch StoreError.productNotFound {
            errorMessage = "Product not available. Please try again."
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }

        isPurchasing = false
    }

    private func restorePurchases() async {
        errorMessage = nil
        isPurchasing = true

        do {
            try await licenseManager.restorePurchases()
            // Check if purchase was restored
            if licenseManager.isPro {
                isPresented = false
            } else {
                errorMessage = "No previous purchases found."
            }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }

        isPurchasing = false
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

// MARK: - Preview

#if DEBUG
struct UpgradePromptView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradePromptView(isPresented: .constant(true), promptType: .general)
    }
}
#endif
