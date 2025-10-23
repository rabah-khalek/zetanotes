#!/bin/bash
# Common functions and configuration for release scripts
# Sourced by both release-local.sh and release-ci.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Build app with Xcode
build_app() {
    local PROJECT_DIR="$1"
    local BUILD_DIR="$2"
    local SIGNING_IDENTITY="$3"

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

    cp -R "$BUILT_APP" "$BUILD_DIR/ZetaNotes.app"
    print_success "App built successfully"
}

# Re-sign Sparkle components with Developer ID
resign_sparkle() {
    local BUILD_DIR="$1"
    local SIGNING_IDENTITY="$2"

    print_step "Re-signing Sparkle components with Developer ID"

    SPARKLE_FRAMEWORK="$BUILD_DIR/ZetaNotes.app/Contents/Frameworks/Sparkle.framework"

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
}

# Re-sign llama.cpp libraries
resign_llama_libs() {
    local BUILD_DIR="$1"
    local SIGNING_IDENTITY="$2"

    echo ""
    echo "Re-signing llama.cpp libraries..."
    for dylib in "$BUILD_DIR/ZetaNotes.app/Contents/Frameworks/"*.dylib; do
        if [ -f "$dylib" ]; then
            echo "  Signing: $(basename "$dylib")"
            codesign --force --sign "$SIGNING_IDENTITY" \
                --options runtime \
                --timestamp \
                "$dylib" || print_error "Failed to sign $(basename "$dylib")"
        fi
    done
    print_success "llama.cpp libraries re-signed"
}

# Re-sign main app bundle
resign_app_bundle() {
    local BUILD_DIR="$1"
    local PROJECT_DIR="$2"
    local SIGNING_IDENTITY="$3"

    print_step "Re-signing main app bundle"

    codesign --force --sign "$SIGNING_IDENTITY" \
        --entitlements "$PROJECT_DIR/ZetaNotes/ZetaNotes.entitlements" \
        --options runtime \
        --timestamp \
        --deep \
        "$BUILD_DIR/ZetaNotes.app" || print_error "Failed to re-sign main app bundle"

    print_success "Main app bundle re-signed"
}

# Verify signatures
verify_signatures() {
    local BUILD_DIR="$1"
    local VERIFY_SCRIPT="$2"

    print_step "Verifying all signatures"

    # Verify app bundle signature
    echo "Verifying final app signature..."
    codesign --verify --verbose --deep --strict "$BUILD_DIR/ZetaNotes.app" || print_error "Code signature verification failed"

    # Verify all embedded frameworks
    echo ""
    echo "Verifying embedded frameworks..."
    for framework in "$BUILD_DIR/ZetaNotes.app/Contents/Frameworks/"*; do
        if [ -d "$framework" ] || [ -f "$framework" ]; then
            echo "  Checking: $(basename "$framework")"
            codesign --verify --verbose "$framework" || print_warning "$(basename "$framework") signature check failed"
        fi
    done

    # Run comprehensive verification script
    if [ -f "$VERIFY_SCRIPT" ]; then
        chmod +x "$VERIFY_SCRIPT"
        if bash "$VERIFY_SCRIPT" "$BUILD_DIR/ZetaNotes.app"; then
            print_success "All signatures verified successfully"
        else
            print_error "Signature verification failed!"
        fi
    else
        print_warning "Verification script not found at: $VERIFY_SCRIPT"
    fi
}

# Create DMG
create_dmg_file() {
    local BUILD_DIR="$1"
    local DMG_NAME="$2"

    print_step "Creating DMG"
    cd "$BUILD_DIR"

    if ! command -v create-dmg &> /dev/null; then
        print_error "create-dmg not found! Install with: brew install create-dmg"
    fi

    create-dmg \
        --volname "ZetaNotes" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "ZetaNotes.app" 175 190 \
        --hide-extension "ZetaNotes.app" \
        --app-drop-link 425 185 \
        --no-internet-enable \
        "$DMG_NAME" \
        "ZetaNotes.app" || print_error "DMG creation failed"

    print_success "DMG created"
}

# Sign DMG
sign_dmg() {
    local DMG_PATH="$1"
    local SIGNING_IDENTITY="$2"

    print_step "Signing DMG"
    codesign --sign "$SIGNING_IDENTITY" \
        --timestamp \
        --options runtime \
        "$DMG_PATH" || print_error "DMG signing failed"

    codesign --verify --verbose "$DMG_PATH" || print_error "DMG signature verification failed"
    print_success "DMG signed and verified"
}

