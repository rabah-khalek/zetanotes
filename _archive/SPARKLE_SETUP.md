# Sparkle Auto-Update Setup Guide

This guide will help you complete the Sparkle integration for ZetaNotes.

## What's Been Done ✅

The following has been automatically configured:

1. ✅ **EdDSA Signing Keys Generated**
   - Public key added to Info.plist
   - Private key stored in macOS Keychain

2. ✅ **Info.plist Updated**
   - SUFeedURL configured (points to appcast.xml)
   - SUPublicEDKey added
   - Auto-update settings enabled

3. ✅ **App Code Modified**
   - Sparkle framework import added
   - SPUStandardUpdaterController initialized
   - "Check for Updates..." menu item added

4. ✅ **Appcast Feed Created**
   - `docs/appcast.xml` created with initial v1.0 entry

5. ✅ **Release Script Created**
   - `scripts/release_with_sparkle.sh` automates entire release process

6. ✅ **Documentation Updated**
   - DISTRIBUTION.md includes Sparkle workflow
   - Troubleshooting section added

## What You Need to Do 🔧

### Step 1: Add Sparkle Framework to Xcode (2 minutes)

Since Swift Package Manager dependencies can't be added via command line easily, you need to add Sparkle manually in Xcode:

1. **Open the project:**
   ```bash
   open ZetaNotes.xcodeproj
   ```

2. **Add Sparkle package:**
   - Click on the project in the navigator (blue icon)
   - Select the "ZetaNotes" target
   - Go to "Package Dependencies" tab
   - Click the "+" button
   - Enter URL: `https://github.com/sparkle-project/Sparkle`
   - Click "Add Package"
   - Select version: "Up to Next Major Version" (2.0.0 < 3.0.0)
   - Click "Add Package"
   - Make sure "Sparkle" is added to the ZetaNotes target
   - Click "Add Package"

3. **Build the project to verify:**
   ```bash
   # Command line build test
   xcodebuild -scheme ZetaNotes -configuration Debug build
   ```

   Or just press `Cmd+B` in Xcode.

### Step 2: Update GitHub URLs (1 minute)

Replace placeholder URLs with your actual GitHub username:

1. **Update Info.plist:**
   ```bash
   # Replace YOUR_USERNAME with your GitHub username
   sed -i '' 's/YOUR_USERNAME/your-github-username/g' ZetaNotes/Info.plist
   ```

2. **Update appcast.xml:**
   ```bash
   sed -i '' 's/YOUR_USERNAME/your-github-username/g' docs/appcast.xml
   ```

3. **Update release script:**
   ```bash
   sed -i '' 's/YOUR_USERNAME/your-github-username/g' scripts/release_with_sparkle.sh
   ```

4. **Update DISTRIBUTION.md:**
   ```bash
   sed -i '' 's/YOUR_USERNAME/your-github-username/g' DISTRIBUTION.md
   ```

### Step 3: Update Developer Certificate Name (1 minute)

Update the release script with your actual Developer ID certificate:

1. **Find your certificate name:**
   ```bash
   security find-identity -v -p codesigning
   ```

   Look for a line like:
   ```
   1) ABCD1234... "Developer ID Application: Your Name (TEAM123)"
   ```

2. **Update the script:**
   Edit `scripts/release_with_sparkle.sh` and replace:
   ```bash
   CERT_NAME="Developer ID Application: Your Name (TEAM_ID)"
   ```

   With your actual certificate name (the part in quotes).

### Step 4: Test the Build (2 minutes)

1. **Build and run the app:**
   ```bash
   # In Xcode, press Cmd+R to build and run
   ```

2. **Verify the menu item exists:**
   - Once the app launches
   - Click "ZetaNotes" in the menu bar
   - You should see "Check for Updates..." menu item

3. **Test the update check:**
   - Click "Check for Updates..."
   - You should see a dialog saying "You're up to date!" (since there are no newer versions)

## How to Release Updates 🚀

Once everything is set up, releasing updates is easy:

### For Each New Release:

1. **Update version in Xcode:**
   - Project → General → Version (e.g., 1.0.1)
   - Project → General → Build (increment by 1)

