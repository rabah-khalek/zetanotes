#!/bin/bash

# Check Notarization Status Script
# Shows recent notarization submissions

# Load environment variables if .env exists
if [ -f .env ]; then
    source .env
fi

# Check credentials
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo "Error: Missing environment variables"
    echo "Required: APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD"
    echo ""
    echo "Either export them or create a .env file with:"
    echo "  APPLE_ID=your-apple-id@example.com"
    echo "  APPLE_TEAM_ID=YOUR_TEAM_ID"
    echo "  APPLE_APP_SPECIFIC_PASSWORD=your-app-specific-password"
    exit 1
fi

echo "Fetching notarization history..."
echo ""

xcrun notarytool history \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" 2>&1 | head -50
