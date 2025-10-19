# ZetaNotes Auto-Update Mock Walkthrough

This document walks you through a complete mock update scenario from version **1.0** → **1.1** to test the Sparkle auto-update system.

---

## 📋 Current State

**App Configuration:**
- Current Version: `1.0` (in Info.plist)
- Sparkle: Configured but commented out in code
- Appcast URL: `https://YOUR_USERNAME.github.io/zetanotes/appcast.xml`
- EdDSA Public Key: `FDRYSVr/ynz9brNn3H9FX/GukNtKgnQbuXD90zWps7Y=`

**Update Mechanism:**
- Framework: Sparkle 2.x (in `Frameworks/Sparkle.xcframework/`)
- Check Interval: Every 24 hours (86400 seconds)
- Automatic Checks: Enabled

---

## 🎬 Mock Update Scenario: Version 1.0 → 1.1

### Scenario: Switching from TinyLlama to Llama 3.2 1B

Let's simulate releasing version 1.1 with Llama 3.2 1B as the new default model.

---

## Step 1: Prepare Version 1.1 Release

### 1.1 Update Version Number

**In Xcode:**
1. Open `ZetaNotes.xcodeproj`
2. Select **ZetaNotes** target → **General** tab
3. Update:
   - **Version**: `1.0` → `1.1`
   - **Build**: `1` → `2`

**In Info.plist** (automatically updated by Xcode):
```xml
<key>CFBundleShortVersionString</key>
<string>1.1</string>
<key>CFBundleVersion</key>
<string>2</string>
```

### 1.2 Build the Release

```bash
# Option 1: Use the automated script
./scripts/release_unsigned.sh 1.1

# This will:
# ✓ Build ZetaNotes v1.1
# ✓ Download Llama 3.2 1B model (~700MB)
# ✓ Create DMG: ZetaNotes-v1.1.dmg
# ✓ Sign with Sparkle EdDSA
# ✓ Update appcast.xml
```

**What gets generated:**
- `~/Desktop/ZetaNotes-Release/ZetaNotes-v1.1.dmg` (~750MB)
- EdDSA signature for the DMG
- SHA256 checksum
- Updated `docs/appcast.xml`

---

## Step 2: Understanding the Appcast Update

### 2.1 Current Appcast (Version 1.0)

**File:** `docs/appcast.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>ZetaNotes Updates</title>
        <link>https://YOUR_USERNAME.github.io/zetanotes/appcast.xml</link>
        <description>Most recent updates for ZetaNotes</description>
        <language>en</language>

        <!-- Version 1.0 - Current -->
        <item>
            <title>Version 1.0</title>
            <sparkle:version>1.0</sparkle:version>
            <pubDate>Mon, 19 Oct 2025 00:00:00 +0000</pubDate>
            <enclosure
                url="https://github.com/YOUR_USERNAME/zetanotes/releases/download/v1.0/ZetaNotes-v1.0.dmg"
                sparkle:version="1.0"
                length="750000000"
                sparkle:edSignature="OLD_SIGNATURE" />
        </item>
    </channel>
</rss>
```

### 2.2 Updated Appcast (After Release Script)

The `release_unsigned.sh` script automatically adds version 1.1:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>ZetaNotes Updates</title>
        <link>https://YOUR_USERNAME.github.io/zetanotes/appcast.xml</link>
        <description>Most recent updates for ZetaNotes</description>
        <language>en</language>

        <!-- ⭐ Version 1.1 - NEW! -->
        <item>
            <title>Version 1.1</title>
            <link>https://github.com/YOUR_USERNAME/zetanotes</link>
            <sparkle:version>1.1</sparkle:version>
            <sparkle:shortVersionString>1.1</sparkle:shortVersionString>
            <description><![CDATA[
                <h2>ZetaNotes 1.1</h2>
                <p>What's new:</p>
                <ul>
                    <li>🚀 Upgraded default model to Llama 3.2 1B</li>
                    <li>⚡ Better performance (1.2GB RAM vs 1.5GB)</li>
                    <li>✨ Improved instruction-following quality</li>
                    <li>🎯 Same speed, better results!</li>
                </ul>
                <p><strong>Note:</strong> Existing users will keep their current model.
                To try Llama 3.2 1B, go to Settings → AI Models → Download.</p>
            ]]></description>
            <pubDate>Wed, 20 Oct 2025 12:00:00 +0000</pubDate>
            <enclosure
                url="https://github.com/YOUR_USERNAME/zetanotes/releases/download/v1.1/ZetaNotes-v1.1.dmg"
                sparkle:version="1.1"
                sparkle:shortVersionString="1.1"
                length="750000000"
                type="application/octet-stream"
                sparkle:edSignature="MCwCFGFb..." />
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        </item>

        <!-- Version 1.0 - Previous -->
        <item>
            <title>Version 1.0</title>
            <sparkle:version>1.0</sparkle:version>
            <!-- ... -->
        </item>
    </channel>
