# Release Process - Quick Summary

## ✅ Automatic Version Management

**Good news!** You don't need to manually update `Info.plist` anymore.

### How It Works:

1. **You create a git tag**: `v1.0.1`
2. **CI automatically**:
   - Updates `CFBundleShortVersionString` to `1.0.1`
   - Generates unique build number (timestamp)
   - Builds app with correct version
   - Creates signed release
   - Updates appcast.xml
   - Publishes to GitHub Pages

---

## Release in 2 Commands

```bash
# Test locally
./run

# Release (replace 1.0.1 with your version)
git tag v1.0.1 && git push origin v1.0.1
```

**Done!** CI handles everything else.

---

## What Happens Automatically

```
┌─────────────────────────────────────────┐
│  git tag v1.0.1                         │
│  git push origin v1.0.1                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  CI Workflow Runs                       │
│  ✅ Updates Info.plist → 1.0.1          │
│  ✅ Generates build number               │
│  ✅ Builds llama.cpp                     │
│  ✅ Builds ZetaNotes.app                 │
│  ✅ Creates DMG                          │
│  ✅ Signs with EdDSA                     │
│  ✅ Creates release                      │
│  ✅ Updates appcast.xml                  │
│  ✅ Publishes to GitHub Pages            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Users Get Notified (within 24 hours)  │
│  💬 "Update available: 1.0.1"           │
│  🖱️  One-click install                  │
│  🔄 Auto-relaunch                        │
└─────────────────────────────────────────┘
```

---

## Version Numbers

The git tag determines the version:

| Git Tag | App Version | DMG Name |
|---------|-------------|----------|
| `v1.0.1` | `1.0.1` | `ZetaNotes-v1.0.1.dmg` |
| `v1.1.0` | `1.1.0` | `ZetaNotes-v1.1.0.dmg` |
| `v2.0.0` | `2.0.0` | `ZetaNotes-v2.0.0.dmg` |

**Build number** is auto-generated from timestamp: `20251019220530`

---

## No More Manual Updates!

### ❌ Old Way (Manual):
```bash
# Edit Info.plist
CFBundleShortVersionString: 1.0 → 1.0.1
CFBundleVersion: 1 → 2

# Commit
git commit -m "Bump version"

# Tag
git tag v1.0.1
git push
```

### ✅ New Way (Automatic):
```bash
# Just tag and push
git tag v1.0.1
git push origin v1.0.1
```

CI does the rest!

---

## Required Setup (One Time)

Make sure this GitHub Secret is set:

**Name**: `SPARKLE_PRIVATE_KEY`
**Value**: `9sYT3LfxNMW6NoEd8/ygsU83lzb6gJctwg/4lWMFa08=`

Set it here:
```
https://github.com/YOUR_USERNAME/zetanotes-dev/settings/secrets/actions
```

---

## What CI Updates Automatically

The workflow modifies `Info.plist` during the build:

```xml
<!-- Before (in your repo) -->
<key>CFBundleShortVersionString</key>
<string>1.0</string>
<key>CFBundleVersion</key>
<string>1</string>

<!-- After (in CI, during build) -->
<key>CFBundleShortVersionString</key>
<string>1.0.1</string>  <!-- From git tag -->
<key>CFBundleVersion</key>
<string>20251019220530</string>  <!-- Auto-generated -->
```

**Note**: Your local `Info.plist` stays at `1.0` - only the CI build updates it.

---

## Complete Example

Let's release version `1.0.1`:

```bash
# 1. Test current code
./run

# 2. Everything works? Create release
git tag v1.0.1
git push origin v1.0.1

# 3. Monitor CI (optional)
# Go to: https://github.com/YOUR_USERNAME/zetanotes-dev/actions

# 4. Wait ~15 minutes

# 5. Done! Check release:
# https://github.com/rabah-khalek/zetanotes/releases
```

Users automatically get notified!

---

## Why This Is Better

✅ **No version mismatch** - Tag and app version always match
✅ **Fewer commits** - No "bump version" commits
✅ **Less error-prone** - Can't forget to update version
✅ **Automatic build numbers** - Unique timestamp-based
✅ **Simpler workflow** - Just tag and push

---

## For More Details

- **Complete flow**: [AUTO_UPDATE_FLOW.md](AUTO_UPDATE_FLOW.md)
- **Release guide**: [../RELEASE_GUIDE.md](../RELEASE_GUIDE.md)
- **Sparkle setup**: [SPARKLE_SETUP.md](SPARKLE_SETUP.md)
- **CI workflow**: [../.github/workflows/release.yml](../.github/workflows/release.yml)

---

## Summary

**To release a new version**:

```bash
git tag v1.0.1 && git push origin v1.0.1
```

That's literally it! 🚀

The CI automatically:
- Updates version in Info.plist ✅
- Builds and signs the release ✅
- Creates GitHub release ✅
- Updates appcast.xml ✅
- Notifies users ✅
