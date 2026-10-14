#!/bin/bash

# verify-signatures.sh
# Comprehensive signature verification before notarization
# Run this before submitting to Apple's notary service

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_PATH="${1}"
REQUIRED_CERT="Developer ID Application"

if [ -z "$APP_PATH" ]; then
    echo "Usage: $0 <path-to-app-bundle>"
    echo "Example: $0 ZetaNotes.app"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: App bundle not found at $APP_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ZetaNotes Signature Verification Tool            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

ERRORS=0
WARNINGS=0

print_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Function to check signature of a component
check_signature() {
    local component="$1"
    local display_name="$2"

    if [ ! -e "$component" ]; then
        print_warn "$display_name not found"
        return
    fi

    # Get signature info
    local sig_info=$(codesign -dv --verbose=4 "$component" 2>&1)

    # Check if signed
    if ! echo "$sig_info" | grep -q "Authority="; then
        print_fail "$display_name is NOT signed"
        return
    fi

    # Check certificate type
    local authority=$(echo "$sig_info" | grep "Authority=" | head -1)
    if echo "$authority" | grep -q "$REQUIRED_CERT"; then
        print_pass "$display_name signed with Developer ID"
    elif echo "$authority" | grep -q "adhoc"; then
        print_fail "$display_name has AD-HOC signature (must use Developer ID)"
    elif echo "$authority" | grep -q "Apple Development"; then
        print_fail "$display_name signed with Apple Development (must use Developer ID)"
    else
        print_warn "$display_name signed with: $authority"
    fi

    # Check hardened runtime
    if echo "$sig_info" | grep -q "flags=.*runtime"; then
        print_pass "$display_name has hardened runtime"
    else
        print_fail "$display_name missing hardened runtime flag"
    fi

    # Verify signature
    if codesign --verify --verbose "$component" 2>&1 | grep -q "valid on disk"; then
        print_pass "$display_name signature valid"
    else
        if codesign --verify "$component" 2>/dev/null; then
            print_pass "$display_name signature valid"
        else
            print_fail "$display_name signature INVALID"
        fi
    fi
}

echo -e "\n${BLUE}━━━ Main Application ━━━${NC}"
check_signature "$APP_PATH" "ZetaNotes.app"

SPARKLE="$APP_PATH/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE" ]; then
    echo -e "\n${BLUE}━━━ Sparkle Framework ━━━${NC}"
    check_signature "$SPARKLE" "Sparkle.framework"

    echo -e "\n${BLUE}━━━ Sparkle XPC Services ━━━${NC}"
    for xpc in "$SPARKLE"/Versions/B/XPCServices/*.xpc; do
        if [ -d "$xpc" ]; then
            check_signature "$xpc" "$(basename "$xpc")"
        fi
    done

    echo -e "\n${BLUE}━━━ Sparkle Updater ━━━${NC}"
    UPDATER="$SPARKLE/Versions/B/Updater.app"
    check_signature "$UPDATER" "Updater.app"
else
    echo -e "\n${BLUE}━━━ Sparkle Framework ━━━${NC}"
    echo "  Sparkle not bundled (auto-update removed) - skipping"
fi

echo -e "\n${BLUE}━━━ llama.cpp Libraries ━━━${NC}"
for dylib in "$APP_PATH/Contents/Frameworks/"*.dylib; do
    if [ -f "$dylib" ]; then
        check_signature "$dylib" "$(basename "$dylib")"
    fi
done

echo -e "\n${BLUE}━━━ Entitlements Check ━━━${NC}"

# Extract entitlements - codesign outputs in Dict/Key/Value format
TEMP_ENT=$(mktemp)
codesign -d --entitlements - "$APP_PATH" 2>&1 | grep -v "^Executable=" | grep -v "^warning:" > "$TEMP_ENT" 2>/dev/null

if [ -f "$TEMP_ENT" ] && [ -s "$TEMP_ENT" ]; then
    # Check App Sandbox
    if grep -q "com.apple.security.app-sandbox" "$TEMP_ENT"; then
        if grep -A2 "com.apple.security.app-sandbox" "$TEMP_ENT" | grep -q "\[Bool\] true"; then
            print_warn "App Sandbox is ENABLED (may conflict with llama.cpp)"
        else
            print_pass "App Sandbox is disabled (correct for direct distribution)"
        fi
    else
        print_pass "App Sandbox is disabled (correct for direct distribution)"
    fi

    # Check JIT
    if grep -q "com.apple.security.cs.allow-jit" "$TEMP_ENT"; then
        if grep -A2 "com.apple.security.cs.allow-jit" "$TEMP_ENT" | grep -q "\[Bool\] true"; then
            print_pass "JIT entitlement present (required for llama.cpp)"
        else
            print_warn "JIT entitlement is false"
        fi
    else
        print_warn "JIT entitlement missing (may be needed for llama.cpp)"
    fi

    # Check unsigned executable memory
    if grep -q "com.apple.security.cs.allow-unsigned-executable-memory" "$TEMP_ENT"; then
        if grep -A2 "com.apple.security.cs.allow-unsigned-executable-memory" "$TEMP_ENT" | grep -q "\[Bool\] true"; then
            print_pass "Unsigned executable memory entitlement present (required for llama.cpp)"
        else
            print_warn "Unsigned executable memory entitlement is false"
        fi
    else
        print_warn "Unsigned executable memory entitlement missing (may be needed for llama.cpp)"
    fi

    rm -f "$TEMP_ENT"
else
    print_warn "No entitlements found (this may be normal for some builds)"
    rm -f "$TEMP_ENT"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Verification Summary                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready for notarization.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No critical errors, but $WARNINGS warning(s) found.${NC}"
    echo -e "${YELLOW}   Review warnings above.${NC}"
    echo ""
    echo -e "${GREEN}✅ Safe to proceed with notarization.${NC}"
    echo -e "${GREEN}   (Warnings are informational and won't block notarization)${NC}"
    exit 0
else
    echo -e "${RED}❌ Found $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo -e "${RED}   Fix errors before submitting for notarization!${NC}"
    exit 1
fi
