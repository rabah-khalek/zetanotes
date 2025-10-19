# Distribution Strategy: Unsigned vs Signed

## How Successful Apps Handle Distribution

### Tier 1: Fully Signed & Notarized (Linear, VS Code, Discord)

**What they do:**
- Pay $99/year for Apple Developer
- Sign with Developer ID certificate
- Notarize with Apple's servers
- Staple notarization ticket
- Distribute via DMG or PKG

**User experience:**
```
1. Download app
2. Open app → Works immediately
3. Auto-updates → Seamless
```

**Cost:** $99/year + time to set up

**Best for:**
- Commercial apps
- Apps with paying users (>100)
- Professional/enterprise users
- Apps that need frequent updates

---

### Tier 2: Ad-hoc Signed (Your Current Approach)

**What you do:**
- No Apple Developer account
- Use ad-hoc signing (`codesign --sign -`)
- Aggressive quarantine removal
- Clear documentation

**User experience:**
```
1. Download app
2. Open app → Blocked by Gatekeeper
3. Right-click → Open → Confirm
4. Or run terminal command
5. Future opens: Normal
6. Updates: Manual download
```

**Cost:** $0/year + excellent documentation

**Best for:**
- Open source projects
- Developer-focused apps
- Early stage/MVP apps
- Apps with <100 users
- Apps without revenue yet

---

### Tier 3: Homebrew Distribution (Developer Apps)

**What apps like neovim, ripgrep, fzf do:**
```bash
brew install --cask linear  # If they supported it
```

**User experience:**
```
1. brew install --cask zetanotes
2. App installs with --no-quarantine flag
3. Works immediately
4. Updates: brew upgrade
```

**Cost:** $0/year + maintain Cask formula

**Best for:**
- CLI tools
- Developer utilities
- Technical audience
- Open source

---

## Linear's Full Stack (What They Likely Use)

### Distribution
```javascript
// Using Electron Builder or similar
{
  "mac": {
    "hardenedRuntime": true,
    "gatekeeperAssess": false,
    "entitlements": "build/entitlements.mac.plist",
    "entitlementsInherit": "build/entitlements.mac.plist",
    "notarize": {
      "teamId": "LINEAR_TEAM_ID"
    }
  }
}
```

### Build Process
```bash
# 1. Build app
electron-builder build --mac

# 2. Sign with Developer ID
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Linear Inc (TEAM_ID)" \
  --options runtime \
  Linear.app

# 3. Package as DMG/PKG
electron-builder --mac dmg

# 4. Notarize (automated)
xcrun notarytool submit Linear.dmg \
  --apple-id "dev@linear.app" \
  --team-id "TEAM_ID" \
  --password "@keychain:AC_PASSWORD" \
  --wait

# 5. Staple ticket
xcrun stapler staple Linear.dmg

# 6. Upload to CDN
aws s3 cp Linear.dmg s3://downloads.linear.app/
```

### Auto-Updates
```javascript
// Using electron-updater (Electron) or Sparkle (native)
import { autoUpdater } from 'electron-updater';

autoUpdater.checkForUpdatesAndNotify();
// Works seamlessly because app is notarized
```

---

## Your Path Forward (Recommended)

### Phase 1: Now (No Apple Developer) ✅
**What you have:**
- Ad-hoc signed app
- Clear installation instructions
- Troubleshooting script
- Manual updates

**Good for:**
- Initial launch
- Getting first users
- Validating product
- Building community

**User friction:**
- One-time right-click OR terminal command
- Manual update checks

---

### Phase 2: Early Revenue ($1-10/month from ~10-20 users)

**Upgrade to Apple Developer ($99/year)**

**ROI Calculation:**
```
Cost: $99/year
Break-even: 10 annual users ($6/year) = $60/year
         OR 100 monthly users ($1/month) = $100/month

If you have >20 paying users, the $99 pays for itself
```

**Benefits:**
- ✅ Eliminates all support for installation issues
- ✅ Enables automatic updates (huge!)
- ✅ Professional appearance
- ✅ Higher conversion rate (easier to try)

**What changes:**
```bash
# Update release.sh
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --timestamp --options runtime \
  ZetaNotes.app

notarytool submit ZetaNotes.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "@keychain:AC_PASSWORD"

stapler staple ZetaNotes.dmg
```

**Update Sparkle config:**
```xml
<!-- Now works automatically -->
<item>
    <title>Version 1.1.0</title>
    <sparkle:version>1.1.0</sparkle:version>
    <link>https://github.com/.../ZetaNotes-v1.1.0.dmg</link>
    <!-- No user interaction needed! -->
</item>
```

---

### Phase 3: Growth (100+ users)

**Additional optimizations:**
- CI/CD for automated notarization
- PKG installer (more professional than DMG)
- Multiple distribution channels (brew cask)
- Download page with trust signals

---

## Comparison: Linear vs ZetaNotes

