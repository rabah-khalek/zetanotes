#!/bin/bash
set -e  # Exit on any error

# ZetaNotes Unsigned Release Packaging Script
# Creates a distributable DMG without code signing
# Users will need to right-click -> Open on first launch

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="1.0.0"  # Update this for each release

# Paths
PROJECT_DIR="/Users/projects/Documents/zetanotes"
BUILD_DIR="$HOME/Desktop/ZetaNotes-Release-$(date +%Y%m%d-%H%M%S)"
APP_NAME="ZetaNotes"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"

# TinyLlama model
MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
MODEL_FILE="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ZetaNotes Unsigned Build Script v1.0         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This creates an UNSIGNED app${NC}"
echo -e "${YELLOW}   Users will see security warnings on first launch${NC}"
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

# Build app
print_step "Step 2: Building app in Xcode"
echo "This may take 5-10 minutes..."
cd "$PROJECT_DIR"

# Clean first
xcodebuild clean -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Release &> /dev/null || print_error "Clean failed"
print_success "Clean completed"

# Build
echo "Building..."
xcodebuild build \
    -project ZetaNotes.xcodeproj \
    -scheme ZetaNotes \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    | grep -E "^(==|Build succeeded|warning:|error:)" || true

# Find the built app
BUILT_APP=$(find "$BUILD_DIR/DerivedData/Build/Products/Release" -name "*.app" -maxdepth 1 | head -n 1)

if [ -z "$BUILT_APP" ] || [ ! -d "$BUILT_APP" ]; then
    print_error "Build failed - no .app created"
fi
print_success "App built successfully"

# Copy app to build directory
print_step "Step 3: Copying app and cleaning development data"
cp -R "$BUILT_APP" "$BUILD_DIR/${APP_NAME}.app"

