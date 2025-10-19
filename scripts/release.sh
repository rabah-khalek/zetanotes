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
# Don't delete $BUILD_DIR/DerivedData - we need it for the build!
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

# Find the built app - check both Debug and Release folders (naming might be swapped in project)
BUILT_APP=""
for CONFIG in "Release" "Debug"; do
    if [ -d "$BUILD_DIR/DerivedData/Build/Products/$CONFIG" ]; then
        BUILT_APP=$(find "$BUILD_DIR/DerivedData/Build/Products/$CONFIG" -name "*.app" -maxdepth 1 | head -n 1)
        if [ -n "$BUILT_APP" ]; then
            echo "Found app in $CONFIG configuration"
            break
        fi
    fi
done

# If not found in custom location, check default Xcode DerivedData
if [ -z "$BUILT_APP" ]; then
    echo "Checking default Xcode DerivedData location..."
    BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release -name "ZetaNotes.app" 2>/dev/null | head -n 1)
    if [ -z "$BUILT_APP" ]; then
        BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug -name "ZetaNotes.app" 2>/dev/null | head -n 1)
    fi
fi

if [ -z "$BUILT_APP" ] || [ ! -d "$BUILT_APP" ]; then
    echo "Checked locations:"
    echo "  - $BUILD_DIR/DerivedData/Build/Products/Release"
    echo "  - $BUILD_DIR/DerivedData/Build/Products/Debug"
    echo "  - ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release"
    echo "  - ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug"
    print_error "Build failed - no .app created"
fi
print_success "App built successfully at: $BUILT_APP"

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

# Ad-hoc code signing (improves user experience without Apple Developer account)
print_step "Step 4.5: Applying ad-hoc code signature"
echo "This provides code integrity without Apple Developer certificate..."

# Sign all frameworks and dylibs first
print_warning "Signing embedded frameworks and libraries..."
find "$BUILD_DIR/${APP_NAME}.app/Contents" -type f \( -name "*.dylib" -o -name "*.framework" \) -exec codesign --force --deep --sign - {} \; 2>/dev/null || true

# Sign the main app bundle with ad-hoc signature
if codesign --force --deep --sign - "$BUILD_DIR/${APP_NAME}.app" 2>/dev/null; then
    print_success "Ad-hoc signature applied successfully"

    # Verify the signature
    if codesign --verify --verbose "$BUILD_DIR/${APP_NAME}.app" 2>&1 | grep -q "adhoc"; then
        print_success "Signature verified (ad-hoc)"
        echo "  └─ This improves code integrity and user trust"
    else
        print_warning "Signature applied but verification unclear"
    fi
else
    print_warning "Ad-hoc signing failed (non-critical)"
    echo "  └─ App will still work, but without code signature"
fi

# Display signature info
print_warning "Signature details:"
codesign -dvvv "$BUILD_DIR/${APP_NAME}.app" 2>&1 | grep -E "(Identifier|Authority|Signature)" || true
echo ""

# Verify Release configuration
print_warning "Verifying build configuration..."
if [ -f "$BUILD_DIR/DerivedData/Build/Products/Release/ZetaNotes.app/Contents/MacOS/ZetaNotes" ]; then
    print_success "Release build confirmed"
else
    print_warning "Could not verify Release configuration"
fi

# Remove quarantine attributes and fix common issues
print_step "Step 5: Removing quarantine attributes and fixing permissions"

# Remove ALL extended attributes (quarantine, download history, etc.)
print_warning "Removing all extended attributes..."
xattr -cr "$BUILD_DIR/${APP_NAME}.app" 2>/dev/null || true

# Specifically target quarantine attributes
xattr -d com.apple.quarantine "$BUILD_DIR/${APP_NAME}.app" 2>/dev/null || true
find "$BUILD_DIR/${APP_NAME}.app" -type f -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true

# Fix executable permissions (common issue with DMG distribution)
print_warning "Fixing executable permissions..."
chmod +x "$BUILD_DIR/${APP_NAME}.app/Contents/MacOS/"* 2>/dev/null || true
chmod -R u+rwX,go+rX,go-w "$BUILD_DIR/${APP_NAME}.app" 2>/dev/null || true

# Verify the app structure is intact
print_warning "Verifying app bundle structure..."
if [ ! -f "$BUILD_DIR/${APP_NAME}.app/Contents/Info.plist" ]; then
    print_error "Info.plist missing - app bundle is corrupted!"
fi
if [ ! -x "$BUILD_DIR/${APP_NAME}.app/Contents/MacOS/ZetaNotes" ]; then
    print_error "Main executable is not executable!"
fi

print_success "Quarantine attributes removed and permissions fixed"

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

EASY METHOD (Recommended):
  Double-click "Install ZetaNotes.command" in this window
  → It will automatically copy the app and remove security restrictions

MANUAL METHOD:
1. Drag ZetaNotes to Applications folder
2. Go to Applications folder
3. RIGHT-CLICK on ZetaNotes
4. Select "Open" from menu
5. Click "Open" in the security dialog

