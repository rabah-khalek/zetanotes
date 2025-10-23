#!/bin/bash

set -e  # Exit on any error

# ZetaNotes CI Release Script
# For GitHub Actions automated builds
#
# Usage:
#   ./release-ci.sh <version>
#
# Example:
#   ./release-ci.sh 1.0.0
#
# Required environment variables:
#   APPLE_ID                       - Your Apple ID email
#   APPLE_TEAM_ID                  - Your Team ID (e.g., HDA4C6CU89)
#   APPLE_APP_SPECIFIC_PASSWORD    - App-specific password
#   SPARKLE_PRIVATE_KEY            - EdDSA private key for Sparkle signing
#
# Note: Certificate must be imported to CI keychain before running

# Configuration
VERSION="${1}"
if [ -z "$VERSION" ]; then
    echo "Error: Version required"
    echo "Usage: ./release-ci.sh <version>"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/releases/ZetaNotes-Release-$(date +%Y%m%d-%H%M%S)"
DMG_NAME="ZetaNotes-v${VERSION}.dmg"
VERIFY_SCRIPT="$PROJECT_DIR/scripts/verify-signatures.sh"
SIGNING_IDENTITY="Developer ID Application"  # CI uses generic match
SIGN_UPDATE="$PROJECT_DIR/scripts/sparkle/bin/sign_update"

# Load common functions
source "$PROJECT_DIR/scripts/release-common.sh"

# Banner
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ZetaNotes CI Release Builder v5.0          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Version:${NC} ${VERSION}"
echo -e "${GREEN}Environment:${NC} GitHub Actions CI"
echo -e "${GREEN}Signing Identity:${NC} ${SIGNING_IDENTITY}"
echo -e "${GREEN}Build directory:${NC} ${BUILD_DIR}"
echo ""

# Check prerequisites
print_step "Checking prerequisites"

# Check for Developer ID certificate
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    print_error "No Developer ID certificate found in CI keychain!"
fi
print_success "Found Developer ID certificate"

# Check for required tools
if ! command -v create-dmg &> /dev/null; then
    print_error "create-dmg not found! CI should install it with: brew install create-dmg"
fi
print_success "Found create-dmg"

# Check for Sparkle tools
if [ ! -f "$SIGN_UPDATE" ]; then
    print_warning "Sparkle sign_update tool not found at $SIGN_UPDATE"
fi

# Check notarization credentials
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    print_error "Missing notarization credentials! Ensure APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_SPECIFIC_PASSWORD are set in GitHub Secrets"
fi
print_success "Notarization credentials found"

# Check Sparkle private key
if [ -z "$SPARKLE_PRIVATE_KEY" ]; then
    print_warning "SPARKLE_PRIVATE_KEY not set - Sparkle signatures will be skipped"
else
    print_success "Sparkle private key found"
fi

mkdir -p "$BUILD_DIR"

# llama.cpp should already be built by CI workflow before calling this script
if [ ! -d "$PROJECT_DIR/llama.cpp/build" ]; then
    print_warning "llama.cpp build directory not found - CI should build it first"
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

# Generate Sparkle signature from environment variable
cd "$BUILD_DIR"
if [ -n "$SPARKLE_PRIVATE_KEY" ]; then
    SPARKLE_OUTPUT=$(generate_sparkle_signature_env "$DMG_NAME" "$SIGN_UPDATE" "$SPARKLE_PRIVATE_KEY")
    if [ $? -eq 0 ]; then
        # Extract just the signature from the last line
        SPARKLE_SIGNATURE=$(echo "$SPARKLE_OUTPUT" | tail -n 1)
    else
        SPARKLE_SIGNATURE=""
        print_error "Failed to generate Sparkle signature in CI - this is required!"
    fi
else
    SPARKLE_SIGNATURE=""
    print_error "SPARKLE_PRIVATE_KEY not set - cannot generate Sparkle signature!"
fi

# Notarize DMG (required in CI)
NOTARIZATION_OUTPUT=$(notarize_dmg "$DMG_NAME" "$APPLE_ID" "$APPLE_TEAM_ID" "$APPLE_APP_SPECIFIC_PASSWORD")
if [ $? -eq 0 ]; then
    NOTARIZATION_STATUS=$(echo "$NOTARIZATION_OUTPUT" | tail -n 1)
else
    print_error "Notarization failed in CI - this is required!"
fi

# Generate metadata
generate_metadata "$DMG_NAME" "$VERSION" "$SPARKLE_SIGNATURE"

# Summary
print_step "CI Release Summary"
echo ""
echo -e "${GREEN}✅ CI release build complete!${NC}"
echo ""
echo -e "${BLUE}Version:${NC} ${VERSION}"
echo -e "${BLUE}DMG:${NC} ${DMG_NAME}"
echo -e "${BLUE}Location:${NC} ${BUILD_DIR}"
echo -e "${BLUE}Size:${NC} $(du -h "$DMG_NAME" | cut -f1)"
echo -e "${BLUE}SHA256:${NC} $(cat "${DMG_NAME}.sha256" | cut -d' ' -f1)"

if [ -n "$SPARKLE_SIGNATURE" ]; then
    echo -e "${BLUE}Sparkle Signature:${NC} ${SPARKLE_SIGNATURE:0:32}..."
else
    echo -e "${BLUE}Sparkle Signature:${NC} ❌ FAILED"
fi

if [ "$NOTARIZATION_STATUS" = "Accepted" ]; then
    echo -e "${BLUE}Notarization:${NC} ✅ Accepted and stapled"
else
    echo -e "${BLUE}Notarization:${NC} ❌ FAILED"
fi

echo ""
echo -e "${GREEN}CI outputs available for GitHub Actions:${NC}"
echo "DMG_FILE=$BUILD_DIR/$DMG_NAME"
echo "SHA_FILE=$BUILD_DIR/${DMG_NAME}.sha256"
echo "FILE_SIZE=$(stat -f%z "$DMG_NAME")"
echo "SPARKLE_SIGNATURE=$SPARKLE_SIGNATURE"
echo "BUILD_DIR=$BUILD_DIR"
echo ""

# Export for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "DMG_FILE=$BUILD_DIR/$DMG_NAME" >> "$GITHUB_OUTPUT"
    echo "SHA_FILE=$BUILD_DIR/${DMG_NAME}.sha256" >> "$GITHUB_OUTPUT"
    echo "DMG_NAME=$DMG_NAME" >> "$GITHUB_OUTPUT"
    echo "FILE_SIZE=$(stat -f%z "$DMG_NAME")" >> "$GITHUB_OUTPUT"
    echo "SPARKLE_SIGNATURE=$SPARKLE_SIGNATURE" >> "$GITHUB_OUTPUT"
    echo "BUILD_DIR=$BUILD_DIR" >> "$GITHUB_OUTPUT"
    echo "CHECKSUM=$(cat "${DMG_NAME}.sha256" | cut -d' ' -f1)" >> "$GITHUB_OUTPUT"
    print_success "Outputs exported to GITHUB_OUTPUT"
fi

echo ""