</rss>
```

**Key Changes:**
- New `<item>` entry for version 1.1
- Higher version number (`1.1` > `1.0`)
- New download URL
- New EdDSA signature
- Release notes describing the Llama 3.2 1B upgrade

---

## Step 3: How Updates Work in the App

### 3.1 Current State (Sparkle Commented Out)

**File:** `ZetaNotes/ZetaNotesApp.swift`

```swift
// TODO: Uncomment when Sparkle package is added
// import Sparkle

@main
struct ZetaNotesApp: App {
    // TODO: Uncomment when Sparkle package is added
    // private let updaterController: SPUStandardUpdaterController

    init() {
        // TODO: Uncomment when Sparkle package is added
        // updaterController = SPUStandardUpdaterController(
        //     startingUpdater: true,
        //     updaterDelegate: nil,
        //     userDriverDelegate: nil
        // )
    }
}
```

### 3.2 After Enabling Sparkle

**Uncommented version:**

```swift
import SwiftUI
import Sparkle  // ✅ Enabled

@main
struct ZetaNotesApp: App {
    // Sparkle updater controller - handles automatic updates
    private let updaterController: SPUStandardUpdaterController  // ✅ Enabled

    init() {
        // Initialize Sparkle updater controller
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,      // ✅ Start checking immediately
            updaterDelegate: nil,        // Use default behavior
            userDriverDelegate: nil      // Use default UI
        )
        // ... rest of init
    }

    var body: some Scene {
        WindowGroup {
            // ... app content
        }
        .commands {
            // Add Sparkle's Check for Updates menu item
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)  // ✅ Enabled
            }
        }
    }
}
```

---

## Step 4: The Update Flow (User Experience)

### 4.1 Automatic Check (Every 24 Hours)

**Timeline:**
```
Day 1, 9:00 AM  → User installs ZetaNotes v1.0
Day 2, 9:00 AM  → Sparkle checks for updates automatically
                   (24 hours later, per SUScheduledCheckInterval)
