# Homebrew Distribution Guide

## Why Homebrew?

**Benefits:**
- ✅ **FREE** - no Apple Developer account needed
- ✅ **No security warnings** - Homebrew removes quarantine automatically
- ✅ **Professional distribution** - users expect this
- ✅ **Easy updates** - `brew upgrade zetanotes`
- ✅ **Reaches developer audience** - your target users!

## User Experience

### Installation
```bash
brew install --cask zetanotes
```

That's it! No security warnings, no right-click, just works.

### Updates
```bash
brew upgrade zetanotes
```

Automatic when users run `brew upgrade`.

## How to Submit

### 1. Create the Cask Formula

Already done! See: `homebrew/zetanotes.rb`

### 2. Test Locally

```bash
# Install from local formula
brew install --cask homebrew/zetanotes.rb

# Test it works
open /Applications/ZetaNotes.app

# Uninstall to test again
brew uninstall --cask zetanotes
```

### 3. Submit to Homebrew

```bash
# Fork homebrew-cask
gh repo fork Homebrew/homebrew-cask

# Clone your fork
git clone https://github.com/YOUR_USERNAME/homebrew-cask.git
cd homebrew-cask

# Create branch
git checkout -b zetanotes

# Copy formula
cp /path/to/zetanotes.rb Casks/z/zetanotes.rb

# Test with official linter
brew style Casks/z/zetanotes.rb
brew audit --cask zetanotes

# Commit
git add Casks/z/zetanotes.rb
git commit -m "Add ZetaNotes 1.0.0"

# Push
git push origin zetanotes

# Create PR
gh pr create --title "Add ZetaNotes 1.0.0" \
  --body "Privacy-first note-taking with offline AI for Mac"
```

### 4. Wait for Review

- Homebrew maintainers review (usually 1-3 days)
- They may ask for changes
- Once approved, it's live!

### 5. Users Can Install

```bash
brew install --cask zetanotes
```

## Updating Your Cask

When you release a new version:

```bash
# Update the formula
cd homebrew-cask
git checkout -b zetanotes-1.0.1

# Edit Casks/z/zetanotes.rb
# Change version to "1.0.1"
# Update sha256 if needed

# Test
brew reinstall --cask zetanotes

# Submit PR
git add Casks/z/zetanotes.rb
git commit -m "Update ZetaNotes to 1.0.1"
git push origin zetanotes-1.0.1
gh pr create --title "Update ZetaNotes to 1.0.1"
```

## Benefits for Your Users

### Without Homebrew (Current)
```
1. Download DMG from GitHub
2. Open DMG
3. Drag to Applications
4. Try to open → BLOCKED
5. Right-click → Open
6. Or run terminal command
7. Confirm security dialog
8. Finally opens
```

### With Homebrew
```
1. brew install --cask zetanotes
2. Done!
```

## Update README

Add to your README.md:

```markdown
## Installation

### Homebrew (Recommended)

```bash
brew install --cask zetanotes
```

No security warnings, no configuration needed!

### Direct Download

Download the latest DMG from [GitHub Releases](https://github.com/rabah-khalek/zetanotes/releases)

**Important:** Right-click and select "Open" the first time you launch.
```

## Statistics

Popular unsigned apps on Homebrew:
- **OBS Studio**: 2M+ installs
- **Blender**: 500k+ installs
- **Audacity**: 1M+ installs
- **GIMP**: 800k+ installs

All started without Apple Developer accounts!

## Limitations

**Homebrew can't do:**
- ❌ Automatic background updates (user must run `brew upgrade`)
- ❌ Update notifications in your app
- ❌ Work for non-technical users (they don't know Homebrew)

**But it's perfect for:**
- ✅ Developer audience (your target!)
- ✅ Initial distribution
- ✅ Zero cost
- ✅ Professional appearance

## Combining Both Approaches

**Best strategy:**

1. **Primary:** GitHub Releases with clear instructions
   - Reaches everyone
   - Works immediately (with right-click)

2. **Secondary:** Homebrew Cask
   - Zero friction for developers
   - Professional distribution
   - Easy updates

3. **Future:** Apple Developer when revenue justifies
   - Seamless for everyone
   - Auto-updates work
   - Maximum professionalism

## Next Steps

1. ✅ Finish your current release with enhanced scripts
2. ✅ Get first 10-20 users via GitHub Releases
3. ✅ Submit to Homebrew Cask (takes 1 hour)
4. ✅ Add Homebrew instructions to README
5. ✅ When you have 20+ paying users → Get Apple Developer

This gives you **professional distribution for $0** while you validate your product! 🚀

---

**Resources:**
- [Homebrew Cask Documentation](https://docs.brew.sh/Cask-Cookbook)
- [Contributing to homebrew-cask](https://github.com/Homebrew/homebrew-cask/blob/master/CONTRIBUTING.md)
- [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
