# Code Signing Configuration

## Overview

ZetaNotes uses different code signing configurations for Debug and Release builds:

- **Debug builds** (`./build`, `./run`) - Use ad-hoc signing (no Apple Developer account needed)
- **Release builds** (`./scripts/release.sh`) - Use Developer ID Application signing (requires Apple Developer Program)

## Configuration

### Debug Configuration
```
CODE_SIGN_IDENTITY = "-"           // Ad-hoc signing (local development)
CODE_SIGN_STYLE = Manual           // No automatic provisioning
ENABLE_HARDENED_RUNTIME = NO       // Not needed for development
DEVELOPMENT_TEAM = (not required)  // No team needed
```

**Purpose:** Allows local development without Apple Developer account

**Usage:**
```bash
./build   # Builds with ad-hoc signing
./run     # Runs locally without security warnings
```

### Release Configuration
```
CODE_SIGN_IDENTITY = "Developer ID Application"  // Professional signing
CODE_SIGN_STYLE = Automatic                      // Auto-selects certificate
ENABLE_HARDENED_RUNTIME = YES                    // Required for notarization
DEVELOPMENT_TEAM = "YOUR_TEAM_ID"               // Set when Apple Dev account ready
```

**Purpose:** Professional distribution with Apple Developer Program

**Usage:**
```bash
# Local release build (requires Developer ID certificate)
./scripts/release.sh 1.0.1

# Or via GitHub Actions (requires GitHub Secrets configured)
git tag v1.0.1 && git push origin v1.0.1
```

## For Developers

### Local Development (No Apple Developer Account)

You can develop and test ZetaNotes locally without any Apple Developer account:

1. **Build:** `./build`
2. **Run:** `./run` or `open build/Build/Products/Debug/ZetaNotes.app`
3. The app will be signed with ad-hoc signature (for local use only)

**Limitations of ad-hoc signing:**
- ⚠️ Cannot distribute to other users
- ⚠️ Cannot notarize
- ⚠️ Cannot use on other Macs
- ✅ Perfect for local development and testing

### Release Distribution (Apple Developer Program Required)

When you're ready to distribute:

1. **Enroll** in Apple Developer Program ($99/year)
2. **Configure** certificates (see `APPLE_DEVELOPER_SETUP.md`)
3. **Add Team ID** to `ZetaNotes.xcodeproj` Release configuration:
   ```
   DEVELOPMENT_TEAM = "ABC1234DEF"  // Your Team ID
   ```
4. **Build and notarize:** `./scripts/release.sh 1.0.1`

See `docs/APPLE_DEVELOPER_SETUP.md` for complete setup instructions.

## Troubleshooting

### "Signing for ZetaNotes requires a development team"

**If this happens in Debug/Development:**
- This should not happen with current config
- Verify you're building in Debug configuration: `./build`
- Check project settings: `CODE_SIGN_IDENTITY` should be `"-"` for Debug

**If this happens in Release:**
- This is expected - you need Apple Developer Program
- Either: Add your `DEVELOPMENT_TEAM` to Release config
- Or: Use Debug builds for local development

### "Code signature invalid"

**Debug builds:**
- Ad-hoc signatures are only valid on the Mac that built them
- This is normal and expected

**Release builds:**
- Ensure you have valid Developer ID Application certificate
- Run: `security find-identity -v -p codesigning`
- Should show "Developer ID Application: [Your Name]"

### "App cannot be opened because the developer cannot be verified"

**Debug builds:**
- Right-click → Open (one time only)
- This is expected for ad-hoc signed apps

**Release builds:**
- Should not happen if properly signed and notarized
- Verify notarization: `spctl -a -vv /path/to/ZetaNotes.app`

## Summary

| Build Type | Purpose | Code Signing | Apple Dev Required | Distribution |
|------------|---------|--------------|-------------------|--------------|
| **Debug** | Local development | Ad-hoc (`-`) | ❌ No | Local only |
| **Release** | Production distribution | Developer ID | ✅ Yes | Public |

The current configuration allows you to:
- ✅ Develop locally without Apple Developer account
- ✅ Test all features during development
- ✅ Distribute professionally when ready (with Apple Dev account)

## Next Steps

1. **For local development:** You're all set! Just use `./build` and `./run`
2. **For distribution:** When Apple Developer Program is approved, see `APPLE_DEVELOPER_SETUP.md`
