#!/bin/bash
# One-time setup script for code signing and notarization

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OffNotes Code Signing Setup (One-Time)     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Find certificate
echo -e "${BLUE}▶ Step 1: Finding code signing certificate${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Available certificates:"
security find-identity -v -p codesigning

echo ""
echo "Copy the full name in quotes (e.g., 'Developer ID Application: Your Name (TEAM_ID)')"
read -p "Paste your certificate name: " CERT_NAME

if [ -z "$CERT_NAME" ]; then
    echo -e "${RED}✗ Certificate name cannot be empty${NC}"
    exit 1
fi

# Verify it exists
if ! security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo -e "${RED}✗ Certificate not found: $CERT_NAME${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Certificate verified${NC}"

# Extract Team ID
TEAM_ID=$(echo "$CERT_NAME" | grep -o '([^)]*)' | tr -d '()')
echo -e "${GREEN}✓ Team ID: $TEAM_ID${NC}"

# Step 2: Setup notarytool credentials
echo ""
echo -e "${BLUE}▶ Step 2: Setting up notarization credentials${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You need:"
echo "  1. Your Apple ID email"
echo "  2. Your Team ID: $TEAM_ID"
echo "  3. An app-specific password from https://appleid.apple.com"
echo ""
echo "Generate app-specific password at:"
echo "  https://appleid.apple.com → Security → App-Specific Passwords"
echo ""
read -p "Apple ID email: " APPLE_ID
read -p "App-specific password (xxxx-xxxx-xxxx-xxxx): " APP_PASSWORD

if [ -z "$APPLE_ID" ] || [ -z "$APP_PASSWORD" ]; then
    echo -e "${RED}✗ Apple ID and password are required${NC}"
    exit 1
fi

echo ""
echo "Storing credentials in Keychain..."
xcrun notarytool store-credentials "notary-profile" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Credentials stored successfully${NC}"
else
    echo -e "${RED}✗ Failed to store credentials${NC}"
    exit 1
fi

# Step 3: Update scripts
echo ""
echo -e "${BLUE}▶ Step 3: Updating packaging script${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update package-release.sh
sed -i '' "s/CERT_NAME=\".*\"/CERT_NAME=\"$CERT_NAME\"/" "$SCRIPT_DIR/package-release.sh"
echo -e "${GREEN}✓ Updated package-release.sh with certificate name${NC}"

# Update ExportOptions.plist
sed -i '' "s/<string>YOUR_TEAM_ID<\/string>/<string>$TEAM_ID<\/string>/" "$SCRIPT_DIR/ExportOptions.plist"
echo -e "${GREEN}✓ Updated ExportOptions.plist with Team ID${NC}"

# Step 4: Summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Setup Complete! ✓                  ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Certificate:${NC} $CERT_NAME"
echo -e "${BLUE}Team ID:${NC} $TEAM_ID"
echo -e "${BLUE}Apple ID:${NC} $APPLE_ID"
echo -e "${BLUE}Notary Profile:${NC} notary-profile"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run: ./scripts/package-release.sh"
echo "2. Wait 15-20 minutes for build + notarization"
echo "3. Get your signed DMG ready for release!"
echo ""
echo -e "${GREEN}You're all set! 🚀${NC}"
