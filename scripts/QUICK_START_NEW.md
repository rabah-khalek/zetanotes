# Quick Start Guide - New Release System

## TL;DR - What Changed?

**Before:** 3 scripts doing the same thing differently
**After:** 1 script that works everywhere + 7 small helper modules

## Quick Comparison

### Old Way ❌

```bash
# Pick the right script for your environment
./scripts/release.sh 1.0.0         # Which one to use?
./scripts/release-local.sh 1.0.0   # This one for local?
./scripts/release-ci.sh 1.0.0      # This one for CI?

# Logic duplicated across files
# Hard to maintain
# Confusing to debug
```

### New Way ✅

```bash
# One script that auto-detects environment
./scripts/release-new.sh 1.0.0

# Automatically works both locally AND in CI
# Modular and maintainable
# Easy to debug and understand
```

## File Structure

```
Old Structure (BEFORE):              New Structure (AFTER):
━━━━━━━━━━━━━━━━━━━━━━━             ━━━━━━━━━━━━━━━━━━━━━━━

scripts/                             scripts/
├── release.sh                       ├── release-new.sh ⭐ (one entry point)
├── release-local.sh                 ├── release-config.sh (configuration)
├── release-ci.sh                    └── lib/ (modular helpers)
└── release-common.sh                    ├── colors.sh
                                         ├── validation.sh
❌ 4 files, 1,360 lines                  ├── xcode.sh
❌ Lots of duplication                   ├── signing.sh
❌ Hard to follow                        ├── sparkle.sh
                                         ├── notarization.sh
                                         └── packaging.sh

                                     ✅ 9 files, 749 lines
                                     ✅ Zero duplication
                                     ✅ Clear organization
```

## Usage Examples

### Local Development

```bash
# Normal release
./scripts/release-new.sh 1.0.0

# With llama.cpp rebuild
./scripts/release-new.sh 1.0.0 rebuild
```

### Environment Setup

```bash
# Required for notarization
export APPLE_ID='your-apple-id@example.com'
export APPLE_TEAM_ID='HDA4C6CU89'
export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'

# Optional: Sparkle keychain account
export SPARKLE_ACCOUNT_NAME='my-sparkle-key'
```

### CI/GitHub Actions

No changes needed! Just use the new workflow:

```yaml
# In .github/workflows/release-new.yml
- name: Build release
  run: ./scripts/release-new.sh ${{ steps.version.outputs.VERSION }}
```

## What's Different?

### Simplified Workflow

**Old workflow (release.yml):**
- 260 lines
- Duplicates signing logic
- Duplicates Sparkle signature logic
- Duplicates metadata generation
- Hard to maintain

**New workflow (release-new.yml):**
- 130 lines (50% smaller!)
- Just calls the unified script
- Script handles all the logic
- Easy to maintain

### Easier to Modify

**Old:** Want to change signing? Edit 3-4 files

```bash
# Edit release.sh line 150-180
# Edit release-local.sh line 120-150
# Edit release-ci.sh line 115-145
# Edit release-common.sh line 100-150
```

**New:** Want to change signing? Edit 1 file

```bash
# Edit lib/signing.sh
# That's it! Works everywhere automatically
```

### Better Organization

**Old flow (hard to follow):**
```
release.sh
  ↓ sources
release-common.sh
  ↓ calls build_app()
  ↓ 50 lines of mixed logic
  ↓ calls resign_sparkle()
  ↓ 40 lines of mixed logic
  ↓ back to release.sh
  ↓ ...continue...
```

**New flow (clear steps):**
```
release-new.sh
  ├─ Step 1: validation.sh → check_certificate()
  ├─ Step 2: xcode.sh → build_app()
  ├─ Step 3: signing.sh → resign_sparkle_components()
  ├─ Step 4: signing.sh → resign_llama_libraries()
  ├─ Step 5: signing.sh → resign_app_bundle()
  ├─ Step 6: validation.sh → verify_signatures()
  ├─ Step 7: packaging.sh → create_dmg()
  ├─ Step 8: signing.sh → sign_dmg()
  ├─ Step 9: sparkle.sh → generate_sparkle_signature()
  └─ Step 10: notarization.sh → notarize_dmg()
```

## Configuration in One Place

**Old:** Hardcoded values everywhere

```bash
# In release.sh
TEAM_ID="HDA4C6CU89"
SIGNING_IDENTITY="Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"

# In release-local.sh (same values!)
TEAM_ID="HDA4C6CU89"
SIGNING_IDENTITY="Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"

# In release-ci.sh (different but similar!)
SIGNING_IDENTITY="Developer ID Application"
```

**New:** Configure once

```bash
# In scripts/release-config.sh
TEAM_ID="HDA4C6CU89"
SIGNING_IDENTITY_LOCAL="Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"
SIGNING_IDENTITY_CI="Developer ID Application"

# Script auto-detects which to use
```

## Migration

When ready to switch:

```bash
# 1. Backup old files
mkdir scripts/old/
mv scripts/release*.sh scripts/old/

# 2. Activate new script
mv scripts/release-new.sh scripts/release.sh

# 3. Update workflow
mv .github/workflows/release.yml .github/workflows/release-old.yml
mv .github/workflows/release-new.yml .github/workflows/release.yml

# 4. Test
./scripts/release.sh 1.0.0-test
```

## Questions?

- **Full documentation:** `scripts/RELEASE_PIPELINE.md`
- **Before/after comparison:** `scripts/REORGANIZATION.md`
- **Trouble?** Each module has clear error messages with troubleshooting steps

## Bottom Line

✅ **Less code** (46% reduction)
✅ **Zero duplication** (was duplicated 3x before)
✅ **Easier to understand** (clear modules vs monolithic files)
✅ **Easier to maintain** (change once, works everywhere)
✅ **Same functionality** (nothing removed, everything preserved)
