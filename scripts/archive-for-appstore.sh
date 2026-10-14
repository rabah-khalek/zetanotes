#!/bin/bash
# Archive ZetaNotes for App Store submission
# This script creates a proper .xcarchive with all required components including dSYMs

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${BLUE}==>${NC} ${GREEN}$1${NC}\n"
}

print_error() {
    echo -e "\n${RED}ERROR:${NC} $1\n"
    exit 1
}

print_success() {
    echo -e "${GREEN}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW} WARNING:${NC} $1"
}

# Configuration
APP_NAME="ZetaNotes"
SCHEME="ZetaNotes"
PROJECT_FILE="ZetaNotes.xcodeproj"
TEAM_ID="HDA4C6CU89"
BUNDLE_ID="com.zetanotes.zetanotes"

# Build paths
ARCHIVE_PATH="$PROJECT_DIR/build/ZetaNotes.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/AppStore"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions-AppStore.plist"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}          ${GREEN}ZetaNotes App Store Archive Builder${NC}             ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# STEP 1: Clean and rebuild llama.cpp
print_step "Rebuilding llama.cpp with debug symbols"

cd "$PROJECT_DIR"
rm -rf llama.cpp/build
export SRCROOT="$PROJECT_DIR"
bash scripts/build-llama.sh || print_error "llama.cpp build failed"

print_success "llama.cpp rebuilt with debug symbols"

# STEP 2: Clean Xcode build
print_step "Cleaning previous builds"

rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"

xcodebuild clean \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Release

print_success "Clean complete"

# STEP 3: Archive the app
print_step "Archiving app for App Store"

xcodebuild archive \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    ENABLE_HARDENED_RUNTIME=YES \
    DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
    DWARF_DSYM_FOLDER_PATH="$ARCHIVE_PATH/dSYMs" \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
    | xcbeautify || xcodebuild archive \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_STYLE=Manual \
        CODE_SIGN_IDENTITY="Apple Distribution" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
        ENABLE_HARDENED_RUNTIME=YES \
        DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
        DWARF_DSYM_FOLDER_PATH="$ARCHIVE_PATH/dSYMs" \
        OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime"

if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive creation failed - archive not found at $ARCHIVE_PATH"
fi

print_success "Archive created successfully"

# STEP 3.5: Verify and fix archive structure
print_step "Verifying archive structure"

APP_IN_ARCHIVE="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"

if [ ! -d "$APP_IN_ARCHIVE" ]; then
    print_error "App not found in archive at expected path: $APP_IN_ARCHIVE"
fi

# Check for frameworks
FRAMEWORKS_DIR="$APP_IN_ARCHIVE/Contents/Frameworks"
if [ -d "$FRAMEWORKS_DIR" ]; then
    echo "Frameworks directory found with $(ls -1 "$FRAMEWORKS_DIR" | wc -l | xargs) files"

    # Remove any accidental Info.plist files in dylibs
    find "$FRAMEWORKS_DIR" -name "*.dylib" -type d -o -name "Info.plist" | while read item; do
        if [[ "$item" == *.dylib ]] && [ -d "$item" ]; then
            print_warning "Found bundle structure for dylib: $(basename "$item"), will be fixed during export"
        fi
    done
fi

print_success "Archive structure verified"

# STEP 4: Generate and copy llama.cpp dSYM files to archive
print_step "Generating dSYM files for llama.cpp libraries"

DSYM_DIR="$ARCHIVE_PATH/dSYMs"
mkdir -p "$DSYM_DIR"

# First, find where the dylibs were copied in the app bundle
APP_IN_ARCHIVE="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
FRAMEWORKS_DIR="$APP_IN_ARCHIVE/Contents/Frameworks"

