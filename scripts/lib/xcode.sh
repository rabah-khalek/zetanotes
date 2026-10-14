#!/bin/bash
# Xcode build functions

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

build_app() {
    local project_dir="$1"
    local build_dir="$2"
    local team_id="$3"

    print_step "Building and signing app"
    cd "$project_dir"

    # Clean build
    xcodebuild clean \
        -project ZetaNotes.xcodeproj \
        -scheme ZetaNotes \
        -configuration Release \
        -quiet

    # Build with signing
    xcodebuild \
        -project ZetaNotes.xcodeproj \
        -scheme ZetaNotes \
        -configuration Release \
        -derivedDataPath "$build_dir/DerivedData" \
        CODE_SIGN_STYLE=Manual \
        CODE_SIGN_IDENTITY="Developer ID Application" \
        DEVELOPMENT_TEAM="$team_id" \
        ENABLE_HARDENED_RUNTIME=YES \
        OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
        -quiet || print_error "Build failed"

    # Find and copy built app
    local built_app=$(find "$build_dir/DerivedData/Build/Products" -name "ZetaNotes.app" -maxdepth 2 | head -n 1)
    [ -z "$built_app" ] && print_error "App not found after build"

    cp -R "$built_app" "$build_dir/ZetaNotes.app"

    print_success "App built successfully"
}

rebuild_llama_if_needed() {
    local rebuild_flag="$1"
    local project_dir="$2"

    # ALWAYS rebuild llama.cpp for releases to ensure fresh signatures
    # The rebuild flag is kept for backward compatibility but ignored
    print_step "Rebuilding llama.cpp from scratch (required for notarization)"

    if [ -d "$project_dir/llama.cpp/build" ]; then
        echo "Removing old llama.cpp build..."
        rm -rf "$project_dir/llama.cpp/build"
    fi

    echo "Building llama.cpp with Metal support..."
    cd "$project_dir"

    # Set SRCROOT for build-llama.sh script
    export SRCROOT="$project_dir"
    bash scripts/build-llama.sh || print_error "llama.cpp build failed"

    print_success "llama.cpp rebuilt successfully"
}
