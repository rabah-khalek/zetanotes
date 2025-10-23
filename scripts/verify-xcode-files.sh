#!/bin/bash
# Verify critical files are in Xcode project

set -e

PROJECT_FILE="ZetaNotes.xcodeproj/project.pbxproj"

echo "🔍 Verifying Critical Files in Xcode Project..."
echo ""

# Critical files that must be in project
CRITICAL_FILES=(
    "StoreKitManager.swift"
    "LicenseManager.swift"
    "Configuration.storekit"
    "UpgradePromptView.swift"
    "ZetaNotesApp.swift"
    "ContentView.swift"
    "AIEngine.swift"
)

ALL_OK=true

for file in "${CRITICAL_FILES[@]}"; do
    # Check if file exists in project.pbxproj
    if grep -q "$file" "$PROJECT_FILE"; then
        # Check if file actually exists on disk
        if find ZetaNotes -name "$file" -type f 2>/dev/null | grep -q .; then
            echo "✅ $file (in project & on disk)"
        else
            echo "⚠️  $file (in project but NOT on disk)"
            ALL_OK=false
        fi
    else
        echo "❌ $file (NOT in project)"
        ALL_OK=false
    fi
done

echo ""

if [ "$ALL_OK" = true ]; then
    echo "✅ All critical files verified!"
    echo ""
    echo "📊 Project Statistics:"
    echo "   Swift files in project: $(grep -c '\.swift.*Sources' "$PROJECT_FILE")"
    echo "   Total files in project: $(grep -c 'PBXFileReference' "$PROJECT_FILE")"
else
    echo "⚠️  Some files are missing or misconfigured"
    echo ""
    echo "💡 To fix:"
    echo "   1. Open ZetaNotes.xcodeproj in Xcode"
    echo "   2. Check Project Navigator for red/missing files"
    echo "   3. Right-click and re-add any missing files"
fi

echo ""
echo "🧪 To verify build works:"
echo "   xcodebuild -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Debug clean build"