if [ -d "$FRAMEWORKS_DIR" ]; then
    echo "Found frameworks directory: $FRAMEWORKS_DIR"

    # Generate dSYM for each dylib in the app bundle
    for dylib in "$FRAMEWORKS_DIR"/*.dylib; do
        if [ -f "$dylib" ]; then
            dylib_name=$(basename "$dylib")
            echo "  Generating dSYM for: $dylib_name"

            # Generate dSYM using dsymutil
            dsymutil "$dylib" -o "$DSYM_DIR/${dylib_name}.dSYM" || {
                print_warning "Failed to generate dSYM for $dylib_name"
            }
        fi
    done

    # List all dSYM files in the archive
    echo ""
    echo "dSYM files in archive:"
    ls -la "$DSYM_DIR"

    # Count dSYM files
    dsym_count=$(find "$DSYM_DIR" -name "*.dSYM" -type d | wc -l | xargs)
    echo ""
    echo "Total dSYM files: $dsym_count"

    if [ "$dsym_count" -lt 6 ]; then
        print_warning "Expected at least 6 dSYM files for llama.cpp libraries, found $dsym_count"
    else
        print_success "All dSYM files generated successfully"
    fi

    # Ensure dylibs are not treated as bundles - they should be plain files
    echo ""
    echo "Checking for bundle structures in dylibs..."
    for item in "$FRAMEWORKS_DIR"/*.dylib; do
        if [ -d "$item" ]; then
            # This is a directory masquerading as a dylib - should not happen
            print_warning "Found bundle structure at: $(basename "$item") - fixing"
            # If this happens, we need to find the actual binary inside
            if [ -f "$item/$(basename "$item")" ]; then
                mv "$item/$(basename "$item")" "$FRAMEWORKS_DIR/temp_$(basename "$item")"
                rm -rf "$item"
                mv "$FRAMEWORKS_DIR/temp_$(basename "$item")" "$item"
            fi
        fi
    done

    # Strip debug symbols from the dylibs now that we have dSYMs
    print_step "Stripping debug symbols from dylibs (symbols preserved in dSYMs)"
    for dylib in "$FRAMEWORKS_DIR"/*.dylib; do
        if [ -f "$dylib" ]; then
            dylib_name=$(basename "$dylib")
            echo "  Stripping: $dylib_name"
            strip -S "$dylib" || print_warning "Could not strip $dylib_name"
        fi
    done
    print_success "Debug symbols stripped from dylibs"
else
    print_error "Frameworks directory not found in archive at: $FRAMEWORKS_DIR"
fi

# STEP 5: Create ExportOptions.plist for App Store
print_step "Creating App Store export options"

cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>ZetaNotes App Store</string>
    </dict>
</dict>
</plist>
EOF

print_success "Export options created"

# STEP 6: Export for App Store
print_step "Exporting for App Store submission"

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    | xcbeautify || xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS"

if [ ! -d "$EXPORT_PATH/$APP_NAME.app" ] && [ ! -f "$EXPORT_PATH/$APP_NAME.pkg" ]; then
    print_error "Export failed - no app or pkg found in $EXPORT_PATH"
fi

print_success "Export complete"

# STEP 7: Validate the package
print_step "Validating exported package"

# Find the exported package
if [ -f "$EXPORT_PATH/$APP_NAME.pkg" ]; then
    PKG_FILE="$EXPORT_PATH/$APP_NAME.pkg"
    echo "Found package: $PKG_FILE"

    # Show package info
    echo ""
    echo "Package details:"
    ls -lh "$PKG_FILE"

    # Expand the package to verify contents
    echo ""
    echo "Verifying package contents..."
    TMP_EXPAND="$PROJECT_DIR/build/pkg_verify"
    rm -rf "$TMP_EXPAND"
    mkdir -p "$TMP_EXPAND"

    pkgutil --expand "$PKG_FILE" "$TMP_EXPAND" 2>/dev/null || true

    if [ -d "$TMP_EXPAND" ]; then
        # Check for duplicate bundle identifiers
        echo "Checking for bundle identifier conflicts..."
        find "$TMP_EXPAND" -name "Info.plist" | while read plist; do
            bundle_id=$(defaults read "$plist" CFBundleIdentifier 2>/dev/null || echo "none")
            bundle_exec=$(defaults read "$plist" CFBundleExecutable 2>/dev/null || echo "none")
            if [ "$bundle_id" != "none" ]; then
                echo "  Bundle: $bundle_id - Executable: $bundle_exec"
            fi
        done
        rm -rf "$TMP_EXPAND"
    fi

    print_success "Package validation complete"
elif [ -d "$EXPORT_PATH/$APP_NAME.app" ]; then
    APP_FILE="$EXPORT_PATH/$APP_NAME.app"
    echo "Found app bundle: $APP_FILE"

    # Verify code signature
    echo ""
    echo "Verifying code signature:"
    codesign -dv --verbose=4 "$APP_FILE" 2>&1 | head -20

    # Check dylibs are not bundles
    echo ""
    echo "Verifying dylibs are plain files (not bundles):"
    if [ -d "$APP_FILE/Contents/Frameworks" ]; then
        for item in "$APP_FILE/Contents/Frameworks"/*.dylib; do
            if [ -d "$item" ]; then
                print_error "ERROR: $(basename "$item") is a directory (bundle structure) but should be a plain file"
            elif [ -f "$item" ]; then
                echo "  $(basename "$item") is a plain file"
            fi
        done
    fi

    print_success "App bundle validation complete"
else
    print_error "Could not find exported package or app"
fi

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}                    ${BLUE}Build Summary${NC}                           ${GREEN}║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC} Archive:      ${ARCHIVE_PATH##*/}"
echo -e "${GREEN}║${NC} Export Path:  ${EXPORT_PATH##*/}"
echo -e "${GREEN}║${NC} Team ID:      $TEAM_ID"
echo -e "${GREEN}║${NC} Bundle ID:    $BUNDLE_ID"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Open Xcode and go to Window > Organizer"
echo -e "  2. Select the archive: ${ARCHIVE_PATH##*/}"
echo -e "  3. Click 'Validate App' to check for issues"
echo -e "  4. Click 'Distribute App' and select 'App Store Connect'"
echo -e "  5. Follow the prompts to upload to App Store Connect"
echo ""
echo -e "${YELLOW}Or use Transporter app:${NC}"
echo -e "  1. Open Transporter app"
echo -e "  2. Drag and drop: $PKG_FILE"
echo -e "  3. Click 'Deliver' to upload to App Store Connect"
echo ""

print_success "Archive ready for App Store submission!"
