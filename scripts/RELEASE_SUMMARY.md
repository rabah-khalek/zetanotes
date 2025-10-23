# Release Script Implementation Summary

## ✅ What Was Implemented

The `release.sh` script now provides a **complete, unified workflow** that works in both local and CI environments.

### Key Features Added

#### 1. **Sparkle EdDSA Signature Generation** ✅
- **Local**: Reads private key from macOS Keychain (account: `zetanotes-sparkle`)
- **CI**: Reads private key from `SPARKLE_PRIVATE_KEY` environment variable
- Automatically detects which mode to use
- Generates and saves signature for appcast.xml updates
- Creates `.sparkle-signature` file with signature info

#### 2. **Improved Notarization Workflow** ✅
- Removed unreliable `--wait` flag
- Implements manual polling (every 10 seconds, max 10 minutes)
- Better timeout handling and progress indicators
- Automatic stapling when notarization succeeds
- Verification of stapled ticket with `spctl`
- Detailed error logs saved to `notarization-failure.json`

#### 3. **Environment Detection** ✅
- Auto-detects GitHub Actions via `GITHUB_ACTIONS` env var
- Adjusts certificate detection for CI vs local
- Different signing identity patterns
- Appropriate warnings for missing credentials

#### 4. **Appcast Metadata Generation** ✅
- Creates `.appcast-info` file with all necessary data
- Includes version, file size, SHA256, Sparkle signature
- Provides ready-to-use XML snippet for appcast.xml
- Shows download URL for GitHub Releases

#### 5. **Comprehensive Checks** ✅
- Verifies Developer ID certificate exists
- Checks for required tools (create-dmg)
- Validates Sparkle tools availability
- Confirms notarization credentials are set
- Different warnings for CI vs local environments

## How It Works

### Local Build Flow

```bash
./scripts/release.sh 1.0.0
```

**Environment Variables Required:**
```bash
export APPLE_ID="your-apple-id@example.com"
export APPLE_TEAM_ID="HDA4C6CU89"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
# SPARKLE_PRIVATE_KEY not needed - uses Keychain
```

**Process:**
1. ✅ Builds app with Xcode
2. ✅ Signs all components (app, Sparkle, libraries)
3. ✅ Verifies signatures
4. ✅ Creates DMG
5. ✅ Signs DMG
6. ✅ **Generates Sparkle signature from Keychain**
7. ✅ Submits for notarization
8. ✅ Polls status every 10 seconds
9. ✅ Staples ticket when accepted
10. ✅ Creates metadata files

**Output Files:**
- `ZetaNotes-v1.0.0.dmg` - Notarized DMG
- `ZetaNotes-v1.0.0.dmg.sha256` - Checksum
- `ZetaNotes-v1.0.0.dmg.sparkle-signature` - Sparkle signature
- `ZetaNotes-v1.0.0.dmg.appcast-info` - Appcast metadata
- `notarization-submit.log` - Submission log
- `notarization-status.log` - Final status

### CI Build Flow

```yaml
- name: Build, sign, and notarize release
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
    APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
    SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}  # ← Used by release.sh
  run: |
    ./scripts/release.sh ${{ steps.version.outputs.VERSION }}
```

**Process:**
- Same as local, but uses `SPARKLE_PRIVATE_KEY` env var instead of Keychain
- Certificate detection uses "Developer ID Application" (without name)
- All other steps identical

**CI Workflow Simplification:**
The CI workflow's separate Sparkle signing step (lines 188-298 in release.yml) is now **redundant** because release.sh handles it automatically. You can optionally remove that step and rely on release.sh entirely.

## Environment Variables Reference

### Required for Notarization (Both Local & CI)
- `APPLE_ID` - Your Apple ID email
- `APPLE_TEAM_ID` - Your 10-character team ID (e.g., HDA4C6CU89)
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password from appleid.apple.com

### Optional for Sparkle (Environment-specific)
- `SPARKLE_PRIVATE_KEY` - **(CI only)** Private EdDSA key as string
- `SPARKLE_ACCOUNT_NAME` - **(Local only)** Keychain account name (default: zetanotes-sparkle)

### Auto-detected
- `GITHUB_ACTIONS` - Set by GitHub CI, triggers CI mode

