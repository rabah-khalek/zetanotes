# Quick Guide: Test Auto-Updates Locally

This is a step-by-step guide to test the Sparkle auto-update notification **without publishing anything to GitHub**.

---

## Prerequisites

- Xcode installed
- ZetaNotes project open
- Terminal access

---

## Step 1: Enable Sparkle (5 minutes)

### 1.1 Uncomment Sparkle Import

**File:** `ZetaNotes/ZetaNotesApp.swift`

**Find this:**
```swift
// TODO: Uncomment when Sparkle package is added
// import Sparkle
```

**Change to:**
```swift
import Sparkle  // ✅ Enabled for testing
```

### 1.2 Uncomment Updater Controller

**Find this:**
```swift
// TODO: Uncomment when Sparkle package is added
// private let updaterController: SPUStandardUpdaterController
```

**Change to:**
```swift
private let updaterController: SPUStandardUpdaterController  // ✅ Enabled
```

### 1.3 Uncomment Initialization

**Find this:**
```swift
init() {
    // TODO: Uncomment when Sparkle package is added
    // updaterController = SPUStandardUpdaterController(
    //     startingUpdater: true,
    //     updaterDelegate: nil,
    //     userDriverDelegate: nil
    // )
```

**Change to:**
```swift
init() {
    // Initialize Sparkle updater controller
    updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
```

### 1.4 Uncomment Menu Item

**Find this:**
```swift
// TODO: Uncomment when Sparkle package is added
// CommandGroup(after: .appInfo) {
//     CheckForUpdatesView(updater: updaterController.updater)
// }
```

**Change to:**
```swift
CommandGroup(after: .appInfo) {
    CheckForUpdatesView(updater: updaterController.updater)
}
```

---

## Step 2: Point to Local Test Server

### 2.1 Modify Info.plist Temporarily

**File:** `ZetaNotes/Info.plist`

**Find:**
```xml
<key>SUFeedURL</key>
<string>https://YOUR_USERNAME.github.io/zetanotes/appcast.xml</string>
```

**Change to:**
```xml
<key>SUFeedURL</key>
<string>http://localhost:8000/test-appcast.xml</string>
```

⚠️ **Remember to change this back before releasing!**

---

## Step 3: Start Local Web Server

Open a new Terminal window:

```bash
# Navigate to the docs directory
cd /Users/projects/Documents/zetanotes/docs

# Start a simple HTTP server
python3 -m http.server 8000
```

**You should see:**
```
Serving HTTP on :: port 8000 (http://[::]:8000/) ...
```

**Keep this terminal window open!**

---

## Step 4: Build and Run ZetaNotes

### 4.1 Verify Current Version

**File:** `ZetaNotes/Info.plist`

Make sure your current version is `1.0`:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0</string>
```

### 4.2 Build and Run

1. In Xcode, click **Product** → **Run** (or press ⌘R)
2. Wait for the app to launch

---

## Step 5: Test Update Notification

### 5.1 Trigger Update Check

In the running ZetaNotes app:

1. Click **ZetaNotes** menu (top-left)
2. Click **Check for Updates...**

**You should see this menu item now!** (Added by Sparkle)

### 5.2 Expected Result

**Update Notification Appears:**

```
┌─────────────────────────────────────────────────┐
│  A new version of ZetaNotes is available!      │
├─────────────────────────────────────────────────┤
│                                                 │
│  Version 1.1 TEST is now available—you have 1.0 │
│                                                 │
│  Release Notes:                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ 🧪 Test Update - ZetaNotes 1.1          │ │
│  │                                           │ │
│  │ What's New:                               │ │
│  │ • 🚀 Upgraded to Llama 3.2 1B            │ │
│  │ • ⚡ Lower memory usage                   │ │
│  │ • ✨ Improved instruction-following      │ │
│  │                                           │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│              [Remind Me Later]  [Install Now]  │
└─────────────────────────────────────────────────┘
```

**✅ SUCCESS!** The update notification works!

### 5.3 What Happens if You Click Install

Since this is a test:
- Sparkle will try to download `http://localhost:8000/ZetaNotes-v1.1-TEST.dmg`
- The file doesn't exist, so download will fail
- That's okay! We just wanted to see the notification

---

## Step 6: Check Console Logs

### 6.1 Open Console.app

```bash
# Or just open Console.app from Spotlight
open /System/Applications/Utilities/Console.app
```

