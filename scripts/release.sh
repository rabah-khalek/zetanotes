#!/bin/bash
# ZetaNotes Unified Release Script
# Works in both local and CI environments
#
# Usage:
#   ./release.sh <version> [--app-review]
#
# Examples:
#   ./release.sh 1.0.0              # Release with fresh llama.cpp build
#   ./release.sh 1.0.0 --app-review # Build for App Store review (enables test credentials)
#
# Environment variables:
#   APPLE_ID                       - Apple ID email (for notarization)
#   APPLE_TEAM_ID                  - Team ID (for notarization)
#   APPLE_APP_SPECIFIC_PASSWORD    - App-specific password (for notarization)
#   SPARKLE_PRIVATE_KEY            - EdDSA private key (for CI Sparkle signing)
#   SPARKLE_ACCOUNT_NAME           - Keychain account (for local Sparkle signing)

set -e  # Exit on any error

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load configuration
source "$SCRIPT_DIR/release-config.sh"

# Load library functions
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/validation.sh"
source "$SCRIPT_DIR/lib/xcode.sh"
source "$SCRIPT_DIR/lib/signing.sh"
source "$SCRIPT_DIR/lib/sparkle.sh"
source "$SCRIPT_DIR/lib/notarization.sh"
source "$SCRIPT_DIR/lib/packaging.sh"

# Parse arguments
VERSION="${1}"
REBUILD_LLAMA="always"  # Always rebuild for fresh signatures
APP_REVIEW_MODE="false"

# Check for --app-review flag
if [ "$2" = "--app-review" ] || [ "$1" = "--app-review" ]; then
    APP_REVIEW_MODE="true"
    # If --app-review is first arg, shift to get version
    if [ "$1" = "--app-review" ]; then
        VERSION="${2}"
    fi
fi

if [ -z "$VERSION" ]; then
    print_error "Version required. Usage: ./release.sh <version> [--app-review]"
fi

# Detect environment and set paths
ENVIRONMENT=$(detect_environment)
SIGNING_IDENTITY=$(get_signing_identity "$ENVIRONMENT")
BUILD_DIR="$PROJECT_DIR/releases/${APP_NAME}-Release-$(date +%Y%m%d-%H%M%S)"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"

# Show banner
print_banner "$VERSION" "$ENVIRONMENT"
echo -e "${GREEN}Signing Identity:${NC} ${SIGNING_IDENTITY}"
echo -e "${GREEN}Build directory:${NC} ${BUILD_DIR}"
if [ "$APP_REVIEW_MODE" = "true" ]; then
    echo -e "${YELLOW}⚠️  APP REVIEW MODE ENABLED${NC}"
    echo -e "${YELLOW}   Test credentials: Email='admin' Key='TEST'${NC}"
fi
echo ""

# ============================================================================
# STEP 1: Prerequisites
# ============================================================================

print_step "Checking prerequisites"

check_certificate
check_create_dmg
check_sparkle_tools "$PROJECT_DIR/$SIGN_UPDATE_PATH" || true  # Sparkle removed; non-fatal

IS_CI_ENV="false"
[ "$ENVIRONMENT" = "ci" ] && IS_CI_ENV="true"

NOTARIZATION_ENABLED="false"
if check_notarization_credentials "$IS_CI_ENV"; then
    NOTARIZATION_ENABLED="true"
fi

mkdir -p "$BUILD_DIR"

# ============================================================================
# STEP 2: Rebuild llama.cpp (always - ensures fresh signatures)
# ============================================================================

rebuild_llama_if_needed "$REBUILD_LLAMA" "$PROJECT_DIR"

# ============================================================================
# STEP 3: Build app
# ============================================================================

build_app "$PROJECT_DIR" "$BUILD_DIR" "$TEAM_ID" "$APP_REVIEW_MODE"

# ============================================================================
# STEP 4: Re-sign components
# ============================================================================

resign_sparkle_components "$BUILD_DIR" "$SIGNING_IDENTITY"
resign_llama_libraries "$BUILD_DIR" "$SIGNING_IDENTITY"
resign_app_bundle "$BUILD_DIR" "$PROJECT_DIR" "$SIGNING_IDENTITY"

# ============================================================================
# STEP 5: Verify signatures
# ============================================================================

print_step "Verifying all signatures"

