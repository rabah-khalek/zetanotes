//
//  CustomServiceEditorView.swift
//  NoteTaker
//
//  Editor for creating and editing custom AI services
//

import SwiftUI

struct CustomServiceEditorView: View {
    @State private var service: CustomService
    @Binding var isPresented: Bool
    let onSave: (CustomService) -> Void

    @StateObject private var customServiceManager = CustomServiceManager.shared
    @State private var shortcutError: String?
    @State private var nameError: String?

    init(service: CustomService, isPresented: Binding<Bool>, onSave: @escaping (CustomService) -> Void) {
        _service = State(initialValue: service)
        _isPresented = isPresented
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with icon
            HStack(spacing: 12) {
                // Icon indicator
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: service.name.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name.isEmpty ? "New Custom Service" : "Edit Custom Service")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(service.name.isEmpty ? "Create a custom AI service" : "Modify your service")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .help("Close (⎋)")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))

            Divider()

            // Form Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name Field with character count
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Service Name", systemImage: "tag")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text("\(service.name.count)/20")
                                .font(.caption)
                                .foregroundColor(service.name.count > 15 ? .orange : .secondary)
                        }

                        TextField("e.g., 'Make Concise', 'Add Emojis'", text: $service.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 14))
                            .onChange(of: service.name) { _ in
                                validateName()
                            }

                        if let error = nameError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        } else {
                            Text("A short, descriptive name for your service")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Color Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Color", systemImage: "paintpalette")
                            .font(.system(size: 14, weight: .semibold))

                        Text("Choose a color to help identify this service")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(ServiceColor.allCases, id: \.self) { colorOption in
                                Button(action: {
                                    service.color = colorOption
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(colorOption.color)
                                            .frame(width: 32, height: 32)

                                        if service.color == colorOption {
                                            Circle()
                                                .strokeBorder(Color.primary, lineWidth: 2)
                                                .frame(width: 36, height: 36)

                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .help(colorOption.displayName)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Keyboard Shortcut - Better visual hierarchy
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Keyboard Shortcut", systemImage: "command")
                            .font(.system(size: 14, weight: .semibold))

                        HStack(spacing: 8) {
                            // Command symbol in a badge
                            HStack(spacing: 4) {
                                Text("⌘")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("+")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)

                            TextField("Letter", text: $service.keyboardShortcut)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 60)
                                .onChange(of: service.keyboardShortcut) { newValue in
                                    let filtered = String(newValue.uppercased().prefix(1))
                                    service.keyboardShortcut = filtered
                                    validateShortcut()
                                }

                            Text("(single letter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let error = shortcutError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reserved shortcuts:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 4) {
                                    ForEach(["P", "R", "S", "T", "N"], id: \.self) { key in
                                        Text("⌘\(key)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    //Divider to separate sections
                    Divider()
                        .padding(.horizontal, 20)

                    // Prompt Field - Enhanced
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("AI Prompt", systemImage: "text.bubble")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Text("\(service.prompt.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("Instructions sent to the AI. Be specific about the desired output format and style.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ZStack(alignment: .topLeading) {
                            if service.prompt.isEmpty {
                                Text("Example: \"Rewrite this text to be more concise while keeping all key points. Use bullet points if appropriate.\"")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(12)
                            }

                            TextEditor(text: $service.prompt)
                                .font(.system(size: 13))
                                .frame(height: 160)
                                .padding(8)
                                .background(Color(nsColor: .textBackgroundColor))
                                .scrollContentBackground(.hidden)
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                        // Quick example buttons
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Quick examples:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            HStack(spacing: 6) {
                                ForEach([
                                    ("Make concise", "Rewrite this text to be more concise while keeping all key points. Use clear, direct language."),
                                    ("Add emojis", "Rewrite this text with relevant emojis to make it more engaging and fun. Keep the same meaning."),
                                    ("Email format", "Rewrite this as a professional email with proper greeting and closing.")
                                ], id: \.0) { example in
                                    Button(action: { service.prompt = example.1 }) {
                                        Text(example.0)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.08))
                                            .foregroundColor(.blue)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }

            Divider()

            // Footer - Better button styling
            HStack(spacing: 12) {
                Spacer()

                Button(action: {
                    if isValid {
                        var updatedService = service
                        updatedService.touch()
                        onSave(updatedService)
                        isPresented = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                        Text(service.name.isEmpty ? "Create Service" : "Save Changes")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 600, height: 700)
    }

    private var isValid: Bool {
        !service.name.isEmpty &&
        !service.keyboardShortcut.isEmpty &&
        !service.prompt.isEmpty &&
        shortcutError == nil &&
        nameError == nil
    }

    private func validateShortcut() {
        guard !service.keyboardShortcut.isEmpty else {
            shortcutError = nil
            return
        }

        if !customServiceManager.isShortcutAvailable(service.keyboardShortcut, excluding: service.id) {
            shortcutError = "This keyboard shortcut is already in use"
        } else {
            shortcutError = nil
        }
    }

    private func validateName() {
        guard !service.name.isEmpty else {
            nameError = nil
            return
        }

        if service.name.count > 20 {
            nameError = "Name must be 20 characters or less"
        } else {
            nameError = nil
        }
    }
}

// MARK: - Preview

struct CustomServiceEditorView_Previews: PreviewProvider {
    static var previews: some View {
        CustomServiceEditorView(
            service: CustomService(name: "Test", prompt: "Test prompt"),
            isPresented: .constant(true),
            onSave: { _ in }
        )
    }
}
