#!/bin/bash

set -e  # Exit on any error

# ZetaNotes Release Script - Signed & Notarized Distribution
# For Apple Developer Program members

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
VERSION="${1:-1.0.0}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/releases/ZetaNotes-Release-$(date +%Y%m%d-%H%M%S)"
APP_NAME="ZetaNotes"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"

# Detect certificate name based on environment
if [ -n "$GITHUB_ACTIONS" ]; then
    SIGNING_IDENTITY="Developer ID Application"
else
    SIGNING_IDENTITY="Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"
fi

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ZetaNotes Release Builder v3.0 (Signed)     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Version:${NC} ${VERSION}"
echo -e "${GREEN}Signing Identity:${NC} ${SIGNING_IDENTITY}"
echo -e "${GREEN}Build directory:${NC} ${BUILD_DIR}"
echo ""

# Helper functions
print_step() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ Error: $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check prerequisites
print_step "Checking prerequisites"

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    print_error "No Developer ID certificate found!"
fi
print_success "Found Developer ID certificate"

mkdir -p "$BUILD_DIR"

# Build
print_step "Building and signing app"
cd "$PROJECT_DIR"

xcodebuild clean -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Release -quiet

xcodebuild \
    -project ZetaNotes.xcodeproj \
    -scheme ZetaNotes \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="HDA4C6CU89" \
    -quiet || print_error "Build failed"

BUILT_APP=$(find "$BUILD_DIR/DerivedData/Build/Products" -name "ZetaNotes.app" -maxdepth 2 | head -n 1)
[ -z "$BUILT_APP" ] && print_error "App not found after build"

cp -R "$BUILT_APP" "$BUILD_DIR/${APP_NAME}.app"

codesign --verify --verbose "$BUILD_DIR/${APP_NAME}.app" || print_error "Code signature verification failed"
print_success "App signed successfully"

# Create DMG
print_step "Creating DMG"
cd "$BUILD_DIR"

if ! command -v create-dmg &> /dev/null; then
    print_error "create-dmg not found! Install with: brew install create-dmg"
fi

create-dmg \
    --volname "${APP_NAME}" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 175 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 425 185 \
    --no-internet-enable \
    "$DMG_NAME" \
    "${APP_NAME}.app" || print_error "DMG creation failed"

print_success "DMG created"

# Sign DMG
print_step "Signing DMG"
codesign --sign "$SIGNING_IDENTITY" --timestamp "$DMG_NAME" || print_error "DMG signing failed"
print_success "DMG signed"

# Notarize
print_step "Notarizing with Apple"

if [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo "Submitting for notarization..."

    # Verify DMG exists before submitting
    if [ ! -f "$DMG_NAME" ]; then
        print_error "DMG file not found: $DMG_NAME"
    fi

    echo "File to notarize: $(pwd)/$DMG_NAME"

    # Submit and capture output with verbose logging
    NOTARIZATION_OUTPUT=$(xcrun notarytool submit "$DMG_NAME" \
        --verbose \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        --wait 2>&1 | tee notarization.log)

    # Extract and display submission ID prominently
    SUBMISSION_ID=$(echo "$NOTARIZATION_OUTPUT" | grep -o "id: [a-f0-9-]*" | head -1 | awk '{print $2}')
    if [ -n "$SUBMISSION_ID" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Submission ID: $SUBMISSION_ID"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi

    echo "$NOTARIZATION_OUTPUT"

    if echo "$NOTARIZATION_OUTPUT" | grep -q "status: Accepted"; then
        print_success "Notarization successful!"
        xcrun stapler staple "$DMG_NAME" 2>&1 || print_warning "Stapling failed"
    else
        # Extract submission ID for detailed error log
        SUBMISSION_ID=$(echo "$NOTARIZATION_OUTPUT" | grep -o "id: [a-f0-9-]*" | head -1 | awk '{print $2}')

        print_error "Notarization failed"

        if [ -n "$SUBMISSION_ID" ]; then
            echo ""
            echo "Fetching detailed failure log from Apple..."
            xcrun notarytool log "$SUBMISSION_ID" \
                --apple-id "$APPLE_ID" \
                --team-id "$APPLE_TEAM_ID" \
                --password "$APPLE_APP_SPECIFIC_PASSWORD" \
                notarization-failure.json 2>/dev/null

            if [ -f "notarization-failure.json" ]; then
                echo ""
                echo "Failure details saved to: notarization-failure.json"

                # Try to show key issues if jq is available
                if command -v jq &> /dev/null; then
                    echo ""
                    echo "Issues found:"
                    jq -r '.issues[]? | "  • [\(.severity)] \(.message)"' notarization-failure.json 2>/dev/null || true
                fi
            fi
        fi

        exit 1
    fi
else
    print_warning "Skipping notarization (credentials not set)"
fi

# Checksum
print_step "Generating checksum"
shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
print_success "SHA256 checksum created"

# Summary
print_step "Release Summary"
echo ""
echo -e "${GREEN}✅ Release build complete!${NC}"
echo ""
echo -e "${BLUE}Version:${NC} ${VERSION}"
echo -e "${BLUE}DMG:${NC} ${DMG_NAME}"
echo -e "${BLUE}Location:${NC} ${BUILD_DIR}"
echo -e "${BLUE}Size:${NC} $(du -h "$DMG_NAME" | cut -f1)"
echo -e "${BLUE}SHA256:${NC} $(cat "${DMG_NAME}.sha256" | cut -d' ' -f1)"
echo ""
