# Integration Checklist for Monetization

## ✅ What's Been Created

1. **LicenseManager.swift** - Core license validation and feature gating
2. **UpgradePromptView.swift** - Beautiful upgrade UI with license activation
3. **MONETIZATION_STRATEGY.md** - Complete strategy document

## 📋 What Needs Integration

### 1. Add to Xcode Project

The files need to be added to your Xcode project:

```bash
# Files created:
- NoteTaker/Managers/LicenseManager.swift
- NoteTaker/Views/UpgradePromptView.swift
- MONETIZATION_STRATEGY.md (documentation only)
```

**Action:** Open Xcode → Right-click NoteTaker folder → Add Files → Select the new files

---

### 2. Update AIEngine.swift

Add license checks before model switching:

```swift
// In AIEngine.swift - switchModel function
func switchModel(to modelType: AIModel) async {
    // Add license check
    guard LicenseManager.shared.canUseModel(modelType) else {
        logWarning("🔒 Model \(modelType.rawValue) requires Pro license")
        await MainActor.run {
            NotificationCenter.default.post(
                name: .showUpgradePrompt,
                object: UpgradePromptView.PromptType.modelSwitching
            )
        }
        return
    }

    // Continue with existing code...
    await loadModel(modelType)
}
```

---

### 3. Update AISettingsView.swift

Show Pro badge and lock icons for open-source models:

```swift
// In model picker section
ForEach(AIModel.allCases, id: \.self) { model in
    Button(action: {
        if LicenseManager.shared.canUseModel(model) {
            Task {
                await aiEngine.switchModel(to: model)
            }
        } else {
            showUpgradePrompt = true
            upgradePromptType = .modelSwitching
        }
    }) {
        HStack {
            VStack(alignment: .leading) {
                Text(model.displayName)
                    .font(.body)
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !LicenseManager.shared.canUseModel(model) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
            } else if aiEngine.selectedModel == model {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// Add Pro status display
if LicenseManager.shared.isPro {
    HStack {
        Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
        Text("Pro Active")
            .fontWeight(.semibold)
        Spacer()
    }
    .padding()
    .background(Color.green.opacity(0.1))
    .cornerRadius(8)
} else {
    Button("Upgrade to Pro") {
        showUpgradePrompt = true
        upgradePromptType = .general
    }
    .buttonStyle(.borderedProminent)
}
```

---

### 4. Add Prompt Editing Lock

In any view that allows prompt customization:

```swift
// Before showing prompt editor
if LicenseManager.shared.canEditPrompts {
    // Show prompt editor
    showingPromptEditor = true
} else {
    // Show upgrade prompt
    showUpgradePrompt = true
    upgradePromptType = .promptEditing
}
```

---

### 5. Update ContentView.swift

Add upgrade prompt handling:

```swift
// In ContentView
@State private var showUpgradePrompt = false
@State private var showLicenseActivation = false
@State private var upgradePromptType: UpgradePromptView.PromptType = .general

// In body
.sheet(isPresented: $showUpgradePrompt) {
    UpgradePromptView(
        isPresented: $showUpgradePrompt,
        promptType: upgradePromptType
    )
}
.sheet(isPresented: $showLicenseActivation) {
    LicenseActivationView(isPresented: $showLicenseActivation)
}
.onReceive(NotificationCenter.default.publisher(for: .showUpgradePrompt)) { notification in
    if let type = notification.object as? UpgradePromptView.PromptType {
        upgradePromptType = type
    }
    showUpgradePrompt = true
}
.onReceive(NotificationCenter.default.publisher(for: .showLicenseActivation)) { _ in
    showLicenseActivation = true
}
```

---

### 6. Add Notification Name

In NoteTakerApp.swift or a shared file:

```swift
extension Notification.Name {
    static let showUpgradePrompt = Notification.Name("showUpgradePrompt")
    // .showLicenseActivation is already defined in UpgradePromptView.swift
}
```

---

### 7. Update App Launch

In NoteTakerApp.swift, initialize LicenseManager:

```swift
init() {
    // Existing initialization...

    // Initialize license manager (loads from keychain)
    _ = LicenseManager.shared

    logInfo("App launched - Pro: \(LicenseManager.shared.isPro)")
}
```

---

### 8. Set Up Gumroad

Before you can test license validation:

1. **Create Gumroad account:** <https://gumroad.com/start>
2. **Create product:**
   - Name: "NoteTaker Pro"
   - Price: $29
   - Type: Digital Product
   - Enable "Generate unique license keys"
3. **Get product permalink:**
   - Settings → Permalink (e.g., "notetaker-pro")
   - Update in `LicenseManager.swift` line 71:

     ```swift
     let productPermalink = "notetaker-pro" // YOUR ACTUAL PERMALINK
     ```

4. **Get Gumroad URL:**
   - Your product URL will be: `https://YOUR-GUMROAD-USERNAME.gumroad.com/l/notetaker-pro`
   - Update in `UpgradePromptView.swift` line 150:

     ```swift
     let gumroadURL = "https://YOUR-USERNAME.gumroad.com/l/notetaker-pro"
     ```

---

### 9. Testing

**Test in DEBUG mode:**

```swift
// Test license activation with test key
Email: test@example.com
Key: TEST-XXXX-XXXX-XXXX

// This bypasses Gumroad validation in DEBUG mode
```

**Test free tier:**

1. Remove any existing license: `LicenseManager.shared.removeLicense()`
2. Try to switch to Phi-3 → Should show upgrade prompt
3. Try to edit prompts → Should show upgrade prompt

**Test Pro tier:**

1. Activate test license
2. Should see all models unlocked
3. Should be able to edit prompts
4. System monitor should show "Pro Active"

---

### 10. Build and Test

```bash
cd /Users/projects/Documents/notetaker

# Clean build
xcodebuild -project NoteTaker.xcodeproj \
  -scheme NoteTaker \
  clean build

# Run app
open ~/Library/Developer/Xcode/DerivedData/NoteTaker-*/Build/Products/Debug/NoteTaker.app
```

---

## 🎯 Quick Integration Steps

1. **Add files to Xcode** (2 min)
2. **Update AIEngine.swift** - Add model switch check (5 min)
3. **Update AISettingsView.swift** - Add Pro UI (10 min)
4. **Update ContentView.swift** - Add sheets (5 min)
5. **Test with test license** (5 min)
6. **Set up Gumroad** (10 min)
7. **Test real license** (5 min)

**Total time: ~45 minutes**

---

## 🚀 After Integration

### Before Public Release

1. **Remove DEBUG test license** in production builds
2. **Update bundle ID** from `com.example.NoteTaker` to your real ID
3. **Create app icon** (see next section)
4. **Test license validation thoroughly**
5. **Create Gumroad product page**
6. **Write product description**
7. **Take screenshots**

### Marketing

1. **Create landing page** or GitHub README
2. **Post on Reddit** (r/macapps, r/productivity)
3. **Tweet** about launch
4. **Product Hunt** submission
5. **Hacker News** Show HN post

---

## 📝 Next Steps

Want me to:

1. ✅ **Show you how to add the files to Xcode?**
2. ✅ **Generate the exact code changes for AIEngine.swift?**
3. ✅ **Create the AISettingsView Pro UI?**
4. ✅ **Help set up your Gumroad product?**
5. ✅ **Create an app icon?**

Let me know what you'd like to tackle first!
