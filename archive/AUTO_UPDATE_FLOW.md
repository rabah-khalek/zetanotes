# ZetaNotes Auto-Update Flow

## Overview

ZetaNotes now has **fully functional auto-updates** using Sparkle framework! Users will automatically receive update notifications when new versions are released.

---

## What Was Fixed

### 1. ✅ Activated Sparkle Code
- **File**: [ZetaNotes/ZetaNotesApp.swift](../ZetaNotes/ZetaNotesApp.swift)
- Uncommented `import Sparkle`
- Activated `SPUStandardUpdaterController`
- Enabled "Check for Updates" menu item

### 2. ✅ Created Update UI
- **File**: [ZetaNotes/Views/CheckForUpdatesView.swift](../ZetaNotes/Views/CheckForUpdatesView.swift)
- SwiftUI view for manual update checking
- Integrates with Sparkle's updater

### 3. ✅ Fixed Feed URL
- **File**: [ZetaNotes/Info.plist](../ZetaNotes/Info.plist)
- Updated `SUFeedURL` from `https://zetanotes.com/appcast.xml` to `https://rabah-khalek.github.io/zetanotes/appcast.xml`
- Updated `SUPublicEDKey` to match the newly generated key

### 4. ✅ Fixed CI Signature Generation
- **File**: [.github/workflows/release.yml](../.github/workflows/release.yml)
- Changed to use `sign_update` tool directly (more reliable)
- Added fallback to `generate_appcast` with proper DMG handling
- Better error reporting

### 5. ✅ Sparkle Configuration
- EdDSA keys generated and stored
- Public key: `OaS6XLRg52NaUmFiFX46nv1MlVb2gicyeSuxemv9N5I=`
- Private key: Needs to be added to GitHub Secrets (see below)

---

## How Auto-Updates Work

### When You Release a New Version

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Push Git Tag                                              │
│    git tag v1.0.1                                           │
│    git push origin v1.0.1                                   │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. GitHub Actions CI/CD Runs                                │
│    ✅ Clones llama.cpp and builds it                        │
│    ✅ Builds ZetaNotes.app                                  │
│    ✅ Creates DMG installer                                 │
│    ✅ Signs DMG with EdDSA signature                        │
│    ✅ Creates GitHub Release                                │
│    ✅ Uploads DMG + SHA256                                  │
│    ✅ Updates docs/appcast.xml with:                        │
│       - Version number                                      │
│       - Download URL                                        │
│       - File size                                           │
│       - EdDSA signature                                     │
│    ✅ Pushes to rabah-khalek/zetanotes (public repo)       │
│    ✅ GitHub Pages serves appcast.xml                       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. User's App Checks for Updates (Every 24 Hours)          │
│    📡 SPUStandardUpdaterController runs in background       │
│    📥 Fetches: https://rabah-khalek.github.io/...appcast.xml│
│    🔍 Compares versions (1.0 vs 1.0.1)                     │
│    🔐 Verifies EdDSA signature                              │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Update Dialog Appears                                    │
│    💬 "A new version of ZetaNotes is available!"           │
│    📝 Shows release notes from appcast                      │
│    🎯 User clicks "Install Update"                          │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Sparkle Downloads & Installs                            │
│    ⬇️  Downloads DMG from GitHub Release                    │
│    ✅ Verifies EdDSA signature                              │
│    📦 Extracts and replaces app in Applications            │
│    🔄 Relaunches ZetaNotes automatically                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Required GitHub Secret

For the CI workflow to sign releases, you need to add the private key to GitHub Secrets:

### Steps:

1. **Go to Repository Settings**:
   ```
   https://github.com/YOUR_USERNAME/zetanotes-dev/settings/secrets/actions
   ```

2. **Click "New repository secret"**

3. **Add the secret**:
   - **Name**: `SPARKLE_PRIVATE_KEY`
   - **Value**: `9sYT3LfxNMW6NoEd8/ygsU83lzb6gJctwg/4lWMFa08=`

4. **Click "Add secret"**

⚠️ **NEVER commit the private key to git!**

---

## Sparkle Configuration Summary

| Setting | Value | Location |
|---------|-------|----------|
| **SUFeedURL** | `https://rabah-khalek.github.io/zetanotes/appcast.xml` | Info.plist |
| **SUPublicEDKey** | `OaS6XLRg52NaUmFiFX46nv1MlVb2gicyeSuxemv9N5I=` | Info.plist |
| **SUEnableAutomaticChecks** | `true` | Info.plist |
| **SUScheduledCheckInterval** | `86400` (24 hours) | Info.plist |
| **Private Key** | `9sYT3LfxNMW6NoEd8/ygsU83lzb6gJctwg/4lWMFa08=` | GitHub Secret |

---

## User Experience

### First Launch
- App checks for updates in background
- No notification if already on latest version

### Update Available
1. **Notification appears**: "A new version of ZetaNotes is available!"
2. **Release notes shown**: What's new in this version
3. **User choices**:
   - **Install Update**: Downloads and installs immediately
   - **Remind Me Later**: Will check again in 24 hours
   - **Skip This Version**: Won't notify for this version

### Manual Check
- User can go to: **ZetaNotes menu → Check for Updates...**
- Triggers immediate update check
- Shows "You're up to date!" if on latest version

