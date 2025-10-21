# ZetaNotes Notarization Fixes - October 2025

## Problem Summary

Your notarization requests were stuck in "In Progress" status due to several critical issues identified after thorough review of Apple's guidelines and your codebase.

## Root Causes Identified

### 🚨 CRITICAL ISSUES FIXED

1. **Wrong Code Signing Certificate**
   - **Problem**: App was signed with "Apple Development" certificate
   - **Required**: "Developer ID Application" certificate for notarization
   - **Impact**: Apple likely held submission for "in-depth analysis"
   - **Status**: ✅ Fixed in build-llama.sh and release.sh

2. **Sparkle Framework Components - Ad-Hoc Signatures**
   - **Problem**: XPC services (Downloader.xpc, Installer.xpc) and Updater.app had ad-hoc signatures
   - **Required**: All components must be signed with Developer ID Application
   - **Impact**: Mixed signatures trigger notarization delays/rejections
   - **Status**: ✅ Fixed - release.sh now re-signs all Sparkle components

3. **App Sandbox Entitlement Conflict**
   - **Problem**: `com.apple.security.app-sandbox=true` conflicts with llama.cpp's memory requirements
   - **Required**: Sandbox only needed for Mac App Store distribution
   - **Impact**: May cause runtime issues and notarization scrutiny
   - **Status**: ✅ Fixed - Sandbox disabled for direct distribution

### ⚠️ ADDITIONAL IMPROVEMENTS

4. **Deprecated API Usage**
   - **Problem**: `NSStringPboardType` deprecated since macOS 10.14
   - **Status**: ✅ Replaced with modern UTI types (`public.utf8-plain-text`)

5. **Missing Privacy Descriptions**
   - **Problem**: No usage description keys in Info.plist
   - **Status**: ✅ Added defensive privacy descriptions

6. **Inconsistent Certificate Usage**
   - **Problem**: Build scripts could fall back to Apple Development
   - **Status**: ✅ Scripts now enforce Developer ID Application

## Files Modified

### 1. ZetaNotes/ZetaNotes.entitlements
- **Change**: Commented out `com.apple.security.app-sandbox`
- **Reason**: Not required for direct distribution; conflicts with llama.cpp
- **Note**: Re-enable only if distributing via Mac App Store

### 2. ZetaNotes/Info.plist
- **Changes**:
  - Replaced `NSStringPboardType` with `public.utf8-plain-text` and `public.plain-text`
  - Added `NSNetworkUsageDescription` and `NSLocalNetworkUsageDescription`
- **Reason**: Modernize APIs and add defensive privacy descriptions

### 3. scripts/build-llama.sh
- **Changes**:
  - Enforces Developer ID Application certificate
  - Fails build if certificate not found (no fallback to Apple Development)
  - Better error messages
- **Reason**: Ensure all llama.cpp dylibs properly signed from the start

### 4. scripts/release.sh
- **Changes**:
  - Added comprehensive Sparkle component re-signing
  - Re-signs XPC services (Downloader.xpc, Installer.xpc)
  - Re-signs Updater.app
  - Re-signs Sparkle.framework
  - Re-signs all llama.cpp dylibs
- **Reason**: Fix the critical ad-hoc signature issue

### 5. scripts/verify-signatures.sh (NEW)
- **Purpose**: Comprehensive pre-notarization verification
- **Features**:
  - Checks all component signatures
  - Verifies Developer ID usage
  - Verifies hardened runtime flags
  - Checks entitlements
  - Color-coded pass/fail output
- **Integration**: Automatically called by release.sh before DMG creation

## Script Enhancements

### release.sh v4.0 Improvements
1. **Automatic Signature Verification**: Calls verify-signatures.sh before DMG creation
2. **llama.cpp Rebuild Option**: Pass `rebuild` as second argument to force clean rebuild
3. **Better Error Handling**: Stops immediately if signature verification fails
4. **Usage Documentation**: Built-in help and examples

### verify-signatures.sh Features
1. **Comprehensive Checks**:
   - Main app signature and certificate type
   - Sparkle framework and all components
   - XPC services (Downloader.xpc, Installer.xpc)
   - Updater.app
   - All llama.cpp dylibs
   - Entitlements configuration
