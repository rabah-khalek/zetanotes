# ZetaNotes Launch Checklist

Complete guide to launch ZetaNotes to production via GitHub Pages + LemonSqueezy.

---

## ✅ Phase 1: Code Changes (COMPLETED)

- [x] Removed Qwen2.5 0.5B from model list
- [x] Verified LicenseManager gates Pro features correctly
- [x] Updated UpgradePromptView with new pricing tiers (Monthly $1, Annual $10, Lifetime $30)
- [x] Updated AISettingsView pricing display
- [x] Updated feature descriptions to focus on models + prompts

**Result:** Free tier gets all AI features with TinyLlama, Pro unlocks 8 open-source models + custom prompts with flexible pricing.

---

## ✅ Phase 2: Branding (COMPLETED)

- [x] Changed app name from "ZetaNotes" to "ZetaNotes"
- [x] Updated Info.plist with new branding
- [x] Updated bundle identifiers and URL schemes
- [x] Updated copyright notices

**Files Updated:**
- [ZetaNotes/Info.plist](ZetaNotes/Info.plist)

---

## ✅ Phase 3: GitHub Pages Website (COMPLETED)

- [x] Created `/docs` folder
- [x] Created [index.html](docs/index.html) landing page
- [x] Created [download.html](docs/download.html) installation guide
- [x] Added pricing information
- [x] Added system requirements

**Next Steps:**
1. Replace `YOUR_USERNAME` in HTML files with actual GitHub username
2. Enable GitHub Pages in repository settings
3. Verify site loads at `https://YOUR_USERNAME.github.io/zetanotes/`

---

## ✅ Phase 4: LemonSqueezy Integration (COMPLETED)

- [x] Updated [LicenseManager.swift](ZetaNotes/Managers/LicenseManager.swift) to use LemonSqueezy API
- [x] Updated [UpgradePromptView.swift](ZetaNotes/Views/UpgradePromptView.swift) with LemonSqueezy checkout URL

**Next Steps:**
1. Create LemonSqueezy account at https://lemonsqueezy.com
2. Create product "ZetaNotes Pro" with three pricing tiers:
   - Monthly: $1/month (recurring subscription)
   - Annual: $10/year (recurring subscription)
   - Lifetime: $30 (one-time payment)
3. Enable license key generation for all variants
4. Update `LicenseManager.swift` line 120-121 with your Store ID and Product ID
5. Update `UpgradePromptView.swift` with your checkout URLs for each tier
6. Update website HTML files with correct LemonSqueezy links

---

## ✅ Phase 5: Distribution (COMPLETED)

- [x] Created comprehensive [DISTRIBUTION.md](DISTRIBUTION.md) guide
- [x] Documented signing process
- [x] Documented notarization process
- [x] Documented DMG creation
- [x] Created automation script template

**Next Steps:** Follow DISTRIBUTION.md to build and distribute.

---

## ✅ Phase 6: Documentation (COMPLETED)

- [x] Created user-focused [README.md](README.md)
- [x] Created [DISTRIBUTION.md](DISTRIBUTION.md) for developers
- [x] Created this launch checklist

---

## 🚀 LAUNCH STEPS (TODO)

### Step 1: LemonSqueezy Setup (30 minutes)

1. **Create Account**
   - Go to https://lemonsqueezy.com
   - Sign up (or log in)
   - Complete onboarding

2. **Create Store**
   - Settings → Stores → Create Store
   - Name: "ZetaNotes"
   - Currency: USD

3. **Create Product**
   - Products → New Product
   - Name: **ZetaNotes Pro**
   - Description: "Unlock 8 open-source AI models and custom prompt editing."
   - Type: **Digital Product**

4. **Create Three Variants**

   **Variant 1: Monthly Subscription**
   - Name: "Monthly Pro"
   - Price: **$1/month**
   - Billing: Recurring
   - Save and get the **Variant ID**

   **Variant 2: Annual Subscription**
   - Name: "Annual Pro"
   - Price: **$10/year**
   - Billing: Recurring (yearly)
   - Save and get the **Variant ID**

   **Variant 3: Lifetime License**
   - Name: "Lifetime Pro"
   - Price: **$30**
   - Type: One-time payment
   - Save and get the **Variant ID**

5. **Enable License Keys**
   - Product Settings → License Keys
   - Enable: **Yes** (for all variants)
   - Length: 16-32 characters (your choice)
   - Format: `XXXX-XXXX-XXXX-XXXX` (recommended)

6. **Get API Credentials**
   - Settings → API
   - Create API Key
   - Copy **Store ID** and **API Key**

