#!/bin/bash

set -e  # Exit on any error

# Test Notarization Script - Simplified version with clean status updates

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-dmg>"
    echo "Example: $0 ~/Desktop/ZetaNotes-Release-*/ZetaNotes-v1.0.0.dmg"
    exit 1
fi

DMG_PATH="$1"

# Verify DMG exists
if [ ! -f "$DMG_PATH" ]; then
    echo -e "${RED}Error: DMG file not found: $DMG_PATH${NC}"
    exit 1
fi

# Check credentials
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo -e "${RED}Error: Missing environment variables${NC}"
    echo "Required: APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}ZetaNotes Notarization Test${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo "DMG: $(basename "$DMG_PATH")"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""

# Submit for notarization with clean output
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait 2>&1 | \
    grep -E "(Submission ID|status:|Successfully uploaded|Processing complete)" | \
    while IFS= read -r line; do
        timestamp=$(date '+%H:%M:%S')
        if echo "$line" | grep -q "id:"; then
            id=$(echo "$line" | awk '{print $2}')
            echo -e "${BLUE}[$timestamp]${NC} Submission ID: $id"
        elif echo "$line" | grep -q "Successfully uploaded"; then
            echo -e "${GREEN}[$timestamp]${NC} Upload complete"
        elif echo "$line" | grep -q "status: Accepted"; then
            echo -e "${GREEN}[$timestamp]${NC} ✅ Notarization ACCEPTED"
        elif echo "$line" | grep -q "status: Invalid"; then
            echo -e "${RED}[$timestamp]${NC} ❌ Notarization FAILED"
        elif echo "$line" | grep -q "status: In Progress"; then
            echo -e "${YELLOW}[$timestamp]${NC} Processing..."
        elif echo "$line" | grep -q "Processing complete"; then
            echo -e "${GREEN}[$timestamp]${NC} Processing complete"
        else
            echo -e "${BLUE}[$timestamp]${NC} $line"
        fi
    done

# Get submission ID from most recent submission
SUBMISSION_ID=$(xcrun notarytool history --limit 1 \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" 2>/dev/null | \
    grep -E "id:" | head -1 | awk '{print $2}')

# Check result and show details
echo ""
NOTARY_STATUS=$(xcrun notarytool info "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" 2>/dev/null | \
    grep "status:" | awk '{print $2}')

if [ "$NOTARY_STATUS" = "Accepted" ]; then
    echo -e "${GREEN}Stapling notarization ticket...${NC}"
    if xcrun stapler staple "$DMG_PATH" 2>&1 | grep -v "^$"; then
        echo -e "${GREEN}✅ DMG is notarized and stapled!${NC}"
    else
        echo -e "${YELLOW}⚠ Stapling failed, but DMG is still notarized${NC}"
    fi
elif [ "$NOTARY_STATUS" = "Invalid" ]; then
    echo -e "${RED}❌ Notarization FAILED${NC}"
    echo ""
    echo -e "${YELLOW}Fetching failure details from Apple...${NC}"
    echo ""

    # Get detailed log from Apple
    xcrun notarytool log "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        notarization-failure.json 2>/dev/null

    if [ -f "notarization-failure.json" ]; then
        echo -e "${RED}Failure reasons:${NC}"
        # Pretty print the issues from the JSON log
        if command -v jq &> /dev/null; then
            jq -r '.issues[]? | "  • [\(.severity)] \(.message)"' notarization-failure.json 2>/dev/null || cat notarization-failure.json
        else
            # Fallback if jq not available
            grep -o '"message":"[^"]*"' notarization-failure.json | sed 's/"message":"//g' | sed 's/"$//' | sed 's/^/  • /' || cat notarization-failure.json
        fi
        echo ""
        echo "Full log saved to: $(pwd)/notarization-failure.json"
    fi

    echo ""
    echo "Common issues:"
    echo "  • Missing or invalid code signature"
    echo "  • Hardened runtime not enabled"
    echo "  • Unsigned frameworks or libraries"
    echo "  • Invalid entitlements"
    exit 1
else
    echo -e "${YELLOW}⚠ Unexpected status: $NOTARY_STATUS${NC}"
    echo "Check details with:"
    echo "  xcrun notarytool info $SUBMISSION_ID --apple-id \$APPLE_ID --team-id \$APPLE_TEAM_ID --password \$APPLE_APP_SPECIFIC_PASSWORD"
    exit 1
fi
