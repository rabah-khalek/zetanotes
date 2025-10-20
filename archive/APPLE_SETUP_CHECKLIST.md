# Apple Developer Program Setup - Quick Start Checklist

Use this checklist to track your progress setting up Apple Developer Program for ZetaNotes.

## Prerequisites

- [ ] macOS development Mac with Xcode installed
- [ ] GitHub account with access to zetanotes repository
- [ ] Credit card or payment method for Apple ($99/year)

## Phase 1: Apple Developer Enrollment (1-2 days)

- [ ] Go to https://developer.apple.com/programs/
- [ ] Click "Enroll" and sign in with your Apple ID
- [ ] Complete enrollment form
- [ ] Pay $99 enrollment fee
- [ ] Wait for approval email (1-2 business days)
- [ ] Confirm approval by logging into https://developer.apple.com/account

**Status:** ⏳ Waiting for Apple approval

---

## Phase 2: Get Certificates (30 minutes)

- [ ] Open Xcode on your Mac
- [ ] Go to Xcode → Settings → Accounts
- [ ] Click "+" and add your Apple ID
- [ ] Select your team and click "Download Manual Profiles"
- [ ] Open Keychain Access
- [ ] Verify "Developer ID Application" certificate exists
- [ ] If not, create one at https://developer.apple.com/account/resources/certificates/
- [ ] Note your Team ID from https://developer.apple.com/account (Membership section)

**Team ID:** _________________ (10-character code)

---

## Phase 3: Configure Xcode Project (5 minutes)

**Note:** Debug builds already work without Apple Developer account (ad-hoc signing).
You only need to configure Release builds for distribution.

- [ ] Open ZetaNotes.xcodeproj in Xcode
- [ ] Select ZetaNotes project → ZetaNotes target
- [ ] Go to "Signing & Capabilities" tab
- [ ] Click on "Release" in the configuration dropdown at top
- [ ] Select your Team from dropdown (only for Release)
- [ ] Verify "Automatically manage signing" is checked for Release
- [ ] Verify signing certificate shows "Developer ID Application" for Release
- [ ] Debug configuration should show "-" (ad-hoc) - don't change this
- [ ] Close Xcode

**Certificate Name:** Developer ID Application: ________________

---

## Phase 4: Create App-Specific Password (5 minutes)

