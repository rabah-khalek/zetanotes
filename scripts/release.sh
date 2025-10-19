#!/bin/bash
set -e  # Exit on any error

# ZetaNotes Release Script
# Single source of truth for creating releases (unsigned)
# Users will download models via the welcome page on first run

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="${1:-1.0.0}"
SKIP_PADDLE_CHECK="${2:-false}"  # Add flag to skip Paddle verification
BUILD_DIR="$HOME/Desktop/ZetaNotes-Release-$(date +%Y%m%d-%H%M%S)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="ZetaNotes"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ZetaNotes Release Builder v2.0            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Version:${NC} ${VERSION}"
echo -e "${GREEN}Build directory:${NC} ${BUILD_DIR}"
if [ "$SKIP_PADDLE_CHECK" = "true" ]; then
    echo -e "${YELLOW}⚠️  Paddle verification: SKIPPED (for testing)${NC}"
fi
echo -e "${YELLOW}⚠️  Note: AI model NOT bundled - users download on first run${NC}"
echo ""

if [ -z "$1" ]; then
    echo -e "${YELLOW}Warning: No version specified, using 1.0.0${NC}"
    echo "Usage: $0 <version> [skip_paddle]"
    echo "Example: $0 1.0.1"
    echo "         $0 1.0.1 true    # Skip Paddle checks for testing"
    echo ""
fi

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

if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
fi
print_success "Xcode found: $(xcodebuild -version | head -n 1)"

if ! command -v create-dmg &> /dev/null; then
    # Check common locations for create-dmg (local dev and CI)
    if [ -f "/opt/homebrew/bin/create-dmg" ]; then
        # Apple Silicon Mac (local dev)
        CREATE_DMG="/opt/homebrew/bin/create-dmg"
        USE_CREATE_DMG=true
        print_success "create-dmg found at /opt/homebrew/bin/create-dmg"
    elif [ -f "/usr/local/bin/create-dmg" ]; then
        # Intel Mac or CI environment
        CREATE_DMG="/usr/local/bin/create-dmg"
        USE_CREATE_DMG=true
        print_success "create-dmg found at /usr/local/bin/create-dmg"
    elif [ -f "/home/linuxbrew/.linuxbrew/bin/create-dmg" ]; then
        # Linuxbrew (unlikely but just in case)
        CREATE_DMG="/home/linuxbrew/.linuxbrew/bin/create-dmg"
        USE_CREATE_DMG=true
        print_success "create-dmg found at /home/linuxbrew/.linuxbrew/bin/create-dmg"
    else
        print_warning "create-dmg not found. Install with: brew install create-dmg"
        echo "Will use fallback DMG creation method"
        USE_CREATE_DMG=false
    fi
else
    CREATE_DMG="create-dmg"
    USE_CREATE_DMG=true
    print_success "create-dmg found in PATH"
fi

echo ""
# Skip interactive prompt in CI environment
if [ -z "$CI" ]; then
    read -p "Continue with build? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
else
    print_success "Running in CI environment - skipping confirmation prompt"
fi

# Create build directory
print_step "Step 1: Creating build directory"
mkdir -p "$BUILD_DIR"
print_success "Created: $BUILD_DIR"

# Production Safety Checks
print_step "Step 2: Running production safety checks"

