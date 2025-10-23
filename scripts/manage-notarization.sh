#!/bin/bash
# Manage stuck notarization submissions
# Lists and optionally cancels in-progress notarizations

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Notarization Submission Manager"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for required credentials
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo "❌ Error: Notarization credentials not set"
    echo ""
    echo "Required environment variables:"
    echo "  APPLE_ID"
    echo "  APPLE_TEAM_ID"
    echo "  APPLE_APP_SPECIFIC_PASSWORD"
    exit 1
fi

echo "Using Apple ID: $APPLE_ID"
echo "Team ID: $APPLE_TEAM_ID"
echo ""

# Function to list recent submissions
list_submissions() {
    echo "Fetching recent notarization submissions..."
    echo ""

    xcrun notarytool history \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        2>&1
}

# Function to get detailed info about a submission
get_submission_info() {
    local submission_id="$1"

    echo "Fetching details for submission: $submission_id"
    echo ""

    xcrun notarytool info "$submission_id" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        2>&1
}

# Main logic
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Recent Notarization Submissions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

list_submissions

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ℹ️  Note: Apple's notarytool does not support canceling submissions."
echo ""
echo "Submissions that show 'In Progress' for more than 24 hours are"
echo "likely stuck in Apple's system and will eventually timeout or"
echo "be automatically rejected."
echo ""
echo "What you can do:"
echo ""
echo "1. Wait for them to timeout (Apple usually times out after 24-48 hours)"
echo ""
echo "2. Check status of a specific submission:"
echo "   xcrun notarytool info <SUBMISSION_ID> \\"
echo "     --apple-id '$APPLE_ID' \\"
echo "     --team-id '$APPLE_TEAM_ID' \\"
echo "     --password '\$APPLE_APP_SPECIFIC_PASSWORD'"
echo ""
echo "3. If a submission is truly stuck (>48 hours), it won't affect new"
echo "   submissions. You can safely submit new notarization requests."
echo ""
echo "4. Each new release creates a fresh submission with its own ID."
echo "   Old stuck submissions don't block new ones."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Do you want to check a specific submission ID? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter submission ID: " submission_id

    if [ -n "$submission_id" ]; then
        echo ""
        get_submission_info "$submission_id"
    fi
fi

echo ""
echo "✅ Done"