### 6.2 Filter for ZetaNotes

In Console.app:
1. Type `ZetaNotes` in the search box
2. Look for Sparkle-related logs:

**Expected logs:**
```
Sparkle: Checking for updates...
Sparkle: Fetching appcast from http://localhost:8000/test-appcast.xml
Sparkle: Found update: Version 1.1 TEST
Sparkle: Current version: 1.0, Latest version: 1.1
Sparkle: Update is available
```

---

## Step 7: Test "No Updates Available"

### 7.1 Update to Version 1.1

**File:** `ZetaNotes/Info.plist`

**Change:**
```xml
<key>CFBundleShortVersionString</key>
<string>1.1</string>
```

### 7.2 Build and Run Again

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Run** (⌘R)

### 7.3 Check for Updates

1. Click **ZetaNotes** → **Check for Updates...**

**Expected Result:**
```
┌─────────────────────────────────────┐
│  You're up to date!                 │
├─────────────────────────────────────┤
│                                     │
│  ZetaNotes 1.1 is currently the     │
│  newest version available.          │
│                                     │
│                [OK]                 │
└─────────────────────────────────────┘
```

**✅ Perfect!** Sparkle correctly detects you're on the latest version.

---

## Step 8: Restore Original Settings

### 8.1 Restore Info.plist

**Change back to production URL:**
```xml
<key>SUFeedURL</key>
<string>https://YOUR_USERNAME.github.io/zetanotes/appcast.xml</string>
```

### 8.2 Restore Version (if needed)

```xml
<key>CFBundleShortVersionString</key>
<string>1.0</string>
```

### 8.3 Stop Test Server

In the Terminal window running the HTTP server:
- Press `Ctrl+C` to stop

---

## Troubleshooting

### ❌ Menu Item "Check for Updates" Doesn't Appear

**Problem:** Sparkle not initialized

**Solution:**
1. Verify all Sparkle code is uncommented in `ZetaNotesApp.swift`
2. Clean build folder (⇧⌘K)
3. Rebuild and run

### ❌ Error: "No update available"

**Problem:** Appcast not accessible or version comparison failed

**Solutions:**

1. **Check web server is running:**
   ```bash
   curl http://localhost:8000/test-appcast.xml
   # Should return XML content
   ```

2. **Check Info.plist has correct URL:**
   ```xml
   <key>SUFeedURL</key>
   <string>http://localhost:8000/test-appcast.xml</string>
   ```

3. **Verify version numbers:**
   - Current version (Info.plist): `1.0`
   - Test appcast version: `1.1`
   - `1.1 > 1.0` ✅

### ❌ Update Check Does Nothing

**Problem:** Sparkle can't reach appcast

**Solutions:**

1. **Check Console.app for errors:**
   - Filter for "Sparkle"
   - Look for network errors

2. **Test appcast manually:**
   ```bash
   curl http://localhost:8000/test-appcast.xml
   ```

3. **Verify SUFeedURL in running app:**
   ```bash
   defaults read /path/to/ZetaNotes.app/Contents/Info.plist SUFeedURL
   ```

---

## What You Proved

By completing this test, you've verified:

✅ **Sparkle is integrated** - The framework loads correctly
✅ **Menu item works** - "Check for Updates" appears
✅ **Appcast parsing works** - Sparkle reads the XML
✅ **Version comparison works** - Detects 1.1 > 1.0
✅ **UI appears** - Update notification shows with release notes
✅ **No updates works** - Correctly detects when up-to-date

---

## Next Steps

To enable auto-updates in production:

1. **Keep Sparkle uncommented** in `ZetaNotesApp.swift`
2. **Restore production appcast URL** in Info.plist
3. **Build release v1.1** with:
   ```bash
   ./scripts/release_unsigned.sh 1.1
   ```
4. **Upload to GitHub releases**
5. **Commit and push updated `docs/appcast.xml`**

Your users will automatically get update notifications! 🎉

---

## Summary

**What we tested:**

```
1. Enabled Sparkle in code
        ↓
2. Started local test server (localhost:8000)
        ↓
3. Built ZetaNotes v1.0
        ↓
4. Clicked "Check for Updates"
        ↓
5. Sparkle fetched test-appcast.xml
        ↓
6. Compared v1.0 < v1.1
        ↓
7. Update notification appeared! ✅
```

**Time to test:** ~10 minutes
**Confidence gained:** 100% that auto-updates work! 🚀
