#!/bin/bash
set -e

echo "Testing complete Sparkle signature generation flow..."
echo ""

# Paths
DMG_PATH="$HOME/Documents/zetanotes-dev/test.dmg"
PRIVATE_KEY_FILE="$HOME/.sparkle_keys/sparkle_eddsa_private_key"
SIGN_UPDATE="$HOME/Documents/zetanotes-dev/scripts/sparkle/bin/sign_update"

# Verify files exist
if [ ! -f "$DMG_PATH" ]; then
    echo "❌ DMG not found: $DMG_PATH"
    exit 1
fi

if [ ! -f "$PRIVATE_KEY_FILE" ]; then
    echo "❌ Private key not found: $PRIVATE_KEY_FILE"
    exit 1
fi

if [ ! -f "$SIGN_UPDATE" ]; then
    echo "❌ sign_update tool not found: $SIGN_UPDATE"
    exit 1
fi

echo "✅ All required files exist"
echo ""

# Step 1: Generate signature using sign_update
echo "Step 1: Generating signature with sign_update..."
SIGN_OUTPUT=$("$SIGN_UPDATE" --ed-key-file "$PRIVATE_KEY_FILE" "$DMG_PATH" 2>&1)
SIGN_EXIT_CODE=$?

if [ $SIGN_EXIT_CODE -eq 0 ]; then
    echo "✅ sign_update completed successfully"
    echo "Output: $SIGN_OUTPUT"
    echo ""

    # Extract signature
    SIGNATURE=$(echo "$SIGN_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | sed 's/sparkle:edSignature="\([^"]*\)"/\1/')

    if [ -n "$SIGNATURE" ]; then
        echo "✅ Extracted signature: $SIGNATURE"
        echo ""
    else
        echo "❌ Couldn't extract signature from output"
        exit 1
    fi
else
    echo "❌ sign_update failed with exit code: $SIGN_EXIT_CODE"
    echo "Error: $SIGN_OUTPUT"
    exit 1
fi

# Step 2: Verify the signature
echo "Step 2: Verifying signature..."
if "$SIGN_UPDATE" --ed-key-file "$PRIVATE_KEY_FILE" --verify "$DMG_PATH" "$SIGNATURE" 2>&1; then
    echo "✅ Signature verified successfully!"
    echo ""
else
    echo "❌ Signature verification failed"
    exit 1
fi

# Step 3: Create a test appcast.xml
echo "Step 3: Creating test appcast.xml..."
cat > /tmp/test_appcast.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>ZetaNotes Updates</title>
        <link>https://rabah-khalek.github.io/zetanotes/appcast.xml</link>
        <description>Most recent updates for ZetaNotes</description>
        <language>en</language>

        <item>
            <title>Version 1.0.0</title>
            <link>https://github.com/rabah-khalek/zetanotes</link>
            <sparkle:version>1.0.0</sparkle:version>
            <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
            <description><![CDATA[
                <h2>ZetaNotes 1.0.0</h2>
                <p>Test release</p>
            ]]></description>
            <pubDate>$(date -R)</pubDate>
            <enclosure
                url="https://github.com/rabah-khalek/zetanotes/releases/download/v1.0.0/test.dmg"
                sparkle:version="1.0.0"
                sparkle:shortVersionString="1.0.0"
                length="52428800"
                type="application/octet-stream"
                sparkle:edSignature="$SIGNATURE" />
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        </item>

    </channel>
</rss>
EOF

echo "✅ Created test appcast.xml at /tmp/test_appcast.xml"
echo ""
echo "Contents:"
cat /tmp/test_appcast.xml
echo ""

echo "========================================="
echo "✅ ALL TESTS PASSED!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - Signature generation: ✅"
echo "  - Signature verification: ✅"
echo "  - Appcast creation: ✅"
echo ""
echo "The signature is: $SIGNATURE"
echo ""
echo "This signature can be used in the release workflow!"
