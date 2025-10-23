# ✅ Notarization Setup Status

## Current Status: CONFIGURED ✅

Your notarization credentials are **already set up correctly**!

```bash
✅ APPLE_ID: rabah.khalek@gmail.com
✅ APPLE_TEAM_ID: HDA4C6CU89
✅ APPLE_APP_SPECIFIC_PASSWORD: ******* (SET)
```

## What This Means

When you run the release script locally:
```bash
./scripts/release-new.sh 1.0.0
```

The script will automatically:
1. ✅ Build and sign your app
2. ✅ Create and sign the DMG
3. ✅ Submit to Apple for notarization
4. ✅ Wait for Apple's approval (1-5 minutes)
5. ✅ Staple the notarization ticket to the DMG
6. ✅ Verify the notarization

**No placeholders to fill in - everything is ready!**

## Environment Variables Used

The release pipeline checks for these 3 environment variables:

| Variable | Purpose | Your Status |
|----------|---------|-------------|
| `APPLE_ID` | Your Apple ID email | ✅ Set to `rabah.khalek@gmail.com` |
| `APPLE_TEAM_ID` | Your Developer Team ID | ✅ Set to `HDA4C6CU89` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from Apple | ✅ Set (hidden for security) |

## How It Works

### In `scripts/release-new.sh`:

```bash
# Step 1: Check if credentials are set
check_notarization_credentials "$IS_CI_ENV"

# Step 8: Notarize if credentials exist
if [ "$NOTARIZATION_ENABLED" = "true" ]; then
    notarize_dmg "$DMG_NAME" "$APPLE_ID" "$APPLE_TEAM_ID" "$APPLE_APP_SPECIFIC_PASSWORD"
fi
```

### The validation function checks:

```bash
if [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    print_success "Notarization credentials found"
    return 0
else
    print_warning "Notarization credentials not set"
    # Shows instructions...
    return 1
fi
```

## Where Are These Variables Stored?

These are environment variables, typically set in your shell profile:

**Check where they're defined:**
```bash
# Check your zsh profile
grep -E "APPLE_ID|APPLE_TEAM_ID|APPLE_APP_SPECIFIC_PASSWORD" ~/.zshrc ~/.zshenv ~/.zprofile 2>/dev/null
```

They might be in:
- `~/.zshrc` (most common for zsh)
- `~/.zshenv`
- `~/.zprofile`
- `~/.bash_profile` (if you use bash)

## Testing Notarization

To test if notarization will work:

```bash
# Run a release build
./scripts/release-new.sh 0.0.8-test

# You should see:
# ✓ Notarization credentials found
# ▶ Notarizing with Apple
# Submission ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# Waiting for notarization (this can take 1-5 minutes)...
# ..................
# ✓ Notarization accepted!
# ✓ Notarization ticket stapled
```

## For CI/GitHub Actions

The same credentials need to be set as **GitHub Secrets**:

1. Go to: `https://github.com/rabah-khalek/notetaker/settings/secrets/actions`
2. Ensure these secrets exist:
   - `APPLE_ID`
   - `APPLE_TEAM_ID`
   - `APPLE_APP_SPECIFIC_PASSWORD`

## If Notarization Is Skipped

If you see "Notarization: Skipped" in the release summary, it means one of the environment variables is not set. The script will show you which ones are missing.

## Regenerating App-Specific Password

If you ever need to regenerate your app-specific password:

1. Go to: https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. Go to "Security" → "App-Specific Passwords"
4. Generate a new password
5. Update your environment variable:
   ```bash
   export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'
   ```
6. Add to your `~/.zshrc` to make it permanent

## Troubleshooting

### "Notarization credentials not set"
- Run: `echo $APPLE_ID` to check if set
- If empty, add to `~/.zshrc`:
  ```bash
  export APPLE_ID='rabah.khalek@gmail.com'
  export APPLE_TEAM_ID='HDA4C6CU89'
  export APPLE_APP_SPECIFIC_PASSWORD='your-password-here'
  ```
- Then: `source ~/.zshrc`

### "Notarization failed with status: Invalid"
- Check `notarization-failure.json` in the build directory
- Common issues:
  - Missing hardened runtime flag (script handles this)
  - Unsigned nested components (script handles this)
  - Invalid entitlements

### "Notarization timed out"
- Apple's service might be slow
- You can check status manually with the Submission ID shown
- The DMG is still valid, just not notarized yet

## Summary

**You're all set!** ✅

No placeholders or missing information. Your local release pipeline is fully configured for notarization. Just run:

```bash
./scripts/release-new.sh VERSION
```

And it will automatically notarize your DMG with Apple.