2. **Clear Output**: Color-coded pass/fail/warning indicators
3. **Exit Codes**: Returns 0 only if all checks pass
4. **Detailed Reporting**: Shows exactly what's wrong and where

## Next Steps

### 1. Clean Build
```bash
# Clean previous builds
rm -rf llama.cpp/build
xcodebuild clean -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Release

# Remove old releases (optional)
rm -rf releases/ZetaNotes-Release-*/
```

### 2. Build New Release

**Normal build (recommended for minor updates):**
```bash
cd scripts
./release.sh 0.0.6
```

**Full rebuild (recommended for major updates or first build after fixes):**
```bash
cd scripts
./release.sh 0.0.6 rebuild
```

The `rebuild` option will:
- Delete and rebuild llama.cpp from scratch
- Sign all dylibs with Developer ID
- Ensure clean state

### 3. Automatic Verification

The release script now automatically runs signature verification before creating the DMG. If verification fails, the build stops immediately.

You can also manually verify:
```bash
./verify-signatures.sh ../releases/ZetaNotes-Release-*/ZetaNotes.app
```

Expected output: All green checkmarks, no red errors

### 4. Submit for Notarization

The release script automatically submits if you have environment variables set:
```bash
export APPLE_ID="your-apple-id@example.com"
export APPLE_TEAM_ID="HDA4C6CU89"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

./release.sh 0.0.6
```

Or submit manually:
```bash
xcrun notarytool submit ZetaNotes-v0.0.6.dmg \
    --apple-id "your@email.com" \
    --team-id "HDA4C6CU89" \
    --password "xxxx-xxxx-xxxx-xxxx" \
    --wait
```

### 5. Monitor Status
```bash
./check-notarization-status.sh
```

## Expected Timeline

Based on Apple Developer Forum reports for first-time notarizations in 2025:

- **First submission**: 1-4 days (system learning to recognize your app)
- **Subsequent submissions**: Minutes to hours
- **Your case**: Since you already have 3 "In Progress" submissions, the new one with proper signatures should process faster

## Why "In Progress" Took So Long

1. **First-time developer**: Apple's notary service performs "in-depth analysis" for new developers
2. **Mixed certificates**: Apple Development + ad-hoc signatures triggered additional scrutiny
3. **Service delays**: January-March 2025 had documented notary service delays
4. **Learning period**: System needs to learn your app's signature pattern

## Technical Deep Dive

### Certificate Requirements
- ✅ Developer ID Application: Required for notarization
- ❌ Apple Development: Development/testing only
- ❌ Ad-hoc signatures: Never acceptable for notarization

### Hardened Runtime
All components must have `flags=0x10000(runtime)` or `flags=0x10002(adhoc,runtime)` is incorrect - the `adhoc` flag means it's not properly signed.

### Sparkle Framework Gotcha
Xcode automatically re-signs embedded frameworks during Archive, BUT:
- It preserves hardened runtime ✅
- It may use ad-hoc signatures for nested components ❌
- Solution: Explicitly re-sign XPC services and helpers

### llama.cpp Memory Requirements
- Needs: `allow-jit` and `allow-unsigned-executable-memory`
- Conflicts with: `app-sandbox` (in most cases)
- Solution: Sandbox only for Mac App Store builds

## Verification Checklist

Before submitting:
- [ ] All components signed with "Developer ID Application"
- [ ] No "Apple Development" signatures
- [ ] No ad-hoc signatures (`adhoc` flag)
- [ ] Hardened runtime on all components
- [ ] App Sandbox disabled (for direct distribution)
- [ ] JIT and unsigned-executable-memory entitlements present
- [ ] DMG signed with Developer ID
- [ ] Run verify-signatures.sh with 0 errors

## References

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Sparkle Code Signing Guide](https://sparkle-project.org/documentation/)
- Apple Developer Forums: Notarization delays in 2025

## Contact

If issues persist after these fixes:
- Check notarization log: `xcrun notarytool log <submission-id> ...`
- Apple Developer Technical Support (requires paid developer account)
- Review Apple Developer Forums for similar cases

---

Generated: October 21, 2025
Version: 1.0
