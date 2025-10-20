# Deployment Checklist

Complete guide for deploying ZetaNotes from development to public release.

## Prerequisites ✅

### 1. GitHub Repositories

- [ ] **Private repo exists**: `rabah-khalek/zetanotes-dev` (or current: `notetaker`)
- [ ] **Public repo created**: `rabah-khalek/zetanotes`
- [ ] Public repo has GitHub Pages enabled (Settings → Pages → Deploy from `/docs`)

### 2. Sparkle Keys Generated

```bash
# Download generate_keys tool
curl -L https://github.com/sparkle-project/Sparkle/releases/latest/download/generate_keys.tar.xz -o generate_keys.tar.xz
tar -xf generate_keys.tar.xz
chmod +x generate_keys

# Generate keys
./generate_keys
```

Output:

```
A key has been generated and saved in your keychain.
PrivateKey: [KEEP THIS SECRET - goes in GitHub Secrets]
PublicKey: [ADD THIS TO Info.plist]
```

- [ ] **Private key** saved in GitHub Secrets as `SPARKLE_PRIVATE_KEY`
- [ ] **Public key** added to `ZetaNotes/Info.plist`:

  ```xml
  <key>SUPublicEDKey</key>
  <string>YOUR_PUBLIC_KEY_HERE</string>
  ```

### 3. GitHub Personal Access Token

Create at: <https://github.com/settings/tokens>

- [ ] Token created with `repo` scope
- [ ] Token saved in GitHub Secrets as `PUBLIC_REPO_TOKEN`

### 4. Update App Info.plist

- [ ] `SUFeedURL` points to public repo appcast:

  ```xml
  <key>SUFeedURL</key>
  <string>https://rabah-khalek.github.io/zetanotes/appcast.xml</string>
  ```

- [ ] `SUPublicEDKey` contains your public key
- [ ] `SUEnableAutomaticChecks` set to `true`

## Deployment Steps 🚀

### Step 1: Prepare Development Repo

In your `zetanotes-dev` repo:

- [ ] All code is committed and pushed
- [ ] Version number updated in `Info.plist`
- [ ] `CHANGELOG.md` updated (if you have one)
- [ ] All tests pass
- [ ] Build works locally: `./scripts/release.sh 1.0.0`

### Step 2: Set Up GitHub Secrets

In `zetanotes-dev` repo → Settings → Secrets and variables → Actions:

- [ ] `PUBLIC_REPO_TOKEN` added
- [ ] `SPARKLE_PRIVATE_KEY` added

### Step 3: Set Up Public Repository

Follow `PUBLIC_REPO_SETUP.md`:

- [ ] Public repo created and initialized
- [ ] `docs/` folder created
- [ ] `README.md` updated with public-facing content
- [ ] GitHub Pages enabled from `/docs`
- [ ] Pages deployment successful (visit URL to verify)

### Step 4: Test CI Workflow Locally

Before pushing a tag, verify the build script works:

```bash
cd zetanotes-dev
./scripts/release.sh 1.0.0
```

- [ ] Build completes without errors
- [ ] DMG created in `~/Desktop/ZetaNotes-Release-*/`
- [ ] SHA256 checksum generated
- [ ] App opens correctly from DMG

### Step 5: First Release

#### Option A: Tag-based (Recommended)

```bash
# In zetanotes-dev repo
git tag v1.0.0
git push origin v1.0.0
```

#### Option B: Manual Workflow Dispatch

1. Go to Actions tab in GitHub
2. Select "Build and Release to Public Repo"
3. Click "Run workflow"
4. Enter version: `1.0.0`
5. Click "Run workflow"

### Step 6: Monitor CI Workflow

Watch the workflow run:

- [ ] Checkout completes
- [ ] Build succeeds
- [ ] Sparkle signature generated
- [ ] Release created in public repo
- [ ] Docs updated
- [ ] Workflow completes successfully

### Step 7: Verify Release

Check public repo: <https://github.com/rabah-khalek/zetanotes/releases>

