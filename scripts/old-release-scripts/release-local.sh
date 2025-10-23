#!/bin/bash

set -e  # Exit on any error

# ZetaNotes Local Release Script
# For local development builds with notarization
#
# Usage:
#   ./release-local.sh <version> [rebuild]
#
# Examples:
#   ./release-local.sh 1.0.0              # Normal release
#   ./release-local.sh 1.0.0 rebuild      # Rebuild llama.cpp first
#
# Required environment variables:
#   APPLE_ID                       - Your Apple ID email
#   APPLE_TEAM_ID                  - Your Team ID (e.g., HDA4C6CU89)
#   APPLE_APP_SPECIFIC_PASSWORD    - App-specific password
#
# Optional:
#   SPARKLE_ACCOUNT_NAME           - Keychain account (default: zetanotes-sparkle)

# Configuration
VERSION="${1:-1.0.0}"
REBUILD_LLAMA="${2:-no}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/releases/ZetaNotes-Release-$(date +%Y%m%d-%H%M%S)"
DMG_NAME="ZetaNotes-v${VERSION}.dmg"
VERIFY_SCRIPT="$PROJECT_DIR/scripts/verify-signatures.sh"
SIGNING_IDENTITY="Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"
SIGN_UPDATE="$PROJECT_DIR/scripts/sparkle/bin/sign_update"
SPARKLE_ACCOUNT="${SPARKLE_ACCOUNT_NAME:-zetanotes-sparkle}"

# Load common functions
source "$PROJECT_DIR/scripts/release-common.sh"

# Banner
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ZetaNotes Local Release Builder v5.0       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Version:${NC} ${VERSION}"
echo -e "${GREEN}Environment:${NC} Local Development"
echo -e "${GREEN}Signing Identity:${NC} ${SIGNING_IDENTITY}"
echo -e "${GREEN}Build directory:${NC} ${BUILD_DIR}"
echo -e "${GREEN}Rebuild llama.cpp:${NC} ${REBUILD_LLAMA}"
echo ""

# Check prerequisites
print_step "Checking prerequisites"

# Check for Developer ID certificate
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    print_error "No Developer ID certificate found!"
fi
print_success "Found Developer ID certificate"

# Check for required tools
if ! command -v create-dmg &> /dev/null; then
    print_error "create-dmg not found! Install with: brew install create-dmg"
fi
print_success "Found create-dmg"

# Check for Sparkle tools
if [ ! -f "$SIGN_UPDATE" ]; then
    print_warning "Sparkle sign_update tool not found"
    print_warning "Sparkle signatures will be skipped - run ./scripts/setup-sparkle-keys.sh"
fi

# Check notarization credentials
if [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    print_success "Notarization credentials found"
else
    print_warning "Notarization credentials not set"
    echo ""
    echo "To enable notarization, set these environment variables:"
    echo "  export APPLE_ID='your-apple-id@example.com'"
    echo "  export APPLE_TEAM_ID='HDA4C6CU89'"
    echo "  export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
    echo ""
fi

mkdir -p "$BUILD_DIR"

# Optionally rebuild llama.cpp
if [ "$REBUILD_LLAMA" = "rebuild" ]; then
    print_step "Rebuilding llama.cpp from scratch"

    if [ -d "$PROJECT_DIR/llama.cpp/build" ]; then
        echo "Removing old llama.cpp build..."
        rm -rf "$PROJECT_DIR/llama.cpp/build"
    fi

    echo "Building llama.cpp with Metal support..."
    cd "$PROJECT_DIR"
    bash scripts/build-llama.sh || print_error "llama.cpp build failed"

    print_success "llama.cpp rebuilt successfully"
fi

# Build app
build_app "$PROJECT_DIR" "$BUILD_DIR" "$SIGNING_IDENTITY"

# Re-sign Sparkle components
resign_sparkle "$BUILD_DIR" "$SIGNING_IDENTITY"

# Re-sign llama.cpp libraries
resign_llama_libs "$BUILD_DIR" "$SIGNING_IDENTITY"

# Re-sign main app bundle
resign_app_bundle "$BUILD_DIR" "$PROJECT_DIR" "$SIGNING_IDENTITY"

# Verify signatures
verify_signatures "$BUILD_DIR" "$VERIFY_SCRIPT"

# Create DMG
create_dmg_file "$BUILD_DIR" "$DMG_NAME"

# Sign DMG
sign_dmg "$BUILD_DIR/$DMG_NAME" "$SIGNING_IDENTITY"

# Generate Sparkle signature from Keychain
cd "$BUILD_DIR"
SPARKLE_OUTPUT=$(generate_sparkle_signature_keychain "$DMG_NAME" "$SIGN_UPDATE" "$SPARKLE_ACCOUNT")
if [ $? -eq 0 ]; then
    # Extract just the signature from the last line
    SPARKLE_SIGNATURE=$(echo "$SPARKLE_OUTPUT" | tail -n 1)
else
    SPARKLE_SIGNATURE=""
    print_warning "Continuing without Sparkle signature"
fi

# Notarize DMG
if notarize_dmg "$DMG_NAME" "$APPLE_ID" "$APPLE_TEAM_ID" "$APPLE_APP_SPECIFIC_PASSWORD"; then
    NOTARIZATION_STATUS="Accepted"
else
    NOTARIZATION_STATUS="Skipped"
fi

# Generate metadata
generate_metadata "$DMG_NAME" "$VERSION" "$SPARKLE_SIGNATURE"

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

if [ -n "$SPARKLE_SIGNATURE" ]; then
    echo -e "${BLUE}Sparkle Signature:${NC} ${SPARKLE_SIGNATURE:0:32}..."
else
    echo -e "${BLUE}Sparkle Signature:${NC} ⚠️  NOT GENERATED"
fi

if [ "$NOTARIZATION_STATUS" = "Accepted" ]; then
    echo -e "${BLUE}Notarization:${NC} ✅ Accepted and stapled"
else
    echo -e "${BLUE}Notarization:${NC} ⚠️  Skipped (credentials not set)"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Upload ${DMG_NAME} to GitHub Releases"
echo "2. Update docs/appcast.xml with the information from ${DMG_NAME}.appcast-info"
echo "3. Push appcast.xml changes to trigger update notifications"
echo ""