| Aspect | Linear | ZetaNotes (Current) | ZetaNotes (with Dev ID) |
|--------|--------|---------------------|------------------------|
| **Distribution** | Signed + Notarized | Ad-hoc signed | Signed + Notarized |
| **Installation** | Click & open | Right-click + open | Click & open |
| **Security Warning** | None | "Unidentified developer" | None |
| **Auto Updates** | Seamless | Manual | Seamless |
| **Cost** | $99/year | $0/year | $99/year |
| **Support Burden** | Minimal | Some | Minimal |
| **Professionalism** | High | Medium | High |
| **Time to First Run** | 10 seconds | 60 seconds + terminal | 10 seconds |

---

## Other Successful Unsigned Apps (Proof It Works)

### Sublime Text (Early Years)
- Unsigned for first ~5 years
- Users understood (developer tool)
- Still became very successful
- Later got signed

### OBS Studio (Open Source)
- Unsigned on some platforms
- Large user base
- Clear instructions work
- Community helps newcomers

### Blender (Early macOS Versions)
- Had installation friction
- Users dealt with it
- Professional 3D software
- Now fully signed

### Key Lesson:
**If your product is good, users will jump through hoops**

But... fewer hoops = more users.

---

## Decision Framework

### Stay Unsigned If:
- ✅ You have <50 active users
- ✅ No revenue yet
- ✅ Developer/technical audience
- ✅ Open source with community support
- ✅ Still iterating rapidly
- ✅ Want to minimize costs

### Get Apple Developer If:
- ✅ You have 20+ paying users
- ✅ Making >$200/year revenue
- ✅ Non-technical audience
- ✅ Want to reduce support burden
- ✅ Frequent updates (>1/month)
- ✅ Professional appearance matters

### The Math:
```
Support time saved: ~1-2 hours/week
Your hourly rate: $50/hour (conservative)
Annual savings: 52 weeks × 1.5 hours × $50 = $3,900

Cost of Apple Developer: $99/year

ROI: 3,900% 🚀
```

---

## How to Migrate When Ready

### 1. Get Apple Developer Account
```
https://developer.apple.com/programs/enroll/
$99/year (credit card)
Approval: 1-2 days
```

### 2. Create Certificates
```bash
# In Xcode
Xcode → Settings → Accounts → Manage Certificates
→ Create "Developer ID Application" certificate
```

### 3. Update Build Script
```bash
# Add to release.sh
IDENTITY="Developer ID Application: Your Name (TEAM_ID)"

codesign --deep --force --verify --verbose \
  --sign "$IDENTITY" \
  --options runtime \
  --timestamp \
  "$BUILD_DIR/ZetaNotes.app"
```

### 4. Set Up Notarization
```bash
# Store credentials
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID"

# Add to release.sh
xcrun notarytool submit "$DMG_NAME" \
  --keychain-profile "AC_PASSWORD" \
  --wait

xcrun stapler staple "$DMG_NAME"
```

### 5. Update Sparkle
```xml
<!-- appcast.xml - auto-updates now work! -->
<enclosure
  url="https://github.com/.../ZetaNotes-v1.0.0.dmg"
  sparkle:version="1.0.0"
  sparkle:shortVersionString="1.0.0"
  sparkle:edSignature="BASE64_SIGNATURE"
  length="123456789"
  type="application/octet-stream"
/>
```

### 6. Migration for Existing Users
```
Release notes:
"🎉 ZetaNotes is now notarized by Apple!
 - No more security warnings
 - Automatic updates now work seamlessly
 - Existing users: Just download this version once"
```

---

## The Bottom Line

**Linear can do it because:**
1. They have revenue/funding ($99/year is nothing for them)
2. They target professionals (high expectations)
3. They update frequently (auto-updates are critical)
4. It's a commercial product (professionalism matters)

**You should do it when:**
1. You have enough paying users to justify $99/year
2. Installation friction is causing user drop-off
3. You want to ship updates more than once/month
4. Support burden for installation issues is >2 hours/week

**Current strategy is fine because:**
1. You're just launching
2. You have clear documentation
3. Developer audience understands
4. You can upgrade later without issues

**Recommended trigger:** Once you have **20+ Pro subscribers**, get the Apple Developer account. That's when it pays for itself immediately.

---

## Quick Win: Homebrew Cask (Free!)

While waiting for revenue to justify Apple Developer:

```ruby
# zetanotes.rb
cask "zetanotes" do
  version "1.0.0"
  sha256 "abc123..."

  url "https://github.com/rabah-khalek/zetanotes/releases/download/v#{version}/ZetaNotes-v#{version}.dmg"
  name "ZetaNotes"
  desc "Privacy-first note-taking with offline AI"
  homepage "https://github.com/rabah-khalek/zetanotes"

  app "ZetaNotes.app"

  # Homebrew handles the quarantine flag!
  postflight do
    system_command "/usr/bin/xattr",
      args: ["-cr", "#{appdir}/ZetaNotes.app"]
  end
end
```

**Users install:**
```bash
brew install --cask zetanotes
# No security warnings!
# Homebrew removes quarantine automatically
```

This gives you a **professional distribution channel for $0** while you build revenue! 🚀

---

**Created:** October 19, 2025