- [ ] Go to https://appleid.apple.com
- [ ] Sign in with your Apple ID
- [ ] In Security section, click "App-Specific Passwords"
- [ ] Click "+" or "Generate Password"
- [ ] Label: "ZetaNotes Notarization"
- [ ] Copy the generated password (you can't view it again!)
- [ ] Save it securely (you'll need it for GitHub Secrets)

**App-Specific Password:** xxxx-xxxx-xxxx-xxxx

---

## Phase 5: Export Certificate for CI (10 minutes)

- [ ] Open Keychain Access
- [ ] Select login keychain → My Certificates
- [ ] Find "Developer ID Application: [Your Name]"
- [ ] Right-click → Export
- [ ] Save as Certificates.p12
- [ ] Set a strong password (write it down!)
- [ ] Open Terminal
- [ ] Run: `base64 -i Certificates.p12 -o Certificates.base64.txt`
- [ ] Run: `cat Certificates.base64.txt`
- [ ] Copy the base64 output (you'll paste into GitHub Secrets)

**Certificate Password:** ________________

---

## Phase 6: Configure GitHub Secrets (10 minutes)

- [ ] Go to https://github.com/rabah-khalek/zetanotes
- [ ] Click Settings → Secrets and variables → Actions
- [ ] Click "New repository secret" for each:

| Secret Name | Value | Status |
|-------------|-------|--------|
| `APPLE_CERTIFICATE_BASE64` | (paste base64 from Phase 5) | ☐ |
| `APPLE_CERTIFICATE_PASSWORD` | (password from Phase 5) | ☐ |
| `APPLE_ID` | your@email.com | ☐ |
| `APPLE_TEAM_ID` | (from Phase 2) | ☐ |
| `APPLE_APP_SPECIFIC_PASSWORD` | (from Phase 4) | ☐ |

- [ ] All 5 secrets added successfully

---

## Phase 7: Test Local Build (15 minutes)

- [ ] Open Terminal
- [ ] cd to zetanotes-dev directory
- [ ] Run: `./scripts/release.sh 1.0.1`
- [ ] Verify output shows:
  - [ ] "✓ Found Developer ID certificate"
  - [ ] "✓ App signed successfully"
  - [ ] "✓ DMG signed"
- [ ] Find the DMG on your Desktop
- [ ] Mount the DMG
- [ ] Drag ZetaNotes to Applications
- [ ] Double-click to launch
- [ ] Verify: No security warnings!

**Local build test:** ☐ PASSED

---

## Phase 8: Test Notarization (30 minutes)

- [ ] Set environment variables in Terminal:
  ```bash
  export APPLE_ID="your@email.com"
  export APPLE_TEAM_ID="YOUR_TEAM_ID"
  export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
  ```
- [ ] Run: `./scripts/release.sh 1.0.2`
- [ ] Wait 5-30 minutes for notarization
- [ ] Verify output shows:
  - [ ] "✓ Notarization successful!"
  - [ ] "✓ Notarization ticket stapled"
- [ ] Run: `spctl -a -vv ~/Desktop/ZetaNotes-Release-*/ZetaNotes-v1.0.2.dmg`
- [ ] Verify: "source=Notarized Developer ID"

**Notarization test:** ☐ PASSED

---

## Phase 9: Deploy to GitHub (10 minutes)

- [ ] Commit all changes:
  ```bash
  git add .
  git commit -m "Configure Apple Developer Program signing"
  git push
  ```
- [ ] Create release tag:
  ```bash
  git tag v1.0.3
  git push origin v1.0.3
  ```
- [ ] Go to GitHub → Actions tab
- [ ] Watch "Build and Release" workflow
- [ ] Verify workflow completes successfully
- [ ] Go to Releases tab
- [ ] Verify new release v1.0.3 exists
- [ ] Download the DMG
- [ ] Test installation on a clean Mac (if possible)

**GitHub Actions:** ☐ PASSED

---

## Phase 10: Final Verification (15 minutes)

### On Your Development Mac
- [ ] Download DMG from GitHub Releases
- [ ] Mount DMG
- [ ] Drag to Applications (replacing old version)
- [ ] Launch ZetaNotes
- [ ] Verify: No security warnings
- [ ] Check for updates (should work via Sparkle)

### On a Clean Mac (if available)
- [ ] Download DMG on a Mac that's never had ZetaNotes
- [ ] Mount DMG
- [ ] Drag to Applications
- [ ] Double-click to launch
- [ ] Verify: Opens immediately without warnings
- [ ] Verify: AI model download works
- [ ] Verify: All features work

**Final verification:** ☐ PASSED

---

## ✅ Setup Complete!

Congratulations! Your app is now professionally distributed with:

- ✅ Code signed with Apple Developer ID
- ✅ Notarized by Apple
- ✅ No security warnings for users
- ✅ Automatic updates via Sparkle
- ✅ Professional CI/CD pipeline

## Next Release

For your next release, simply:

1. Update version in code
2. Commit changes
3. Push tag: `git tag v1.0.4 && git push origin v1.0.4`
4. GitHub Actions handles the rest automatically!

## Support

- **Detailed Guide:** `docs/APPLE_DEVELOPER_SETUP.md`
- **Summary:** `docs/SETUP_COMPLETE.md`
- **Issues:** https://github.com/rabah-khalek/zetanotes/issues

---

**Completion Date:** ________________

**Notes:**

_______________________________________________
_______________________________________________
_______________________________________________
