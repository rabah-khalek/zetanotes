#!/bin/bash
# Validation and prerequisite checks

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

check_certificate() {
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        print_error "No Developer ID certificate found!"
    fi
    print_success "Found Developer ID certificate"
}

check_create_dmg() {
    if ! command -v create-dmg &> /dev/null; then
        print_error "create-dmg not found! Install with: brew install create-dmg"
    fi
    print_success "Found create-dmg"
}

check_sparkle_tools() {
    local sign_update="$1"

    if [ ! -f "$sign_update" ]; then
        print_warning "Sparkle sign_update tool not found at: $sign_update"
        print_warning "Sparkle signatures will be skipped - run ./scripts/setup-sparkle-keys.sh"
        return 1
    fi
    return 0
}

check_notarization_credentials() {
    local is_ci="$1"

    if [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
        print_success "Notarization credentials found"
        return 0
    else
        print_warning "Notarization credentials not set"
        if [ "$is_ci" = "true" ]; then
            print_warning "In CI: Ensure secrets are set"
        else
            echo ""
            echo "To enable notarization, set these environment variables:"
            echo "  export APPLE_ID='your-apple-id@example.com'"
            echo "  export APPLE_TEAM_ID='YOUR_TEAM_ID'"
            echo "  export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
            echo ""
        fi
        return 1
    fi
}

verify_app_signature() {
    local app_path="$1"

    echo "Verifying app bundle signature..."
    if ! codesign --verify --verbose --deep --strict "$app_path" 2>&1; then
        print_error "App signature verification failed"
    fi
    print_success "App signature verified"
}

verify_all_frameworks() {
    local app_path="$1"

    echo "Verifying embedded frameworks..."
    for framework in "$app_path/Contents/Frameworks/"*; do
        if [ -d "$framework" ] || [ -f "$framework" ]; then
            echo "  Checking: $(basename "$framework")"
            codesign --verify --verbose "$framework" || print_warning "$(basename "$framework") signature check failed"
        fi
    done
}

run_verification_script() {
    local app_path="$1"
    local verify_script="$2"

    if [ ! -f "$verify_script" ]; then
        print_warning "Verification script not found at: $verify_script"
        return 1
    fi

    chmod +x "$verify_script"
    if bash "$verify_script" "$app_path"; then
        print_success "All signatures verified successfully"
        return 0
    else
        print_error "Signature verification failed!"
    fi
}
