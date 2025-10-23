#!/bin/bash
# Code signing functions

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

resign_sparkle_components() {
    local build_dir="$1"
    local signing_identity="$2"

    print_step "Re-signing Sparkle components with Developer ID"

    local sparkle_framework="$build_dir/ZetaNotes.app/Contents/Frameworks/Sparkle.framework"

    if [ ! -d "$sparkle_framework" ]; then
        print_warning "Sparkle framework not found - skipping Sparkle signing"
        return 0
    fi

    # Sign XPC Services
    for xpc in "$sparkle_framework"/Versions/B/XPCServices/*.xpc; do
        if [ -d "$xpc" ]; then
            echo "  Signing: $(basename "$xpc")"
            codesign --force --sign "$signing_identity" \
                --options runtime \
                --timestamp \
                --deep \
                "$xpc" || print_error "Failed to sign $(basename "$xpc")"
        fi
    done

    # Sign Updater.app
    local updater_app="$sparkle_framework/Versions/B/Updater.app"
    if [ -d "$updater_app" ]; then
        echo "  Signing: Updater.app"
        codesign --force --sign "$signing_identity" \
            --options runtime \
            --timestamp \
            --deep \
            "$updater_app" || print_error "Failed to sign Updater.app"
    fi

    # Re-sign framework
    echo "  Re-signing: Sparkle.framework"
    codesign --force --sign "$signing_identity" \
        --options runtime \
        --timestamp \
        "$sparkle_framework" || print_error "Failed to sign Sparkle.framework"

    print_success "Sparkle components re-signed"
}

resign_llama_libraries() {
    local build_dir="$1"
    local signing_identity="$2"

    echo ""
    echo "Re-signing llama.cpp libraries..."

    for dylib in "$build_dir/ZetaNotes.app/Contents/Frameworks/"*.dylib; do
        if [ -f "$dylib" ]; then
            echo "  Signing: $(basename "$dylib")"
            codesign --force --sign "$signing_identity" \
                --options runtime \
                --timestamp \
                "$dylib" || print_error "Failed to sign $(basename "$dylib")"
        fi
    done

    print_success "llama.cpp libraries re-signed"
}

resign_app_bundle() {
    local build_dir="$1"
    local project_dir="$2"
    local signing_identity="$3"

    print_step "Re-signing main app bundle"

    codesign --force --sign "$signing_identity" \
        --entitlements "$project_dir/ZetaNotes/ZetaNotes.entitlements" \
        --options runtime \
        --timestamp \
        --deep \
        "$build_dir/ZetaNotes.app" || print_error "Failed to re-sign app bundle"

    print_success "Main app bundle re-signed"
}

sign_dmg() {
    local dmg_path="$1"
    local signing_identity="$2"

    print_step "Signing DMG"

    codesign --sign "$signing_identity" \
        --timestamp \
        --options runtime \
        "$dmg_path" || print_error "DMG signing failed"

    codesign --verify --verbose "$dmg_path" || print_error "DMG signature verification failed"

    print_success "DMG signed and verified"
}
