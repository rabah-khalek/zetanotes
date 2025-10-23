# ZetaNotes Release Workflow

Complete guide for creating signed, notarized, and update-ready releases.

## Prerequisites

### 1. Apple Developer Certificate
- Developer ID Application certificate installed in Keychain
- Valid Apple Developer Program membership

### 2. Required Tools
```bash
brew install create-dmg
```

### 3. Sparkle EdDSA Keys
Generate keys for signing updates (one-time setup):

```bash
./scripts/setup-sparkle-keys.sh
```

This will:
- Generate EdDSA key pair in macOS Keychain
- Show public key to add to `ZetaNotes/Info.plist`
- Show private key to store in GitHub Secrets

**Important:** The public key should already be in `Info.plist`:
```xml
<key>SUPublicEDKey</key>
<string>OaS6XLRg52NaUmFiFX46nv1MlVb2gicyeSuxemv9N5I=</string>
```

### 4. Notarization Credentials
Set these environment variables:

```bash
export APPLE_ID="your-apple-id@example.com"
export APPLE_TEAM_ID="HDA4C6CU89"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

Get app-specific password from: https://appleid.apple.com/account/manage

## Local Release Build

### Full Release (with notarization)
```bash
./scripts/release.sh 1.0.0
```

### With llama.cpp rebuild
```bash
./scripts/release.sh 1.0.0 rebuild
```

### What the script does:

1. ✅ **Builds the app** with Xcode in Release configuration
2. ✅ **Signs all components** with Developer ID:
   - Main app bundle
   - Sparkle framework and XPC services
   - llama.cpp libraries
3. ✅ **Verifies signatures** using verify-signatures.sh
4. ✅ **Creates DMG** with app icon and layout
5. ✅ **Signs DMG** with Developer ID + hardened runtime
6. ✅ **Generates Sparkle EdDSA signature** for update security
7. ✅ **Submits to Apple for notarization**
8. ✅ **Waits for notarization** (polls every 10 seconds, max 10 minutes)
9. ✅ **Staples notarization ticket** to DMG
10. ✅ **Verifies final DMG** is properly notarized
11. ✅ **Generates checksums** (SHA256)
12. ✅ **Creates appcast info** for updating docs/appcast.xml

## Output Files

After successful build in `releases/ZetaNotes-Release-YYYYMMDD-HHMMSS/`:

- `ZetaNotes-v1.0.0.dmg` - Notarized DMG for distribution
- `ZetaNotes-v1.0.0.dmg.sha256` - SHA256 checksum
- `ZetaNotes-v1.0.0.dmg.sparkle-signature` - Sparkle EdDSA signature
- `ZetaNotes-v1.0.0.dmg.appcast-info` - Info for appcast.xml
- `notarization-submit.log` - Notarization submission log
- `notarization-status.log` - Final notarization status
- `ZetaNotes.app/` - Built app bundle

## Post-Release Steps

### 1. Upload to GitHub Releases

```bash
cd releases/ZetaNotes-Release-YYYYMMDD-HHMMSS/

# Create GitHub release
gh release create v1.0.0 \
  --title "ZetaNotes v1.0.0" \
  --notes "Release notes here" \
  ZetaNotes-v1.0.0.dmg \
  ZetaNotes-v1.0.0.dmg.sha256
```

### 2. Update Appcast XML

Copy the info from `ZetaNotes-v1.0.0.dmg.appcast-info` and update `docs/appcast.xml`:

```xml
<item>
    <title>Version 1.0.0</title>
    <sparkle:version>1.0.0</sparkle:version>
    <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
    <description><![CDATA[
        <h2>What's New</h2>
        <ul>
            <li>Feature 1</li>
            <li>Feature 2</li>
        </ul>
    ]]></description>
    <pubDate>Mon, 21 Oct 2025 12:00:00 +0000</pubDate>
    <enclosure
        url="https://github.com/rabah-khalek/zetanotes/releases/download/v1.0.0/ZetaNotes-v1.0.0.dmg"
        sparkle:version="1.0.0"
        sparkle:shortVersionString="1.0.0"
        length="3807568"
        type="application/octet-stream"
        sparkle:edSignature="PASTE_SIGNATURE_HERE" />
    <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