## Comparison: Before vs After

### Before (Original release.sh)
❌ No Sparkle signature generation
❌ Notarization could timeout silently
❌ No verification of notarization ticket
❌ Manual appcast.xml updates required
❌ No CI support for Sparkle signing

### After (Updated release.sh)
✅ Automatic Sparkle signature (both local & CI)
✅ Reliable notarization with polling
✅ Automatic stapling and verification
✅ Generates ready-to-use appcast metadata
✅ Single script works in local & CI environments

## GitHub Secrets Setup

For CI builds, ensure these secrets are set in your repository:

1. **APPLE_ID** - Your Apple ID email
2. **APPLE_TEAM_ID** - Your team ID (HDA4C6CU89)
3. **APPLE_APP_SPECIFIC_PASSWORD** - App-specific password
4. **SPARKLE_PRIVATE_KEY** - Private EdDSA key from `./scripts/setup-sparkle-keys.sh`
5. **APPLE_CERTIFICATE_BASE64** - Base64-encoded .p12 certificate
6. **APPLE_CERTIFICATE_PASSWORD** - Certificate password
7. **PUBLIC_REPO_TOKEN** - GitHub PAT for publishing to public repo

## Verification Checklist

After running release.sh, verify:

- [ ] **DMG is notarized:**
  ```bash
  spctl -a -vv -t install ZetaNotes-v1.0.0.dmg
  # Should show: source=Notarized Developer ID
  ```

- [ ] **Sparkle signature exists:**
  ```bash
  cat ZetaNotes-v1.0.0.dmg.sparkle-signature
  # Should show: sparkle:edSignature="[long base64 string]"
  ```

- [ ] **All metadata files created:**
  ```bash
  ls -la ZetaNotes-v1.0.0.dmg*
  # Should show: .dmg, .sha256, .sparkle-signature, .appcast-info
  ```

- [ ] **Notarization logs available:**
  ```bash
  cat notarization-status.log
  # Should contain: status: Accepted
  ```

## Next Steps for Users

### 1. Upload to GitHub Releases
```bash
gh release create v1.0.0 \
  --title "ZetaNotes v1.0.0" \
  --notes "Release notes" \
  ZetaNotes-v1.0.0.dmg \
  ZetaNotes-v1.0.0.dmg.sha256
```

### 2. Update docs/appcast.xml
Copy the XML snippet from `ZetaNotes-v1.0.0.dmg.appcast-info`

### 3. Commit and push appcast
```bash
git add docs/appcast.xml
git commit -m "Release v1.0.0"
git push
```

## Troubleshooting

### "Sparkle signing failed - key may not be in Keychain"
**Solution:** Run `./scripts/setup-sparkle-keys.sh` to generate keys

### "Notarization timed out after 600 seconds"
**Solution:** Check status manually:
```bash
xcrun notarytool info SUBMISSION-ID \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD"
```

### "No Developer ID certificate found"
**Solution:** Install Developer ID Application certificate in Keychain

### In CI: "Could not extract Sparkle signature"
**Solution:** Verify `SPARKLE_PRIVATE_KEY` secret is set correctly in GitHub

## Optional: Simplify CI Workflow

Since release.sh now handles Sparkle signing, you can remove the duplicate Sparkle signing step from `.github/workflows/release.yml` (lines 188-298). The workflow will be cleaner and use release.sh for everything.

## Documentation

- **Quick Guide:** [QUICK_RELEASE_GUIDE.md](./QUICK_RELEASE_GUIDE.md)
- **Full Details:** [RELEASE_WORKFLOW.md](./RELEASE_WORKFLOW.md)
- **This Summary:** [RELEASE_SUMMARY.md](./RELEASE_SUMMARY.md)

## Conclusion

The updated `release.sh` provides a **complete, production-ready release workflow** that:

✅ Works identically in local and CI environments
✅ Handles all signing (code, DMG, Sparkle)
✅ Reliably notarizes with Apple
✅ Generates all necessary metadata
✅ Provides clear error messages and troubleshooting

**You can now create fully-signed, notarized, update-enabled releases with a single command:**
```bash
./scripts/release.sh 1.0.0
```
