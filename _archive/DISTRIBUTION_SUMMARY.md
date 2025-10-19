# Distribution Summary

## Current Setup: Free Distribution (No Apple Developer Account)

ZetaNotes is configured for **free distribution** without requiring an Apple Developer account.

### What This Means

**For You (Developer):**
- ✅ **$0/year** - No Apple Developer Program fee
- ✅ Full control over distribution via GitHub Releases
- ✅ Build with `./scripts/package-unsigned.sh`

**For Users:**
- ⚠️ First launch requires right-click → Open (bypass Gatekeeper)
- ⚠️ macOS shows "unidentified developer" warning (one-time)
- ✅ After first launch, opens normally
- ❌ No automatic updates (manual download from GitHub)

### Building & Distributing

```bash
# Build unsigned release
xcodebuild -scheme ZetaNotes -configuration Release build

# Create DMG
./scripts/package-unsigned.sh

# Upload to GitHub Releases
# Users download and install manually
```

### User Installation Process

1. Download DMG from GitHub Releases
2. Open DMG
3. Drag ZetaNotes to Applications
4. **Right-click** ZetaNotes → **Open** (important!)
5. Click "Open" in security dialog
6. App opens normally from then on

---

## Optional: Professional Distribution (Requires Apple Developer Account)

If you later decide to get an Apple Developer account ($99/year):

### Benefits
- ✅ No security warnings for users
- ✅ Professional user experience (double-click to open)
- ✅ Code signing with Developer ID
- ✅ Notarization by Apple
- ✅ Optional: Automatic updates via Sparkle

### Setup
```bash
# One-time setup
./scripts/setup-signing.sh

# Build signed & notarized releases
./scripts/package-release.sh
```

### What Changes
- Users can open app with double-click (no right-click needed)
- No "unidentified developer" warnings
- More trustworthy for non-technical users
- Can add Sparkle for automatic updates (see archived docs)

---

## Documentation Archive

All detailed documentation has been archived to `docs/archive/`:
- DISTRIBUTION.md - Full distribution guide
- SPARKLE_SETUP.md - Auto-update integration
- MONETIZATION_STRATEGY.md - Pricing strategies
- And other implementation docs

These are available if you need them later but not required for current setup.

---

## Current Workflow

1. **Develop** - Build and test in Xcode
2. **Release** - Run `./scripts/package-unsigned.sh`
3. **Upload** - Create GitHub Release with DMG
4. **Users** - Download and right-click to open first time
5. **Update** - Repeat for each new version

**Simple, free, and works well for technical users and open-source projects.**