verify_app_signature "$BUILD_DIR/${APP_NAME}.app"
verify_all_frameworks "$BUILD_DIR/${APP_NAME}.app"
run_verification_script "$BUILD_DIR/${APP_NAME}.app" "$PROJECT_DIR/$VERIFY_SCRIPT_PATH"

print_success "All signatures verified"

# ============================================================================
# STEP 6: Create and sign DMG
# ============================================================================

create_dmg "$BUILD_DIR" "$DMG_NAME"
sign_dmg "$BUILD_DIR/$DMG_NAME" "$SIGNING_IDENTITY"

# ============================================================================
# STEP 7: Generate Sparkle signature
# ============================================================================

cd "$BUILD_DIR"

SPARKLE_SIGNATURE=""
FILE_SIZE=$(stat -f%z "$DMG_NAME")

# Generate signature
if generate_sparkle_signature \
    "$DMG_NAME" \
    "$PROJECT_DIR/$SIGN_UPDATE_PATH" \
    "$SPARKLE_ACCOUNT_NAME" \
    "$SPARKLE_PRIVATE_KEY"; then

    # Capture the signature (last line of output)
    SPARKLE_SIGNATURE_OUTPUT=$(generate_sparkle_signature \
        "$DMG_NAME" \
        "$PROJECT_DIR/$SIGN_UPDATE_PATH" \
        "$SPARKLE_ACCOUNT_NAME" \
        "$SPARKLE_PRIVATE_KEY")

    SPARKLE_SIGNATURE=$(echo "$SPARKLE_SIGNATURE_OUTPUT" | tail -n 1)

    # Save signature to file
    if [ -n "$SPARKLE_SIGNATURE" ]; then
        save_sparkle_signature "$DMG_NAME" "$SPARKLE_SIGNATURE" "$FILE_SIZE"
    fi
fi

# In CI, require Sparkle signature
if [ "$ENVIRONMENT" = "ci" ] && [ -z "$SPARKLE_SIGNATURE" ]; then
    print_error "CRITICAL: Sparkle signature is required in CI but was not generated"
fi

# ============================================================================
# STEP 8: Notarize DMG
# ============================================================================

NOTARIZATION_STATUS="Skipped"

if [ "$NOTARIZATION_ENABLED" = "true" ]; then
    if notarize_dmg \
        "$DMG_NAME" \
        "$APPLE_ID" \
        "$APPLE_TEAM_ID" \
        "$APPLE_APP_SPECIFIC_PASSWORD"; then

        NOTARIZATION_STATUS="Accepted"
    else
        NOTARIZATION_STATUS="Failed"

        # In CI, notarization is required
        if [ "$ENVIRONMENT" = "ci" ]; then
            print_error "Notarization failed in CI - this is required"
        fi
    fi
fi

# ============================================================================
# STEP 9: Generate metadata
# ============================================================================

SHA256=$(generate_checksum "$DMG_NAME")
generate_appcast_info "$DMG_NAME" "$VERSION" "$SPARKLE_SIGNATURE"

# ============================================================================
# STEP 10: Summary
# ============================================================================

print_release_summary "$VERSION" "$DMG_NAME" "$SPARKLE_SIGNATURE" "$NOTARIZATION_STATUS"

if [ "$APP_REVIEW_MODE" = "true" ]; then
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  APP REVIEW BUILD - PROVIDE THESE CREDENTIALS TO APPLE${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Email:        ${NC}admin"
    echo -e "${YELLOW}  License Key:  ${NC}TEST"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
fi

# Export outputs for CI
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "DMG_FILE=$BUILD_DIR/$DMG_NAME" >> "$GITHUB_OUTPUT"
    echo "SHA_FILE=$BUILD_DIR/${DMG_NAME}.sha256" >> "$GITHUB_OUTPUT"
    echo "DMG_NAME=$DMG_NAME" >> "$GITHUB_OUTPUT"
    echo "FILE_SIZE=$FILE_SIZE" >> "$GITHUB_OUTPUT"
    echo "SPARKLE_SIGNATURE=$SPARKLE_SIGNATURE" >> "$GITHUB_OUTPUT"
    echo "BUILD_DIR=$BUILD_DIR" >> "$GITHUB_OUTPUT"
    echo "CHECKSUM=$SHA256" >> "$GITHUB_OUTPUT"
fi

print_success "Release complete!"
