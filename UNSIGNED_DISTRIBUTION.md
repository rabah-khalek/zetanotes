# Unsigned Distribution Guide

Guide for distributing OffNotes **without** Apple Developer account signing.

---

## ✅ Will It Work?

**YES!** Your app will work, but:

### What Users Will See:

1. **First launch:** Security warning
2. **Workaround:** Right-click → Open → Confirm
3. **After that:** Works normally forever

### Is It Safe?

**Absolutely!** The warning just means:
- You didn't pay Apple $99/year for a Developer certificate
- macOS doesn't recognize you as a "verified developer"
- **Your app is still 100% safe**

---

## 🚀 Quick Start

### Build Your Release (10 minutes)

```bash
cd /Users/projects/Documents/notetaker

# Update version (edit line 18)
nano scripts/package-unsigned.sh
# Change: VERSION="1.0.0"

# Run build script
./scripts/package-unsigned.sh
```

**Output:**
- `~/Desktop/OffNotes-Release-YYYYMMDD-HHMMSS/`
- `OffNotes-v1.0.0.dmg` ← Upload this to GitHub
- `OffNotes-v1.0.0.dmg.sha256` ← Checksum for website
- `INSTALLATION.txt` ← Include in GitHub release

---

## 📤 Distribution Steps

### 1. Upload to GitHub

```bash
# Create release on GitHub
# Tag: v1.0.0
# Title: OffNotes v1.0.0

# Upload files:
# - OffNotes-v1.0.0.dmg
# - INSTALLATION.txt (paste contents in description)
```

### 2. Update Website

```bash
# Copy checksum
cat ~/Desktop/OffNotes-Release-*/OffNotes-v1.0.0.dmg.sha256

# Update docs/download.html line 29
# Paste checksum

# Commit and push
git add docs/
git commit -m "Update download for v1.0.0"
git push
```

---

## 👥 User Instructions

### What Users Must Do (First Time Only)

Users will see: **"OffNotes can't be opened because it is from an unidentified developer"**

**Solution (2 methods):**

#### Method 1: Right-Click to Open (Recommended)

1. Download and install OffNotes to Applications
2. **Right-click** (or Control-click) on OffNotes
3. Select **"Open"** from menu
4. Click **"Open"** in the security dialog
5. ✅ Done! Works normally forever after

#### Method 2: System Settings

1. Try to open OffNotes normally (it will be blocked)
2. Go to **System Settings → Privacy & Security**
3. Scroll down to "Security" section
4. See: "OffNotes was blocked from use"
5. Click **"Open Anyway"**
6. Confirm by clicking **"Open"**
7. ✅ Done! Works normally forever after

### Video Tutorial (Recommended)

Consider creating a 30-second video showing:
1. Downloading DMG
2. Dragging to Applications
3. Right-clicking and opening
4. App launches successfully

Post on your website and GitHub.

---

## ⚠️ Limitations of Unsigned Distribution

### What Works:
- ✅ App runs perfectly
- ✅ All features work
- ✅ Updates work (just replace .app)
- ✅ LemonSqueezy licensing works
- ✅ Model downloads work
- ✅ Everything local works

