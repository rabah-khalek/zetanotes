#!/bin/bash
#
# test-signature.sh
# Test Sparkle signature generation locally
#

set -e

echo "╔═══════════════════════════════════════════════╗"
echo "║   Sparkle Signature Generation Test          ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Check if we have a test DMG
if [ ! -f "test.dmg" ]; then
    echo "⚠️  No test.dmg found. Let's create one..."

    # Build the app first
    echo "Building app..."
    xcodebuild -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Debug build -quiet

    # Find built app
    BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData -path "*/Build/Products/Debug/ZetaNotes.app" -not -path "*/Index.noindex/*" | head -1)

    if [ -z "$BUILT_APP" ]; then
        echo "❌ Could not find built app"
        exit 1
    fi

    echo "✅ Found app at: $BUILT_APP"

    # Create a simple DMG
    echo "Creating test DMG..."
    hdiutil create -size 50m -fs HFS+ -volname "ZetaNotes" test.dmg
    hdiutil attach test.dmg -mountpoint /tmp/zetanotes_test
    cp -R "$BUILT_APP" /tmp/zetanotes_test/
    hdiutil detach /tmp/zetanotes_test

    echo "✅ Created test.dmg"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Signature Generation Methods"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if private key exists
PRIVATE_KEY_FILE="$HOME/.sparkle_keys/sparkle_eddsa_private_key"
if [ ! -f "$PRIVATE_KEY_FILE" ]; then
    echo "❌ Private key not found at: $PRIVATE_KEY_FILE"
    echo "Run: ./scripts/setup-sparkle-keys.sh first"
    exit 1
fi

echo "✅ Found private key at: $PRIVATE_KEY_FILE"
echo "Private key content:"
cat "$PRIVATE_KEY_FILE"
echo ""

# Method 1: Using sign_update directly
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Method 1: sign_update tool"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "scripts/sparkle/bin/sign_update" ]; then
    echo "Running: sign_update test.dmg $PRIVATE_KEY_FILE"
    if SIGNATURE=$(scripts/sparkle/bin/sign_update test.dmg "$PRIVATE_KEY_FILE" 2>&1); then
        if [ -n "$SIGNATURE" ]; then
            echo "✅ SUCCESS! Signature: $SIGNATURE"
        else
            echo "⚠️  Command succeeded but returned empty signature"
        fi
    else
        echo "❌ FAILED with error:"
        echo "$SIGNATURE"
    fi
else
    echo "❌ sign_update not found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Method 2: generate_appcast with directory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Save current directory
CURRENT_DIR=$(pwd)

# Create temp directory
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/releases"
cp test.dmg "$TEMP_DIR/releases/"

cd "$TEMP_DIR"

if [ -f "$PRIVATE_KEY_FILE" ]; then
    echo "Running: generate_appcast --ed-key-file ..."

    "$CURRENT_DIR/scripts/sparkle/bin/generate_appcast" \
        --ed-key-file "$PRIVATE_KEY_FILE" \
        --download-url-prefix "https://example.com/releases/" \
        releases 2>&1 | tee generate_appcast.log

    echo ""
    echo "Looking for appcast.xml..."
    echo "Contents of temp directory:"
    ls -la
    echo ""

    # Find where appcast.xml was created
    APPCAST_FILE=$(find . -name "appcast.xml" -type f 2>/dev/null)

    if [ -n "$APPCAST_FILE" ]; then
        echo "✅ Found appcast.xml at: $APPCAST_FILE"
        echo ""
        echo "Contents:"
        cat "$APPCAST_FILE"
        echo ""

        # Check for signature
        if grep -q "sparkle:edSignature" "$APPCAST_FILE"; then
            SIGNATURE=$(grep -o 'sparkle:edSignature="[^"]*"' "$APPCAST_FILE" | sed 's/sparkle:edSignature="\([^"]*\)"/\1/')
            echo "✅ SUCCESS! Found signature in appcast: $SIGNATURE"
        else
            echo "❌ FAILED: No signature in appcast.xml"
            echo ""
            echo "This usually means:"
            echo "  1. generate_appcast couldn't read the DMG"
            echo "  2. Version info in the app doesn't match filename"
            echo "  3. Private key format is wrong"
        fi
    else
        echo "❌ FAILED: No appcast.xml found anywhere in temp directory"
    fi
fi

cd - > /dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Method 3: Check key format"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Private key (base64):"
cat "$PRIVATE_KEY_FILE"
echo ""

echo "Private key length: $(cat "$PRIVATE_KEY_FILE" | wc -c) bytes"
echo "Decoded length: $(cat "$PRIVATE_KEY_FILE" | base64 -d 2>/dev/null | wc -c) bytes (should be 32)"

echo ""
echo "Public key from Keychain:"
scripts/sparkle/bin/generate_keys --account "zetanotes-sparkle" -p

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "If signature generation failed, check:"
echo "  1. Private key format (should be 44-char base64 string)"
echo "  2. Public key in Info.plist matches the keychain"
echo "  3. DMG contains app with valid Info.plist"
echo ""