7. **Update Code**
   ```swift
   // In LicenseManager.swift line 120-121
   let storeId = "YOUR_STORE_ID"
   let productId = "YOUR_PRODUCT_ID"
   ```

   ```swift
   // In UpgradePromptView.swift - Update all three checkout URLs
   case "monthly":
       checkoutURL = "https://zetanotes.lemonsqueezy.com/checkout/buy/MONTHLY_VARIANT_ID"
   case "annual":
       checkoutURL = "https://zetanotes.lemonsqueezy.com/checkout/buy/ANNUAL_VARIANT_ID"
   case "lifetime":
       checkoutURL = "https://zetanotes.lemonsqueezy.com/checkout/buy/LIFETIME_VARIANT_ID"
   ```

8. **Update Website**
   - Update `docs/index.html` line 399
   - Update `docs/download.html` line 153

---

### Step 2: Build & Sign App (AUTOMATED - 15-20 minutes)

**Use the automated packaging script!** See [scripts/README.md](scripts/README.md)

#### Quick Start:

**First time only (5 minutes):**
```bash
cd /Users/projects/Documents/zetanotes
chmod +x scripts/*.sh
./scripts/setup-signing.sh
```

**Every release (15-20 minutes automated):**
```bash
# 1. Update version in scripts/package-release.sh line 19
VERSION="1.0.0"  # Change for each release

# 2. Run the script
./scripts/package-release.sh

# 3. Wait for completion - it does everything automatically!
```

The script automatically:
- ✅ Builds app in Xcode
- ✅ Bundles TinyLlama model
- ✅ Signs with Developer ID
- ✅ Creates DMG
- ✅ Notarizes with Apple
- ✅ Generates SHA256 checksum

**Manual alternative:** Follow [DISTRIBUTION.md](DISTRIBUTION.md) steps:

1. **Prerequisites**
   - [ ] Apple Developer Account ($99/year)
   - [ ] Developer ID Certificate installed
   - [ ] App-specific password generated
   - [ ] `notarytool` credentials stored

2. **Build App**
   ```bash
   # In Xcode: Product → Archive
   # Export to ~/Desktop/ZetaNotes-Release/
   ```

3. **Bundle TinyLlama**
   ```bash
   mkdir -p ~/Desktop/ZetaNotes-Release/ZetaNotes.app/Contents/Resources/Models
   curl -L "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf" \
     -o ~/Desktop/ZetaNotes-Release/ZetaNotes.app/Contents/Resources/Models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
   ```

4. **Sign App**
   ```bash
   CERT_NAME="Developer ID Application: Your Name (TEAM_ID)"
   codesign --deep --force --verify --verbose \
     --sign "$CERT_NAME" \
     --options runtime \
     --timestamp \
     ~/Desktop/ZetaNotes-Release/ZetaNotes.app
   ```

5. **Create DMG**
   ```bash
   create-dmg \
     --volname "ZetaNotes Installer" \
     --window-size 800 400 \
     --icon "ZetaNotes.app" 200 190 \
     --app-drop-link 600 185 \
     ZetaNotes-v1.0.0.dmg \
     ~/Desktop/ZetaNotes-Release/ZetaNotes.app
   ```

6. **Sign DMG**
   ```bash
   codesign --sign "$CERT_NAME" --timestamp ZetaNotes-v1.0.0.dmg
   ```

7. **Notarize**
   ```bash
   xcrun notarytool submit ZetaNotes-v1.0.0.dmg \
     --keychain-profile "notary-profile" \
     --wait
   ```

8. **Staple**
   ```bash
   xcrun stapler staple ZetaNotes-v1.0.0.dmg
   ```

9. **Generate Checksum**
   ```bash
   shasum -a 256 ZetaNotes-v1.0.0.dmg
   # Save this checksum!
   ```

---

### Step 3: GitHub Release (30 minutes)

1. **Create Release**
   - Go to GitHub → Releases → **Draft a new release**
   - Tag: `v1.0.0`
   - Title: **ZetaNotes v1.0.0**
   - Description: (See template in DISTRIBUTION.md)

2. **Upload DMG**
   - Drag `ZetaNotes-v1.0.0.dmg` to assets
   - Publish release

3. **Get Download URL**
   - Copy the DMG download URL
   - Format: `https://github.com/YOUR_USERNAME/zetanotes/releases/download/v1.0.0/ZetaNotes-v1.0.0.dmg`

4. **Update Website**
   - Replace `YOUR_USERNAME` in `docs/index.html`
   - Replace `YOUR_USERNAME` in `docs/download.html`
   - Update checksum in `docs/download.html` line 29

---

### Step 4: Enable GitHub Pages (5 minutes)

1. **Repository Settings**
   - Go to Settings → Pages
   - Source: **Deploy from a branch**
   - Branch: `main`
   - Folder: `/docs`
   - Save