### What Doesn't Work:
- ❌ Auto-updates (you'd need Sparkle + code signing)
- ❌ Some enterprise Macs might block entirely
- ❌ Looks less "professional" (scary warning)

### What's Different:
- ⚠️ Users see security warning on first launch
- ⚠️ Users must actively bypass Gatekeeper
- ⚠️ Some users might not trust it

---

## 💡 How to Reduce User Friction

### 1. Clear Instructions

Put these **prominently** on download page:
```
⚠️ IMPORTANT: First Launch Instructions

You WILL see a security warning. This is normal.

To open OffNotes:
1. Right-click on OffNotes in Applications
2. Select "Open"
3. Click "Open" in dialog

After first time, works normally forever.
```

### 2. Explain Why

On your website:
```
Why do I see a security warning?

OffNotes is not signed with an Apple Developer certificate ($99/year).
The app is 100% safe and open source - you can verify the code on GitHub.

Apple shows this warning for ANY app that isn't signed by a paid developer account.
```

### 3. Build Trust

- Show GitHub link prominently
- Include SHA256 checksum
- Link to source code
- Explain it's open source
- Mention offline/privacy focus

### 4. Video Tutorial

Create a quick video:
- Shows the warning appearing
- Shows right-click → Open process
- Shows app working perfectly
- Calms user fears

---

## 📊 Comparison: Signed vs Unsigned

| Feature | Unsigned (Free) | Signed ($99/year) |
|---------|----------------|-------------------|
| **Works?** | ✅ Yes | ✅ Yes |
| **First launch** | ⚠️ Warning + workaround | ✅ No warning |
| **After first launch** | ✅ Normal | ✅ Normal |
| **User trust** | ⚠️ Lower | ✅ Higher |
| **Enterprise Macs** | ❌ Might block | ✅ Works |
| **Setup time** | 0 min | 30 min one-time |
| **Annual cost** | $0 | $99 |
| **Break-even point** | - | 7 Pro sales |

---

## 🎯 Recommendation

### Start Unsigned, Upgrade Later

**Month 1:** Launch unsigned (free)
- Test the market
- Get initial users
- See if people buy Pro
- Learn from feedback

**After 7 Pro sales:** Get Apple Developer ($99)
- Pay for itself with Pro sales
- Update to signed version
- Users get better experience
- Looks more professional

### Why This Works:

1. **No upfront cost** - test before investing
2. **Users can still use it** - just extra step
3. **Easy to upgrade** - just re-release signed version
4. **Same codebase** - no code changes needed

---

## 🔄 Upgrading to Signed Later

When you're ready to get Apple Developer:

1. **Sign up** at developer.apple.com ($99)
2. **Get certificate** (Xcode → Preferences → Accounts)
3. **Run signed script:**
   ```bash
   ./scripts/setup-signing.sh      # One-time setup
   ./scripts/package-release.sh    # Build signed DMG
   ```
4. **Release v1.0.1** (or v1.1.0) as signed version
5. **Update website** - no more warnings!

Users on old version can update normally.

---

## 🐛 Troubleshooting

### "The app is damaged and can't be opened"

**Cause:** Quarantine attribute set by macOS

**Solution (user does this):**
```bash
xattr -cr /Applications/OffNotes.app
```

Or re-download from your website.

### "OffNotes will damage your computer"

**Cause:** macOS thinks it's malware (rare, but possible)

**Solution:**
- This is serious - check your code for malware!
- Run malware scan
- If false positive, report to Apple
- Consider getting signed version

### App blocked on enterprise/school Mac

**Cause:** Strict IT policies

**Solution:**
- User must ask IT admin
- Or: Get signed version ($99/year)
- Enterprise requires signed apps

---

## 📝 Sample Release Description

Use this in your GitHub release:

```markdown
# OffNotes v1.0.0

Privacy-first note-taking with offline AI.

## ⚠️ Important: First Launch Instructions

**You WILL see a security warning.** This is normal for unsigned apps.

To open OffNotes:
1. Download and open the DMG
2. Drag OffNotes to Applications
3. **Right-click** on OffNotes in Applications
4. Select "Open" from the menu
5. Click "Open" in the security dialog

After the first time, it works normally (no right-click needed).

## Why do I see a warning?

OffNotes is not signed with an Apple Developer certificate ($99/year).
The app is completely safe and open source. You can verify the source code
at https://github.com/YOUR_USERNAME/offnotes

## Download

**DMG:** [OffNotes-v1.0.0.dmg](link)
**Size:** ~800 MB (includes TinyLlama AI model)
**SHA256:** `your_checksum_here`

## System Requirements

- macOS 13.0+ (Ventura or later)
- Apple Silicon (M1/M2/M3/M4) recommended
- 4 GB RAM minimum (8 GB+ recommended)

## What's Included

- TinyLlama 1.1B AI model (free)
- All AI features (autocomplete, summaries, translation, search)
- Unlimited notes
- 100% offline

## Upgrade to Pro

- 8 premium AI models
- Custom prompt editing
- $14.99 one-time payment
- Upgrade at https://offnotes.lemonsqueezy.com/checkout

---

Full documentation: https://YOUR_USERNAME.github.io/offnotes/
```

---

## 🎉 You're Ready!

Just run:

```bash
./scripts/package-unsigned.sh
```

Then upload the DMG to GitHub and you're live! 🚀

No $99 needed, no certificates, no notarization. Just works!
