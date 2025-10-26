#!/bin/bash

# Update App Store URL Script for ZetaNotes v1.0.0
# This script updates the placeholder App Store URL with your actual URL

set -e  # Exit on error

echo "🍎 ZetaNotes - App Store URL Updater"
echo "======================================"
echo ""

# Check if App ID was provided
if [ -z "$1" ]; then
    echo "❌ Error: No App Store ID provided"
    echo ""
    echo "Usage: ./UPDATE_APP_STORE_URL.sh YOUR_APP_ID"
    echo ""
    echo "Example:"
    echo "  ./UPDATE_APP_STORE_URL.sh 6738123456"
    echo ""
    echo "Find your App ID in App Store Connect:"
    echo "  - Go to App Store Connect"
    echo "  - Select your app"
    echo "  - Look in the URL or App Information section"
    echo "  - The ID is the number after 'id' in the URL"
    echo ""
    exit 1
fi

APP_ID="$1"
DOCS_DIR="$(dirname "$0")/docs"

echo "📝 Configuration:"
echo "  App Store ID: $APP_ID"
echo "  Docs folder: $DOCS_DIR"
echo ""

# Verify docs directory exists
if [ ! -d "$DOCS_DIR" ]; then
    echo "❌ Error: docs/ directory not found at $DOCS_DIR"
    exit 1
fi

# Backup before making changes
echo "💾 Creating backups..."
cp "$DOCS_DIR/index.html" "$DOCS_DIR/index.html.backup"
cp "$DOCS_DIR/download.html" "$DOCS_DIR/download.html.backup"
echo "  ✓ Backups created (.backup files)"
echo ""

# Update index.html
echo "🔄 Updating index.html..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/idYOUR_APP_ID/id$APP_ID/g" "$DOCS_DIR/index.html"
else
    # Linux
    sed -i "s/idYOUR_APP_ID/id$APP_ID/g" "$DOCS_DIR/index.html"
fi

# Update download.html
echo "🔄 Updating download.html..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/idYOUR_APP_ID/id$APP_ID/g" "$DOCS_DIR/download.html"
else
    # Linux
    sed -i "s/idYOUR_APP_ID/id$APP_ID/g" "$DOCS_DIR/download.html"
fi

echo ""
echo "✅ Success! App Store URL updated."
echo ""
echo "📄 Files updated:"
echo "  - docs/index.html"
echo "  - docs/download.html"
echo ""
echo "🔗 New URL: https://apps.apple.com/app/id$APP_ID"
echo ""
echo "🚀 Next steps:"
echo "  1. Verify changes:"
echo "     grep -n \"id$APP_ID\" docs/index.html docs/download.html"
echo ""
echo "  2. Test locally:"
echo "     cd docs && python3 -m http.server 8000"
echo ""
echo "  3. Commit and deploy:"
echo "     git add docs/"
echo "     git commit -m \"Update App Store URL to id$APP_ID\""
echo "     git push origin main"
echo ""
echo "  4. Monitor deployment at: https://zetanotes.com"
echo ""
echo "💡 Backups saved with .backup extension (you can delete them after verifying)"
echo ""
