# ZetaNotes Release Guide

Quick reference for releasing new versions of ZetaNotes.

---

## Prerequisites (One-Time Setup)

### 1. GitHub Secrets Configured

Verify these secrets exist in your repository:

```
Settings → Secrets and variables → Actions
```

Required secrets:
- **SPARKLE_PRIVATE_KEY**: `9sYT3LfxNMW6NoEd8/ygsU83lzb6gJctwg/4lWMFa08=`
- **PUBLIC_REPO_TOKEN**: GitHub PAT with `repo` scope for pushing to public repo

### 2. GitHub Pages Enabled

In `rabah-khalek/zetanotes` (public repo):
```
Settings → Pages → Source: Deploy from branch (main)
```

Appcast URL: https://rabah-khalek.github.io/zetanotes/appcast.xml

---

## Release Process

### Step 1: Update Version Number

Edit `ZetaNotes/Info.plist`:

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.1</string>  <!-- Update this -->

<key>CFBundleVersion</key>
<string>2</string>  <!-- Increment build number -->
```

### Step 2: Test Locally

```bash
./run
```

Verify:
- App launches successfully
- All features work
- No crashes or errors

### Step 3: Commit and Tag

```bash
# Commit version changes
git add ZetaNotes/Info.plist
git commit -m "Bump version to 1.0.1"

# Create tag
git tag v1.0.1

# Push everything
git push origin main
git push origin v1.0.1
```

### Step 4: Wait for CI

GitHub Actions will automatically:
1. Build llama.cpp (5-10 min)
2. Build ZetaNotes app (2-3 min)
3. Create DMG installer
4. Sign with EdDSA signature
5. Create release in public repo
6. Update appcast.xml
7. Publish to GitHub Pages

**Total time**: ~10-15 minutes

Monitor progress:
```
Actions → release workflow
```

### Step 5: Verify Release

1. **Check public repo**: https://github.com/rabah-khalek/zetanotes/releases
   - Release should exist with tag `v1.0.1`
   - DMG file should be attached
   - SHA256 checksum included

2. **Check appcast**: https://rabah-khalek.github.io/zetanotes/appcast.xml
   - Should list new version
   - Should have EdDSA signature
   - Download URL should point to new DMG

3. **Test update flow**:
   - Install previous version
   - Launch app
   - Go to: ZetaNotes → Check for Updates...
   - Should show update available
   - Install and verify it works

---

## Version Numbering

Use [Semantic Versioning](https://semver.org/):

- **Major** (1.0.0 → 2.0.0): Breaking changes, major new features
- **Minor** (1.0.0 → 1.1.0): New features, no breaking changes
- **Patch** (1.0.0 → 1.0.1): Bug fixes only

Examples:
- `1.0.0` - Initial release
- `1.0.1` - Bug fix release
- `1.1.0` - New feature (e.g., added export functionality)
- `2.0.0` - Major update (e.g., complete UI redesign)

---

## CI Workflow Overview

The release workflow does:

```yaml
1. Setup Environment
   - Install Xcode
   - Install create-dmg
   - Setup Sparkle tools

2. Build llama.cpp
   - Clone llama.cpp repo
   - Build with Metal support
   - Create libraries

3. Build ZetaNotes
   - Run release.sh script
   - Skip Paddle checks (development mode)
   - Create DMG installer

4. Sign Release
   - Use sign_update tool
   - Generate EdDSA signature
   - Verify signature created

5. Publish Release
   - Create GitHub release in public repo
   - Upload DMG + SHA256
   - Include installation instructions

6. Update Docs
   - Update appcast.xml with new version
   - Update download links
   - Push to GitHub Pages
```

---

## Troubleshooting

### Build Fails

**Check workflow logs**:
```
Actions → release workflow → Click on failed run
```

Common issues:
- **llama.cpp build fails**: Usually CMake or compiler issues
- **App build fails**: Check for Swift compile errors
- **Signature generation fails**: Verify SPARKLE_PRIVATE_KEY secret is set

### Updates Not Working

**Verify configuration**:

1. Check Info.plist:
   ```xml
   <key>SUFeedURL</key>
   <string>https://rabah-khalek.github.io/zetanotes/appcast.xml</string>
   ```

2. Check appcast is accessible:
   ```bash
   curl https://rabah-khalek.github.io/zetanotes/appcast.xml
   ```

3. Check version comparison:
   - App version (Info.plist): `1.0.0`
   - Appcast version: `1.0.1`
   - App version must be LOWER than appcast version

4. Clear cached update state:
   ```bash
   defaults delete com.zetanotes.ZetaNotes
   ```

### Signature Verification Fails

**Check key match**:

Public key in Info.plist:
```
OaS6XLRg52NaUmFiFX46nv1MlVb2gicyeSuxemv9N5I=
```

Must match the public key from private key:
```
9sYT3LfxNMW6NoEd8/ygsU83lzb6gJctwg/4lWMFa08=
```

If keys don't match:
1. Regenerate keys: `./scripts/setup-sparkle-keys.sh`
2. Update public key in Info.plist
3. Update SPARKLE_PRIVATE_KEY secret in GitHub
4. Re-release all versions

---

## Release Checklist

Use this checklist for each release:

- [ ] Version number updated in Info.plist
- [ ] Build number incremented
- [ ] Tested locally with `./run`
- [ ] All features working
- [ ] Committed changes
- [ ] Tagged release: `git tag vX.Y.Z`
- [ ] Pushed tag: `git push origin vX.Y.Z`
- [ ] CI workflow completed successfully
- [ ] Release visible in public repo
- [ ] DMG file attached to release
- [ ] appcast.xml updated on GitHub Pages
- [ ] Tested update flow from previous version
- [ ] Release notes added to GitHub release (optional)

---

## Quick Commands

```bash
# Build and test locally
./run

# Check current version
grep -A 1 "CFBundleShortVersionString" ZetaNotes/Info.plist

# Create release
git add ZetaNotes/Info.plist
git commit -m "Bump version to X.Y.Z"
git tag vX.Y.Z
git push origin main vX.Y.Z

# Monitor CI
# Go to: https://github.com/YOUR_USERNAME/zetanotes-dev/actions

# Check appcast
curl https://rabah-khalek.github.io/zetanotes/appcast.xml

# Clear update cache (for testing)
defaults delete com.zetanotes.ZetaNotes
```

---

## Support

For more details, see:
- [Auto-Update Flow Documentation](docs/AUTO_UPDATE_FLOW.md)
- [Sparkle Setup Guide](docs/SPARKLE_SETUP.md)
- [Release Workflow](.github/workflows/release.yml)

---

## Summary

**Releasing a new version is simple**:

1. Update version in Info.plist
2. Tag and push: `git tag v1.0.1 && git push origin v1.0.1`
3. Wait ~15 minutes for CI
4. Users automatically get notified!

That's it! 🚀
