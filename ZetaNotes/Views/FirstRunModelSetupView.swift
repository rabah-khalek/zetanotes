//
//  FirstRunModelSetupView.swift
//  ZetaNotes
//
//  First-run experience for downloading the default AI model
//

import SwiftUI

struct FirstRunModelSetupView: View {
    @ObservedObject private var modelDownloader = ModelDownloader.shared
    @ObservedObject private var downloadState = ModelDownloadState.shared
    @EnvironmentObject var aiEngine: AIEngine
    @AppStorage("hasCompletedFirstRun") private var hasCompletedFirstRun = false

    @State private var viewState: ViewState = .initial
    @State private var errorMessage: String?

    // Fixed default model - only offer Llama 3.2 1B
    private let defaultModel: AIModel = .llamaThreeTwoOneB

    enum ViewState {
        case initial
        case downloading
        case completed
        case error
        case skipped // User chose to skip download
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)

                // App Icon with gradient background
                ZStack {
                    // Gradient circle background
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)

                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 120, height: 120)
                        .cornerRadius(26)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }

                // Welcome Text
                VStack(spacing: 8) {
                    Text("Welcome to ZetaNotes")
                        .font(.system(size: 36, weight: .bold))
                        .padding(.top, 36)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.primary, .primary.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Privacy-first note-taking with offline AI")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("All AI processing happens on your device")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.9))
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }

                // Decorative divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .secondary.opacity(0.3), .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)

                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.purple.opacity(0.6))

                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .secondary.opacity(0.3), .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 120)

                // Setup Content
                VStack(spacing: 24) {
                    switch viewState {
                    case .initial:
                        initialView
                    case .downloading:
                        downloadingView
                    case .completed:
                        completedView
                    case .error:
                        errorView
                    case .skipped:
                        skippedView
                    }
                }
                .frame(width: 600)

                Spacer()
                    .frame(height: 60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)

                // Subtle gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.02),
                        Color.clear,
                        Color.blue.opacity(0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }

    // MARK: - Initial View

    private var initialView: some View {
        VStack(spacing: 28) {
            // AI Capabilities Section with gradient card
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI-Powered Features")
                            .font(.system(size: 18, weight: .bold))
                        Text("Intelligent assistance at your fingertips")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Text("ZetaNotes includes powerful AI features that run entirely offline on your Mac:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Features grid - 2 columns
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        FeatureCardView(icon: "wand.and.stars", title: "Smart Autocomplete", color: .blue)
                        FeatureCardView(icon: "doc.text.magnifyingglass", title: "Summarization", color: .green)
                    }
                    HStack(spacing: 10) {
                        FeatureCardView(icon: "globe", title: "Translation", color: .orange)
                        FeatureCardView(icon: "checkmark.seal", title: "Grammar Check", color: .purple)
                    }
                    HStack(spacing: 10) {
                        FeatureCardView(icon: "magnifyingglass", title: "Semantic Search", color: .pink)
                        FeatureCardView(icon: "text.alignleft", title: "Reformulation", color: .indigo)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .purple.opacity(0.3),
                                        .blue.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color.purple.opacity(0.1), radius: 10, x: 0, y: 4)

            // Model Download Section
            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Download AI Model")
                        .font(.system(size: 17, weight: .semibold))
                }

                Text(
                    "To use these features, download a \(defaultModel.fileSize) AI model that runs locally on your device. Your data never leaves your Mac."
                )
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)

                // Model info card with enhanced design
                HStack(spacing: 16) {
                    // Model icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.15), .blue.opacity(0.08)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 26))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(defaultModel.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)

                        HStack(spacing: 14) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 10))
                                Text(defaultModel.fileSize)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Image(systemName: "memorychip.fill")
                                    .font(.system(size: 10))
                                Text(defaultModel.memoryUsage)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        }

                        Text(defaultModel.description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.06),
                                    Color.blue.opacity(0.03)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.blue.opacity(0.25), lineWidth: 1.5)
                        )
                )
                .shadow(color: Color.blue.opacity(0.08), radius: 6, x: 0, y: 2)

                // Action Buttons
                HStack(spacing: 12) {
                    // Skip button
                    Button(action: {
                        viewState = .skipped
                        hasCompletedFirstRun = true
                    }) {
                        Text("Skip for Now")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    // Download button with gradient
                    Button(action: {
                        startDownload()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Download Model")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Text("You can download this later from Settings > AI Model")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }

    // MARK: - Downloading View

    private var downloadingView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                // Animated download icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.15), .blue.opacity(0.05)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 8) {
                    Text("Downloading \(defaultModel.displayName)")
                        .font(.system(size: 22, weight: .semibold))

                    Text("This may take a few minutes depending on your internet connection")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }
            }

            // Progress section with enhanced styling
            VStack(spacing: 14) {
                ProgressView(value: downloadState.downloadProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 420)
                    .tint(.blue)

                HStack {
                    HStack(spacing: 6) {
                        Text("\(Int(downloadState.downloadProgress * 100))%")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)

                        Text("complete")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(defaultModel.fileSize)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 420)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )

            // Cancel Button
            Button(action: {
                modelDownloader.cancelDownload()
                downloadState.cancelDownload()
                viewState = .initial
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                    Text("Cancel Download")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 28) {
            // Success icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green.opacity(0.15), .green.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.green)
            }

            VStack(spacing: 10) {
                Text("Setup Complete!")
                    .font(.system(size: 24, weight: .bold))

                Text("\(defaultModel.displayName) has been downloaded and is ready to use")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                completeSetup()
            }) {
                HStack(spacing: 10) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 220)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Skipped View

    private var skippedView: some View {
        VStack(spacing: 28) {
            // Info icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.15), .blue.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "info.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 12) {
                Text("AI Features Disabled")
                    .font(.system(size: 24, weight: .bold))

                Text(
                    "You can use ZetaNotes for note-taking, but AI features will be unavailable until you download a model."
                )
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.blue.opacity(0.7))
                    Text("You can download the AI model anytime from Settings > AI Model")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.top, 4)
            }

            Button(action: {
                // Already set hasCompletedFirstRun in skip button
            }) {
                Text("Continue to App")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 220)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("Download Failed")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let error = errorMessage {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    viewState = .initial
                    errorMessage = nil
                }) {
                    Text("Choose Different Model")
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    startDownload()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry Download")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func startDownload() {
        viewState = .downloading
        errorMessage = nil
        downloadState.startDownload(modelName: defaultModel.displayName)

        modelDownloader.downloadModel(defaultModel) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    downloadState.completeDownload()
                    // Load the model into AIEngine
                    Task {
                        await aiEngine.loadModel(defaultModel)
                        await MainActor.run {
                            viewState = .completed
                        }
                    }

                case let .failure(error):
                    downloadState.failDownload(error: error.localizedDescription)
                    viewState = .error
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func completeSetup() {
        hasCompletedFirstRun = true
    }
}

// MARK: - Feature Card View

struct FeatureCardView: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Simple Feature Row (without subtitle)

struct SimpleFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

struct FirstRunModelSetupView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunModelSetupView()
            .environmentObject(AIEngine.shared)
            .frame(width: 800, height: 600)
    }
}
