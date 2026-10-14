#!/bin/bash
# Sparkle auto-update support was removed; these stubs keep release.sh running.
# Each function is only defined if no other library provides it.

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

declare -F check_sparkle_tools >/dev/null || check_sparkle_tools() {
    print_warning "Sparkle signing disabled (no auto-update channel)"
    return 1
}

declare -F resign_sparkle_components >/dev/null || resign_sparkle_components() {
    echo "No Sparkle components to re-sign"
    return 0
}

declare -F generate_sparkle_signature >/dev/null || generate_sparkle_signature() {
    return 1
}

declare -F save_sparkle_signature >/dev/null || save_sparkle_signature() {
    return 0
}

declare -F generate_appcast_info >/dev/null || generate_appcast_info() {
    echo "Appcast generation skipped (Sparkle removed)"
    return 0
}

declare -F print_release_summary >/dev/null || print_release_summary() {
    local version="$1" dmg_name="$2" sparkle_sig="$3" notarization_status="$4"
    echo ""
    echo "Release $version"
    echo "  DMG:          $dmg_name"
    echo "  Notarization: $notarization_status"
}
