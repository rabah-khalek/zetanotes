#!/bin/bash
set -e

#####################################################################
# ZetaNotes Unsigned Release Script with Sparkle Auto-Update
#
# This script creates unsigned releases for FREE distribution.
# No Apple Developer account required ($0/year)!
#
# What it does:
# 1. Builds the app
# 2. Bundles Llama 3.2 1B model
# 3. Creates DMG
# 4. Signs with Sparkle EdDSA (for update verification)
# 5. Updates appcast.xml
#
# Users will need to right-click → Open on first launch,
# but auto-updates will work!
#
# Usage: ./scripts/release_unsigned.sh <version>
# Example: ./scripts/release_unsigned.sh 1.0.0
#####################################################################

VERSION="${1:-1.0.0}"
BUILD_DIR="$HOME/Desktop/ZetaNotes-Release"
APP_PATH="$BUILD_DIR/ZetaNotes.app"
DMG_NAME="ZetaNotes-v${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
SPARKLE_BIN="$(pwd)/scripts/sparkle/bin"
APPCAST_FILE="$(pwd)/docs/appcast.xml"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}ZetaNotes UNSIGNED Release v${VERSION}${NC}"
echo -e "${GREEN}(Free - No Apple Developer Account)${NC}"
echo -e "${GREEN}=====================================${NC}"

if [ -z "$1" ]; then
    echo -e "${YELLOW}Warning: No version specified, using 1.0.0${NC}"
    echo "Usage: $0 <version>"
fi

# Step 1: Clean and Build
echo -e "\n${GREEN}[1/6]${NC} Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo -e "${GREEN}[2/6]${NC} Building ZetaNotes v${VERSION}..."
# Build for ARM64 only (Apple Silicon)
xcodebuild -scheme ZetaNotes \
  -configuration Release \
  -archivePath "$BUILD_DIR/ZetaNotes.xcarchive" \
  ARCHS="arm64" \
  ONLY_ACTIVE_ARCH=NO \
  archive

# Extract app from archive (skip export for unsigned builds)
cp -R "$BUILD_DIR/ZetaNotes.xcarchive/Products/Applications/ZetaNotes.app" "$BUILD_DIR/"

# Step 2: Bundle Llama 3.2 1B model
echo -e "${GREEN}[3/6]${NC} Downloading Llama 3.2 1B model (~700MB)..."
mkdir -p "$APP_PATH/Contents/Resources/Models"
if [ ! -f "$APP_PATH/Contents/Resources/Models/Llama-3.2-1B-Instruct-Q4_K_M.gguf" ]; then
    curl -L "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf" \
      -o "$APP_PATH/Contents/Resources/Models/Llama-3.2-1B-Instruct-Q4_K_M.gguf"
fi

# Step 3: Create DMG
echo -e "${GREEN}[4/6]${NC} Creating DMG installer..."
if command -v create-dmg &> /dev/null; then
    create-dmg \
      --volname "ZetaNotes Installer" \
      --window-pos 200 120 \
      --window-size 800 400 \
      --icon-size 100 \
      --icon "ZetaNotes.app" 200 190 \
      --hide-extension "ZetaNotes.app" \
      --app-drop-link 600 185 \
      "$DMG_PATH" \
      "$APP_PATH" || {
        # Fallback to hdiutil
        hdiutil create -size 1.5g -fs HFS+ -volname "ZetaNotes" "$BUILD_DIR/temp.dmg"
        hdiutil attach "$BUILD_DIR/temp.dmg" -readwrite -mountpoint /Volumes/ZetaNotes
        cp -R "$APP_PATH" /Volumes/ZetaNotes/
        ln -s /Applications /Volumes/ZetaNotes/Applications
        hdiutil detach /Volumes/ZetaNotes
        hdiutil convert "$BUILD_DIR/temp.dmg" -format UDZO -o "$DMG_PATH"
        rm "$BUILD_DIR/temp.dmg"
    }
else
    hdiutil create -size 1.5g -fs HFS+ -volname "ZetaNotes" "$BUILD_DIR/temp.dmg"
    hdiutil attach "$BUILD_DIR/temp.dmg" -readwrite -mountpoint /Volumes/ZetaNotes
    cp -R "$APP_PATH" /Volumes/ZetaNotes/
    ln -s /Applications /Volumes/ZetaNotes/Applications
    hdiutil detach /Volumes/ZetaNotes
    hdiutil convert "$BUILD_DIR/temp.dmg" -format UDZO -o "$DMG_PATH"
    rm "$BUILD_DIR/temp.dmg"
fi

# Step 4: Sign with Sparkle EdDSA (for update verification)
echo -e "${GREEN}[5/6]${NC} Signing DMG with Sparkle EdDSA..."
SPARKLE_SIGNATURE=$("$SPARKLE_BIN/sign_update" "$DMG_PATH")
echo -e "${GREEN}EdDSA Signature: ${SPARKLE_SIGNATURE}${NC}"

DMG_SIZE=$(stat -f%z "$DMG_PATH")
CHECKSUM=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')

# Step 5: Update Appcast
echo -e "${GREEN}[6/6]${NC} Updating appcast.xml..."
PUBDATE=$(date -R)

NEW_ENTRY="    <!-- Version ${VERSION} -->
    <item>
        <title>Version ${VERSION}</title>
        <link>https://github.com/YOUR_USERNAME/zetanotes</link>
        <sparkle:version>${VERSION}</sparkle:version>
        <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
        <description><![CDATA[
            <h2>ZetaNotes ${VERSION}</h2>
            <p>What's new:</p>
            <ul>
                <li>Add release notes here</li>
            </ul>
        ]]></description>
        <pubDate>${PUBDATE}</pubDate>
        <enclosure
            url=\"https://github.com/YOUR_USERNAME/zetanotes/releases/download/v${VERSION}/ZetaNotes-v${VERSION}.dmg\"
            sparkle:version=\"${VERSION}\"
            sparkle:shortVersionString=\"${VERSION}\"
            length=\"${DMG_SIZE}\"
            type=\"application/octet-stream\"
            sparkle:edSignature=\"${SPARKLE_SIGNATURE}\" />
        <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
    </item>

"

cp "$APPCAST_FILE" "$APPCAST_FILE.backup"
awk -v entry="$NEW_ENTRY" '
    /<language>en<\/language>/ {
        print
        print ""
        print entry
        next
    }
    {print}
' "$APPCAST_FILE.backup" > "$APPCAST_FILE"

# Summary
echo -e "\n${GREEN}=====================================${NC}"
echo -e "${GREEN}Release Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "Version: ${GREEN}${VERSION}${NC}"
echo -e "DMG: ${GREEN}${DMG_PATH}${NC}"
echo -e "Size: ${GREEN}${DMG_SIZE} bytes${NC}"
echo -e "SHA256: ${GREEN}${CHECKSUM}${NC}"
echo -e "EdDSA Signature: ${GREEN}${SPARKLE_SIGNATURE}${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Test the DMG locally"
echo "2. Create GitHub release: https://github.com/YOUR_USERNAME/zetanotes/releases/new"
echo "3. Upload ${DMG_NAME} to the release"
echo "4. Commit and push updated appcast.xml:"
echo "   git add docs/appcast.xml"
echo "   git commit -m \"Update appcast for v${VERSION}\""
echo "   git push origin main"
echo ""
echo -e "${YELLOW}Note: This is an UNSIGNED build.${NC}"
echo "Users will need to right-click → Open on first launch."
echo "After that, auto-updates will work normally!"
