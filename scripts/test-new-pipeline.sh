#!/bin/bash
# Test script to verify the new release pipeline works correctly
# Run this before migrating from old to new system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Testing New Release Pipeline"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Check all library modules exist
echo "✓ Test 1: Checking library modules..."
MODULES=(
    "lib/colors.sh"
    "lib/validation.sh"
    "lib/xcode.sh"
    "lib/signing.sh"
    "lib/sparkle.sh"
    "lib/notarization.sh"
    "lib/packaging.sh"
)

for module in "${MODULES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$module" ]; then
        echo "  ✗ Missing: $module"
        exit 1
    fi
    echo "  ✓ Found: $module"
done

# Test 2: Check configuration file
echo ""
echo "✓ Test 2: Checking configuration..."
if [ ! -f "$SCRIPT_DIR/release-config.sh" ]; then
    echo "  ✗ Missing: release-config.sh"
    exit 1
fi
echo "  ✓ Found: release-config.sh"

# Test 3: Check main script
echo ""
echo "✓ Test 3: Checking main release script..."
if [ ! -f "$SCRIPT_DIR/release-new.sh" ]; then
    echo "  ✗ Missing: release-new.sh"
    exit 1
fi
if [ ! -x "$SCRIPT_DIR/release-new.sh" ]; then
    echo "  ✗ Not executable: release-new.sh"
    exit 1
fi
echo "  ✓ Found and executable: release-new.sh"

# Test 4: Source library modules (syntax check)
echo ""
echo "✓ Test 4: Syntax checking library modules..."
for module in "${MODULES[@]}"; do
    if bash -n "$SCRIPT_DIR/$module" 2>&1; then
        echo "  ✓ Valid syntax: $module"
    else
        echo "  ✗ Syntax error in: $module"
        exit 1
    fi
done

# Test 5: Source configuration (syntax check)
echo ""
echo "✓ Test 5: Syntax checking configuration..."
if bash -n "$SCRIPT_DIR/release-config.sh" 2>&1; then
    echo "  ✓ Valid syntax: release-config.sh"
else
    echo "  ✗ Syntax error in: release-config.sh"
    exit 1
fi

# Test 6: Source main script (syntax check)
echo ""
echo "✓ Test 6: Syntax checking main script..."
if bash -n "$SCRIPT_DIR/release-new.sh" 2>&1; then
    echo "  ✓ Valid syntax: release-new.sh"
else
    echo "  ✗ Syntax error in: release-new.sh"
    exit 1
fi

# Test 7: Check workflow file
echo ""
echo "✓ Test 7: Checking GitHub Actions workflow..."
if [ ! -f "$PROJECT_DIR/.github/workflows/release-new.yml" ]; then
    echo "  ✗ Missing: .github/workflows/release-new.yml"
    exit 1
fi
echo "  ✓ Found: .github/workflows/release-new.yml"

# Test 8: Check documentation
echo ""
echo "✓ Test 8: Checking documentation..."
DOCS=(
    "RELEASE_PIPELINE.md"
    "REORGANIZATION.md"
    "QUICK_START_NEW.md"
    "REORGANIZATION_SUMMARY.txt"
)

for doc in "${DOCS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$doc" ]; then
        echo "  ✗ Missing: $doc"
        exit 1
    fi
    echo "  ✓ Found: $doc"
done

# Test 9: Compare line counts
echo ""
echo "✓ Test 9: Comparing line counts..."
echo "  Old system:"
OLD_LINES=0
[ -f "$SCRIPT_DIR/release.sh" ] && OLD_LINES=$((OLD_LINES + $(wc -l < "$SCRIPT_DIR/release.sh")))
[ -f "$SCRIPT_DIR/release-local.sh" ] && OLD_LINES=$((OLD_LINES + $(wc -l < "$SCRIPT_DIR/release-local.sh")))
[ -f "$SCRIPT_DIR/release-ci.sh" ] && OLD_LINES=$((OLD_LINES + $(wc -l < "$SCRIPT_DIR/release-ci.sh")))
[ -f "$SCRIPT_DIR/release-common.sh" ] && OLD_LINES=$((OLD_LINES + $(wc -l < "$SCRIPT_DIR/release-common.sh")))
echo "    Scripts: $OLD_LINES lines"

NEW_LINES=0
NEW_LINES=$((NEW_LINES + $(wc -l < "$SCRIPT_DIR/release-new.sh")))
NEW_LINES=$((NEW_LINES + $(wc -l < "$SCRIPT_DIR/release-config.sh")))
for module in "${MODULES[@]}"; do
    NEW_LINES=$((NEW_LINES + $(wc -l < "$SCRIPT_DIR/$module")))
done
echo "  New system:"
echo "    Scripts: $NEW_LINES lines"

if [ $NEW_LINES -lt $OLD_LINES ]; then
    REDUCTION=$(( (OLD_LINES - NEW_LINES) * 100 / OLD_LINES ))
    echo "    ✓ Reduction: ${REDUCTION}% fewer lines"
fi

# Test 10: Dry run help
echo ""
echo "✓ Test 10: Testing script help/usage..."
if "$SCRIPT_DIR/release-new.sh" 2>&1 | grep -q "Version required"; then
    echo "  ✓ Script shows usage when no version provided"
else
    echo "  ✗ Script doesn't show proper error message"
    exit 1
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ All Tests Passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Test with a real build:"
echo "     ./scripts/release-new.sh 1.0.0-test"
echo ""
echo "  2. Compare outputs with old system"
echo ""
echo "  3. When satisfied, migrate:"
echo "     See scripts/QUICK_START_NEW.md for migration steps"
echo ""