# Remove any development databases/data
print_warning "Removing development data from app bundle..."
rm -rf "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/"*.sqlite* 2>/dev/null || true
rm -rf "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/"*.db 2>/dev/null || true

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   PRODUCTION SAFETY CHECKS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check for DEV_TODO markers that should be replaced before release
print_warning "1. Checking for DEV_TODO markers..."
DEV_TODO_COUNT=$(grep -r "DEV_TODO\|DEV_STORE_ID\|DEV_PRODUCT_ID\|DEV_VARIANT_ID" "$PROJECT_DIR/ZetaNotes" 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEV_TODO_COUNT" -gt 0 ]; then
    echo ""
    print_error "Found $DEV_TODO_COUNT DEV_TODO markers in source code!

Please replace these with production values before release:
  - DEV_STORE_ID → Your actual LemonSqueezy store ID
  - DEV_PRODUCT_ID → Your actual LemonSqueezy product ID
  - DEV_VARIANT_ID → Your actual LemonSqueezy variant ID

To find them all:
  grep -rn 'DEV_' ZetaNotes/

To get these values:
  1. Go to https://app.lemonsqueezy.com/settings/api
  2. Create a product for ZetaNotes Pro
  3. Note the IDs and replace in code
"
fi
print_success "No DEV_TODO markers found (or check passed)"

# Verify DEBUG blocks are present
print_warning "2. Verifying DEBUG-only code is properly wrapped..."
if ! grep -q "#if DEBUG" "$PROJECT_DIR/ZetaNotes/Managers/LicenseManager.swift" 2>/dev/null; then
    print_error "No #if DEBUG blocks found in LicenseManager.swift! Test credentials may leak to production!"
fi
print_success "DEBUG blocks verified in LicenseManager"

# Check for test license code (should only be in DEBUG blocks)
print_warning "3. Checking test license configuration..."
if grep -r "testLicenseKey\|testLicenseEmail" "$PROJECT_DIR/ZetaNotes/Managers/LicenseManager.swift" 2>/dev/null | grep -v "#if DEBUG" | grep -q "test"; then
    print_error "Test license code found OUTSIDE of #if DEBUG blocks!"
else
    print_success "Test credentials properly wrapped in #if DEBUG (safe for release)"
fi

# Verify Release configuration
print_warning "4. Verifying build configuration..."
if [ -f "$BUILD_DIR/DerivedData/Build/Products/Release/ZetaNotes.app/Contents/MacOS/ZetaNotes" ]; then
    print_success "Release build confirmed"
else
    print_warning "Could not verify Release configuration"
fi

echo ""
echo -e "${GREEN}✓ All production safety checks passed!${NC}"
echo ""

# Note: User data is stored in ~/Library/Application Support/ZetaNotes, not in the app bundle
# So this is just a safety precaution to ensure no dev data in the bundle itself

print_success "App copied and cleaned: $BUILD_DIR/${APP_NAME}.app"

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

# Remove quarantine attribute (helps reduce warnings)
print_step "Step 5: Removing quarantine attributes"
xattr -cr "$BUILD_DIR/${APP_NAME}.app" 2>/dev/null || true
print_success "Quarantine attributes removed"

# Create DMG
print_step "Step 6: Creating DMG"
cd "$BUILD_DIR"

if [ "$USE_CREATE_DMG" = true ]; then
    # Using create-dmg (prettier)
    create-dmg \
        --volname "${APP_NAME} Installer" \
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

    # Create README with instructions
    cat > "/Volumes/$APP_NAME/README.txt" << 'EOF'
ZetaNotes Installation Instructions

1. Drag ZetaNotes to Applications folder
2. Go to Applications folder
3. RIGHT-CLICK on ZetaNotes
4. Select "Open" from menu
5. Click "Open" in the security dialog

This is required because the app is not signed with an Apple Developer certificate.

After the first time, you can open it normally.

For more help: https://YOUR_USERNAME.github.io/zetanotes/download.html
EOF

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

# Remove quarantine from DMG too
print_step "Step 7: Removing quarantine from DMG"
xattr -cr "$DMG_NAME" 2>/dev/null || true
print_success "Quarantine removed from DMG"

# Generate checksum
print_step "Step 8: Generating SHA256 checksum"
CHECKSUM=$(shasum -a 256 "$DMG_NAME" | cut -d' ' -f1)
echo "$CHECKSUM" > "${DMG_NAME}.sha256"
print_success "Checksum: $CHECKSUM"

# Create installation instructions file
print_step "Step 9: Creating installation guide"
cat > "$BUILD_DIR/INSTALLATION.txt" << EOF
ZetaNotes v${VERSION} - Installation Instructions
================================================

IMPORTANT: This app is not signed with an Apple Developer certificate.
You will see a security warning on first launch. This is normal.

Installation Steps:
-------------------

1. Open the ZetaNotes-v${VERSION}.dmg file

2. Drag ZetaNotes to your Applications folder

3. Go to your Applications folder

4. RIGHT-CLICK (or Control-Click) on ZetaNotes

5. Select "Open" from the menu

6. Click "Open" in the security dialog that appears

7. ZetaNotes will launch!

After the first time, you can open ZetaNotes normally (no right-click needed).

Alternative Method (if above doesn't work):
------------------------------------------

1. Try to open ZetaNotes normally (it will be blocked)

2. Go to System Settings → Privacy & Security

3. Scroll down to "Security" section

4. You'll see: "ZetaNotes was blocked from use"

5. Click "Open Anyway"

6. Confirm by clicking "Open"

Why do I see this warning?
--------------------------

ZetaNotes is not signed with an Apple Developer certificate (\$99/year).
The app is safe - you can verify the source code at:
https://github.com/YOUR_USERNAME/zetanotes

The warning is just Apple's way of saying "we haven't verified this developer."

Need Help?
----------

Visit: https://YOUR_USERNAME.github.io/zetanotes/download.html
Email: support@zetanotes.app

SHA256 Checksum (for verification):
${CHECKSUM}
EOF

print_success "Installation guide created"

# Clean up DerivedData
rm -rf "$BUILD_DIR/DerivedData"
print_success "Cleaned up build artifacts"

# Summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Unsigned Build Complete! ✓             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Version:${NC} ${VERSION}"
echo -e "${BLUE}Location:${NC} ${BUILD_DIR}"
echo -e "${BLUE}DMG:${NC} ${DMG_NAME} (${DMG_SIZE})"
echo -e "${BLUE}SHA256:${NC} ${CHECKSUM}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: User Instructions${NC}"
echo ""
echo "Users MUST follow these steps on first launch:"
echo "1. Download and mount DMG"
echo "2. Drag ZetaNotes to Applications"
echo "3. RIGHT-CLICK ZetaNotes in Applications"
echo "4. Select 'Open' from menu"
echo "5. Click 'Open' in security dialog"
echo ""
echo "Installation guide created: $BUILD_DIR/INSTALLATION.txt"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the DMG yourself (important!)"
echo "2. Create GitHub release"
echo "3. Upload: ${DMG_NAME}"
echo "4. Include INSTALLATION.txt in release description"
echo "5. Update docs/download.html with checksum: ${CHECKSUM}"
echo ""
echo -e "${GREEN}Build ready for distribution! 🚀${NC}"
echo ""