# Check for DEV_TODO markers
print_warning "Checking for DEV_TODO markers..."
DEV_TODO_COUNT=$(grep -r "DEV_TODO\|DEV_VENDOR_ID\|DEV_PRODUCT_ID\|DEV_PRICE_ID" "$PROJECT_DIR/ZetaNotes" 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEV_TODO_COUNT" -gt 0 ] && [ "$SKIP_PADDLE_CHECK" != "true" ]; then
    echo ""
    print_error "Found $DEV_TODO_COUNT DEV_TODO markers in source code!

Please replace these with production values before release:
  - DEV_VENDOR_ID → Your actual Paddle vendor ID
  - DEV_PRODUCT_ID → Your actual Paddle product ID
  - DEV_PRICE_ID → Your actual Paddle price ID

To find them all:
  grep -rn 'DEV_' ZetaNotes/

To get these values:
  1. Go to https://vendors.paddle.com (or sandbox.vendors.paddle.com for testing)
  2. Create a product for ZetaNotes Pro
  3. Set up pricing plans (Monthly: \$1, Annual: \$6, Lifetime: \$20)
  4. Note the IDs and replace in code

To skip this check for testing: $0 $VERSION true
"
elif [ "$DEV_TODO_COUNT" -gt 0 ] && [ "$SKIP_PADDLE_CHECK" = "true" ]; then
    print_warning "Found $DEV_TODO_COUNT DEV_TODO markers - SKIPPED (testing mode)"
else
    print_success "No DEV_TODO markers found"
fi

# Verify DEBUG blocks
print_warning "Verifying DEBUG-only code is properly wrapped..."
if ! grep -q "#if DEBUG" "$PROJECT_DIR/ZetaNotes/Managers/LicenseManager.swift" 2>/dev/null; then
    print_error "No #if DEBUG blocks found in LicenseManager.swift!"
fi
print_success "DEBUG blocks verified"

# Check for test license code outside DEBUG blocks
print_warning "Checking test license configuration..."
# Check if test license constants are properly wrapped in DEBUG blocks
if [ "$SKIP_PADDLE_CHECK" != "true" ]; then
    # Extract the section with test license declarations and check if it's in a DEBUG block
    TEST_LICENSE_SECTION=$(grep -A 3 -B 3 "private let testLicenseKey\|private let testLicenseEmail" "$PROJECT_DIR/ZetaNotes/Managers/LicenseManager.swift" 2>/dev/null || true)
    if [ -n "$TEST_LICENSE_SECTION" ] && ! echo "$TEST_LICENSE_SECTION" | grep -q "#if DEBUG"; then
        print_error "Test license constants found OUTSIDE of #if DEBUG blocks!"
    else
        print_success "Test credentials properly wrapped in #if DEBUG"
    fi
else
    print_warning "Test license configuration check - SKIPPED (testing mode)"
fi

echo ""
print_success "All production safety checks passed!"

# Build app
print_step "Step 3: Building app in Xcode"
echo "This may take 5-10 minutes..."
cd "$PROJECT_DIR"

# Clean first - more thorough cleanup
print_warning "Performing thorough clean..."
xcodebuild clean -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Release
rm -rf ~/Library/Developer/Xcode/DerivedData/ZetaNotes-*
rm -rf "$BUILD_DIR/DerivedData"
print_success "Clean completed"

# Build with proper error handling
echo "Building (errors will cause script to exit)..."
BUILD_LOG="$BUILD_DIR/build.log"

if ! xcodebuild build \
    -project ZetaNotes.xcodeproj \
    -scheme ZetaNotes \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -quiet \
    > "$BUILD_LOG" 2>&1; then

    echo ""
    print_error "Build failed! Check the build log below:

$(tail -50 "$BUILD_LOG")

Full build log: $BUILD_LOG
"
fi

# Show any warnings from the build
if grep -q "warning:" "$BUILD_LOG"; then
    echo ""
    print_warning "Build completed with warnings:"
    grep "warning:" "$BUILD_LOG" | head -10
    echo ""
fi

print_success "Build completed successfully"

# Find the built app
BUILT_APP=$(find "$BUILD_DIR/DerivedData/Build/Products/Release" -name "*.app" -maxdepth 1 | head -n 1)

if [ -z "$BUILT_APP" ] || [ ! -d "$BUILT_APP" ]; then
    print_error "Build failed - no .app created"
fi
print_success "App built successfully"

# Copy app and clean development data
print_step "Step 4: Copying app and cleaning development data"
cp -R "$BUILT_APP" "$BUILD_DIR/${APP_NAME}.app"

# Remove any development databases/data
print_warning "Removing development data from app bundle..."
rm -rf "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/"*.sqlite* 2>/dev/null || true
rm -rf "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/"*.db 2>/dev/null || true
rm -rf "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/Models" 2>/dev/null || true

# Clean up any development UserDefaults/preferences that might persist
print_warning "Clearing development preferences..."
# Note: This removes preferences for the current user, not from the app bundle
# Users will get a fresh experience as if launching for the first time
defaults delete com.zetanotes.ZetaNotes 2>/dev/null || true
defaults delete com.example.ZetaNotes 2>/dev/null || true

print_success "App copied and cleaned: $BUILD_DIR/${APP_NAME}.app"
print_success "Models directory removed (users will download on first run)"
print_success "Development preferences cleared"

# Verify Release configuration
print_warning "Verifying build configuration..."
if [ -f "$BUILD_DIR/DerivedData/Build/Products/Release/ZetaNotes.app/Contents/MacOS/ZetaNotes" ]; then
    print_success "Release build confirmed"
else
    print_warning "Could not verify Release configuration"
fi

# Remove quarantine attribute
print_step "Step 5: Removing quarantine attributes"
xattr -cr "$BUILD_DIR/${APP_NAME}.app" 2>/dev/null || true
print_success "Quarantine attributes removed"

# Create DMG
print_step "Step 6: Creating DMG"
cd "$BUILD_DIR"

if [ "$USE_CREATE_DMG" = true ]; then
    # Using create-dmg (prettier)
    echo "Using create-dmg for professional installer interface..."
    "$CREATE_DMG" \
        --volname "${APP_NAME} Installer" \
        --window-pos 200 120 \
        --window-size 800 450 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 200 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 600 185 \
        --text-size 12 \
        "$DMG_NAME" \
        "${APP_NAME}.app" 2>&1 | grep -v "^hdiutil:" || true    # create-dmg might fail but still create the DMG
    if [ ! -f "$DMG_NAME" ]; then
        print_warning "create-dmg failed, using fallback method"
        USE_CREATE_DMG=false
    fi
fi

if [ "$USE_CREATE_DMG" = false ]; then
    # Fallback method
    echo "Using manual DMG creation..."

    # Clean up any existing mounts first
    if [ -d "/Volumes/$APP_NAME" ]; then
        echo "Unmounting existing volume..."
        hdiutil detach "/Volumes/$APP_NAME" -force 2>/dev/null || true
        sleep 2
    fi

    # Remove any existing temp files
    rm -f temp.dmg "$DMG_NAME" 2>/dev/null || true

    # Create temporary DMG (smaller now without model)
    hdiutil create -size 200m -fs HFS+ -volname "$APP_NAME" temp.dmg

    # Mount it with a unique mount point to avoid conflicts
    MOUNT_POINT="/Volumes/${APP_NAME}_$(date +%s)"
    hdiutil attach temp.dmg -readwrite -mountpoint "$MOUNT_POINT"

    # Copy app
    cp -R "${APP_NAME}.app" "$MOUNT_POINT/"

    # Create Applications symlink
    ln -s /Applications "$MOUNT_POINT/Applications"

    # Create README with instructions
    cat > "$MOUNT_POINT/README.txt" << 'EOF'
ZetaNotes Installation Instructions

1. Drag ZetaNotes to Applications folder
2. Go to Applications folder
3. RIGHT-CLICK on ZetaNotes
4. Select "Open" from menu
5. Click "Open" in the security dialog

This is required because the app is not signed with an Apple Developer certificate.

After the first time, you can open it normally.

The AI model will be downloaded automatically when you first launch the app.

For more help: https://github.com/rabah-khalek/zetanotes
EOF

    # Sync and wait a moment for filesystem operations to complete
    sync
    sleep 2

    # Force unmount with retries
    echo "Unmounting DMG..."
    for i in {1..5}; do
        if hdiutil detach "$MOUNT_POINT" -force 2>/dev/null; then
            echo "Successfully unmounted on attempt $i"
            break
        else
            echo "Unmount attempt $i failed, retrying..."
            sleep 2
        fi
    done

    # Wait a moment for the detach to complete
    sleep 2

    # Convert to compressed DMG
    echo "Converting to compressed DMG..."
    hdiutil convert temp.dmg -format UDZO -o "$DMG_NAME"

    # Clean up
    rm temp.dmg
fi

if [ ! -f "$DMG_NAME" ]; then
    print_error "DMG creation failed"
fi

DMG_SIZE=$(du -h "$DMG_NAME" | cut -f1)
print_success "DMG created: $DMG_SIZE"

# Remove quarantine from DMG
print_step "Step 7: Removing quarantine from DMG"
xattr -cr "$DMG_NAME" 2>/dev/null || true
print_success "Quarantine removed from DMG"

# Generate checksum
print_step "Step 8: Generating SHA256 checksum"
CHECKSUM=$(shasum -a 256 "$DMG_NAME" | cut -d' ' -f1)
echo "$CHECKSUM" > "${DMG_NAME}.sha256"
print_success "Checksum: $CHECKSUM"

# Create installation instructions
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

7. ZetaNotes will launch and show the welcome screen

8. Download the AI model (will be prompted on first run)

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
https://github.com/rabah-khalek/zetanotes

The warning is just Apple's way of saying "we haven't verified this developer."

AI Model Download:
------------------

On first launch, ZetaNotes will show a welcome screen where you can:
- Download the Llama 3.2 1B model (~700MB)
- Skip and download later from Settings

The model download happens automatically within the app.
No need to manually download or install models!

Need Help?
----------

Website: https://zetanotes.com
GitHub: https://github.com/rabah-khalek/zetanotes
Issues: https://github.com/rabah-khalek/zetanotes/issues

Pro Features:
-------------

ZetaNotes is free forever with basic AI features.
For advanced features (8 AI models, Chat Assistant, Custom Tools):
- Visit: https://zetanotes.com/pricing
- Monthly: \$1/month
- Annual: \$6/year (50% off)
- Lifetime: \$20 one-time

Payment processing by Paddle.com (secure & international)

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
echo -e "${GREEN}║        Release Build Complete! ✓              ║${NC}"
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
echo "6. Download AI model from welcome screen"
echo ""
echo "Installation guide: $BUILD_DIR/INSTALLATION.txt"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the DMG yourself (important!)"
echo "2. Create GitHub release: https://github.com/rabah-khalek/zetanotes/releases/new"
echo "3. Upload: ${DMG_NAME}"
echo "4. Include INSTALLATION.txt in release description"
echo "5. Update download page with checksum: ${CHECKSUM}"
echo "6. Update Paddle product settings if needed"
echo "7. Test Pro license purchase flow with Paddle"
echo ""
echo -e "${GREEN}Build ready for distribution! 🚀${NC}"
echo ""
