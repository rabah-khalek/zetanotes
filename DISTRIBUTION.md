# OffNotes Distribution Guide

This guide covers signing, notarizing, and distributing OffNotes via GitHub Pages.

## Prerequisites

### 1. Apple Developer Account
- Enroll at https://developer.apple.com ($99/year)
- Required for code signing and notarization

### 2. Developer ID Certificate
1. Open **Xcode** → **Preferences** → **Accounts**
2. Add your Apple ID
3. Select your team → **Manage Certificates**
4. Click **+** → **Developer ID Application**
5. Certificate will be created and installed in Keychain

### 3. App-Specific Password
1. Go to https://appleid.apple.com
2. Sign in → **Security** → **App-Specific Passwords**
3. Generate a new password (save it securely)
4. This is needed for `notarytool`

### 4. Verify Your Setup
```bash
# Check if you have the certificate
security find-identity -v -p codesigning

# Should show something like:
# 1) XXXXX "Developer ID Application: Your Name (TEAM_ID)"
```

---

## Step 1: Build the App for Distribution

### Update Version Numbers
1. Open Xcode
2. Select **NoteTaker** target → **General**
3. Update **Version** (e.g., `1.0.0`) and **Build** (e.g., `1`)

### Build in Xcode
1. Select **Product** → **Archive**
2. Wait for build to complete
3. In Organizer, select your archive
4. Click **Distribute App** → **Copy App**
5. Save `OffNotes.app` to a clean folder (e.g., `~/Desktop/OffNotes-Release/`)

**OR Build via Command Line:**
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Build for release
xcodebuild -scheme NoteTaker \
  -configuration Release \
  -archivePath ~/Desktop/OffNotes.xcarchive \
  archive

# Export the app
xcodebuild -exportArchive \
  -archivePath ~/Desktop/OffNotes.xcarchive \
  -exportPath ~/Desktop/OffNotes-Release \
  -exportOptionsPlist ExportOptions.plist
```

---

## Step 2: Bundle TinyLlama Model

The TinyLlama model should be bundled with the app so users can use AI features immediately.

### Download TinyLlama
```bash
# Create models directory
mkdir -p ~/Desktop/OffNotes-Release/OffNotes.app/Contents/Resources/Models

# Download TinyLlama model (~700MB)
curl -L "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf" \
  -o ~/Desktop/OffNotes-Release/OffNotes.app/Contents/Resources/Models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
```

**Important:** After adding the model, you must re-sign the app (see Step 3).

---

## Step 3: Code Sign the App

### Sign with Developer ID
```bash
# Replace YOUR_NAME with the name from your certificate
# Get it from: security find-identity -v -p codesigning
CERT_NAME="Developer ID Application: Your Name (TEAM_ID)"

# Sign the app (deep signing includes all contents)
codesign --deep --force --verify --verbose \
  --sign "$CERT_NAME" \
  --options runtime \
  --timestamp \
  ~/Desktop/OffNotes-Release/OffNotes.app
```

### Verify Signature
```bash
# Verify the signature is valid
codesign --verify --deep --strict --verbose=2 \
  ~/Desktop/OffNotes-Release/OffNotes.app

# Check if hardened runtime is enabled
codesign -d --entitlements - \
  ~/Desktop/OffNotes-Release/OffNotes.app
```

**Expected output:** Should show no errors and display entitlements.

---

## Step 4: Create DMG Installer

### Option A: Using create-dmg (Recommended)

Install `create-dmg`:
```bash
brew install create-dmg
```

Create the DMG:
```bash
cd ~/Desktop/OffNotes-Release

create-dmg \
  --volname "OffNotes Installer" \
  --volicon "OffNotes.app/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "OffNotes.app" 200 190 \
  --hide-extension "OffNotes.app" \
  --app-drop-link 600 185 \
  --background dmg-background.png \
  OffNotes-v1.0.0.dmg \
  OffNotes.app
```

### Option B: Manual DMG Creation

```bash
cd ~/Desktop/OffNotes-Release

# Create a temporary DMG
hdiutil create -size 1g -fs HFS+ -volname "OffNotes" temp.dmg

# Mount it
hdiutil attach temp.dmg -readwrite -mountpoint /Volumes/OffNotes

# Copy app to DMG
cp -R OffNotes.app /Volumes/OffNotes/

# Create Applications symlink for drag-drop
ln -s /Applications /Volumes/OffNotes/Applications

# Unmount
hdiutil detach /Volumes/OffNotes

# Convert to compressed, read-only DMG
hdiutil convert temp.dmg -format UDZO -o OffNotes-v1.0.0.dmg