2. **Run the release script:**
   ```bash
   ./scripts/release_with_sparkle.sh 1.0.1
   ```

3. **Upload to GitHub:**
   - Create a new release: https://github.com/YOUR_USERNAME/zetanotes/releases/new
   - Tag: `v1.0.1`
   - Upload the generated DMG from `~/Desktop/ZetaNotes-Release/`

4. **Publish the appcast:**
   ```bash
   git add docs/appcast.xml
   git commit -m "Update appcast for v1.0.1"
   git push origin main
   ```

5. **Done!** 🎉
   - Users with v1.0 will be automatically notified
   - They can download and install the update with one click

## How Users Experience Updates 👥

1. **Automatic check on launch** (once per day)
   - App checks `appcast.xml` in the background

2. **Update notification appears**
   - Shows version number and release notes
   - "Install Update" and "Skip This Version" buttons

3. **One-click installation**
   - User clicks "Install Update"
   - DMG downloads automatically
   - App quits, installs update, and relaunches

4. **Seamless experience**
   - No manual downloading
   - No App Store required
   - Cryptographically verified (EdDSA signature)

## Configuration Details 📋

### Update Check Settings (in Info.plist):

- **SUFeedURL**: Where to check for updates (your appcast.xml)
- **SUEnableAutomaticChecks**: `true` (check automatically)
- **SUScheduledCheckInterval**: `86400` (check once per day)
- **SUAllowsAutomaticUpdates**: `true` (allow one-click updates)
- **SUAutomaticallyUpdate**: `false` (require user approval)

### Security:

- **EdDSA Signature**: Each DMG is cryptographically signed
- **Public Key**: Embedded in app (SUPublicEDKey in Info.plist)
- **Private Key**: Stored in your macOS Keychain
- **Verification**: App verifies DMG signature before installing

## Troubleshooting 🔧

### "Module 'Sparkle' not found" error

You forgot Step 1. Add Sparkle via Xcode's Package Dependencies.

### "You're up to date" when you expect an update

1. Check appcast.xml is accessible:
   ```bash
   curl https://YOUR_USERNAME.github.io/zetanotes/appcast.xml
   ```

2. Verify version numbers:
   - Appcast version > current app version
   - Check CFBundleShortVersionString in Info.plist

3. Check Sparkle logs:
   - Open Console.app
   - Filter: `process:ZetaNotes AND sparkle`

### Update downloads but won't install

1. Verify EdDSA signature:
   ```bash
   ./scripts/sparkle/bin/sign_update ~/path/to/DMG.dmg
   ```

2. Ensure signature in appcast.xml matches

3. Check DMG is properly signed:
   ```bash
   codesign --verify --deep --strict ~/path/to/DMG.dmg
   ```

## Testing Updates 🧪

To test the update mechanism before releasing:

1. **Create a test version:**
   - Change version to 1.0.1 in Xcode
   - Build the app
   - Run `./scripts/release_with_sparkle.sh 1.0.1`

2. **Update your appcast.xml:**
   - Already done by the script

3. **Test locally:**
   - Install the current version (1.0)
   - Push the updated appcast.xml to GitHub Pages
   - Run the app
   - Click "Check for Updates..."
   - Should show 1.0.1 is available

4. **Clean up:**
   - Revert version back to 1.0
   - Remove test entry from appcast.xml

## Next Steps 📝

1. ✅ Complete Step 1 (Add Sparkle to Xcode)
2. ✅ Complete Step 2 (Update GitHub URLs)
3. ✅ Complete Step 3 (Update certificate name)
4. ✅ Complete Step 4 (Test build)
5. 🚀 Create your first release!

## Resources 📚

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle GitHub](https://github.com/sparkle-project/Sparkle)
- [Publishing Updates Guide](https://sparkle-project.org/documentation/publishing/)

## Questions?

Check the troubleshooting sections in:
- This file (above)
- [DISTRIBUTION.md](DISTRIBUTION.md) (Sparkle section)

---

**Summary**: You're 90% done! Just add the Sparkle package in Xcode, update URLs, and you're ready to release updates with automatic notifications! 🎉
