#!/bin/bash
set -e  # Exit on any error

# OffNotes Release Packaging Script
# This script automates the entire release process:
# 1. Builds the app in Xcode
# 2. Bundles TinyLlama model
# 3. Signs the app
# 4. Creates DMG
# 5. Signs DMG
# 6. Notarizes with Apple
# 7. Staples notarization ticket
# 8. Generates SHA256 checksum

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - EDIT THESE VALUES
CERT_NAME="Developer ID Application: Your Name (TEAM_ID)"  # Change this!
NOTARY_PROFILE="notary-profile"  # Name you used in 'notarytool store-credentials'
VERSION="1.0.0"  # Update this for each release

# Paths
PROJECT_DIR="/Users/projects/Documents/notetaker"
BUILD_DIR="$HOME/Desktop/OffNotes-Release-$(date +%Y%m%d-%H%M%S)"
ARCHIVE_PATH="$HOME/Desktop/OffNotes.xcarchive"
APP_NAME="OffNotes"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"

# TinyLlama model
MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
MODEL_FILE="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OffNotes Release Packaging Script v1.0     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Version:${NC} ${VERSION}"
echo -e "${GREEN}Build directory:${NC} ${BUILD_DIR}"
echo ""

# Function to print step headers
print_step() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error and exit
print_error() {
    echo -e "${RED}✗ Error: $1${NC}"
    exit 1
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ Warning: $1${NC}"
}

# Check prerequisites
print_step "Step 0: Checking prerequisites"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
fi
print_success "Xcode found: $(xcodebuild -version | head -n 1)"

# Check if certificate exists
if ! security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    print_error "Certificate '$CERT_NAME' not found. Update CERT_NAME in this script."
fi
print_success "Code signing certificate found"

# Check if notary profile exists
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" &> /dev/null; then
    print_warning "Notary profile '$NOTARY_PROFILE' not found. You'll need to set it up."
    echo "Run: xcrun notarytool store-credentials \"$NOTARY_PROFILE\" --apple-id YOUR@EMAIL.COM --team-id TEAM_ID --password APP_SPECIFIC_PASSWORD"
fi

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    print_warning "create-dmg not found. Install with: brew install create-dmg"
    echo "Will use fallback DMG creation method"
    USE_CREATE_DMG=false
else
    USE_CREATE_DMG=true
    print_success "create-dmg found"
fi

echo ""
read -p "Continue with build? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Create build directory
print_step "Step 1: Creating build directory"
mkdir -p "$BUILD_DIR"
print_success "Created: $BUILD_DIR"

# Build and archive
print_step "Step 2: Building and archiving app in Xcode"
echo "This may take 5-10 minutes..."
cd "$PROJECT_DIR"

# Clean first
xcodebuild clean -project NoteTaker.xcodeproj -scheme NoteTaker -configuration Release || print_error "Clean failed"
print_success "Clean completed"

# Archive
xcodebuild archive \
    -project NoteTaker.xcodeproj \
    -scheme NoteTaker \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    | grep -E "^(==|note:|warning:|error:)" || true

if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive failed - no .xcarchive created"
fi
print_success "Archive created: $ARCHIVE_PATH"

# Export app
print_step "Step 3: Exporting app"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$BUILD_DIR" \
    -exportOptionsPlist "$PROJECT_DIR/scripts/ExportOptions.plist" \
    2>&1 | grep -E "^(==|note:|warning:|error:)" || true

if [ ! -d "$BUILD_DIR/${APP_NAME}.app" ]; then
    print_error "Export failed - no .app created"
fi

# Remove any development databases/data from app bundle
print_warning "Cleaning development data from app bundle..."
rm -rf "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/"*.sqlite* 2>/dev/null || true
rm -rf "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/"*.db 2>/dev/null || true

print_success "App exported and cleaned: $BUILD_DIR/${APP_NAME}.app"

# Bundle TinyLlama model
print_step "Step 4: Bundling TinyLlama model"
MODELS_DIR="$BUILD_DIR/${APP_NAME}.app/Contents/Resources/Models"
mkdir -p "$MODELS_DIR"

echo "Downloading TinyLlama (~700MB)..."
if curl -L --progress-bar "$MODEL_URL" -o "$MODELS_DIR/$MODEL_FILE"; then
    MODEL_SIZE=$(du -h "$MODELS_DIR/$MODEL_FILE" | cut -f1)
    print_success "Model downloaded: $MODEL_SIZE"
else
    print_error "Failed to download model"
fi

