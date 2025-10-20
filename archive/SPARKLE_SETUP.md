# Sparkle Auto-Update Setup

This document explains how to set up Sparkle EdDSA signatures for secure auto-updates in ZetaNotes.

## What is Sparkle?

Sparkle is a software update framework for macOS that allows your app to automatically check for and install updates. It uses EdDSA (Ed25519) cryptographic signatures to ensure that updates are authentic and haven't been tampered with.

## Why do you need this?

Without Sparkle signatures:
- ❌ Auto-updates will NOT work
- ❌ Users will have to manually download new versions
- ❌ Your release build will complete but updates won't be secure

With Sparkle signatures:
- ✅ Users get automatic update notifications
- ✅ Updates are cryptographically verified
- ✅ Secure delivery of new versions

## Setup Steps

### 1. Generate EdDSA Key Pair

Run the setup script:

```bash
./scripts/setup-sparkle-keys.sh
```

This will:
- Use the `generate_appcast` tool already included in `scripts/sparkle/bin/`
- Generate a new EdDSA key pair (public + private)
- Save keys to `~/.sparkle_keys/`
- Display instructions for the next steps

**Note**: The Sparkle tools are already included in this repository at `scripts/sparkle/bin/`, so no additional downloads are needed!

### 2. Add Public Key to Info.plist

The public key needs to be embedded in your app. Add this to `ZetaNotes/Info.plist`:

```xml
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

Replace `YOUR_PUBLIC_KEY_HERE` with the public key displayed by the setup script.

### 3. Add Private Key to GitHub Secrets

The private key is used in CI to sign releases. **Keep this secret!**

1. Go to your GitHub repository settings:
   ```
   https://github.com/YOUR_USERNAME/zetanotes-dev/settings/secrets/actions
   ```

2. Click "New repository secret"

3. Create a secret:
   - **Name**: `SPARKLE_PRIVATE_KEY`
   - **Value**: (paste your private key)

4. Click "Add secret"

### 4. Commit and Push

Commit the Info.plist changes:

```bash
git add ZetaNotes/Info.plist
git commit -m "Add Sparkle public key for auto-updates"
git push
```

### 5. Test

Create a new release and verify:
- The CI build completes successfully
- The release includes a Sparkle signature
- The signature is displayed in the GitHub release notes

## Key Security

### Public Key
- ✅ Safe to commit to git
- ✅ Safe to share publicly
- ✅ Embedded in your distributed app

### Private Key
- ❌ **NEVER** commit to git
- ❌ **NEVER** share publicly
- ❌ **NEVER** hardcode in source
- ✅ Store in GitHub Secrets only
- ✅ Keep backup in secure password manager

## Troubleshooting

### "generate_appcast not found"

The `generate_appcast` tool should already be in `scripts/sparkle/bin/`. If the setup script can't find it:

```bash
# Verify the tool exists
ls -la scripts/sparkle/bin/generate_appcast

# If missing, check if you have the sparkle directory
ls -la scripts/sparkle/

# The tools should be committed to the repository
git ls-files scripts/sparkle/bin/
```

If the entire `scripts/sparkle/` directory is missing, you may need to restore it from git or download Sparkle tools.

### "CI build fails - SPARKLE_PRIVATE_KEY secret not set"

The CI workflow now allows building without signatures (with warnings). To enable proper auto-updates:
1. Follow step 3 above to add the secret
2. Push a new commit to trigger another build

### "Keys already exist"

If you run the setup script again and keys already exist:
- Choose 'n' to keep existing keys
- Choose 'y' to generate new keys (this will invalidate old releases!)

**Warning**: If you generate new keys, old app versions won't trust updates signed with the new key!

## References

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [EdDSA Signing](https://sparkle-project.org/documentation/signing/)
- [Security Best Practices](https://sparkle-project.org/documentation/security/)
