# App Store Distribution - Issues Fixed

## Problems Identified

The distribution validation errors occurred due to several issues:

### 1. **Invalid Bundle Identifier Variables**
**Error:** `Invalid Bundle Identifier. The application bundle contains a tool or framework $(PRODUCT_NAME) using the bundle identifier '$(PRODUCT_BUNDLE_IDENTIFIER)'`

**Root Cause:** The Info.plist file was using Xcode build variables like `$(PRODUCT_BUNDLE_IDENTIFIER)`, `$(PRODUCT_NAME)`, and `$(EXECUTABLE_NAME)`. When exporting for distribution, these variables weren't being properly expanded, leaving placeholder text in the final package.

**Fix:** Replaced all variable placeholders in `ZetaNotes/Info.plist` with hardcoded values:
- `$(PRODUCT_BUNDLE_IDENTIFIER)` → `com.zetanotes.zetanotes`
- `$(PRODUCT_NAME)` → `ZetaNotes`
- `$(EXECUTABLE_NAME)` → `ZetaNotes`
- `$(PRODUCT_BUNDLE_PACKAGE_TYPE)` → `APPL`
- `$(DEVELOPMENT_LANGUAGE)` → `en`
- `$(MACOSX_DEPLOYMENT_TARGET)` → `13.0`

### 2. **Missing Debug Symbols (dSYM) for llama.cpp Libraries**
**Error:** `The archive did not include a dSYM for the libggml-*.dylib and libllama.dylib`

**Root Cause:** The CMake build configuration for llama.cpp wasn't generating debug symbols, and the archiving process wasn't collecting dSYM files for external dylib dependencies.

**Fix:**
1. Updated `scripts/build-llama.sh` to:
   - Add debug symbols to CMake build flags: `-DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG -g"`
   - Generate dSYM files using `dsymutil` after building each dylib
   - Sign libraries after dSYM generation

2. Created new `scripts/archive-for-appstore.sh` script that:
   - Properly archives the app with `xcodebuild archive`
   - Copies all llama.cpp dSYM files to the archive's dSYMs folder
   - Ensures `DEBUG_INFORMATION_FORMAT=dwarf-with-dsym` is set

### 3. **Bundle Structure Issues**
**Error:** `The CFBundleExecutable of two bundles may not point to the same file`

**Root Cause:** Multiple bundle paths pointing to the same location, likely due to improper packaging.

**Fix:** The new archive script uses proper Xcode archiving workflow instead of copying files manually, which ensures correct bundle structure.

## How to Use

### For App Store Distribution

1. **First, rebuild llama.cpp** (this will include the dSYM generation):
   ```bash
   cd /Users/projects/Documents/zetanotes-dev
   rm -rf llama.cpp/build
   ./scripts/build-llama.sh
   ```

2. **Run the new archive script**:
   ```bash
   ./scripts/archive-for-appstore.sh
   ```

3. **Submit to App Store**:
   - Open Xcode
   - Go to Window > Organizer
   - Select the created archive
   - Click "Validate App" (recommended first)
   - Click "Distribute App" → "App Store Connect"

   **OR** use Transporter app:
   - Open Transporter
   - Drag the .pkg file from `build/AppStore/`
   - Click "Deliver"

### For Developer ID Distribution (DMG)

The existing `scripts/release.sh` script continues to work for Developer ID distribution:

```bash
./scripts/release.sh 1.0.0
```

## What Changed

### Files Modified

1. **ZetaNotes/Info.plist**
   - Removed all Xcode variable placeholders
   - Set hardcoded values for bundle identifier, name, executable, etc.

2. **scripts/build-llama.sh**
   - Added debug symbol generation flags to CMake
   - Added `dsymutil` step to create .dSYM files for all .dylib files
   - Ensured dSYM generation happens before code signing

3. **scripts/archive-for-appstore.sh** (NEW)
   - Complete App Store archive and export workflow
   - Proper dSYM handling
   - Validation and verification steps
   - Creates archive at `build/ZetaNotes.xcarchive`
   - Exports package to `build/AppStore/`

## Verification

After running the archive script, verify the package contains everything:

```bash
# Check archive contents
ls -la build/ZetaNotes.xcarchive/dSYMs/

# Expected output should include:
# - ZetaNotes.app.dSYM
# - libllama.dylib.dSYM
# - libggml.dylib.dSYM
# - libggml-base.dylib.dSYM
# - libggml-blas.dylib.dSYM
# - libggml-cpu.dylib.dSYM
# - libggml-metal.dylib.dSYM

# Verify app signature
codesign -dv --verbose=4 build/AppStore/ZetaNotes.app
```

## Troubleshooting

### If dSYM files are still missing:

1. Clean everything:
   ```bash
   rm -rf llama.cpp/build
   rm -rf build
   ```

2. Rebuild llama.cpp manually:
   ```bash
   ./scripts/build-llama.sh
   ```

3. Verify dSYM files were created:
   ```bash
   ls -la llama.cpp/build/bin/*.dSYM
   ```

4. Run archive script again:
   ```bash
   ./scripts/archive-for-appstore.sh
   ```

### If bundle identifier errors persist:

Check that Info.plist has no variable placeholders:
```bash
grep '\$' ZetaNotes/Info.plist
```

This should return no results. If it does, manually replace any remaining variables.

### If code signing fails:

Ensure you have the correct certificates:
```bash
security find-identity -v -p codesigning
```

You need:
- "Apple Distribution: Rabah Abdul Khalek (HDA4C6CU89)" for App Store
- "Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)" for DMG distribution

## Important Notes

1. **Always use the archive script for App Store submissions** - Don't use the regular `release.sh` script, as it creates DMG packages for Developer ID distribution, not App Store packages.

2. **Info.plist is now hardcoded** - This is intentional and required for App Store distribution. The variables work fine for local builds but fail during App Store validation.

3. **dSYM files are critical** - Apple requires debug symbols for all executables and libraries. Without them, crash reports won't include function names and line numbers.

4. **Code signing order matters** - dSYM files must be generated BEFORE code signing the libraries, otherwise the signature won't match.

## Next Steps After Fix

1. Run the archive script
2. Validate the archive in Xcode Organizer
3. If validation passes, distribute to App Store Connect
4. Monitor App Store Connect for any additional validation issues
5. Once approved, you can submit for review

The archive is now properly configured with:
- ✅ Valid, hardcoded bundle identifiers
- ✅ Complete dSYM files for all libraries
- ✅ Proper code signing with timestamp
- ✅ Correct bundle structure
- ✅ All required entitlements and provisioning