- [ ] Release exists with correct tag
- [ ] DMG file uploaded
- [ ] SHA256 file uploaded
- [ ] Release notes look correct
- [ ] Download link works

### Step 8: Verify GitHub Pages

Visit: <https://rabah-khalek.github.io/zetanotes/>

- [ ] Page loads correctly
- [ ] Download button works
- [ ] Links to release work
- [ ] Logo displays
- [ ] Pricing section correct

### Step 9: Verify Appcast

Visit: <https://rabah-khalek.github.io/zetanotes/appcast.xml>

- [ ] XML is valid
- [ ] Version number correct
- [ ] Download URL correct
- [ ] File size populated
- [ ] EdDSA signature present (not "WILL_BE_GENERATED")

### Step 10: Test Auto-Update (Optional)

Build a previous version locally and test update:

1. Install old version
2. Launch app
3. Check for updates
4. Verify update prompt appears
5. Test update installation

## Post-Deployment 📝

### Announce Release

- [ ] Tweet/social media announcement
- [ ] Update any external links
- [ ] Notify beta testers
- [ ] Update Product Hunt (if listed)

### Monitor

- [ ] Check download counts in GitHub Insights
- [ ] Monitor for issues/bug reports
- [ ] Check crash reports (if implemented)

### Documentation

- [ ] Update main README if needed
- [ ] Update screenshots if UI changed
- [ ] Update demo video if major features added

## For Future Releases 🔄

### Regular Release Process

1. [ ] Update version in `Info.plist`
2. [ ] Commit changes: `git commit -am "Bump version to X.X.X"`
3. [ ] Push: `git push`
4. [ ] Tag: `git tag vX.X.X`
5. [ ] Push tag: `git push origin vX.X.X`
6. [ ] Wait for CI to complete
7. [ ] Verify release in public repo
8. [ ] Test download
9. [ ] Announce!

### Version Numbering

Follow semantic versioning:

- **Major** (1.0.0): Breaking changes, major features
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.0.1): Bug fixes, small improvements

## Troubleshooting Common Issues 🔧

### CI fails at "Generate Sparkle signature"

**Solution**: Check `SPARKLE_PRIVATE_KEY` secret is set correctly

### CI fails at "Create release in public repo"

**Solution**: Check `PUBLIC_REPO_TOKEN` has `repo` scope

### GitHub Pages shows 404

**Solution**: Wait 5-10 minutes, check Pages is enabled from `/docs`

### Appcast signature is "WILL_BE_GENERATED"

**Solution**: CI didn't run properly, check workflow logs

### Auto-update doesn't work in app

**Solution**:

1. Check `SUFeedURL` in Info.plist
2. Verify appcast.xml is accessible
3. Check public key matches private key
4. Ensure app is from previous version

## Security Reminders 🔐

- ❌ **NEVER** commit `SPARKLE_PRIVATE_KEY` to git
- ❌ **NEVER** commit `PUBLIC_REPO_TOKEN` to git
- ❌ **NEVER** push source code to public repo
- ✅ Keep private key in GitHub Secrets only
- ✅ Keep source code in private `-dev` repo only
- ✅ Only release builds and docs go to public repo

## Quick Reference 📚

### Important URLs

- Dev repo: `https://github.com/rabah-khalek/zetanotes-dev`
- Public repo: `https://github.com/rabah-khalek/zetanotes`
- Releases: `https://github.com/rabah-khalek/zetanotes/releases`
- Website: `https://rabah-khalek.github.io/zetanotes/`
- Appcast: `https://rabah-khalek.github.io/zetanotes/appcast.xml`

### Commands

```bash
# Tag and release
git tag v1.0.0
git push origin v1.0.0

# Test build locally
./scripts/release.sh 1.0.0

# View workflow status
gh run list --workflow=release.yml

# Download latest release
curl -L https://github.com/rabah-khalek/zetanotes/releases/latest/download/ZetaNotes.dmg -o ZetaNotes.dmg
```

---

**Ready to deploy?** Start at Step 1! 🚀
