# Public Repository Setup Guide

This guide explains how to set up the public `zetanotes` repository to work with the CI/CD pipeline.

## Repository Structure

The public `zetanotes` repository should be a **minimal, release-only** repository:

```
zetanotes/                    # Public repo
├── docs/                     # GitHub Pages content (auto-updated by CI)
│   ├── index.html           # Main landing page
│   ├── appcast.xml          # Sparkle update feed
│   ├── logo.png             # App logo
│   └── download.html        # Alternative download page (optional)
├── README.md                # Public-facing README with download info
├── LICENSE                  # License file (MIT recommended)
└── .gitignore              # Ignore system files
```

## Step-by-Step Setup

### 1. Create the Public Repository

```bash
# On GitHub, create a new public repository named "zetanotes"
# Repository: https://github.com/rabah-khalek/zetanotes
# Description: "Offline AI note-taking for macOS"
# Public ✅
# Add README ✅
# Add LICENSE (MIT) ✅
# Do NOT add .gitignore yet (we'll customize it)
```

### 2. Clone and Initialize

```bash
# Clone the new public repo
git clone https://github.com/rabah-khalek/zetanotes.git
cd zetanotes

# Create docs folder
mkdir -p docs

# Copy docs from your dev repo
cp -r /path/to/zetanotes-dev/docs/* ./docs/

# Create .gitignore
cat > .gitignore << 'EOF'
# macOS
.DS_Store
._*
.Spotlight-V100
.Trashes

# Temporary files
*.tmp
*.log
EOF
```

### 3. Create Public README.md

Replace the default README with:

```markdown
# ZetaNotes

**Offline AI note-taking for macOS**

ZetaNotes is a privacy-first note-taking application with built-in AI assistance that runs entirely on your Mac. No internet connection required, no data collection.

## ✨ Features

- 🔒 **100% Offline**: All AI processing happens locally on your Mac
- ✨ **Smart Autocomplete**: AI-powered writing assistance
- 📝 **Instant Summarization**: Summarize notes with one click
- 🌍 **Translation**: Translate to 12+ languages
- 🔍 **Semantic Search**: Find notes by meaning, not just keywords
- 💬 **AI Chat**: Built-in conversational assistant

## 📦 Download

**[Download ZetaNotes](https://github.com/rabah-khalek/zetanotes/releases/latest/download/ZetaNotes.dmg)**

Or visit our website: **[rabah-khalek.github.io/zetanotes](https://rabah-khalek.github.io/zetanotes)**

### System Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (M1/M2/M3/M4) recommended
- 4 GB RAM minimum (8 GB+ recommended)
- 2 GB disk space (includes app + AI models)

### Installation

1. Download the DMG file
2. Open the DMG
3. Drag ZetaNotes to Applications
4. **RIGHT-CLICK** on ZetaNotes and select "Open"
5. Click "Open" in the security dialog

After first launch, you can open normally.

## 🔐 Privacy & Security

- **No data collection**: Your notes never leave your Mac
- **No analytics**: We don't track what you do
- **No cloud sync**: Everything stays local
- **Offline AI**: Models run entirely on your device

## 🛠 Tech Stack

- **Native macOS**: Built with SwiftUI
- **AI Models**: Llama 3.2, Phi-3, Qwen 2.5, Gemma 2
- **Metal GPU**: Hardware acceleration for fast inference
- **llama.cpp**: Efficient local AI inference

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🐛 Issues & Support

Found a bug or have a feature request? Please open an issue in this repository.

## 🔄 Auto-Updates

ZetaNotes uses [Sparkle](https://sparkle-project.org/) for automatic updates. The app will check for updates and notify you when a new version is available.

---

**Note**: This repository contains releases only. Source code is maintained separately.
```

### 4. Enable GitHub Pages

1. Go to repository Settings
2. Navigate to "Pages" in the left sidebar
3. Under "Build and deployment":
   - **Source**: Deploy from a branch
   - **Branch**: `main`
   - **Folder**: `/docs`
