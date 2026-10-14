#!/bin/bash

# Run from the repository root regardless of the current directory
cd "$(dirname "$0")/.." || exit 1

# SwiftLint Auto-Formatter and Linter
# This script automatically fixes violations and then reports remaining issues

set -e

for tool in swiftformat swiftlint; do
    command -v "$tool" >/dev/null || { echo "$tool not found. Install with: brew install swiftformat swiftlint"; exit 1; }
done

echo "Running SwiftFormat to auto-format code..."
swiftformat ZetaNotes/ --quiet

echo ""
echo "Running SwiftLint auto-fix on ZetaNotes/ directory..."
swiftlint --fix ZetaNotes/

echo ""
echo "Auto-fix complete!"
echo ""
echo "Running SwiftLint to check remaining violations..."
echo ""

# Run lint but don't fail the script
swiftlint lint ZetaNotes/ || true

echo ""
echo "Done!"