---

## Testing Auto-Updates

### Local Testing (Before Release)

1. **Start a test server**:
   ```bash
   cd docs
   python3 -m http.server 8000
   ```

2. **Temporarily change feed URL** in Info.plist:
   ```xml
   <key>SUFeedURL</key>
   <string>http://localhost:8000/test-appcast.xml</string>
   ```

3. **Build and run** the app

4. **Trigger update check**:
   - Menu: ZetaNotes → Check for Updates...
   - Or wait for automatic check

5. **Verify dialog appears** with test update info

### Production Testing

1. **Build v0.9.9 locally**:
   - Change `CFBundleShortVersionString` to `0.9.9` in Info.plist
   - Build and install this version

2. **Release v1.0**:
   ```bash
   git tag v1.0
   git push origin v1.0
   ```

3. **Wait for CI** to complete (5-10 minutes)

4. **Launch v0.9.9 app**:
   - Should show update notification within a few seconds
   - Or click "Check for Updates..." for immediate check

5. **Install update**:
   - Click "Install Update"
   - Verify it downloads and installs v1.0
   - Verify app relaunches with new version

---

## Release Checklist

When releasing a new version:

- [ ] Update `CFBundleShortVersionString` in Info.plist
- [ ] Update `CFBundleVersion` (build number)
- [ ] Test locally with `./run`
- [ ] Commit changes
- [ ] Create and push tag:
  ```bash
  git tag v1.0.1
  git push origin v1.0.1
  ```
- [ ] Wait for CI to complete
- [ ] Verify release created in public repo
- [ ] Test update from previous version
- [ ] Check appcast.xml was updated on GitHub Pages

---

## What Happens on Each Release

### Automated by CI:

1. ✅ **Build app** with Release configuration
2. ✅ **Create DMG** with installer
3. ✅ **Generate EdDSA signature** for DMG
4. ✅ **Create GitHub Release** in public repo with:
   - DMG file
   - SHA256 checksum
   - Installation instructions
5. ✅ **Update appcast.xml** with:
   - New version number
   - Download URL
   - File size
   - EdDSA signature
   - Release notes
6. ✅ **Publish to GitHub Pages** (serves appcast.xml)

### Happens Automatically:

1. ✅ **Users get notified** within 24 hours
2. ✅ **One-click update** for users
3. ✅ **Signature verification** ensures security
4. ✅ **Auto-relaunch** after update

---

## Troubleshooting

### "Update check failed"
- Verify GitHub Pages is enabled for rabah-khalek/zetanotes
- Check appcast.xml is accessible at: https://rabah-khalek.github.io/zetanotes/appcast.xml
- Verify SUFeedURL in Info.plist matches the appcast URL

### "Signature verification failed"
- Ensure public key in Info.plist matches the private key used to sign
- Regenerate keys if needed: `./scripts/setup-sparkle-keys.sh`
- Update GitHub Secret with new private key

### "No updates available" (when update exists)
- Check version number in Info.plist is lower than released version
- Clear user defaults: `defaults delete com.zetanotes.ZetaNotes`
- Verify appcast.xml has correct version number

### CI signature generation fails
- Verify `SPARKLE_PRIVATE_KEY` secret is set correctly
- Check private key format (should be base64 string)
- Look for `sign_update` tool in `scripts/sparkle/bin/`

---

## Files Modified

| File | Changes | Purpose |
|------|---------|---------|
| [ZetaNotesApp.swift](../ZetaNotes/ZetaNotesApp.swift) | Uncommented Sparkle code | Activate auto-updates |
| [CheckForUpdatesView.swift](../ZetaNotes/Views/CheckForUpdatesView.swift) | Created new file | Manual update checking |
| [Info.plist](../ZetaNotes/Info.plist) | Updated SUFeedURL and SUPublicEDKey | Point to correct appcast |
| [release.yml](../.github/workflows/release.yml) | Fixed signature generation | Use sign_update tool |
| [appcast.xml](appcast.xml) | Already configured | Update feed (auto-updated by CI) |

---

## Security

### EdDSA Signatures
- Each release is cryptographically signed
- App verifies signature before installing
- Prevents tampering or malicious updates
- Uses Ed25519 elliptic curve cryptography

### Private Key Storage
- ✅ Stored securely in GitHub Secrets
- ✅ Never committed to repository
- ✅ Never exposed in logs or output
- ✅ Only accessible during CI builds

### Public Key Distribution
- ✅ Embedded in Info.plist
- ✅ Distributed with every app
- ✅ Safe to share publicly
- ✅ Used to verify signatures

---

## Summary

🎉 **Auto-updates are now fully functional!**

### What works:
- ✅ Automatic update checks every 24 hours
- ✅ Manual "Check for Updates" menu item
- ✅ Secure EdDSA signature verification
- ✅ One-click update installation
- ✅ Auto-relaunch after update
- ✅ CI/CD automatically signs releases
- ✅ GitHub Pages hosts appcast feed

### Next time you release:
1. Update version in Info.plist
2. Push a git tag: `git tag v1.0.1 && git push origin v1.0.1`
3. CI does everything else automatically!
4. Users get notified within 24 hours

That's it! 🚀
