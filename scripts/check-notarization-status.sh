#!/bin/bash

# Quick Notarization Status Checker
# Usage: ./check-notarization-status.sh [submission-id]

SUBMISSION_ID="${1:-0c73b412-8915-457a-a5b4-6d79bb297411}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Checking notarization status...${NC}"
echo ""

# Check credentials
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo -e "${RED}Error: Missing credentials${NC}"
    echo "Set these environment variables:"
    echo "  export APPLE_ID=\"your-apple-id@email.com\""
    echo "  export APPLE_APP_SPECIFIC_PASSWORD=\"your-app-password\""
    exit 1
fi

# Get status
xcrun notarytool info "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --team-id "HDA4C6CU89" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "To get detailed logs if it failed:"
echo "  xcrun notarytool log $SUBMISSION_ID \\"
echo "    --apple-id \"\$APPLE_ID\" \\"
echo "    --team-id \"HDA4C6CU89\" \\"
echo "    --password \"\$APPLE_APP_SPECIFIC_PASSWORD\" \\"
echo "    notarization-log.json"