This is required because the app is not signed with an Apple Developer certificate.

After the first time, you can open it normally.

The AI model will be downloaded automatically when you first launch the app.

TROUBLESHOOTING:
If you see "damaged" or "malware" warnings that won't let you open:

Option 1 - Use Automatic Installer:
  Double-click "Install ZetaNotes.command" in the DMG

Option 2 - Terminal Fix:
  1. Open Terminal (Applications → Utilities → Terminal)
  2. Copy and paste this command:
     sudo xattr -cr /Applications/ZetaNotes.app && sudo chmod +x /Applications/ZetaNotes.app/Contents/MacOS/ZetaNotes
  3. Enter your password when prompted
  4. Try opening ZetaNotes again

Option 3 - System Settings:
  1. Go to System Settings → Privacy & Security
  2. Scroll down to Security section
  3. Click "Open Anyway" next to ZetaNotes warning
  4. Confirm by clicking "Open"

For more help: https://github.com/rabah-khalek/zetanotes/issues
EOF

    # Copy troubleshooting script
    if [ -f "$PROJECT_DIR/scripts/fix-zetanotes.sh" ]; then
        cp "$PROJECT_DIR/scripts/fix-zetanotes.sh" "$MOUNT_POINT/"
        chmod +x "$MOUNT_POINT/fix-zetanotes.sh"
        print_success "Added troubleshooting script to DMG"
    fi

    # Copy automatic installer script
    if [ -f "$PROJECT_DIR/scripts/Install ZetaNotes.command" ]; then
        cp "$PROJECT_DIR/scripts/Install ZetaNotes.command" "$MOUNT_POINT/"
        chmod +x "$MOUNT_POINT/Install ZetaNotes.command"
        # Remove quarantine from installer too
        xattr -cr "$MOUNT_POINT/Install ZetaNotes.command" 2>/dev/null || true
        print_success "Added automatic installer to DMG"
    fi

    # CRITICAL: Remove quarantine from files BEFORE creating DMG
    print_warning "Removing quarantine from all files before DMG creation..."
    xattr -cr "$MOUNT_POINT/${APP_NAME}.app" 2>/dev/null || true
    xattr -d com.apple.quarantine "$MOUNT_POINT/${APP_NAME}.app" 2>/dev/null || true
    find "$MOUNT_POINT/${APP_NAME}.app" -exec xattr -c {} \; 2>/dev/null || true

    # Fix permissions inside mount
    chmod +x "$MOUNT_POINT/${APP_NAME}.app/Contents/MacOS/"* 2>/dev/null || true

    print_success "Quarantine removed from files in DMG"

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

# Remove quarantine from DMG itself and verify
print_step "Step 7: Final DMG cleanup and verification"

# Remove quarantine from the DMG file itself
print_warning "Removing quarantine from DMG file..."
xattr -cr "$DMG_NAME" 2>/dev/null || true
xattr -d com.apple.quarantine "$DMG_NAME" 2>/dev/null || true

# Verify no quarantine attributes remain
XATTR_COUNT=$(xattr "$DMG_NAME" 2>/dev/null | wc -l | tr -d ' ')
if [ "$XATTR_COUNT" -eq 0 ]; then
    print_success "DMG is clean (no extended attributes)"
else
    print_warning "DMG still has extended attributes (may be added on download)"
    xattr -l "$DMG_NAME" || true
fi

# Test mount the DMG to verify integrity
print_warning "Verifying DMG integrity..."
TEST_MOUNT="/Volumes/${APP_NAME}_test_$$"
if hdiutil attach "$DMG_NAME" -readonly -mountpoint "$TEST_MOUNT" -nobrowse 2>/dev/null; then
    # Check if app is readable
    if [ -d "$TEST_MOUNT/${APP_NAME}.app" ]; then
        print_success "DMG verification passed - app is accessible"

        # Check for quarantine in mounted app
        MOUNTED_XATTR=$(xattr "$TEST_MOUNT/${APP_NAME}.app" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$MOUNTED_XATTR" -eq 0 ]; then
            print_success "App inside DMG has no quarantine attributes"
        else
            print_warning "App inside DMG has extended attributes:"
            xattr -l "$TEST_MOUNT/${APP_NAME}.app" || true
        fi
    else
        print_error "App not found in DMG!"
    fi

    # Unmount test volume
    hdiutil detach "$TEST_MOUNT" -force 2>/dev/null || true
else
    print_warning "Could not verify DMG (non-critical)"
fi

print_success "DMG cleanup and verification complete"

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

Terminal Fix (if you see "damaged" or persistent malware warnings):
-------------------------------------------------------------------

If the right-click method doesn't work at all, run this in Terminal:

  sudo xattr -cr /Applications/ZetaNotes.app && sudo chmod +x /Applications/ZetaNotes.app/Contents/MacOS/ZetaNotes

This removes quarantine attributes and fixes permissions.
You'll need to enter your Mac password.

After running this, try opening ZetaNotes normally or via right-click.

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
