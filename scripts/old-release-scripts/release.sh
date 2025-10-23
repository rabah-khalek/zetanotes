#!/bin/bash

set -e  # Exit on any error

# ZetaNotes Release Script - Signed & Notarized Distribution
# For Apple Developer Program members
#
# Usage:
#   ./release.sh <version> [rebuild]
#
# Examples:
#   ./release.sh 1.0.0              # Normal release with existing llama.cpp build
#   ./release.sh 1.0.0 rebuild      # Rebuild llama.cpp from scratch before release
#
# Environment variables:
#
# Required for notarization:
#   APPLE_ID                       - Your Apple ID email
#   APPLE_TEAM_ID                  - Your Team ID (e.g., HDA4C6CU89)
#   APPLE_APP_SPECIFIC_PASSWORD    - App-specific password from appleid.apple.com
#
# Optional for Sparkle signing:
#   SPARKLE_ACCOUNT_NAME           - Keychain account name for EdDSA key (default: zetanotes-sparkle)
#
# Auto-detected:
#   GITHUB_ACTIONS                 - Set by GitHub CI, adjusts certificate detection

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
VERSION="${1:-1.0.0}"
REBUILD_LLAMA="${2:-no}"  # Pass "rebuild" as second argument to force llama.cpp rebuild
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/releases/ZetaNotes-Release-$(date +%Y%m%d-%H%M%S)"
APP_NAME="ZetaNotes"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
VERIFY_SCRIPT="$PROJECT_DIR/scripts/verify-signatures.sh"

# Detect certificate name based on environment
if [ -n "$GITHUB_ACTIONS" ]; then
    SIGNING_IDENTITY="Developer ID Application"
else
    SIGNING_IDENTITY="Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"
fi

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ZetaNotes Release Builder v4.0 (Signed)     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Version:${NC} ${VERSION}"
echo -e "${GREEN}Signing Identity:${NC} ${SIGNING_IDENTITY}"
echo -e "${GREEN}Build directory:${NC} ${BUILD_DIR}"
echo -e "${GREEN}Rebuild llama.cpp:${NC} ${REBUILD_LLAMA}"
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

# Detect environment
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "Running in GitHub Actions CI environment"
    IS_CI=true
else
    echo "Running in local development environment"
    IS_CI=false
fi

# Check for Developer ID certificate
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    print_error "No Developer ID certificate found!"
fi
print_success "Found Developer ID certificate"

# Check for required tools
if ! command -v create-dmg &> /dev/null; then
    print_error "create-dmg not found! Install with: brew install create-dmg"
fi

# Check for Sparkle tools
if [ ! -f "$PROJECT_DIR/scripts/sparkle/bin/sign_update" ]; then
    print_warning "Sparkle sign_update tool not found - Sparkle signatures will be skipped"
fi

