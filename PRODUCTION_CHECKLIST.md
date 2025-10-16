# Production Deployment Checklist

## ⚠️ CRITICAL: Before Building for Production

This document ensures NO development code leaks into your production release.

---

## 1. Replace DEV_TODO Placeholders

### LemonSqueezy Configuration

**File:** `NoteTaker/Managers/LicenseManager.swift`

```swift
// Lines 84-87
// BEFORE (Development):
let storeId = "DEV_STORE_ID" // DEV_TODO: CHANGE THIS
let productId = "DEV_PRODUCT_ID" // DEV_TODO: CHANGE THIS

// AFTER (Production):
let storeId = "123456" // Your actual LemonSqueezy store ID
let productId = "789012" // Your actual LemonSqueezy product ID
```

**How to get these values:**

1. Go to <https://app.lemonsqueezy.com/settings/api>
2. Find your store ID in the URL or API settings
3. Go to your product page and note the product ID

---

**File:** `NoteTaker/Views/UpgradePromptView.swift`

```swift
// Line 155
// BEFORE (Development):
let checkoutURL = "https://offnotes.lemonsqueezy.com/checkout/buy/DEV_VARIANT_ID"

// AFTER (Production):
let checkoutURL = "https://offnotes.lemonsqueezy.com/checkout/buy/abc123def456"
```

**How to get this value:**

1. Go to <https://app.lemonsqueezy.com/products>
2. Click on "OffNotes Pro"
3. Go to "Checkout" tab
4. Copy the full checkout URL or just the variant ID

---

## 2. Verify DEBUG Blocks

### Test License Code (Safe - Already Protected)

**File:** `NoteTaker/Managers/LicenseManager.swift`

```swift
// Lines 28-32 - ALREADY SAFE ✅
#if DEBUG
private let allowTestLicense = true
private let testLicenseKey = "TEST"
private let testLicenseEmail = "ADMIN"
#endif
```

**File:** `NoteTaker/Views/UpgradePromptView.swift`

```swift
// Lines 290-294 - ALREADY SAFE ✅
#if DEBUG
Text("Debug: Use email 'admin' and key 'test'")
    .font(.caption)
    .foregroundColor(.orange)
#endif
```

These blocks are **automatically removed** in Release builds. No action needed.

---

## 3. Run Automated Safety Checks

The package script will automatically check for issues:

```bash
./scripts/package-unsigned.sh
```

**What it checks:**

- ✅ DEV_TODO markers presence
- ✅ DEBUG blocks are properly wrapped
- ✅ Test credentials are protected
- ✅ Build configuration is Release
- ✅ No development databases in bundle

**If any check fails:** The script will STOP and show exactly what needs to be fixed.

---

## 4. Manual Verification (Double-Check)

### Search for Dev Markers

```bash
# Should return ZERO results in production code:
grep -rn "DEV_STORE_ID\|DEV_PRODUCT_ID\|DEV_VARIANT_ID" NoteTaker/

# If you see results, replace them with real values!
```

### Verify Test Credentials Are Protected

```bash
# Should only appear inside #if DEBUG blocks:
grep -B2 -A2 "testLicenseKey" NoteTaker/Managers/LicenseManager.swift

# You should see:
# #if DEBUG
# private let testLicenseKey = "TEST"
# ...
# #endif
```

---

## 5. What Gets Removed in Production

When you build with `-configuration Release`, Swift compiler automatically:

### ✅ Removes This Code

```swift
#if DEBUG
// All this code is REMOVED in Release builds
private let allowTestLicense = true
private let testLicenseKey = "TEST"
private let testLicenseEmail = "ADMIN"

print("🔍 DEBUG: Checking test credentials...")
// ... all debug prints
#endif
```

### ✅ Keeps This Code

```swift
// This stays in Release builds
func validateLicense(key: String, email: String) async -> Bool {
    let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    // Production API validation
    let isValid = await validateWithLemonSqueezy(key: cleanKey, email: cleanEmail)
    return isValid
}
```

---

## 6. Pre-Release Testing Checklist

### Test in Release Configuration

```bash
# Build in Release mode
xcodebuild -project NoteTaker.xcodeproj \
           -scheme NoteTaker \
           -configuration Release \
           build

# Run the Release build
open ~/Library/Developer/Xcode/DerivedData/NoteTaker-*/Build/Products/Release/NoteTaker.app
```

### Verify Test Credentials DON'T Work

1. Open the Release build
2. Try to activate with email: `admin`, key: `test`
3. **Should FAIL** - "Invalid license key"
4. Try with a real license key
5. **Should WORK** - License activated

**If test credentials work in Release build:** Something is wrong! Check #if DEBUG blocks.

---

## 7. Common Mistakes to Avoid

### ❌ DON'T DO THIS

```swift
// WRONG - No DEBUG protection
let testMode = true
if testMode {
    return true // This will leak to production!
}
```

### ✅ DO THIS

```swift
// CORRECT - Properly protected
#if DEBUG
if allowTestLicense {
    return true
}
#endif
```

---

## 8. Package Script Safety Features

The `./scripts/package-unsigned.sh` has built-in safety checks:

```bash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   PRODUCTION SAFETY CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Checking for DEV_TODO markers...
   ✓ No DEV_TODO markers found

2. Verifying DEBUG-only code is properly wrapped...
   ✓ DEBUG blocks verified in LicenseManager

3. Checking test license configuration...
   ✓ Test credentials properly wrapped in #if DEBUG

4. Verifying build configuration...
   ✓ Release build confirmed

✓ All production safety checks passed!
```

---

## 9. Emergency Rollback

If you accidentally shipped dev code:

1. **Immediately remove** the DMG from download links
2. Post update: "Version [X] has been pulled for technical issues"
3. Fix the code
4. Increment version number
5. Re-run all checks
6. Release new version

---

## 10. Final Pre-Launch Checklist

Before uploading to GitHub Releases:

- [ ] All DEV_TODO markers replaced with real values
- [ ] Tested Release build doesn't accept test credentials
- [ ] Package script shows all green ✓ checks
- [ ] Verified no development data in app bundle
- [ ] Tested license activation with real LemonSqueezy key
- [ ] Uploaded DMG to VirusTotal (for trust)
- [ ] Generated SHA256 checksum
- [ ] Updated download page with new checksum
- [ ] Tested DMG installation on clean Mac

---

## Quick Reference

### Development Mode (DEBUG)

- Email: `admin`, Key: `test` → ✅ Works
- Test credentials bypass API

### Production Mode (RELEASE)

- Email: `admin`, Key: `test` → ❌ Fails
- All validation goes through LemonSqueezy API

### Check Current Build Mode

```swift
#if DEBUG
print("Running in DEBUG mode")
#else
print("Running in RELEASE mode")
#endif
```

---

## Need Help?

If you're unsure about any step:

1. **Test in Release mode first** (section 6)
2. **Run the package script** - it will catch most issues
3. **Check the grep commands** in section 4
4. **When in doubt:** Better to be paranoid than leak dev code!

Remember: **The package script will STOP if it finds issues.** Trust it.

---

**Last Updated:** October 16, 2025
**Next Review:** Before each release
