#!/bin/bash
#
# setup-sparkle-keys.sh
# Helper script to generate Sparkle EdDSA keys and set up GitHub secrets
#

set -e

echo "╔═══════════════════════════════════════════════╗"
echo "║   Sparkle EdDSA Key Setup Helper             ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if generate_keys exists (this is what we need for key generation)
GENERATE_KEYS=""

# First check if we have it locally in scripts/sparkle/bin
if [ -f "$PROJECT_ROOT/scripts/sparkle/bin/generate_keys" ]; then
    GENERATE_KEYS="$PROJECT_ROOT/scripts/sparkle/bin/generate_keys"
    echo "✅ Found generate_keys at scripts/sparkle/bin/generate_keys"
elif command -v generate_keys &> /dev/null; then
    GENERATE_KEYS="generate_keys"
    echo "✅ Found generate_keys in PATH"
elif [ -f "$HOME/bin/generate_keys" ]; then
    GENERATE_KEYS="$HOME/bin/generate_keys"
    echo "✅ Found generate_keys at $HOME/bin/generate_keys"
else
    echo "❌ generate_keys not found!"
    echo ""
    echo "Expected location: scripts/sparkle/bin/generate_keys"
    echo ""
    echo "Please ensure Sparkle tools are properly installed in the project."
    echo ""
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Generate EdDSA Key Pair"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create keys directory
KEYS_DIR="${HOME}/.sparkle_keys"
mkdir -p "$KEYS_DIR"

# File paths for exported keys
PRIVATE_KEY_FILE="$KEYS_DIR/sparkle_eddsa_private_key"
ACCOUNT_NAME="zetanotes-sparkle"

echo "Checking for existing keys in Keychain..."

# Check if keys already exist by trying to print the public key
if "$GENERATE_KEYS" --account "$ACCOUNT_NAME" -p >/dev/null 2>&1; then
    echo "⚠️  Keys already exist in macOS Keychain for account: $ACCOUNT_NAME"
    echo ""
    read -p "Do you want to use existing keys? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing keys from Keychain..."
    else
        echo "⚠️  To generate new keys, you must first delete the existing keys:"
        echo "   1. Open 'Keychain Access' app"
        echo "   2. Search for 'Private key for signing Sparkle updates'"
        echo "   3. Delete the existing key(s)"
        echo "   4. Run this script again"
        echo ""
        exit 1
    fi
else
    echo "No existing keys found. Generating new EdDSA key pair..."
    echo ""
    echo "⚠️  The Keychain will ask for permission to store the private key."
    echo "    Please click 'Allow' when prompted."
    echo ""

    # Generate new keys (stores private key in Keychain, prints public key)
    "$GENERATE_KEYS" --account "$ACCOUNT_NAME"
fi

echo ""
echo "Exporting keys to files..."

# Remove existing exported key file if it exists
rm -f "$PRIVATE_KEY_FILE"

# Export private key from Keychain to file
if "$GENERATE_KEYS" --account "$ACCOUNT_NAME" -x "$PRIVATE_KEY_FILE" 2>/dev/null; then
    echo "✅ Private key exported to: $PRIVATE_KEY_FILE"
else
    echo "❌ Failed to export private key from Keychain"
    echo "   You may need to grant access in Keychain Access app"
    exit 1
fi

# Get public key (the -p flag just prints the key directly)
PUBLIC_KEY=$("$GENERATE_KEYS" --account "$ACCOUNT_NAME" -p 2>/dev/null | tr -d '\n\r ')

if [ -z "$PUBLIC_KEY" ]; then
    echo "❌ Failed to retrieve public key"
    exit 1
fi

# Read the private key from file
PRIVATE_KEY=$(cat "$PRIVATE_KEY_FILE" | tr -d '\n\r ')

echo "✅ Keys are ready!"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Add Public Key to Info.plist"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your PUBLIC key (add this to ZetaNotes/Info.plist):"
echo ""
echo "    <key>SUPublicEDKey</key>"
echo "    <string>$PUBLIC_KEY</string>"
echo ""
echo "This key will be embedded in your app to verify updates."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Add Private Key to GitHub Secrets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your PRIVATE key (keep this SECRET!):"
echo ""
echo "$PRIVATE_KEY"
echo ""
echo "⚠️  DO NOT COMMIT THIS KEY TO GIT!"
echo "⚠️  DO NOT SHARE THIS KEY!"
echo ""
echo "To add this as a GitHub secret:"
echo ""
echo "1. Go to: https://github.com/YOUR_USERNAME/zetanotes-dev/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Name: SPARKLE_PRIVATE_KEY"
echo "4. Value: (paste the private key above)"
echo "5. Click 'Add secret'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Update Info.plist (if not already done)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Info.plist already has the public key
INFO_PLIST="ZetaNotes/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    if grep -q "SUPublicEDKey" "$INFO_PLIST"; then
        echo "✅ Info.plist already contains SUPublicEDKey"
        echo ""
        echo "Current value:"
        grep -A 1 "SUPublicEDKey" "$INFO_PLIST" | tail -1
        echo ""
        read -p "Do you want to update it with the new public key? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Please update it manually in: $INFO_PLIST"
            echo "New public key: $PUBLIC_KEY"
        fi
    else
        echo "⚠️  Info.plist does NOT contain SUPublicEDKey"
        echo ""
        echo "Please add this to $INFO_PLIST:"
        echo ""
        echo "    <key>SUPublicEDKey</key>"
        echo "    <string>$PUBLIC_KEY</string>"
        echo ""
    fi
else
    echo "⚠️  Could not find Info.plist at $INFO_PLIST"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary:"
echo "  - Keys saved in: $KEYS_DIR"
echo "  - Public key: Add to Info.plist (SUPublicEDKey)"
echo "  - Private key: Add to GitHub Secrets (SPARKLE_PRIVATE_KEY)"
echo ""
echo "Next steps:"
echo "  1. Add public key to ZetaNotes/Info.plist"
echo "  2. Add private key to GitHub repository secrets"
echo "  3. Commit the Info.plist changes"
echo "  4. Push and trigger a new release build"
echo ""
