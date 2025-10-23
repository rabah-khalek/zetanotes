# App Review Build Guide

## Overview

This guide explains how to create a special build of ZetaNotes for Apple App Review that includes test credentials for reviewers to access Pro features.

## What's Different in App Review Builds?

App Review builds include a special compilation flag (`APP_REVIEW_BUILD`) that enables test credentials:

- **Email:** `admin`
- **License Key:** `TEST`

These credentials grant **Lifetime Pro** access to all features for Apple reviewers to test.

## How to Build for App Review

### Command

```bash
./scripts/release.sh <version> --app-review
```

### Examples

```bash
# Build version 1.0.0 for App Review
./scripts/release.sh 1.0.0 --app-review

# Build version 1.2.3 for App Review
./scripts/release.sh 1.2.3 --app-review
```

### What Happens

1. The script parses the `--app-review` flag
2. Swift compilation includes `-DAPP_REVIEW_BUILD` flag
3. LicenseManager enables test credentials in the release build
4. Build completes with special marking in console output
5. Summary displays test credentials to provide to Apple

## Build Output

When the build completes, you'll see:

```
═══════════════════════════════════════════════════════════════
  APP REVIEW BUILD - PROVIDE THESE CREDENTIALS TO APPLE
═══════════════════════════════════════════════════════════════
  Email:        admin
  License Key:  TEST
═══════════════════════════════════════════════════════════════
```

## Providing Credentials to Apple

### In App Store Connect

1. Navigate to your app → App Review Information
2. In the "Sign-In Information" section:
   - **Username:** `admin`
   - **Password:** `TEST`
3. In the "Notes" section, include:

```
This is a special App Review build with test credentials enabled.

Test Account:
- Email: admin
- License Key: TEST

This allows reviewers to test all Pro features. We are migrating from
Paddle to Apple In-App Purchases, which will be included in an upcoming
update.

For detailed review notes, see the included APP_REVIEW_NOTES.md document.
```

## Verification

To verify the build includes test credentials:

1. Launch the built app
2. Navigate to Settings → License
3. Click "Activate License"
4. Enter: Email=`admin`, Key=`TEST`
5. Should activate successfully with Lifetime Pro

## Important Notes

### ⚠️ DO NOT Use for Production

**NEVER** use the `--app-review` flag for public releases! Test credentials must only be enabled for builds submitted to Apple for review.

### Production Builds

For normal production releases, use:

```bash
./scripts/release.sh <version>
```

This builds **without** the `APP_REVIEW_BUILD` flag, and test credentials will NOT work.

### After IAP Integration

Once Apple In-App Purchases are integrated:

1. Submit a new build **without** `--app-review` flag
2. Remove test credential notes from App Store Connect
3. Users will purchase through IAP instead

## Code Changes

The `--app-review` flag makes the following changes:

### 1. LicenseManager.swift

```swift
#if DEBUG || APP_REVIEW_BUILD
private let allowTestLicense = true
private let testLicenseKey = "TEST"
private let testLicenseEmail = "ADMIN"
#endif
```

### 2. Xcode Build

Adds Swift compilation flag:

```bash
OTHER_SWIFT_FLAGS="-DAPP_REVIEW_BUILD"
```

### 3. Console Logging

App Review builds log:

```
🔍 APP REVIEW BUILD: Test credentials enabled for Apple reviewers
✅ Test license activated (APP REVIEW BUILD - Lifetime)
```

Debug builds log:

```
🔍 DEBUG: Checking test credentials...
✅ Test license activated (DEV MODE - Lifetime)
```

## Troubleshooting

### Test credentials don't work

**Check build was created with `--app-review` flag:**

```bash
# Verify the flag was used during build
grep -r "APP REVIEW BUILD" releases/
```

**Check console logs** when activating license:
- Should see "APP REVIEW BUILD: Test credentials enabled"
- Should NOT see "continuing to API validation"

### Build fails with Swift flag error

Make sure you're using Xcode 12+ which supports `OTHER_SWIFT_FLAGS`.

### Credentials work in production build

**This should never happen!** If test credentials work in a build made without `--app-review`, there's a bug. Contact the development team immediately.

## Security

### Why This Approach is Safe

1. **Flag must be explicitly set:** Developers must intentionally add `--app-review`
2. **Build logs clearly indicate status:** Console output warns when App Review mode is active
3. **Separate from DEBUG builds:** Uses dedicated compilation flag, not Debug configuration
4. **No hardcoded backdoors:** Without the flag, test credentials are completely disabled

### Future Migration

When IAP is ready:

1. Test credentials code can be removed entirely
2. App Review builds will use Sandbox IAP with test accounts
3. No special build flags needed

## Related Files

- [LicenseManager.swift](../ZetaNotes/Managers/LicenseManager.swift) - License validation logic
- [APP_REVIEW_NOTES.md](../docs/APP_REVIEW_NOTES.md) - Document to share with Apple
- [release.sh](release.sh) - Main release script
- [lib/xcode.sh](lib/xcode.sh) - Xcode build functions

## Questions?

For questions about the App Review build process, contact the development team.