# Check notarization credentials
if [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    print_success "Notarization credentials found"
else
    print_warning "Notarization credentials not set - notarization will be skipped"
    if [ "$IS_CI" = true ]; then
        print_warning "In CI: Ensure APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_SPECIFIC_PASSWORD secrets are set"
    fi
fi

mkdir -p "$BUILD_DIR"

# Optionally rebuild llama.cpp
if [ "$REBUILD_LLAMA" = "rebuild" ]; then
    print_step "Rebuilding llama.cpp from scratch"

    # Remove existing build
    if [ -d "$PROJECT_DIR/llama.cpp/build" ]; then
        echo "Removing old llama.cpp build..."
        rm -rf "$PROJECT_DIR/llama.cpp/build"
    fi

    # Build llama.cpp
    echo "Building llama.cpp with Metal support..."
    cd "$PROJECT_DIR"
    bash scripts/build-llama.sh || print_error "llama.cpp build failed"

    print_success "llama.cpp rebuilt successfully"
fi

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
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
    -quiet || print_error "Build failed"

BUILT_APP=$(find "$BUILD_DIR/DerivedData/Build/Products" -name "ZetaNotes.app" -maxdepth 2 | head -n 1)
[ -z "$BUILT_APP" ] && print_error "App not found after build"

cp -R "$BUILT_APP" "$BUILD_DIR/${APP_NAME}.app"

# CRITICAL: Sign Sparkle XPC services and Updater.app with Developer ID
# These components are often signed ad-hoc by Xcode, which causes notarization rejection
print_step "Re-signing Sparkle components with Developer ID"

SPARKLE_FRAMEWORK="$BUILD_DIR/${APP_NAME}.app/Contents/Frameworks/Sparkle.framework"

if [ -d "$SPARKLE_FRAMEWORK" ]; then
    # Sign XPC Services
    for xpc in "$SPARKLE_FRAMEWORK"/Versions/B/XPCServices/*.xpc; do
        if [ -d "$xpc" ]; then
            echo "  Signing: $(basename "$xpc")"
            codesign --force --sign "$SIGNING_IDENTITY" \
                --options runtime \
                --timestamp \
                --deep \
                "$xpc" || print_error "Failed to sign $(basename "$xpc")"
        fi
    done

    # Sign Updater.app
    UPDATER_APP="$SPARKLE_FRAMEWORK/Versions/B/Updater.app"
    if [ -d "$UPDATER_APP" ]; then
        echo "  Signing: Updater.app"
        codesign --force --sign "$SIGNING_IDENTITY" \
            --options runtime \
            --timestamp \
            --deep \
            "$UPDATER_APP" || print_error "Failed to sign Updater.app"
    fi

    # Re-sign the Sparkle framework itself
    echo "  Re-signing: Sparkle.framework"
    codesign --force --sign "$SIGNING_IDENTITY" \
        --options runtime \
        --timestamp \
        "$SPARKLE_FRAMEWORK" || print_error "Failed to sign Sparkle.framework"

    print_success "Sparkle components re-signed with Developer ID"
else
    print_warning "Sparkle framework not found - skipping Sparkle signing"
fi

# Re-sign all llama.cpp dylibs with Developer ID (in case they were signed ad-hoc)
echo ""
echo "Re-signing llama.cpp libraries..."
for dylib in "$BUILD_DIR/${APP_NAME}.app/Contents/Frameworks/"*.dylib; do
    if [ -f "$dylib" ]; then
        echo "  Signing: $(basename "$dylib")"
        codesign --force --sign "$SIGNING_IDENTITY" \
            --options runtime \
            --timestamp \
            "$dylib" || print_error "Failed to sign $(basename "$dylib")"
    fi
done

# CRITICAL: Re-sign the main app bundle AFTER modifying nested components
# When you modify any nested code (frameworks, dylibs, XPC services), you MUST re-sign the parent
print_step "Re-signing main app bundle (required after modifying nested components)"

codesign --force --sign "$SIGNING_IDENTITY" \
    --entitlements "$PROJECT_DIR/ZetaNotes/ZetaNotes.entitlements" \
    --options runtime \
    --timestamp \
    --deep \
    "$BUILD_DIR/${APP_NAME}.app" || print_error "Failed to re-sign main app bundle"

print_success "Main app bundle re-signed"

# Verify app bundle signature
echo ""
echo "Verifying final app signature..."
codesign --verify --verbose --deep --strict "$BUILD_DIR/${APP_NAME}.app" || print_error "Code signature verification failed"

# Verify all embedded frameworks are signed with hardened runtime
echo ""
echo "Verifying embedded frameworks..."
for framework in "$BUILD_DIR/${APP_NAME}.app/Contents/Frameworks/"*; do
    if [ -d "$framework" ] || [ -f "$framework" ]; then
        echo "  Checking: $(basename "$framework")"
        codesign --verify --verbose "$framework" || print_warning "$(basename "$framework") signature check failed"
    fi
done

print_success "App and frameworks signed successfully"

# Verify all signatures before proceeding
print_step "Verifying all signatures"

if [ ! -f "$VERIFY_SCRIPT" ]; then
    print_error "Signature verification script not found at: $VERIFY_SCRIPT"
fi

# Make sure verification script is executable
chmod +x "$VERIFY_SCRIPT"

# Run verification script
if bash "$VERIFY_SCRIPT" "$BUILD_DIR/${APP_NAME}.app"; then
    print_success "All signatures verified successfully"
else
    print_error "Signature verification failed! Fix errors before submitting for notarization."
fi

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
codesign --sign "$SIGNING_IDENTITY" \
    --timestamp \
    --options runtime \
    "$DMG_NAME" || print_error "DMG signing failed"

# Verify DMG signature
codesign --verify --verbose "$DMG_NAME" || print_error "DMG signature verification failed"
print_success "DMG signed and verified"

# Sign DMG for Sparkle updates (EdDSA signature)
print_step "Generating Sparkle EdDSA signature"

SIGN_UPDATE="$PROJECT_DIR/scripts/sparkle/bin/sign_update"
SPARKLE_SIGNATURE=""
DMG_SIZE=$(stat -f%z "$DMG_NAME")

if [ -f "$SIGN_UPDATE" ]; then
    echo "Signing DMG with Sparkle EdDSA key..."

    # Determine signing method: CI (env var) or local (keychain)
    if [ -n "$SPARKLE_PRIVATE_KEY" ]; then
        # CI mode: Use private key from environment variable
        echo "Using Sparkle private key from SPARKLE_PRIVATE_KEY environment variable (CI mode)"

        # Save private key to temporary file
        TEMP_KEY_FILE=$(mktemp)
        echo "$SPARKLE_PRIVATE_KEY" > "$TEMP_KEY_FILE"

        # Sign the DMG using --ed-key-file
        SIGN_OUTPUT=$("$SIGN_UPDATE" --ed-key-file "$TEMP_KEY_FILE" "$DMG_NAME" 2>&1)
        SIGN_EXIT_CODE=$?

        # Clean up temp file immediately
        rm -f "$TEMP_KEY_FILE"

        if [ $SIGN_EXIT_CODE -eq 0 ]; then
            # Extract the EdDSA signature from output
            SPARKLE_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep 'sparkle:edSignature=' | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')

            if [ -n "$SPARKLE_SIGNATURE" ]; then
                print_success "Sparkle EdDSA signature generated (from env var)"
                echo "Signature: ${SPARKLE_SIGNATURE:0:32}..."
                echo "File size: $DMG_SIZE bytes"
            else
                print_warning "Could not extract Sparkle signature from output"
                echo "$SIGN_OUTPUT"
            fi
        else
            print_warning "Sparkle signing failed with exit code: $SIGN_EXIT_CODE"
            echo "$SIGN_OUTPUT"
        fi
    else
        # Local mode: Use key from macOS Keychain
        SPARKLE_ACCOUNT="${SPARKLE_ACCOUNT_NAME:-zetanotes-sparkle}"
        echo "Using Sparkle key from Keychain account: $SPARKLE_ACCOUNT (local mode)"

        # Sign the DMG and extract the signature
        SIGN_OUTPUT=$("$SIGN_UPDATE" --account "$SPARKLE_ACCOUNT" "$DMG_NAME" 2>&1)
        SIGN_EXIT_CODE=$?

        if [ $SIGN_EXIT_CODE -eq 0 ]; then
            # Extract the EdDSA signature from output
            SPARKLE_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep 'sparkle:edSignature=' | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')

            if [ -n "$SPARKLE_SIGNATURE" ]; then
                print_success "Sparkle EdDSA signature generated (from Keychain)"
                echo "Signature: ${SPARKLE_SIGNATURE:0:32}..."
                echo "File size: $DMG_SIZE bytes"
            else
                print_warning "Could not extract Sparkle signature from output"
                echo "$SIGN_OUTPUT"
            fi
        else
            print_warning "Sparkle signing failed - key may not be in Keychain"
            echo "$SIGN_OUTPUT"
            echo ""
            echo "To set up Sparkle keys locally, run:"
            echo "  ./scripts/setup-sparkle-keys.sh"
        fi
    fi

    # Save signature to file if successful
    if [ -n "$SPARKLE_SIGNATURE" ]; then
        cat > "${DMG_NAME}.sparkle-signature" <<EOF
sparkle:edSignature="$SPARKLE_SIGNATURE"
length="$DMG_SIZE"
EOF
        print_success "Signature saved to ${DMG_NAME}.sparkle-signature"
    else
        print_warning "No Sparkle signature generated - updates will not be secure!"
    fi
else
    print_warning "sign_update tool not found at $SIGN_UPDATE"
    print_warning "Sparkle updates will not be signed - this is insecure!"
fi

# Notarize
print_step "Notarizing with Apple"

if [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo "Submitting for notarization..."

    # Verify DMG exists before submitting
    if [ ! -f "$DMG_NAME" ]; then
        print_error "DMG file not found: $DMG_NAME"
    fi

    echo "File to notarize: $(pwd)/$DMG_NAME"

    # Submit for notarization (no --wait flag, we'll poll manually for better reliability)
    NOTARIZATION_OUTPUT=$(xcrun notarytool submit "$DMG_NAME" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        2>&1 | tee notarization-submit.log)

    # Extract submission ID
    SUBMISSION_ID=$(echo "$NOTARIZATION_OUTPUT" | grep -o "id: [a-f0-9-]*" | head -1 | awk '{print $2}')

    if [ -z "$SUBMISSION_ID" ]; then
        print_error "Failed to get submission ID from notarization service"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Submission ID: $SUBMISSION_ID"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Waiting for notarization to complete (this can take 1-5 minutes)..."

    # Poll for status with timeout
    MAX_WAIT_TIME=600  # 10 minutes max
    POLL_INTERVAL=10   # Check every 10 seconds
    ELAPSED=0
    NOTARIZATION_STATUS=""

    while [ $ELAPSED -lt $MAX_WAIT_TIME ]; do
        sleep $POLL_INTERVAL
        ELAPSED=$((ELAPSED + POLL_INTERVAL))

        # Get current status
        STATUS_OUTPUT=$(xcrun notarytool info "$SUBMISSION_ID" \
            --apple-id "$APPLE_ID" \
            --team-id "$APPLE_TEAM_ID" \
            --password "$APPLE_APP_SPECIFIC_PASSWORD" 2>&1)

        # Check if status is available
        if echo "$STATUS_OUTPUT" | grep -q "status:"; then
            NOTARIZATION_STATUS=$(echo "$STATUS_OUTPUT" | grep "status:" | awk '{print $2}')
            echo -n "."  # Progress indicator

            # Check for terminal states
            if [ "$NOTARIZATION_STATUS" = "Accepted" ]; then
                echo ""
                print_success "Notarization accepted!"
                break
            elif [ "$NOTARIZATION_STATUS" = "Invalid" ] || [ "$NOTARIZATION_STATUS" = "Rejected" ]; then
                echo ""
                print_error "Notarization failed with status: $NOTARIZATION_STATUS"
            fi
        fi
    done

    # Save full status to log
    echo "$STATUS_OUTPUT" > notarization-status.log

    # Check if we timed out
    if [ $ELAPSED -ge $MAX_WAIT_TIME ] && [ "$NOTARIZATION_STATUS" != "Accepted" ]; then
        echo ""
        print_warning "Notarization timed out after $MAX_WAIT_TIME seconds"
        echo "Current status: $NOTARIZATION_STATUS"
        echo "Submission ID: $SUBMISSION_ID"
        echo ""
        echo "You can check status manually with:"
        echo "  xcrun notarytool info $SUBMISSION_ID \\"
        echo "    --apple-id \$APPLE_ID \\"
        echo "    --team-id \$APPLE_TEAM_ID \\"
        echo "    --password \$APPLE_APP_SPECIFIC_PASSWORD"
        echo ""
        print_error "Notarization did not complete in time"
    fi

    # If accepted, staple the notarization ticket
    if [ "$NOTARIZATION_STATUS" = "Accepted" ]; then
        echo "Stapling notarization ticket to DMG..."
        if xcrun stapler staple "$DMG_NAME" 2>&1; then
            print_success "Notarization ticket stapled successfully"

            # Verify stapling
            if spctl -a -vv -t install "$DMG_NAME" 2>&1 | grep -q "source=Notarized Developer ID"; then
                print_success "DMG is properly notarized and stapled"
            else
                print_warning "DMG may not be properly stapled - verification failed"
            fi
        else
            print_warning "Stapling failed - users will need internet to verify"
        fi
    else
        # Notarization failed - get detailed error log
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
            else
                echo ""
                echo "Install jq to see formatted error details: brew install jq"
            fi
        fi

        exit 1
    fi
else
    print_warning "Skipping notarization (APPLE_ID, APPLE_TEAM_ID, or APPLE_APP_SPECIFIC_PASSWORD not set)"
    echo ""
    echo "To enable notarization, set these environment variables:"
    echo "  export APPLE_ID='your-apple-id@example.com'"
    echo "  export APPLE_TEAM_ID='YOUR_TEAM_ID'"
    echo "  export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
    echo ""
fi

# Checksum
print_step "Generating checksum"
shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
SHA256=$(cat "${DMG_NAME}.sha256" | cut -d' ' -f1)
print_success "SHA256 checksum created"

# Update appcast.xml information
print_step "Appcast update information"
echo ""
echo "To update your appcast.xml (docs/appcast.xml), you'll need:"
echo ""
echo "  <enclosure"
echo "    url=\"https://github.com/rabah-khalek/zetanotes/releases/download/v${VERSION}/${DMG_NAME}\""
echo "    sparkle:version=\"${VERSION}\""
echo "    sparkle:shortVersionString=\"${VERSION}\""
echo "    length=\"${DMG_SIZE}\""

if [ -n "$SPARKLE_SIGNATURE" ]; then
    echo "    type=\"application/octet-stream\""
    echo "    sparkle:edSignature=\"${SPARKLE_SIGNATURE}\" />"
    echo ""
    print_success "Sparkle signature is ready for appcast"
else
    echo "    type=\"application/octet-stream\" />"
    echo ""
    print_warning "No Sparkle signature - appcast updates will be INSECURE!"
fi

echo ""
echo "This information has been saved to: ${DMG_NAME}.appcast-info"
cat > "${DMG_NAME}.appcast-info" <<EOF
Version: ${VERSION}
DMG Name: ${DMG_NAME}
File Size: ${DMG_SIZE} bytes
SHA256: ${SHA256}
Sparkle Signature: ${SPARKLE_SIGNATURE:-NOT_GENERATED}
Download URL: https://github.com/rabah-khalek/zetanotes/releases/download/v${VERSION}/${DMG_NAME}

Appcast XML snippet:
  <enclosure
    url="https://github.com/rabah-khalek/zetanotes/releases/download/v${VERSION}/${DMG_NAME}"
    sparkle:version="${VERSION}"
    sparkle:shortVersionString="${VERSION}"
    length="${DMG_SIZE}"
    type="application/octet-stream"
    sparkle:edSignature="${SPARKLE_SIGNATURE:-MISSING_SIGNATURE}" />
EOF

# Summary
print_step "Release Summary"
echo ""
echo -e "${GREEN}✅ Release build complete!${NC}"
echo ""
echo -e "${BLUE}Version:${NC} ${VERSION}"
echo -e "${BLUE}DMG:${NC} ${DMG_NAME}"
echo -e "${BLUE}Location:${NC} ${BUILD_DIR}"
echo -e "${BLUE}Size:${NC} $(du -h "$DMG_NAME" | cut -f1) ($DMG_SIZE bytes)"
echo -e "${BLUE}SHA256:${NC} ${SHA256}"
if [ -n "$SPARKLE_SIGNATURE" ]; then
    echo -e "${BLUE}Sparkle Signature:${NC} ${SPARKLE_SIGNATURE:0:32}..."
fi
if [ "$NOTARIZATION_STATUS" = "Accepted" ]; then
    echo -e "${BLUE}Notarization:${NC} ✅ Accepted and stapled"
elif [ -n "$SUBMISSION_ID" ]; then
    echo -e "${BLUE}Notarization:${NC} ⚠️  Skipped or failed (check logs)"
else
    echo -e "${BLUE}Notarization:${NC} ⚠️  Skipped (credentials not set)"
fi
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Upload ${DMG_NAME} to GitHub Releases"
echo "2. Update docs/appcast.xml with the information from ${DMG_NAME}.appcast-info"
echo "3. Push appcast.xml changes to trigger update notifications"
echo ""
