#!/bin/bash
# ZetaNotes Installation Helper
# Run this script if you're having trouble opening ZetaNotes
# Usage: bash fix-zetanotes.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ZetaNotes Installation Troubleshooter      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""

APP_PATH="/Applications/ZetaNotes.app"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}✗ ZetaNotes not found in /Applications/${NC}"
    echo ""
    echo "Please drag ZetaNotes.app to your Applications folder first."
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Found ZetaNotes in Applications folder${NC}"
echo ""

# Check current state
echo -e "${BLUE}Checking current status...${NC}"
echo ""

# Check for quarantine
if xattr "$APP_PATH" 2>/dev/null | grep -q "com.apple.quarantine"; then
    echo -e "${YELLOW}⚠ Quarantine flag detected (download restriction)${NC}"
    HAS_QUARANTINE=true
else
    echo -e "${GREEN}✓ No quarantine flag${NC}"
    HAS_QUARANTINE=false
fi

# Check executable permissions
if [ -x "$APP_PATH/Contents/MacOS/ZetaNotes" ]; then
    echo -e "${GREEN}✓ Executable permissions OK${NC}"
    HAS_EXEC=true
else
    echo -e "${YELLOW}⚠ Executable permissions missing${NC}"
    HAS_EXEC=false
fi

# Check code signature
if codesign -v "$APP_PATH" 2>/dev/null; then
    echo -e "${GREEN}✓ Code signature valid${NC}"
    HAS_SIGNATURE=true
else
    echo -e "${YELLOW}⚠ Code signature issue${NC}"
    HAS_SIGNATURE=false
fi

echo ""

# Determine what needs fixing
NEEDS_FIX=false
if [ "$HAS_QUARANTINE" = true ] || [ "$HAS_EXEC" = false ]; then
    NEEDS_FIX=true
fi

if [ "$NEEDS_FIX" = false ]; then
    echo -e "${GREEN}✓ No issues detected!${NC}"
    echo ""
    echo "If you're still having trouble opening ZetaNotes:"
    echo ""
    echo "Method 1 - Right-click to open:"
    echo "  1. RIGHT-CLICK on ZetaNotes in Applications"
    echo "  2. Select 'Open' from the menu"
    echo "  3. Click 'Open' in the security dialog"
    echo ""
    echo "Method 2 - System Settings:"
    echo "  1. Try to open ZetaNotes normally (it will be blocked)"
    echo "  2. Go to System Settings → Privacy & Security"
    echo "  3. Scroll down and click 'Open Anyway'"
    echo ""
    echo "Method 3 - Terminal override (advanced):"
    echo "  sudo xattr -rd com.apple.quarantine /Applications/ZetaNotes.app"
    echo "  sudo spctl --add --label 'ZetaNotes' /Applications/ZetaNotes.app"
    echo ""
    exit 0
fi

echo -e "${YELLOW}Issues detected. Would you like to apply fixes?${NC}"
echo ""
echo "This will:"
if [ "$HAS_QUARANTINE" = true ]; then
    echo "  - Remove quarantine/download restrictions"
fi
if [ "$HAS_EXEC" = false ]; then
    echo "  - Fix executable permissions"
fi
echo ""
read -p "Apply fixes? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    echo ""
    echo "To apply fixes manually, run:"
    echo "  sudo xattr -cr /Applications/ZetaNotes.app"
    echo "  sudo chmod +x /Applications/ZetaNotes.app/Contents/MacOS/ZetaNotes"
    echo ""
    exit 0
fi

echo ""
echo -e "${BLUE}Applying fixes...${NC}"
echo ""

# Fix 1: Remove quarantine
if [ "$HAS_QUARANTINE" = true ]; then
    echo -e "${YELLOW}Removing quarantine attributes...${NC}"
    if sudo xattr -cr "$APP_PATH" 2>/dev/null; then
        sudo xattr -d com.apple.quarantine "$APP_PATH" 2>/dev/null || true
        echo -e "${GREEN}✓ Quarantine removed${NC}"
    else
        echo -e "${RED}✗ Failed to remove quarantine${NC}"
        echo "  You may need to do this manually in System Settings"
    fi
fi

# Fix 2: Fix permissions
if [ "$HAS_EXEC" = false ]; then
    echo -e "${YELLOW}Fixing executable permissions...${NC}"
    if sudo chmod +x "$APP_PATH/Contents/MacOS/"* 2>/dev/null; then
        echo -e "${GREEN}✓ Permissions fixed${NC}"
    else
        echo -e "${RED}✗ Failed to fix permissions${NC}"
    fi
fi

# Fix 3: Add to Gatekeeper whitelist (requires admin)
echo ""
echo -e "${YELLOW}Would you like to add ZetaNotes to Gatekeeper whitelist?${NC}"
echo "This will prevent future security warnings."
echo ""
read -p "Add to whitelist? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Adding to Gatekeeper whitelist...${NC}"
    if sudo spctl --add --label "ZetaNotes" "$APP_PATH" 2>/dev/null; then
        echo -e "${GREEN}✓ Added to whitelist${NC}"
    else
        echo -e "${YELLOW}⚠ Could not add to whitelist (non-critical)${NC}"
        echo "  The app should still work"
    fi
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Fixes Applied Successfully!          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo "Try opening ZetaNotes now:"
echo "  1. Go to Applications folder"
echo "  2. RIGHT-CLICK on ZetaNotes"
echo "  3. Select 'Open'"
echo "  4. If prompted, click 'Open' to confirm"
echo ""
echo "After the first launch, you can open it normally."
echo ""
echo "If you still have issues:"
echo "  - Restart your Mac"
echo "  - Check System Settings → Privacy & Security"
echo "  - Report the issue: https://github.com/rabah-khalek/zetanotes/issues"
echo ""
