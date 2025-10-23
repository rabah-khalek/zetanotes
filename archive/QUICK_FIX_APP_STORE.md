# Quick Fix Summary - App Store Distribution Errors

## What Was Fixed

### 1. Info.plist Variables Not Expanding
**Changed:** `ZetaNotes/Info.plist`
- Replaced all `$(VARIABLE)` placeholders with actual values
- Now uses hardcoded bundle ID: `com.zetanotes.zetanotes`
- Executable name: `ZetaNotes`

### 2. Missing dSYM Files for llama.cpp
**Changed:** `scripts/build-llama.sh`
- Added debug symbol generation to CMake flags
- Added `dsymutil` step to create `.dSYM` files for all `.dylib` files
- Generated dSYMs before code signing

### 3. Proper Archive Creation
**Created:** `scripts/archive-for-appstore.sh`
- New script specifically for App Store submissions
- Uses `xcodebuild archive` and `-exportArchive`
- Automatically includes all dSYM files in archive
- Creates proper bundle structure

## How to Build for App Store

### Quick Command

```bash
./scripts/archive-for-appstore.sh
```

This will:
1. Rebuild llama.cpp with debug symbols
2. Clean previous builds
3. Create a proper archive with dSYMs
4. Export for App Store submission
5. Place package in `build/AppStore/`

### Then Upload to App Store

**Option 1: Xcode Organizer**
1. Open Xcode
2. Window > Organizer
3. Select the archive
4. Click "Distribute App"
5. Choose "App Store Connect"

**Option 2: Transporter App**
1. Open Transporter
2. Drag `build/AppStore/ZetaNotes.pkg`
3. Click "Deliver"

## Verify the Fix

Check that dSYM files were created:
```bash
ls -la build/ZetaNotes.xcarchive/dSYMs/
```

Should see:
- ZetaNotes.app.dSYM
- libllama.dylib.dSYM
- libggml.dylib.dSYM
- libggml-base.dylib.dSYM
- libggml-blas.dylib.dSYM
- libggml-cpu.dylib.dSYM
- libggml-metal.dylib.dSYM

## If Issues Persist

Clean everything and rebuild:
```bash
rm -rf llama.cpp/build build
./scripts/archive-for-appstore.sh
```

## Note

- Use `archive-for-appstore.sh` for App Store submissions
- Use `release.sh` for DMG distribution (Developer ID)
- These are two different distribution methods with different requirements
