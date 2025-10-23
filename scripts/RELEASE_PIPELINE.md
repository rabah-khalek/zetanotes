# ZetaNotes Release Pipeline

A **simplified, modular** build and release system for ZetaNotes.

## 📁 Structure

```
scripts/
├── release.sh                  # ⭐ Main entry point (auto-detects local/CI)
├── release-config.sh           # Configuration (team IDs, paths, etc.)
├── lib/                        # Modular functions library
│   ├── colors.sh              # Output formatting
│   ├── validation.sh          # Prerequisites and signature verification
│   ├── xcode.sh               # Xcode build functions
│   ├── signing.sh             # Code signing (app, Sparkle, llama.cpp)
│   ├── sparkle.sh             # Sparkle EdDSA signature generation
│   ├── notarization.sh        # Apple notarization
│   └── packaging.sh           # DMG creation and metadata
└── old-release-scripts/        # 🗄️ Archived old scripts

.github/workflows/
├── release.yml                 # ⭐ Active CI workflow
└── old-release.yml            # 🗄️ Archived old workflow
```

## 🚀 Usage

### Local Development Release

```bash
# Release (always rebuilds llama.cpp for fresh signatures)
./scripts/release.sh 1.0.0
```

**Required environment variables:**
```bash
export APPLE_ID='your-apple-id@example.com'
export APPLE_TEAM_ID='YOUR_TEAM_ID'
export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'

# Optional: Override default Sparkle keychain account
export SPARKLE_ACCOUNT_NAME='my-sparkle-key'
```

### CI/GitHub Actions

The workflow automatically triggers on version tags:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or manually via GitHub Actions UI with custom release notes.

**Required GitHub Secrets:**
- `APPLE_CERTIFICATE_BASE64` - Developer ID certificate (base64 encoded)
- `APPLE_CERTIFICATE_PASSWORD` - Certificate password
- `APPLE_ID` - Apple ID email
- `APPLE_TEAM_ID` - Team ID
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password
- `SPARKLE_PRIVATE_KEY` - Sparkle EdDSA private key
- `PUBLIC_REPO_TOKEN` - GitHub PAT for public repo

## 📋 Release Pipeline Steps

The unified script executes these steps in order:

1. **Prerequisites** - Check certificates, tools, credentials
2. **Rebuild llama.cpp** (optional) - Rebuild if `rebuild` argument passed
3. **Build app** - Xcode build with signing
4. **Re-sign components** - Sparkle, llama.cpp, main app bundle
5. **Verify signatures** - Comprehensive signature verification
6. **Create DMG** - Package app as disk image
7. **Sign DMG** - Code sign the DMG
8. **Sparkle signature** - Generate EdDSA signature for auto-updates
9. **Notarize** - Submit to Apple notarization service
10. **Generate metadata** - SHA256, appcast info

## 🎯 Key Improvements

### Before (Problems)

❌ **3 nearly-identical scripts** (release.sh, release-local.sh, release-ci.sh)
❌ **400+ line release-common.sh** with massive functions
❌ **release.yml duplicated** all the build logic
❌ **Hard to debug** - logic scattered across multiple files
❌ **Hardcoded values** everywhere (team IDs, paths, etc.)

### After (Solutions)

✅ **Single entry point** - One script that detects environment
✅ **Modular library** - 7 focused modules with single responsibilities
✅ **Configuration file** - All hardcoded values in one place
✅ **Minimal CI workflow** - Just setup + call the unified script
✅ **Easy to understand** - Clear flow, well-organized

## 🔧 Configuration

Edit `scripts/release-config.sh` to change:
- App name and project settings
- Team ID and signing identities
- Sparkle configuration
- GitHub repository URLs
- System requirements
- File paths

## 📚 Module Reference

### `colors.sh`
- Output formatting functions
- `print_step()`, `print_success()`, `print_error()`, `print_warning()`
- `print_banner()` for script header

### `validation.sh`
- Prerequisite checks (certificates, tools, credentials)
- Signature verification functions
- `check_certificate()`, `check_notarization_credentials()`
- `verify_app_signature()`, `run_verification_script()`

### `xcode.sh`
- Xcode build operations
- `build_app()` - Clean and build with signing
- `rebuild_llama_if_needed()` - Conditional llama.cpp rebuild

### `signing.sh`
- Code signing operations
- `resign_sparkle_components()` - Re-sign Sparkle framework and XPC services
- `resign_llama_libraries()` - Re-sign dylibs
- `resign_app_bundle()` - Re-sign main app
- `sign_dmg()` - Sign DMG file

### `sparkle.sh`
- Sparkle EdDSA signature generation
- `generate_sparkle_signature()` - Works in both local (keychain) and CI (env var) modes
- `save_sparkle_signature()` - Save signature to file

### `notarization.sh`
- Apple notarization process
- `notarize_dmg()` - Submit, poll status, handle failures
- `staple_notarization()` - Staple ticket to DMG

### `packaging.sh`
- DMG creation and metadata
- `create_dmg()` - Create disk image
- `generate_checksum()` - SHA256 hash
- `generate_appcast_info()` - Appcast XML snippet
- `print_release_summary()` - Final summary output

## 🧪 Testing

To test without modifying the current system:

```bash
# Test the new script
./scripts/release-new.sh 1.0.0-test

# Test the new workflow (create a branch)
git checkout -b test-new-workflow
# Copy release-new.yml to release.yml, commit, and tag
```

## 🔄 Migration Plan

When ready to switch to the new system:

1. **Backup old files:**
   ```bash
   mkdir scripts/old/
   mv scripts/release.sh scripts/old/
   mv scripts/release-local.sh scripts/old/
   mv scripts/release-ci.sh scripts/old/
   mv scripts/release-common.sh scripts/old/
   ```

2. **Activate new script:**
   ```bash
   mv scripts/release-new.sh scripts/release.sh
   chmod +x scripts/release.sh
   ```

3. **Update workflow:**
   ```bash
   mv .github/workflows/release.yml .github/workflows/release-old.yml
   mv .github/workflows/release-new.yml .github/workflows/release.yml
   ```

4. **Test:**
   ```bash
   ./scripts/release.sh 1.0.0-migration-test
   ```

## 📖 Additional Documentation

- Original workflow documentation: `scripts/RELEASE_WORKFLOW.md`
- Sparkle setup: `scripts/setup-sparkle-keys.sh`
- Signature verification: `scripts/verify-signatures.sh`

## 🆘 Troubleshooting

### "No Developer ID certificate found"
Run `security find-identity -v -p codesigning` to check installed certificates.

### "Sparkle signature not generated"
- **Local:** Run `./scripts/setup-sparkle-keys.sh` to add key to Keychain
- **CI:** Ensure `SPARKLE_PRIVATE_KEY` secret is set

### "Notarization failed"
Check `notarization-failure.json` in the build directory for detailed error messages.

### Build fails to find llama.cpp
Run with `rebuild` flag: `./scripts/release.sh 1.0.0 rebuild`

## 🎯 Future Improvements

- [ ] Add dry-run mode (`--dry-run` flag)
- [ ] Parallel signing operations where safe
- [ ] Progress bars for long operations
- [ ] Automated rollback on failure
- [ ] Release artifact caching