# Clean up
rm temp.dmg
```

### Sign the DMG
```bash
codesign --sign "$CERT_NAME" --timestamp OffNotes-v1.0.0.dmg

# Verify DMG signature
codesign --verify --deep --strict --verbose=2 OffNotes-v1.0.0.dmg
```

---

## Step 5: Notarize with Apple

Notarization is required for Gatekeeper to allow users to open your app without warnings.

### Store Credentials
```bash
# Store your Apple ID credentials (one-time setup)
xcrun notarytool store-credentials "notary-profile" \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"  # App-specific password
```

### Submit for Notarization
```bash
# Submit the DMG for notarization
xcrun notarytool submit OffNotes-v1.0.0.dmg \
  --keychain-profile "notary-profile" \
  --wait

# This will show progress and wait for completion (5-15 minutes usually)
```

**Expected output:**
```
Conducting pre-submission checks for OffNotes-v1.0.0.dmg...
Submission ID: xxxxx-xxxx-xxxx-xxxx-xxxxxxxxx
Successfully uploaded file
  id: xxxxx-xxxx-xxxx-xxxx-xxxxxxxxx
  path: /path/to/OffNotes-v1.0.0.dmg
Waiting for processing to complete...
Current status: Accepted
```

### Check Notarization Status
```bash
# If you need to check status later
xcrun notarytool info SUBMISSION_ID \
  --keychain-profile "notary-profile"

# View the notarization log (if issues)
xcrun notarytool log SUBMISSION_ID \
  --keychain-profile "notary-profile"
```

### Staple the Notarization Ticket
```bash
# Attach the notarization ticket to the DMG
xcrun stapler staple OffNotes-v1.0.0.dmg

# Verify stapling worked
xcrun stapler validate OffNotes-v1.0.0.dmg
```

**Expected output:** `The validate action worked!`

---

## Step 6: Generate SHA256 Checksum

```bash
# Generate checksum for download page
shasum -a 256 OffNotes-v1.0.0.dmg

# Example output:
# a1b2c3d4e5f6... OffNotes-v1.0.0.dmg
```

**Save this checksum** - you'll add it to `docs/download.html`.

---

## Step 7: Test the DMG

### Test on Clean Mac (Recommended)
1. Copy DMG to a different Mac (or VM)
2. Double-click to mount
3. Drag OffNotes to Applications
4. Try to open (should work without warnings)

### Test Locally
```bash
# Remove quarantine flag to simulate download
xattr -cr ~/Desktop/OffNotes-Release/OffNotes-v1.0.0.dmg

# Mount and test
open OffNotes-v1.0.0.dmg
```

### Verify Gatekeeper Approval
```bash
# Check if Gatekeeper accepts it
spctl --assess --verbose --type execute /Applications/OffNotes.app

# Expected output: "accepted" and "notarized"
```

---

## Step 8: Upload to GitHub Release

### Create Release on GitHub
1. Go to your repository on GitHub
2. Click **Releases** → **Draft a new release**
3. Tag version: `v1.0.0`
4. Release title: `OffNotes v1.0.0`
5. Write release notes (see template below)

### Upload the DMG
1. Drag `OffNotes-v1.0.0.dmg` to the release assets
2. Publish release

### Release Notes Template
```markdown
# OffNotes v1.0.0

Privacy-first note-taking with offline AI. Your notes never leave your device.

## What's Included
- 🔒 100% offline AI processing
- ✨ Smart autocomplete with TinyLlama 1.1B (bundled)
- 📝 Instant summarization
- 🌍 Translate to 12+ languages
- 🔍 Semantic search with vector embeddings

## Free Tier
- TinyLlama 1.1B model (bundled)
- All AI features (autocomplete, summaries, translation)
- Unlimited notes

## Pro Tier (Flexible Pricing)

**Choose your plan:**
- **Monthly**: $1/month - Perfect for trying out
- **Annual**: $10/year - Best value, save $2/year
- **Lifetime**: $30 one-time - Own forever

**All plans include:**
- 8 open-source AI models
- Download and switch between models
- Custom prompt editing
- Priority support

## Installation
1. Download `OffNotes-v1.0.0.dmg`
2. Open DMG and drag OffNotes to Applications
3. Open OffNotes from Applications

## System Requirements
- macOS 13.0+ (Ventura or later)
- Apple Silicon (M1/M2/M3/M4) recommended
- 4 GB RAM minimum (8 GB+ recommended)

## Checksum
SHA256: `YOUR_CHECKSUM_HERE`

---

