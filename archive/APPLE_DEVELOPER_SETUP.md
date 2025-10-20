# Apple Developer Program Setup for ZetaNotes

This guide walks you through setting up code signing and notarization for ZetaNotes with your Apple Developer Program account.

## Overview

With an Apple Developer Program membership ($99/year), you can:

- ✅ **Code sign** your app with a verified Apple Developer certificate
- ✅ **Notarize** your app through Apple's notarization service
- ✅ **Distribute** without security warnings or "right-click to open" workarounds
- ✅ **Enable automatic updates** through Sparkle with no user friction
- ✅ **Build trust** - users can double-click to install like any Mac app

## Prerequisites

1. **Apple Developer Program** membership
   - Enroll at: https://developer.apple.com/programs/
   - Cost: $99/year
   - Processing time: 1-2 business days

2. **Xcode** installed (latest version recommended)
   - Download from Mac App Store

3. **Xcode Command Line Tools** installed
   ```bash
   xcode-select --install
   ```

## Step 1: Get Your Developer Certificate

### 1.1 Sign in to Xcode with your Apple ID

1. Open Xcode
2. Go to **Xcode → Settings → Accounts**
3. Click **+** and sign in with your Apple ID (the one enrolled in Apple Developer Program)
4. Select your team and click **Download Manual Profiles**

### 1.2 Verify Your Certificate

1. Open **Keychain Access** app
2. Select **login** keychain → **My Certificates**
3. You should see:
   - **Apple Development** certificate (for development builds)
   - **Apple Distribution** or **Developer ID Application** certificate (for release builds)

If you don't see these certificates:
1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click **+** to create a new certificate
3. Choose **Developer ID Application** for distributing outside the Mac App Store
4. Follow the instructions to generate and download the certificate
5. Double-click the downloaded certificate to install it in Keychain

## Step 2: Configure ZetaNotes Project

### 2.1 Open Project Settings

1. Open `ZetaNotes.xcodeproj` in Xcode
2. Select the **ZetaNotes** project in the navigator
3. Select the **ZetaNotes** target
4. Go to **Signing & Capabilities** tab

### 2.2 Configure Signing

1. Enable **Automatically manage signing**
2. Select your **Team** from the dropdown (your Apple Developer account)
3. Xcode will automatically:
   - Select the correct certificate
   - Generate provisioning profiles
   - Configure bundle identifier

**Important:** Your bundle identifier should be unique:
- Current: `com.zetanotes.ZetaNotes`
- You can change this to match your developer account (e.g., `com.yourcompany.ZetaNotes`)

### 2.3 Verify Entitlements

The project is already configured with proper entitlements in `ZetaNotes/ZetaNotes.entitlements`:

```xml
- App Sandbox: Enabled
- Network Client: Enabled (for model downloads)
- Hardened Runtime: Enabled
- File Access: User-selected files
```

## Step 3: Get Your Team ID

You'll need your Team ID for CI/CD configuration:

1. Go to https://developer.apple.com/account
2. Click **Membership** in the sidebar
3. Your **Team ID** is shown (10-character alphanumeric code)
4. Save this - you'll need it for GitHub Actions

## Step 4: Create an App-Specific Password

For notarization via command line and CI:

1. Go to https://appleid.apple.com
2. Sign in with your Apple ID
3. In the **Security** section, click **App-Specific Passwords**
4. Click **+** or **Generate Password**
5. Enter a label: "ZetaNotes Notarization"
6. Copy the generated password (you can't view it again!)
7. Save it securely - you'll need it for CI/CD

## Step 5: Export Certificates for CI/CD

To sign and notarize in GitHub Actions, you need to export your certificates:

### 5.1 Export Developer ID Certificate

1. Open **Keychain Access**
2. Select **login** keychain → **My Certificates**
3. Find **Developer ID Application: [Your Name] ([Team ID])**
4. Right-click and select **Export "Developer ID Application..."**
5. Save as `Certificates.p12`
6. Set a strong password (you'll need this for GitHub Secrets)

### 5.2 Prepare Certificate for GitHub Secrets

```bash
# Convert to base64 for GitHub Secrets
base64 -i Certificates.p12 -o Certificates.base64.txt

# Print to terminal (you'll copy this to GitHub Secrets)
cat Certificates.base64.txt
```

## Step 6: Configure GitHub Secrets

Add these secrets to your GitHub repository:

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `APPLE_CERTIFICATE_BASE64` | Output from step 5.2 | Base64-encoded .p12 certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password from step 5.1 | Password for the .p12 file |
| `APPLE_ID` | your@email.com | Your Apple ID email |
| `APPLE_TEAM_ID` | ABC1234DEF | Your 10-character Team ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | xxxx-xxxx-xxxx-xxxx | App-specific password from step 4 |
| `SPARKLE_PRIVATE_KEY` | (existing) | Keep your existing Sparkle signing key |
| `PUBLIC_REPO_TOKEN` | (existing) | Keep your existing GitHub token |

## Step 7: Update Xcode Project (One-Time)

Update the Development Team ID in the project file:

1. Open `ZetaNotes.xcodeproj/project.pbxproj` in a text editor
2. Find the line: `DEVELOPMENT_TEAM = "";`
3. Replace with: `DEVELOPMENT_TEAM = "YOUR_TEAM_ID";` (from Step 3)
4. Save the file

Or use Xcode GUI (easier):
1. Open project in Xcode
2. Select target → Signing & Capabilities
3. Choose your team from dropdown
4. Xcode will update the project file automatically

## Step 8: Test Local Signing

Before pushing to GitHub, test signing locally:

```bash
cd /path/to/zetanotes-dev

# Build and sign
xcodebuild clean build \
  -project ZetaNotes.xcodeproj \
  -scheme ZetaNotes \
  -configuration Release

# Verify signature
codesign --verify --verbose=4 \
  ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/ZetaNotes.app

# Check if it's signed with your Developer ID
codesign -dvv \
  ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/ZetaNotes.app \
  | grep "Authority"
```

You should see:
```
Authority=Developer ID Application: Your Name (TEAM_ID)
Authority=Developer ID Certification Authority
Authority=Apple Root CA
```

## Step 9: Test Local Notarization

Test notarization before CI:

```bash
# Create a ZIP for notarization
cd ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release
ditto -c -k --keepParent ZetaNotes.app ZetaNotes.zip

# Submit for notarization
xcrun notarytool submit ZetaNotes.zip \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  --wait

# If successful, staple the ticket
xcrun stapler staple ZetaNotes.app

# Verify
xcrun stapler validate ZetaNotes.app
spctl -a -v ZetaNotes.app
```

Expected output:
```
ZetaNotes.app: accepted
source=Notarized Developer ID
```

## Step 10: Update Release Script

The `scripts/release.sh` has been updated to:

- ✅ Sign with Developer ID certificate (automatic if team configured)
- ✅ Notarize with Apple
- ✅ Staple notarization ticket to DMG
- ✅ Remove all unsigned app workarounds

Run it locally to test:

```bash
./scripts/release.sh 1.0.1
```

## Step 11: Deploy via GitHub Actions

Once everything is configured:

1. Commit your changes:
   ```bash
   git add .
   git commit -m "Configure Apple Developer Program signing"
   git push
   ```

2. Create a new release:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

3. GitHub Actions will:
   - Build the app
   - Sign with your Developer ID
   - Notarize with Apple
   - Create DMG
   - Upload to GitHub Releases
   - Update appcast.xml

4. Monitor the workflow:
   - Go to **Actions** tab in GitHub
   - Watch the "Build and Release" workflow
   - Check for any errors

## Troubleshooting

### "No signing certificate found"

**Solution:**
1. Ensure you've signed in to Xcode with your Apple ID
2. Download manual profiles in Xcode Settings → Accounts
3. Verify certificate exists in Keychain Access

### "Invalid Active Developer Path"

**Solution:**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcode-select --install
```

### Notarization fails with "Invalid Code Signature"

**Solution:**
1. Ensure Hardened Runtime is enabled
2. Check entitlements are correct
3. Verify all embedded frameworks are signed

### "Could not find Developer ID certificate"

**Solution:**
1. Create a new certificate at https://developer.apple.com/account/resources/certificates/
2. Choose "Developer ID Application"
3. Download and install in Keychain

### GitHub Actions fails: "No profile for team"

**Solution:**
- Ensure `APPLE_TEAM_ID` GitHub secret is set correctly
- Verify `DEVELOPMENT_TEAM` is set in project.pbxproj

### Notarization stuck in "In Progress"

**Solution:**
- Can take 5-30 minutes
- Check status: `xcrun notarytool history --apple-id your@email.com --team-id TEAM_ID`
- Get details: `xcrun notarytool log [submission-id] --apple-id your@email.com --team-id TEAM_ID`

## Next Steps

Once configured, your release process becomes:

1. Update version number
2. Push a git tag
3. GitHub Actions automatically:
   - Builds
   - Signs
   - Notarizes
   - Distributes

Users can now:
- ✅ Double-click DMG to install (no right-click needed!)
- ✅ Drag to Applications folder
- ✅ Open normally (no security warnings!)
- ✅ Receive automatic updates via Sparkle

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
- [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)

## Support

Need help? Open an issue on GitHub with:
- Error messages
- Xcode version
- macOS version
- Steps you've tried

---

**Note:** Keep your certificates and App-Specific Password secure. Never commit them to version control!