# Sign the app
print_step "Step 5: Code signing app"
codesign --deep --force --verify --verbose \
    --sign "$CERT_NAME" \
    --options runtime \
    --timestamp \
    "$BUILD_DIR/${APP_NAME}.app" || print_error "Code signing failed"

# Verify signature
codesign --verify --deep --strict --verbose=2 "$BUILD_DIR/${APP_NAME}.app" || print_error "Signature verification failed"
print_success "App signed and verified"

# Create DMG
print_step "Step 6: Creating DMG"
cd "$BUILD_DIR"

if [ "$USE_CREATE_DMG" = true ]; then
    # Using create-dmg (prettier)
    create-dmg \
        --volname "${APP_NAME} Installer" \
        --volicon "${APP_NAME}.app/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 200 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 600 185 \
        "$DMG_NAME" \
        "${APP_NAME}.app" 2>&1 | grep -v "^hdiutil:" || true

    # create-dmg might fail but still create the DMG
    if [ ! -f "$DMG_NAME" ]; then
        print_warning "create-dmg failed, using fallback method"
        USE_CREATE_DMG=false
    fi
fi

if [ "$USE_CREATE_DMG" = false ]; then
    # Fallback method
    echo "Using manual DMG creation..."

    # Create temporary DMG
    hdiutil create -size 1200m -fs HFS+ -volname "$APP_NAME" temp.dmg

    # Mount it
    hdiutil attach temp.dmg -readwrite -mountpoint "/Volumes/$APP_NAME"

    # Copy app
    cp -R "${APP_NAME}.app" "/Volumes/$APP_NAME/"

    # Create Applications symlink
    ln -s /Applications "/Volumes/$APP_NAME/Applications"

    # Unmount
    hdiutil detach "/Volumes/$APP_NAME"

    # Convert to compressed DMG
    hdiutil convert temp.dmg -format UDZO -o "$DMG_NAME"

    # Clean up
    rm temp.dmg
fi

if [ ! -f "$DMG_NAME" ]; then
    print_error "DMG creation failed"
fi

DMG_SIZE=$(du -h "$DMG_NAME" | cut -f1)
print_success "DMG created: $DMG_SIZE"

# Sign DMG
print_step "Step 7: Signing DMG"
codesign --sign "$CERT_NAME" --timestamp "$DMG_NAME" || print_error "DMG signing failed"
codesign --verify --deep --strict --verbose=2 "$DMG_NAME" || print_error "DMG signature verification failed"
print_success "DMG signed and verified"

# Notarize
print_step "Step 8: Notarizing with Apple"
echo "This may take 5-15 minutes..."
echo "Submitting to Apple..."

SUBMIT_OUTPUT=$(xcrun notarytool submit "$DMG_NAME" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait 2>&1)

if echo "$SUBMIT_OUTPUT" | grep -q "status: Accepted"; then
    print_success "Notarization accepted by Apple"
else
    echo "$SUBMIT_OUTPUT"
    print_error "Notarization failed"
fi

# Staple the notarization ticket
print_step "Step 9: Stapling notarization ticket"
xcrun stapler staple "$DMG_NAME" || print_error "Stapling failed"
xcrun stapler validate "$DMG_NAME" || print_error "Staple validation failed"
print_success "Notarization ticket stapled"

# Generate checksum
print_step "Step 10: Generating SHA256 checksum"
CHECKSUM=$(shasum -a 256 "$DMG_NAME" | cut -d' ' -f1)
echo "$CHECKSUM" > "${DMG_NAME}.sha256"
print_success "Checksum: $CHECKSUM"

# Final verification
print_step "Step 11: Final verification"
echo "Testing Gatekeeper assessment..."
spctl --assess --verbose --type install "$DMG_NAME" || print_warning "Gatekeeper assessment failed (may be normal)"

# Clean up archive
rm -rf "$ARCHIVE_PATH"
print_success "Cleaned up temporary archive"

# Summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Build Completed Successfully!       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Version:${NC} ${VERSION}"
echo -e "${BLUE}Location:${NC} ${BUILD_DIR}"
echo -e "${BLUE}DMG:${NC} ${DMG_NAME} (${DMG_SIZE})"
echo -e "${BLUE}SHA256:${NC} ${CHECKSUM}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the DMG on a clean Mac (or in a VM)"
echo "2. Create GitHub release: https://github.com/YOUR_USERNAME/offnotes/releases/new"
echo "3. Upload: ${DMG_NAME}"
echo "4. Update docs/download.html with checksum: ${CHECKSUM}"
echo "5. Tag release: v${VERSION}"
echo ""
echo -e "${GREEN}Release package ready! 🚀${NC}"
echo ""