```

**What Happens:**
1. **Sparkle makes HTTP request:**
   ```
   GET https://YOUR_USERNAME.github.io/zetanotes/appcast.xml
   ```

2. **Sparkle parses appcast.xml:**
   - Current version: `1.0`
   - Latest version: `1.1`
   - Comparison: `1.1 > 1.0` ✅ Update available!

3. **Sparkle verifies EdDSA signature:**
   - Public key (from Info.plist): `FDRYSVr/...`
   - Signature (from appcast): `MCwCFGFb...`
   - ✅ Signature valid → Update is authentic

### 4.2 Update Notification UI

**The user sees:**

```
┌─────────────────────────────────────────────────┐
│  🔔 ZetaNotes Update Available                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  A new version of ZetaNotes is available!      │
│                                                 │
│  Version 1.1 is now available—you have 1.0.    │
│  Would you like to download it now?            │
│                                                 │
│  Release Notes:                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ ZetaNotes 1.1                             │ │
│  │                                           │ │
│  │ What's new:                               │ │
│  │ • 🚀 Upgraded to Llama 3.2 1B            │ │
│  │ • ⚡ Better performance                   │ │
│  │ • ✨ Improved quality                     │ │
│  │                                           │ │
│  │ Size: 750 MB                              │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│        [Skip This Version]  [Remind Me Later]  │
│                            [Install Update] ←── │
└─────────────────────────────────────────────────┘
```

### 4.3 User Clicks "Install Update"

**Step-by-step:**

1. **Download starts:**
   ```
   Downloading ZetaNotes-v1.1.dmg...
   Progress: [████████░░░░░░░░░░] 45% (338 MB / 750 MB)
   ```

2. **Verification:**
   ```
   Verifying signature... ✅
   Checking integrity... ✅
   ```

3. **Installation prompt:**
   ```
   ┌─────────────────────────────────────────────┐
   │  Ready to Install                           │
   ├─────────────────────────────────────────────┤
   │                                             │
   │  ZetaNotes will quit and update to v1.1    │
   │                                             │
   │  Your notes and settings will be preserved. │
   │                                             │
   │        [Cancel]  [Install and Relaunch] ←── │
   └─────────────────────────────────────────────┘
   ```

4. **User clicks "Install and Relaunch":**
   - App quits gracefully
   - Sparkle extracts DMG
   - Replaces old app with new app
   - Launches new version automatically
   - **User sees:** ZetaNotes v1.1 running!

---

## Step 5: Manual Check for Updates

**User can also check manually:**

1. User clicks: **ZetaNotes** menu → **Check for Updates...**
2. Sparkle immediately checks appcast.xml
3. Same flow as automatic check

**Menu Item** (when Sparkle is enabled):

```swift
.commands {
    CommandGroup(after: .appInfo) {
        CheckForUpdatesView(updater: updaterController.updater)
    }
}
```

**Renders as:**
```
ZetaNotes
  About ZetaNotes
  Check for Updates...        ← Added by Sparkle
  ───────────────────
  Preferences...    ⌘,
  ───────────────────
  Quit ZetaNotes    ⌘Q
```

---

## Step 6: Testing the Update Flow (Dev Mode)

### 6.1 Local Testing Setup

To test updates locally without publishing to GitHub:

```bash
# 1. Start a local web server
cd docs
python3 -m http.server 8000

# Now appcast.xml is available at:
# http://localhost:8000/appcast.xml
```

### 6.2 Modify Info.plist for Testing

**Temporarily change:**
```xml
<key>SUFeedURL</key>
<string>http://localhost:8000/appcast.xml</string>
```

### 6.3 Create Test Appcast

**File:** `docs/appcast.xml` (for testing)

```xml
<item>
    <title>Version 1.1 TEST</title>
    <sparkle:version>1.1</sparkle:version>
    <description><![CDATA[
        <h2>🧪 Test Update - Version 1.1</h2>
        <p>This is a test update to verify Sparkle integration.</p>
    ]]></description>
    <pubDate>$(date -R)</pubDate>
    <enclosure
        url="http://localhost:8000/ZetaNotes-v1.1.dmg"
        sparkle:version="1.1"
        length="750000000"
        type="application/octet-stream"
        sparkle:edSignature="TEST_SIGNATURE" />
</item>
```

### 6.4 Simulate Update Check

**In the app (after uncommenting Sparkle):**

1. Build and run ZetaNotes v1.0
2. Click **ZetaNotes** → **Check for Updates...**
3. Sparkle fetches `http://localhost:8000/appcast.xml`
4. Sees version 1.1 > 1.0
5. Shows update dialog!

**Expected behavior:**
```
✅ Update notification appears
✅ Release notes are displayed
✅ Download starts when user clicks Install
⚠️  Installation will fail (test signature invalid)
   → But you've verified the notification works!
```

---

## Step 7: Production Release Checklist

When releasing version 1.1 for real:

### 7.1 Pre-Release

- [ ] Update version in Xcode (`1.0` → `1.1`)
- [ ] Verify Llama 3.2 1B is set as default in `AIEngine.swift`
- [ ] Update release notes in this document
- [ ] Test build locally

### 7.2 Build Release

```bash
# Build version 1.1 with new model
./scripts/release_unsigned.sh 1.1

# Outputs:
# - ZetaNotes-v1.1.dmg
# - Updated appcast.xml
# - EdDSA signature
```

### 7.3 GitHub Release

