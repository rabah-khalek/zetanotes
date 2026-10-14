#!/bin/bash
# DMG creation and metadata generation

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

create_dmg() {
    local build_dir="$1"
    local dmg_name="$2"

    print_step "Creating DMG"
    cd "$build_dir"

    if ! command -v create-dmg &> /dev/null; then
        print_error "create-dmg not found! Install with: brew install create-dmg"
    fi

    create-dmg \
        --volname "ZetaNotes" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "ZetaNotes.app" 175 190 \
        --hide-extension "ZetaNotes.app" \
        --app-drop-link 425 185 \
        --no-internet-enable \
        "$dmg_name" \
        "ZetaNotes.app" || print_error "DMG creation failed"

    print_success "DMG created"
}

generate_checksum() {
    local dmg_path="$1"

    print_step "Generating checksum"

    shasum -a 256 "$dmg_path" > "${dmg_path}.sha256"
    local sha256=$(cat "${dmg_path}.sha256" | cut -d' ' -f1)

    print_success "SHA256 checksum created"
    echo "$sha256"
}

generate_appcast_info() {
    local dmg_path="$1"
    local version="$2"
    local sparkle_signature="$3"

    local dmg_name=$(basename "$dmg_path")
    local file_size=$(stat -f%z "$dmg_path")
    local sha256=$(cat "${dmg_path}.sha256" | cut -d' ' -f1)

    cat > "${dmg_path}.appcast-info" <<EOF
Version: ${version}
DMG Name: ${dmg_name}
File Size: ${file_size} bytes
SHA256: ${sha256}
Sparkle Signature: ${sparkle_signature:-NOT_GENERATED}
Download URL: https://github.com/rabah-khalek/zetanotes/releases/download/v${version}/${dmg_name}

Appcast XML snippet:
  <enclosure
    url="https://github.com/rabah-khalek/zetanotes/releases/download/v${version}/${dmg_name}"
    sparkle:version="${version}"
    sparkle:shortVersionString="${version}"
    length="${file_size}"
    type="application/octet-stream"
    sparkle:edSignature="${sparkle_signature:-MISSING_SIGNATURE}" />
EOF

    print_success "Appcast info generated: ${dmg_path}.appcast-info"
}

print_release_summary() {
    local version="$1"
    local dmg_path="$2"
    local sparkle_signature="$3"
    local notarization_status="$4"

    local dmg_name=$(basename "$dmg_path")
    local file_size=$(stat -f%z "$dmg_path")
    local sha256=$(cat "${dmg_path}.sha256" | cut -d' ' -f1)

    print_step "Release Summary"
    echo ""
    echo -e "${GREEN}Release build complete!${NC}"
    echo ""
    echo -e "${BLUE}Version:${NC} ${version}"
    echo -e "${BLUE}DMG:${NC} ${dmg_name}"
    echo -e "${BLUE}Size:${NC} $(du -h "$dmg_path" | cut -f1) ($file_size bytes)"
    echo -e "${BLUE}SHA256:${NC} ${sha256}"

    if [ -n "$sparkle_signature" ]; then
        echo -e "${BLUE}Sparkle Signature:${NC} ${sparkle_signature:0:32}..."
    else
        echo -e "${BLUE}Sparkle Signature:${NC}  NOT GENERATED"
    fi

    if [ "$notarization_status" = "Accepted" ]; then
        echo -e "${BLUE}Notarization:${NC} Accepted and stapled"
    else
        echo -e "${BLUE}Notarization:${NC}  ${notarization_status}"
    fi

    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Upload ${dmg_name} to GitHub Releases"
    echo "2. Update docs/appcast.xml with information from ${dmg_name}.appcast-info"
    echo "3. Push appcast.xml changes to trigger update notifications"
    echo ""
}
