# ZetaNotes Release Scripts

Automated scripts to package and release ZetaNotes with one command.

## 🚀 Quick Start

### First Time Setup (5 minutes)

1. **Run setup script:**
   ```bash
   cd /Users/projects/Documents/zetanotes
   chmod +x scripts/*.sh
   ./scripts/setup-signing.sh
   ```

2. **Follow the prompts:**
   - Select your Developer ID certificate
   - Enter your Apple ID
   - Enter app-specific password (from appleid.apple.com)

3. **Done!** The script configures everything automatically.

### Every Release (15-20 minutes automated)

1. **Update version number:**
   ```bash
   # Edit scripts/package-release.sh line 19
   VERSION="1.0.1"  # Change this
   ```

2. **Run packaging script:**
   ```bash
   ./scripts/package-release.sh
   ```

3. **Wait for completion:**
   - Builds app (5-10 min)
   - Downloads TinyLlama (2-5 min)
   - Signs and creates DMG (2 min)
   - Notarizes with Apple (5-15 min)
   - Total: 15-20 minutes hands-off

4. **Get your DMG:**
   - Location: `~/Desktop/ZetaNotes-Release-YYYYMMDD-HHMMSS/`
   - File: `ZetaNotes-v1.0.0.dmg`
   - Checksum: `ZetaNotes-v1.0.0.dmg.sha256`

## 📁 Scripts Included

### `setup-signing.sh`
**One-time setup for code signing and notarization**

- Finds your Developer ID certificate
- Stores notarization credentials in Keychain
- Updates configuration files automatically

**When to run:** Once, before your first release

### `package-release.sh`
**Automated packaging script**

Does everything:
- ✅ Builds app in Xcode
- ✅ Bundles TinyLlama model
- ✅ Signs with Developer ID
- ✅ Creates DMG installer
- ✅ Signs DMG
- ✅ Notarizes with Apple
- ✅ Staples notarization ticket
- ✅ Generates SHA256 checksum
- ✅ Verifies everything works

**When to run:** Every time you want to create a release

### `ExportOptions.plist`
**Xcode export configuration**

Automatically updated by `setup-signing.sh` with your Team ID.

## 🔧 Configuration

### Update Version Number

Before each release, edit `scripts/package-release.sh`:

```bash
# Line 19
VERSION="1.0.1"  # Change this for each release
```

### Update Certificate (if expired)

```bash
# Edit line 16 in package-release.sh
CERT_NAME="Developer ID Application: New Name (NEW_TEAM_ID)"
```

Or re-run `setup-signing.sh`.

## 📋 Prerequisites

### Required (one-time)

1. **Apple Developer Account** ($99/year)
   - Sign up at https://developer.apple.com

2. **Developer ID Certificate**
   - Xcode → Preferences → Accounts → Manage Certificates
   - Create "Developer ID Application" certificate

3. **App-Specific Password**
   - Go to https://appleid.apple.com
   - Security → App-Specific Passwords → Generate
   - Save it securely (used in setup-signing.sh)

4. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

### Optional (for prettier DMG)

```bash
brew install create-dmg
```

If not installed, the script uses a fallback method (works fine, just less pretty).

## 🎯 What Gets Created

After running `package-release.sh`, you get a folder like:

```
~/Desktop/ZetaNotes-Release-20241016-143022/
├── ZetaNotes.app                          # Signed app (for testing)
├── ZetaNotes-v1.0.0.dmg                   # Upload this to GitHub ✅
└── ZetaNotes-v1.0.0.dmg.sha256            # Checksum (update website)
```

## 📤 Upload to GitHub

1. **Create release:**
   ```bash
   # On GitHub: Releases → Draft a new release
   # Tag: v1.0.0
   # Title: ZetaNotes v1.0.0
   ```

2. **Upload DMG:**
   - Drag `ZetaNotes-v1.0.0.dmg` to release assets

3. **Update website:**
   ```bash
   # Copy checksum
   cat ~/Desktop/ZetaNotes-Release-*/ZetaNotes-v1.0.0.dmg.sha256

   # Update docs/download.html line 29
   SHA256: <span id="checksum">PASTE_CHECKSUM_HERE</span>

   # Commit and push
   git add docs/
   git commit -m "Update download checksum for v1.0.0"
   git push
   ```

## 🐛 Troubleshooting

### "Certificate not found"

**Problem:** Script can't find your Developer ID certificate

**Solution:**
```bash
# List certificates
security find-identity -v -p codesigning

# Copy the exact name in quotes and update package-release.sh line 16
CERT_NAME="Developer ID Application: Your Name (TEAM_ID)"
```

### "Notary profile not found"

**Problem:** Notarization credentials not stored

**Solution:**
```bash
# Re-run setup
./scripts/setup-signing.sh

# Or manually:
xcrun notarytool store-credentials "notary-profile" \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

### "Notarization failed"

**Problem:** Apple rejected the notarization

**Solution:**
```bash
# View detailed error log
xcrun notarytool log SUBMISSION_ID --keychain-profile "notary-profile"

# Common issues:
# - Hardened runtime not enabled → Script handles this
# - Invalid signature → Re-run script
# - Binary not properly signed → Check certificate
```

### Build fails

**Problem:** Xcode build errors

**Solution:**
```bash
# Clean and rebuild manually first
cd /Users/projects/Documents/zetanotes
xcodebuild clean -project ZetaNotes.xcodeproj -scheme ZetaNotes
xcodebuild build -project ZetaNotes.xcodeproj -scheme ZetaNotes

# Fix any errors, then re-run package-release.sh
```

### DMG creation fails

**Problem:** create-dmg not installed or errors

**Solution:**
```bash
# Install create-dmg (optional)
brew install create-dmg

# Or let script use fallback method (works fine)
```

## ⏱️ Time Breakdown

| Step | Time | Notes |
|------|------|-------|
| Build in Xcode | 5-10 min | Depends on Mac speed |
| Download TinyLlama | 2-5 min | Depends on internet |
| Sign app | 30 sec | Quick |
| Create DMG | 1 min | Quick |
| Sign DMG | 10 sec | Quick |
| Notarize | 5-15 min | Apple's servers |
| Staple | 10 sec | Quick |
| **Total** | **15-25 min** | Mostly automated waiting |

## 🎨 Customization

### Change DMG appearance

Edit `package-release.sh` around line 150:

```bash
create-dmg \
    --volname "My Custom Name" \
    --background "path/to/background.png" \
    --window-size 900 500 \
    --icon-size 120 \
    ...
```

### Skip notarization (testing only)

Comment out lines 195-214 in `package-release.sh`. **Warning:** Users will get security warnings!

### Add custom files to DMG

Edit `package-release.sh` around line 175:

```bash
# After copying app
cp README.txt "/Volumes/$APP_NAME/"
cp LICENSE "/Volumes/$APP_NAME/"
```

## 📖 Manual Alternative

If you prefer doing it manually, follow [DISTRIBUTION.md](../DISTRIBUTION.md).

## 🆘 Getting Help

- **Script issues:** Open an issue on GitHub
- **Apple Developer issues:** https://developer.apple.com/support/
- **Notarization issues:** https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution

## 📝 Changelog

### v1.0 (2024-10-16)
- Initial automated packaging script
- One-time setup script
- Automatic notarization
- SHA256 checksum generation