1. Go to: `https://github.com/YOUR_USERNAME/zetanotes/releases/new`
2. Create tag: `v1.1`
3. Title: `ZetaNotes 1.1 - Llama 3.2 1B Upgrade`
4. Description:
   ```markdown
   ## What's New in 1.1

   ### 🚀 New Default Model: Llama 3.2 1B
   - Better instruction-following than TinyLlama
   - Lower memory usage (1.2GB vs 1.5GB)
   - Same file size (700MB)
   - Same speed, better quality!

   ### Installation
   1. Download `ZetaNotes-v1.1.dmg`
   2. Open DMG
   3. Drag to Applications
   4. Right-click → Open (first time only)

   **Auto-Update**: Existing users will receive an update notification!

   SHA256: <paste from build output>
   ```
5. Upload: `ZetaNotes-v1.1.dmg`
6. Publish release

### 7.4 Deploy Appcast

```bash
# Commit updated appcast.xml
git add docs/appcast.xml
git commit -m "Update appcast for v1.1 - Llama 3.2 1B"
git push origin main

# GitHub Pages will automatically update
# Appcast live at: https://YOUR_USERNAME.github.io/zetanotes/appcast.xml
```

### 7.5 Verify Live Update

**Test with a real v1.0 installation:**

1. Install ZetaNotes v1.0
2. Open app
3. Click **Check for Updates...**
4. Should see: "Version 1.1 is available"
5. Click **Install Update**
6. App updates automatically!

---

## 🔍 Troubleshooting

### Update Not Showing

**Possible causes:**

1. **Version comparison issue:**
   ```bash
   # Check version in Info.plist
   defaults read ~/Desktop/ZetaNotes.app/Contents/Info.plist CFBundleShortVersionString
   # Should show: 1.0 (for old) or 1.1 (for new)
   ```

2. **Appcast not accessible:**
   ```bash
   # Test appcast URL
   curl https://YOUR_USERNAME.github.io/zetanotes/appcast.xml
   # Should return XML, not 404
   ```

3. **Sparkle not initialized:**
   - Verify Sparkle is uncommented in `ZetaNotesApp.swift`
   - Check console for Sparkle logs

### Signature Verification Failed

```bash
# Verify EdDSA signature
./scripts/sparkle/bin/sign_update ZetaNotes-v1.1.dmg

# Compare with signature in appcast.xml
# They must match exactly!
```

### Download Fails

- Check DMG is uploaded to GitHub releases
- Verify URL in appcast.xml matches GitHub release URL
- Test download manually:
  ```bash
  curl -LO https://github.com/YOUR_USERNAME/zetanotes/releases/download/v1.1/ZetaNotes-v1.1.dmg
  ```

---

## 📊 Update Analytics (No Tracking!)

ZetaNotes respects privacy, so we don't track updates. However, you can estimate adoption:

- **GitHub Release Downloads**: Check release page
- **Appcast Requests**: If using GitHub Pages, check repo traffic stats
- **No user tracking**: We never know which users updated

---

## 🎯 Summary

**The Update Flow:**

```
User runs ZetaNotes v1.0
        ↓
After 24 hours, Sparkle checks appcast.xml
        ↓
Finds version 1.1 > 1.0
        ↓
Verifies EdDSA signature ✅
        ↓
Shows update notification
        ↓
User clicks "Install Update"
        ↓
Downloads ZetaNotes-v1.1.dmg (750MB)
        ↓
Verifies download integrity
        ↓
App quits, update installs, app relaunches
        ↓
User now running ZetaNotes v1.1 with Llama 3.2 1B! 🎉
```

**Key Points:**

✅ **Automatic**: Users get notified without doing anything
✅ **Secure**: EdDSA signatures prevent tampering
✅ **Seamless**: One-click install
✅ **Unsigned-friendly**: Works with unsigned builds (user right-clicks once)
✅ **Privacy-first**: No tracking, no telemetry

---

## Next Steps

To enable auto-updates:

1. **Uncomment Sparkle code** in `ZetaNotesApp.swift`
2. **Test locally** with the local server method
3. **Build v1.1** with the release script
4. **Publish to GitHub** and deploy appcast
5. **Celebrate!** Your users get automatic updates 🎉
