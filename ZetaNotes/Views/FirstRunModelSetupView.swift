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
        VStack(spacing: 0) {
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
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)

                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 70, height: 70)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
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
                .padding(.top, 12)

                // Welcome Text
                VStack(spacing: 2) {
                    Text("Welcome to ZetaNotes")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top, 8)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.primary, .primary.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Privacy-first note-taking with offline AI")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                        Text("All AI processing happens on your device")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary.opacity(0.9))
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 16)
                }

                // Setup Content
                VStack(spacing: 12) {
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
                    .frame(height: 12)
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
        VStack(spacing: 14) {
            // AI Capabilities Section with gradient card
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("AI-Powered Features")
                            .font(.system(size: 16, weight: .bold))
                        Text("Intelligent assistance at your fingertips")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Text("ZetaNotes includes powerful AI features that run entirely offline on your Mac:")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Features grid - 2 columns
                VStack(spacing: 7) {
                    HStack(spacing: 7) {
                        FeatureCardView(icon: "wand.and.stars", title: "Smart Autocomplete", color: .blue)
                        FeatureCardView(icon: "doc.text.magnifyingglass", title: "Summarization", color: .green)
                    }
                    HStack(spacing: 7) {
                        FeatureCardView(icon: "globe", title: "Translation", color: .orange)
                        FeatureCardView(icon: "checkmark.seal", title: "Grammar Check", color: .purple)
                    }
                    HStack(spacing: 7) {
                        FeatureCardView(icon: "magnifyingglass", title: "Semantic Search", color: .pink)
                        FeatureCardView(icon: "text.alignleft", title: "Reformulation", color: .indigo)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
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
            .shadow(color: Color.purple.opacity(0.1), radius: 8, x: 0, y: 3)

            // Model Download Section
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    Text("Download AI Model")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(
                    "To use these features, download a \(defaultModel.fileSize) AI model that runs locally on your device. Your data never leaves your Mac."
                )
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)

                // Model info card with enhanced design
                HStack(spacing: 12) {
                    // Model icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.15), .blue.opacity(0.08)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(defaultModel.displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 9))
                                Text(defaultModel.fileSize)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                            HStack(spacing: 3) {
                                Image(systemName: "memorychip.fill")
                                    .font(.system(size: 9))
                                Text(defaultModel.memoryUsage)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        }

                        Text(defaultModel.description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
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
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.blue.opacity(0.25), lineWidth: 1.5)
                        )
                )
                .shadow(color: Color.blue.opacity(0.08), radius: 4, x: 0, y: 2)

                // Action Buttons - match the width of the model card above
                HStack(spacing: 10) {
                    // Skip button
                    Button(action: {
                        viewState = .skipped
                        hasCompletedFirstRun = true
                    }) {
                        Text("Skip for Now")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    // Download button with gradient
                    Button(action: {
                        startDownload()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Download Model")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }

                Text("You can download this later from Settings > AI Model")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }

    // MARK: - Downloading View

    private var downloadingView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
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
                        .frame(width: 80, height: 80)

                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 6) {
                    Text("Downloading \(defaultModel.displayName)")
                        .font(.system(size: 18, weight: .semibold))

                    Text("This may take a few minutes depending on your internet connection")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }
            }

            // Progress section with enhanced styling
            VStack(spacing: 12) {
                ProgressView(value: downloadState.downloadProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 420)
                    .tint(.blue)

                HStack {
                    HStack(spacing: 5) {
                        Text("\(Int(downloadState.downloadProgress * 100))%")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)

                        Text("complete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(defaultModel.fileSize)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 420)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )

            // Cancel Button
            Button(action: {
                modelDownloader.cancelDownload()
                downloadState.cancelDownload()
                viewState = .initial
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Cancel Download")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.red.opacity(0.08))
                .cornerRadius(7)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 20) {
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
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("Setup Complete!")
                    .font(.system(size: 20, weight: .bold))

                Text("\(defaultModel.displayName) has been downloaded and is ready to use")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                completeSetup()
            }) {
                HStack(spacing: 8) {
                    Text("Get Started")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 200)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Skipped View

    private var skippedView: some View {
        VStack(spacing: 20) {
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
                    .frame(width: 90, height: 90)

                Image(systemName: "info.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 10) {
                Text("AI Features Disabled")
                    .font(.system(size: 20, weight: .bold))

                Text(
                    "You can use ZetaNotes for note-taking, but AI features will be unavailable until you download a model."
                )
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

                HStack(spacing: 5) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue.opacity(0.7))
                    Text("You can download the AI model anytime from Settings > AI Model")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.top, 3)
            }

            Button(action: {
                // Already set hasCompletedFirstRun in skip button
            }) {
                Text("Continue to App")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 3)
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
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
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
            .frame(width: AppTheme.Layout.defaultWindowWidth, height: AppTheme.Layout.defaultWindowHeight)
    }
}