2. **Wait for Deployment**
   - Takes 1-2 minutes
   - Check Actions tab for progress

3. **Verify**
   - Visit `https://YOUR_USERNAME.github.io/zetanotes/`
   - Test download button
   - Test upgrade button (should go to LemonSqueezy)

---

### Step 5: Test Complete Flow (30 minutes)

1. **Download & Install**
   - [ ] Download DMG from GitHub Pages
   - [ ] Open DMG (no warning should appear)
   - [ ] Drag to Applications
   - [ ] Open app (should open without "unidentified developer" warning)
   - [ ] Verify TinyLlama works
   - [ ] Create a test note
   - [ ] Try autocomplete

2. **Test Pro Upgrade**
   - [ ] Click "Upgrade" in app
   - [ ] Verify LemonSqueezy checkout loads
   - [ ] Complete test purchase (or use test mode)
   - [ ] Receive license key via email
   - [ ] Activate license in app
   - [ ] Verify open-source models appear
   - [ ] Download a open-source model
   - [ ] Switch to open-source model

3. **Test Website**
   - [ ] Landing page loads correctly
   - [ ] Download button works
   - [ ] Installation guide is accurate
   - [ ] All links work
   - [ ] Mobile responsive

---

## 📊 Launch Day Checklist

### Pre-Launch (Night Before)

- [ ] All code committed and pushed
- [ ] GitHub Pages deployed and tested
- [ ] LemonSqueezy product live
- [ ] Test purchase completed successfully
- [ ] DMG verified on clean Mac
- [ ] All placeholder URLs updated
- [ ] README has correct links
- [ ] Social media posts drafted

### Launch Day

- [ ] Publish GitHub release
- [ ] Tweet announcement
- [ ] Post to Hacker News (Show HN)
- [ ] Post to r/macapps
- [ ] Post to Product Hunt (optional)
- [ ] Email newsletter (if any)
- [ ] Update personal website/blog

### Post-Launch Monitoring

- [ ] Monitor GitHub issues for bug reports
- [ ] Monitor LemonSqueezy for sales
- [ ] Respond to comments/feedback
- [ ] Fix critical bugs immediately
- [ ] Thank early adopters

---

## 📝 TODO: Before Launch

### Required Changes

1. **Replace Placeholders:**
   - [ ] `YOUR_USERNAME` → your GitHub username (in 6 places)
   - [ ] `YOUR_STORE_ID` → LemonSqueezy Store ID
   - [ ] `YOUR_PRODUCT_ID` → LemonSqueezy Product ID
   - [ ] `YOUR_VARIANT_ID` → LemonSqueezy Variant ID
   - [ ] `CHECKSUM_WILL_BE_ADDED_HERE` → actual SHA256 checksum
   - [ ] `support@zetanotes.app` → your support email

2. **Test Credentials:**
   - [ ] LemonSqueezy API key works
   - [ ] License validation works
   - [ ] Apple Developer ID certificate works
   - [ ] Notarization credentials work

3. **Legal:**
   - [ ] Add LICENSE file (MIT suggested)
   - [ ] Add privacy policy (optional but recommended)
   - [ ] Add terms of service (optional)

---

## 💡 Optional Enhancements

### Before Launch
- [ ] Create demo video/GIF
- [ ] Take screenshots for website
- [ ] Create app icon (if not done)
- [ ] Set up analytics (Plausible recommended)
- [ ] Add FAQ section to website

### After Launch
- [ ] Set up GitHub Discussions
- [ ] Create Discord server
- [ ] Build email list
- [ ] Plan v1.1 features
- [ ] Collect user feedback

---

## 🎯 Success Metrics

### Week 1 Goals
- 100 downloads
- 5 Pro purchases
- 10 GitHub stars
- Break even on Apple Developer fee

### Month 1 Goals
- 1,000 downloads
- 50 Pro purchases ($749 revenue)
- 50 GitHub stars
- 5 feature requests

### Year 1 Goals
- 10,000 downloads
- 500 Pro purchases ($7,495 revenue)
- 500 GitHub stars
- Active community

---

## 📞 Support Resources

- **LemonSqueezy Docs**: https://docs.lemonsqueezy.com
- **Apple Notarization**: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- **GitHub Pages**: https://docs.github.com/en/pages
- **Create-DMG**: https://github.com/create-dmg/create-dmg

---

## 🎉 You're Ready!

All code is complete. Follow the launch steps above to:

1. Set up LemonSqueezy (30 min)
2. Build & sign app (2-3 hours)
3. Create GitHub release (30 min)
4. Enable GitHub Pages (5 min)
5. Test everything (30 min)

**Total estimated time: 4-5 hours**

Good luck with your launch! 🚀