4. Click "Save"
5. Wait a few minutes for deployment
6. Your site will be available at: `https://rabah-khalek.github.io/zetanotes/`

### 5. Configure Repository Settings

#### Enable Releases

- Ensure "Releases" is enabled in repository settings

#### Branch Protection (Optional but Recommended)

- Settings → Branches → Add rule
- Branch name pattern: `main`
- ✅ Require a pull request before merging
- ✅ Require status checks to pass

### 6. Commit and Push

```bash
git add .
git commit -m "Initial public repository setup"
git push origin main
```

### 7. Verify GitHub Pages

After a few minutes, visit:

- Main site: <https://rabah-khalek.github.io/zetanotes/>
- Appcast: <https://rabah-khalek.github.io/zetanotes/appcast.xml>

## What the CI Does

When you push a tag to `zetanotes-dev`, the GitHub Actions workflow will:

1. ✅ Build the app in the `-dev` repo
2. ✅ Generate Sparkle EdDSA signature
3. ✅ Create a release in THIS public repo with:
   - DMG file
   - SHA256 checksum
   - Installation instructions
4. ✅ Update `docs/appcast.xml` with:
   - Correct download URL
   - File size
   - EdDSA signature
5. ✅ Update `docs/index.html` download link
6. ✅ Commit and push changes
7. ✅ GitHub Pages auto-deploys

## Testing the Setup

### Test 1: GitHub Pages

Visit <https://rabah-khalek.github.io/zetanotes/> and verify:

- ✅ Page loads correctly
- ✅ Download button works
- ✅ Logo displays
- ✅ All sections render properly

### Test 2: Appcast Feed

Visit <https://rabah-khalek.github.io/zetanotes/appcast.xml> and verify:

- ✅ XML is valid
- ✅ URLs point to this public repo
- ✅ Version numbers are correct

### Test 3: Manual Release (Optional)

Create a test release manually:

1. Go to Releases → Draft a new release
2. Tag: `v0.0.1`
3. Title: `Test Release`
4. Upload a small test file
5. Publish
6. Verify the release appears correctly

## Maintenance

### When CI Updates Docs

The CI will automatically update `docs/` with each release. You don't need to manually edit:

- ❌ Don't edit `appcast.xml` manually
- ❌ Don't edit download URLs in `index.html`
- ✅ DO edit these files in your `-dev` repo
- ✅ CI will copy them to the public repo

### Manual Updates (if needed)

If you need to update the website content:

1. Edit in `zetanotes-dev/docs/`
2. Push to `-dev` repo
3. Trigger the CI workflow
4. OR manually copy to public repo's `docs/`

## Security Notes

- ✅ Never commit private keys to this repo
- ✅ Never commit source code to this repo
- ✅ Keep all development in the private `-dev` repo
- ✅ This repo should only have releases and docs

## Troubleshooting

### "Page not found" on GitHub Pages

- Wait 5-10 minutes after enabling Pages
- Check Settings → Pages shows "Your site is live at..."
- Verify `docs/index.html` exists in the main branch

### Download link doesn't work

- Ensure a release exists with the DMG file
- Check the URL format: `https://github.com/rabah-khalek/zetanotes/releases/download/v1.0.0/ZetaNotes-v1.0.0.dmg`
- Verify the tag and filename match

### CI can't push to public repo

- Check `PUBLIC_REPO_TOKEN` is set in `-dev` repo secrets
- Verify token has `repo` scope
- Ensure token hasn't expired

## Next Steps

After setting up this public repo:

1. ✅ Set up the GitHub Secrets in `zetanotes-dev`:
   - `PUBLIC_REPO_TOKEN`
   - `SPARKLE_PRIVATE_KEY`

2. ✅ Add Sparkle public key to your app's `Info.plist`

3. ✅ Test the CI workflow with a tag push

4. ✅ Create your first real release!

---

**Questions?** Check the workflow README: `.github/workflows/README.md` in the `-dev` repo
