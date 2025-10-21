# ZetaNotes - Quick Start After Notarization Fixes

## What Was Fixed

✅ **Code signing** - Now uses Developer ID Application (required for notarization)
✅ **Sparkle components** - XPC services and Updater.app properly signed
✅ **App Sandbox** - Disabled for direct distribution (conflicts with llama.cpp)
✅ **Deprecated APIs** - Replaced NSStringPboardType with modern UTI types
✅ **Automatic verification** - Added pre-notarization signature checking

## Build Your First Notarization-Ready Release

### Quick Command (Recommended)
```bash
cd scripts
./release.sh 0.0.6 rebuild
```

This will:
1. Rebuild llama.cpp with proper signatures
2. Build ZetaNotes.app with Developer ID certificate
3. Re-sign all Sparkle components
4. Verify ALL signatures automatically
5. Create signed DMG
6. Submit for notarization (if credentials set)

### Step-by-Step

**1. Set Environment Variables (for automatic notarization)**
```bash
export APPLE_ID="your-apple-id@example.com"
export APPLE_TEAM_ID="HDA4C6CU89"  # Your team ID
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

**2. Clean Previous Builds**
```bash
rm -rf llama.cpp/build
rm -rf releases/ZetaNotes-Release-*/
```

**3. Run Release Script**
```bash
cd scripts
./release.sh 0.0.6 rebuild
```

**4. Monitor Output**
Look for:
- ✓ All libraries signed with Developer ID
- ✓ Sparkle components re-signed with Developer ID
- ✓ All signatures verified successfully
- ✓ Notarization successful!

**5. Check Status (if needed)**
```bash
./check-notarization-status.sh
```

## What to Expect

### First Notarization After Fixes
- **Duration**: Could still take 1-4 days (Apple's system learning)
- **Reason**: First-time developer + previous "In Progress" submissions
- **Good news**: Proper signatures = much higher success rate

### Subsequent Notarizations
- **Duration**: Minutes to hours
- **Reason**: Apple's system recognizes your app

## Common Issues & Solutions

### Issue: "Developer ID Application certificate not found"
**Solution**: Check your certificates
```bash
security find-identity -v -p codesigning
```
You should see: "Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"

### Issue: Signature verification fails
**Solution**: Run manual verification to see details
```bash
./verify-signatures.sh ../releases/ZetaNotes-Release-*/ZetaNotes.app
```
Fix any red ✗ errors shown.

### Issue: Notarization rejected with specific errors
**Solution**: Get detailed log
```bash
xcrun notarytool log <submission-id> \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD"
```

## Release Script Options

### Normal Build
```bash
./release.sh 0.0.6
```
Uses existing llama.cpp build. Good for quick iterations.

### Full Rebuild
```bash
./release.sh 0.0.6 rebuild
```
Rebuilds llama.cpp from scratch. **Recommended for:**
- First build after applying fixes
- Major version updates
- If you suspect llama.cpp signature issues

## Verification Only (No Build)

Want to check an existing build?
```bash
./verify-signatures.sh path/to/ZetaNotes.app
```

Example:
```bash
./verify-signatures.sh releases/ZetaNotes-Release-20251021-164118/ZetaNotes.app
```

## Files Modified (For Reference)

- `ZetaNotes/ZetaNotes.entitlements` - App Sandbox disabled
- `ZetaNotes/Info.plist` - Modern UTI types, privacy descriptions
- `scripts/build-llama.sh` - Enforces Developer ID
- `scripts/release.sh` - Sparkle signing + verification
- `scripts/verify-signatures.sh` - NEW comprehensive checker

## Success Checklist

Before submitting:
- [ ] Built with `./release.sh X.X.X rebuild`
- [ ] Saw green ✓ for all signature verifications
- [ ] DMG created successfully
- [ ] Environment variables set (APPLE_ID, etc.)
- [ ] Submitted to notarization

## Need Help?

1. **Read full details**: See [NOTARIZATION_FIXES.md](NOTARIZATION_FIXES.md)
2. **Check signatures**: Run `./verify-signatures.sh <app-path>`
3. **Review logs**: Get notarization log with `xcrun notarytool log <id> ...`
4. **Apple Support**: Use Apple Developer Technical Support if issues persist

## Why This Will Work

The previous "In Progress" issues were caused by:
1. ❌ Apple Development certificate (wrong)
2. ❌ Ad-hoc signatures on Sparkle components
3. ❌ App Sandbox conflict with llama.cpp

All of these are now **FIXED**:
1. ✅ Developer ID Application certificate enforced
2. ✅ All components properly signed
3. ✅ App Sandbox disabled (correct for direct distribution)
4. ✅ Automatic verification prevents mistakes

---

**Ready to build?** Run:
```bash
cd scripts && ./release.sh 0.0.6 rebuild
```

Good luck! 🚀
