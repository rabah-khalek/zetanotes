#!/bin/bash
# Release configuration - all hardcoded values in one place

# Project settings
APP_NAME="ZetaNotes"
PROJECT_NAME="ZetaNotes"
SCHEME="ZetaNotes"
CONFIGURATION="Release"

# Team and signing
TEAM_ID="HDA4C6CU89"
SIGNING_IDENTITY_LOCAL="Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"
SIGNING_IDENTITY_CI="Developer ID Application"  # CI uses generic match

# Sparkle settings
SPARKLE_ACCOUNT_NAME="${SPARKLE_ACCOUNT_NAME:-zetanotes-sparkle}"  # For local keychain

# GitHub settings
GITHUB_REPO="rabah-khalek/zetanotes"
DOWNLOAD_BASE_URL="https://github.com/${GITHUB_REPO}/releases/download"

# System requirements
MIN_MACOS_VERSION="13.0"

# Paths (relative to project root)
ENTITLEMENTS_PATH="ZetaNotes/ZetaNotes.entitlements"
VERIFY_SCRIPT_PATH="scripts/verify-signatures.sh"
SIGN_UPDATE_PATH="scripts/sparkle/bin/sign_update"
BUILD_LLAMA_SCRIPT="scripts/build-llama.sh"

# Detect environment
detect_environment() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "ci"
    else
        echo "local"
    fi
}

# Get appropriate signing identity based on environment
get_signing_identity() {
    local env="$1"
    if [ "$env" = "ci" ]; then
        echo "$SIGNING_IDENTITY_CI"
    else
        echo "$SIGNING_IDENTITY_LOCAL"
    fi
}
