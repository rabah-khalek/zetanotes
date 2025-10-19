# ZetaNotes Release Scripts

Automated scripts to package and release ZetaNotes with one command.

## 🚀 Quick Start

### Create a Release

```bash
cd /Users/projects/Documents/zetanotes
./scripts/release.sh 1.0.0
```

That's it! The script will:
- ✅ Build the app in Release mode
- ✅ Create an unsigned DMG (for distribution)
- ✅ Generate SHA256 checksum
- ✅ Show installation instructions

**Time:** 5-10 minutes (Xcode build time)

**Output:** `~/Desktop/ZetaNotes-v1.0.0.dmg`

**Note:** Users download models via the welcome page on first run - no model bundling needed!

### Get your DMG

After completion, find your release at:
- Location: `~/Desktop/`
- File: `ZetaNotes-v1.0.0.dmg`
- Checksum: `ZetaNotes-v1.0.0.dmg.sha256`

## 📁 Scripts Included

### `release.sh`
**Unified release packaging script**

Creates unsigned DMG distributions for ZetaNotes.

**Features:**
- ✅ Production safety checks (DEV_TODO markers, DEBUG blocks, test credentials)
- ✅ Clean Xcode build in Release configuration
- ✅ Development data cleanup (models, notes, logs)
- ✅ **No model bundling** - users download via welcome page
- ✅ DMG creation (create-dmg or fallback hdiutil)
- ✅ SHA256 checksum generation
- ✅ Comprehensive installation guide

**When to run:** Every time you want to create a release

**Usage:**
```bash
./scripts/release.sh VERSION
```

Example:
```bash
./scripts/release.sh 1.0.0
```

### Development Scripts

These scripts are for **development setup only**, not for releases:

#### `build-llama.sh`
**Xcode Run Script phase** - builds llama.cpp with Metal support during Xcode builds.

**When it runs:** Automatically during Xcode builds (via Build Phases)

#### `configure-xcode.sh`
**Interactive Xcode configuration helper** - sets up build settings for llama.cpp integration.

**When to run:** Once, during initial development setup

#### `setup-dev.sh`
**One-time development environment setup** - clones llama.cpp, builds it, downloads TinyLlama test model.

**When to run:** Once, when first setting up the development environment

## � Prerequisites

### Required

1. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **llama.cpp** (for development)
   - Run `./scripts/setup-dev.sh` once to set up development environment

### Optional (for prettier DMG)

```bash
brew install create-dmg
```

If not installed, the script uses a fallback method (works fine, just less pretty).

## 🎯 What Gets Created

After running `release.sh`, you get:

```
~/Desktop/
├── ZetaNotes-v1.0.0.dmg           # Upload to GitHub ✅
└── ZetaNotes-v1.0.0.dmg.sha256    # Checksum (update website)
```

## 📤 Upload to GitHub

1. **Create release on GitHub:**
   - Go to Releases → Draft a new release
   - Tag: `v1.0.0`
   - Title: `ZetaNotes v1.0.0`

2. **Upload DMG:**
   - Drag `ZetaNotes-v1.0.0.dmg` to release assets

3. **Update website checksum:**
   ```bash
   # Copy checksum
   cat ~/Desktop/ZetaNotes-v1.0.0.dmg.sha256

   # Update docs/download.html
   # Find the SHA256 section and paste the new checksum

   # Commit and push
   git add docs/
   git commit -m "Update download checksum for v1.0.0"
   git push
   ```

## 🐛 Troubleshooting

### Build fails

**Problem:** Xcode build errors

**Solution:**
```bash
# Clean and rebuild manually first
cd /Users/projects/Documents/zetanotes
xcodebuild clean -project ZetaNotes.xcodeproj -scheme ZetaNotes
xcodebuild build -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Release

# Fix any errors, then re-run release.sh
```

### DMG creation fails

**Problem:** create-dmg not installed or errors

**Solution:**
```bash
# Install create-dmg (optional)
brew install create-dmg

# Or let script use fallback hdiutil method (works fine)
```

### Script shows warnings about production readiness

**Problem:** Script found DEV_TODO markers, DEBUG blocks, or test credentials

**Solution:**
```bash
# Search for issues
grep -r "DEV_TODO" ZetaNotes/
grep -r "DEBUG_BLOCK_START" ZetaNotes/
grep -r "test@example.com" ZetaNotes/

# Fix the issues, then re-run
./scripts/release.sh 1.0.0
```

## ⏱️ Time Breakdown

| Step | Time | Notes |
|------|------|-------|
| Safety checks | 10 sec | Quick scans |
| Xcode build | 5-10 min | Depends on Mac speed |
| Cleanup | 5 sec | Quick |
| DMG creation | 1 min | Quick |
| Checksum | 5 sec | Quick |
| **Total** | **5-10 min** | Mostly Xcode build |

## 📖 Distribution Philosophy

**ZetaNotes uses a simple, user-friendly distribution model:**

- ✅ **Unsigned DMG** - Easy distribution, no $99/year Apple Developer fee
- ✅ **First-run model download** - Users choose and download AI models via welcome page
- ✅ **No model bundling** - Keeps download size small (<10 MB vs >500 MB)
- ✅ **User control** - Users select which models to download based on their needs

This approach prioritizes accessibility and user choice over Apple ecosystem integration.

## 🆘 Getting Help

- **Script issues:** Open an issue on GitHub
- **Build issues:** Check Xcode build logs
- **llama.cpp issues:** See [llama.cpp documentation](https://github.com/ggerganov/llama.cpp)