**Download:** [OffNotes-v1.0.0.dmg](https://github.com/YOUR_USERNAME/offnotes/releases/download/v1.0.0/OffNotes-v1.0.0.dmg)
```

---

## Step 9: Update Website

### Update download.html
1. Edit `docs/download.html`
2. Update the checksum:
   ```html
   SHA256: <span id="checksum">YOUR_ACTUAL_CHECKSUM_HERE</span>
   ```
3. Update download URL:
   ```html
   https://github.com/YOUR_USERNAME/offnotes/releases/download/v1.0.0/OffNotes-v1.0.0.dmg
   ```

### Update index.html
1. Edit `docs/index.html`
2. Update download button URL to point to GitHub release

### Commit and Push
```bash
cd /Users/projects/Documents/notetaker
git add docs/
git commit -m "Update download links for v1.0.0"
git push origin main
```

### Enable GitHub Pages
1. Go to repository **Settings**
2. Scroll to **Pages**
3. Source: **Deploy from a branch**
4. Branch: `main` → folder: `/docs`
5. Save

Your site will be live at: `https://YOUR_USERNAME.github.io/offnotes/`

---

## Automation Script (Optional)

Save this as `scripts/release.sh`:

```bash
#!/bin/bash
set -e

VERSION="1.0.0"
CERT_NAME="Developer ID Application: Your Name (TEAM_ID)"
APP_PATH="$HOME/Desktop/OffNotes-Release/OffNotes.app"
DMG_NAME="OffNotes-v${VERSION}.dmg"

echo "🔨 Building OffNotes v${VERSION}..."

# Step 1: Build
xcodebuild -scheme NoteTaker -configuration Release -archivePath ~/Desktop/OffNotes.xcarchive archive
xcodebuild -exportArchive -archivePath ~/Desktop/OffNotes.xcarchive -exportPath ~/Desktop/OffNotes-Release -exportOptionsPlist ExportOptions.plist

# Step 2: Download TinyLlama
echo "📦 Downloading TinyLlama model..."
mkdir -p "${APP_PATH}/Contents/Resources/Models"
curl -L "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf" \
  -o "${APP_PATH}/Contents/Resources/Models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"

# Step 3: Sign
echo "✍️ Signing app..."
codesign --deep --force --verify --verbose --sign "$CERT_NAME" --options runtime --timestamp "$APP_PATH"

# Step 4: Create DMG
echo "💿 Creating DMG..."
create-dmg --volname "OffNotes Installer" --window-size 800 400 --icon "OffNotes.app" 200 190 --app-drop-link 600 185 "$DMG_NAME" "$APP_PATH"

# Step 5: Sign DMG
echo "✍️ Signing DMG..."
codesign --sign "$CERT_NAME" --timestamp "$DMG_NAME"

# Step 6: Notarize
echo "🔔 Submitting for notarization..."
xcrun notarytool submit "$DMG_NAME" --keychain-profile "notary-profile" --wait

# Step 7: Staple
echo "📎 Stapling ticket..."
xcrun stapler staple "$DMG_NAME"

# Step 8: Checksum
echo "🔢 Generating checksum..."
shasum -a 256 "$DMG_NAME"

echo "✅ Done! DMG ready for release: $DMG_NAME"
```

Make it executable:
```bash
chmod +x scripts/release.sh
./scripts/release.sh
```

---

## Troubleshooting

### Notarization Failed
```bash
# Get detailed error log
xcrun notarytool log SUBMISSION_ID --keychain-profile "notary-profile"

# Common issues:
# - Missing hardened runtime: Add --options runtime to codesign
# - Invalid signature: Re-sign with --deep --force
# - Missing timestamp: Add --timestamp to codesign
```

### Gatekeeper Still Blocks App
```bash
# Check what Gatekeeper sees
spctl --assess --verbose=4 /Applications/OffNotes.app

# If it says "no usable signature":
# - Re-sign the app
# - Make sure you signed AFTER adding TinyLlama model
```

### App Crashes on Launch
```bash
# Check for code signing issues
codesign --verify --deep --strict --verbose=2 /Applications/OffNotes.app

# View crash logs
open ~/Library/Logs/DiagnosticReports/
```

---

## Cost Summary

| Item | Cost | Frequency |
|------|------|-----------|
| Apple Developer Program | $99 | Annual |
| LemonSqueezy Fees | 5% + $0.50 | Per sale |
| GitHub Pages | Free | - |
| Total First Year | $99 | - |

**Break-even:**
- With Lifetime ($30): 4 sales = $120
- With Annual ($10): 10 sales = $100
- With Monthly ($1): 100 months of subscribers = $100

---

## Next Steps

1. ✅ Complete this distribution guide
2. 🚀 Create first GitHub release
3. 📝 Update website with download links
4. 🎯 Set up LemonSqueezy store
5. 📣 Announce launch!