# Generate Sparkle signature (from Keychain)
generate_sparkle_signature_keychain() {
    local DMG_PATH="$1"
    local SIGN_UPDATE="$2"
    local SPARKLE_ACCOUNT="$3"

    print_step "Generating Sparkle EdDSA signature (Keychain)"

    if [ ! -f "$SIGN_UPDATE" ]; then
        print_warning "sign_update tool not found at $SIGN_UPDATE"
        echo ""
        return 1
    fi

    echo "Using Sparkle key from Keychain account: $SPARKLE_ACCOUNT"

    SIGN_OUTPUT=$("$SIGN_UPDATE" --account "$SPARKLE_ACCOUNT" "$DMG_PATH" 2>&1)
    SIGN_EXIT_CODE=$?

    if [ $SIGN_EXIT_CODE -eq 0 ]; then
        SPARKLE_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep 'sparkle:edSignature=' | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')

        if [ -n "$SPARKLE_SIGNATURE" ]; then
            print_success "Sparkle signature generated from Keychain"
            echo "Signature: ${SPARKLE_SIGNATURE:0:32}..."
            echo "$SPARKLE_SIGNATURE"
            return 0
        else
            print_warning "Could not extract Sparkle signature from output"
            echo "$SIGN_OUTPUT"
            return 1
        fi
    else
        print_warning "Sparkle signing failed - key may not be in Keychain"
        echo "$SIGN_OUTPUT"
        echo ""
        echo "To set up Sparkle keys, run:"
        echo "  ./scripts/setup-sparkle-keys.sh"
        return 1
    fi
}

# Generate Sparkle signature (from env var)
generate_sparkle_signature_env() {
    local DMG_PATH="$1"
    local SIGN_UPDATE="$2"
    local SPARKLE_PRIVATE_KEY="$3"

    print_step "Generating Sparkle EdDSA signature (environment variable)"

    if [ ! -f "$SIGN_UPDATE" ]; then
        print_warning "sign_update tool not found at $SIGN_UPDATE"
        echo ""
        return 1
    fi

    if [ -z "$SPARKLE_PRIVATE_KEY" ]; then
        print_warning "SPARKLE_PRIVATE_KEY environment variable not set"
        return 1
    fi

    echo "Using Sparkle private key from environment variable"

    # Save private key to temporary file
    TEMP_KEY_FILE=$(mktemp)
    echo "$SPARKLE_PRIVATE_KEY" > "$TEMP_KEY_FILE"

    # Sign the DMG using --ed-key-file
    SIGN_OUTPUT=$("$SIGN_UPDATE" --ed-key-file "$TEMP_KEY_FILE" "$DMG_PATH" 2>&1)
    SIGN_EXIT_CODE=$?

    # Clean up temp file immediately
    rm -f "$TEMP_KEY_FILE"

    if [ $SIGN_EXIT_CODE -eq 0 ]; then
        SPARKLE_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep 'sparkle:edSignature=' | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')

        if [ -n "$SPARKLE_SIGNATURE" ]; then
            print_success "Sparkle signature generated from environment variable"
            echo "Signature: ${SPARKLE_SIGNATURE:0:32}..."
            echo "$SPARKLE_SIGNATURE"
            return 0
        else
            print_warning "Could not extract Sparkle signature from output"
            echo "$SIGN_OUTPUT"
            return 1
        fi
    else
        print_warning "Sparkle signing failed with exit code: $SIGN_EXIT_CODE"
        echo "$SIGN_OUTPUT"
        return 1
    fi
}

# Notarize DMG
notarize_dmg() {
    local DMG_PATH="$1"
    local APPLE_ID="$2"
    local APPLE_TEAM_ID="$3"
    local APPLE_APP_SPECIFIC_PASSWORD="$4"

    print_step "Notarizing with Apple"

    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
        print_warning "Notarization credentials not set - skipping notarization"
        echo ""
        echo "To enable notarization, set these environment variables:"
        echo "  export APPLE_ID='your-apple-id@example.com'"
        echo "  export APPLE_TEAM_ID='YOUR_TEAM_ID'"
        echo "  export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
        echo ""
        return 1
    fi

    echo "Submitting for notarization..."
    echo "File to notarize: $DMG_PATH"

    # Submit for notarization
    NOTARIZATION_OUTPUT=$(xcrun notarytool submit "$DMG_PATH" \
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
        if xcrun stapler staple "$DMG_PATH" 2>&1; then
            print_success "Notarization ticket stapled successfully"

            # Verify stapling
            if spctl -a -vv -t install "$DMG_PATH" 2>&1 | grep -q "source=Notarized Developer ID"; then
                print_success "DMG is properly notarized and stapled"
            else
                print_warning "DMG may not be properly stapled - verification failed"
            fi
        else
            print_warning "Stapling failed - users will need internet to verify"
        fi

        echo "$NOTARIZATION_STATUS"
        return 0
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
}

# Generate metadata files
generate_metadata() {
    local DMG_PATH="$1"
    local VERSION="$2"
    local SPARKLE_SIGNATURE="$3"

    print_step "Generating metadata"

    DMG_NAME=$(basename "$DMG_PATH")
    DMG_SIZE=$(stat -f%z "$DMG_PATH")

    # Generate checksum
    shasum -a 256 "$DMG_PATH" > "${DMG_PATH}.sha256"
    SHA256=$(cat "${DMG_PATH}.sha256" | cut -d' ' -f1)
    print_success "SHA256 checksum created"

    # Save Sparkle signature
    if [ -n "$SPARKLE_SIGNATURE" ]; then
        cat > "${DMG_PATH}.sparkle-signature" <<EOF
sparkle:edSignature="$SPARKLE_SIGNATURE"
length="$DMG_SIZE"
EOF
        print_success "Sparkle signature saved"
    fi

    # Generate appcast info
    cat > "${DMG_PATH}.appcast-info" <<EOF
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
    print_success "Appcast info generated"
}
