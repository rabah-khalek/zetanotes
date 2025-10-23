#!/bin/bash
# Auto-configure StoreKit Testing in Xcode scheme

set -e

SCHEME_FILE="ZetaNotes.xcodeproj/xcshareddata/xcschemes/ZetaNotes.xcscheme"

echo "🛒 Configuring StoreKit Testing..."
echo ""

# Check if scheme file exists
if [ ! -f "$SCHEME_FILE" ]; then
    echo "⚠️  Scheme file not found: $SCHEME_FILE"
    echo ""
    echo "This is normal if you haven't shared the scheme yet."
    echo ""
    echo "To configure manually:"
    echo "1. Open Xcode"
    echo "2. Product → Scheme → Edit Scheme..."
    echo "3. Select 'Run' → 'Options' tab"
    echo "4. StoreKit Configuration → Select 'Configuration.storekit'"
    echo ""
    exit 1
fi

# Check if StoreKit configuration is already set
if grep -q "storeKitConfigurationFileReference" "$SCHEME_FILE"; then
    echo "✅ StoreKit Configuration already set in scheme!"
    grep "storeKitConfigurationFileReference" "$SCHEME_FILE"
    exit 0
fi

# Backup the scheme file
cp "$SCHEME_FILE" "$SCHEME_FILE.backup"
echo "📋 Backed up scheme file"

# Find the LaunchAction section and add StoreKit configuration
# This is a basic implementation - may need manual verification
echo ""
echo "⚠️  Automatic configuration is complex with Xcode schemes."
echo "Please configure manually:"
echo ""
echo "1. Open Xcode: open ZetaNotes.xcodeproj"
echo "2. Product → Scheme → Edit Scheme... (or Cmd+<)"
echo "3. Select 'Run' on the left"
echo "4. Click 'Options' tab"
echo "5. Under 'StoreKit Configuration' dropdown:"
echo "   → Select 'Configuration.storekit'"
echo "6. Click 'Close'"
echo ""
echo "Then run the app and products will load immediately!"
echo ""