</item>
```

### 3. Commit and Push Appcast

```bash
git add docs/appcast.xml
git commit -m "Update appcast for v1.0.0"
git push
```

Users will now receive update notifications!

## CI/CD with GitHub Actions

The script automatically detects GitHub Actions environment and adjusts accordingly.

### Required GitHub Secrets

Set these in your repository settings:

- `APPLE_ID` - Your Apple ID email
- `APPLE_TEAM_ID` - Your team ID (e.g., HDA4C6CU89)
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password
- `SPARKLE_PRIVATE_KEY` - Private EdDSA key from setup-sparkle-keys.sh
- Certificate imported to GitHub Actions runner

### CI Behavior Differences

- Certificate detection uses "Developer ID Application" (without name)
- Sparkle signing works if private key is available in Keychain
- All other steps identical to local builds

## Troubleshooting

### Notarization Failed

Check the error log:
```bash
cat releases/ZetaNotes-Release-*/notarization-failure.json
```

Common issues:
- **Ad-hoc signatures**: Ensure all components are signed with Developer ID
- **Missing hardened runtime**: Added automatically by release.sh
- **Invalid entitlements**: Check ZetaNotes.entitlements

### Notarization Timed Out

Check status manually:
```bash
xcrun notarytool info SUBMISSION-ID-HERE \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD"
```

If accepted, staple manually:
```bash
xcrun stapler staple ZetaNotes-v1.0.0.dmg
```

### Sparkle Signature Failed

Check Keychain access:
```bash
# List available keys
./scripts/sparkle/bin/generate_keys --account zetanotes-sparkle -p

# If key not found, run setup again
./scripts/setup-sparkle-keys.sh
```

### DMG Creation Failed

Ensure create-dmg is installed:
```bash
brew install create-dmg
```

### Signature Verification Failed

Run manual verification:
```bash
./scripts/verify-signatures.sh releases/ZetaNotes-Release-*/ZetaNotes.app
```

## Verification Commands

### Check DMG is notarized
```bash
spctl -a -vv -t install ZetaNotes-v1.0.0.dmg
# Should show: source=Notarized Developer ID
```

### Check app signature
```bash
codesign -dvvv ZetaNotes.app
# Should show: Developer ID Application: Your Name (TEAMID)
```

### Check Sparkle components
```bash
codesign -dvvv ZetaNotes.app/Contents/Frameworks/Sparkle.framework
codesign -dvvv ZetaNotes.app/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app
```

### Verify notarization ticket
```bash
stapler validate ZetaNotes-v1.0.0.dmg
# Should show: The validate action worked!
```

## Environment Variables Reference

### Required for Notarization
- `APPLE_ID` - Apple ID email address
- `APPLE_TEAM_ID` - 10-character team ID
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password

### Optional
- `SPARKLE_ACCOUNT_NAME` - Keychain account (default: zetanotes-sparkle)
- `GITHUB_ACTIONS` - Auto-detected in CI

### Auto-detected
- `IS_CI` - Set by release.sh based on GITHUB_ACTIONS
- `SIGNING_IDENTITY` - Certificate name (CI vs local)

## Security Notes

### Never Commit These
- ❌ Private EdDSA key (Sparkle)
- ❌ App-specific password
- ❌ Certificates or private keys
- ❌ Keychain passwords

### Safe to Commit
- ✅ Public EdDSA key (in Info.plist)
- ✅ Appcast XML
- ✅ Release checksums
- ✅ This documentation

### GitHub Secrets
Store sensitive values in GitHub repository secrets, not in code or environment files.

## Release Checklist

- [ ] Update version in Info.plist
- [ ] Test app locally
- [ ] Run `./scripts/release.sh X.Y.Z`
- [ ] Verify notarization succeeded
- [ ] Test DMG installs without warnings
- [ ] Upload to GitHub Releases
- [ ] Update docs/appcast.xml with Sparkle signature
- [ ] Commit and push appcast.xml
- [ ] Test update mechanism from previous version
- [ ] Announce release

## Support

If you encounter issues:

1. Check logs in `releases/ZetaNotes-Release-*/`
2. Run `./scripts/verify-signatures.sh` on the app
3. Review notarization-failure.json if available
4. Check Apple's notarization status in App Store Connect

For Sparkle update issues, see: https://sparkle-project.org/documentation/
