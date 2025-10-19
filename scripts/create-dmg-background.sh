#!/bin/bash
# Create a visual background for the DMG with installation instructions
# This makes it clearer for users how to install unsigned apps

set -e

OUTPUT_FILE="${1:-dmg-background.png}"
WIDTH=800
HEIGHT=450

# Create a simple background using ImageMagick (if available)
if command -v convert &> /dev/null; then
    convert -size ${WIDTH}x${HEIGHT} \
        gradient:#f0f0f0-#ffffff \
        -font Helvetica-Bold -pointsize 32 -fill "#333333" \
        -gravity North -annotate +0+20 "ZetaNotes Installation" \
        -font Helvetica -pointsize 16 -fill "#666666" \
        -gravity North -annotate +0+80 "For first launch, RIGHT-CLICK the app and select 'Open'" \
        -gravity North -annotate +0+110 "This bypasses the security warning (one time only)" \
        -gravity South -annotate +0+20 "Drag ZetaNotes to Applications →" \
        "$OUTPUT_FILE"

    echo "DMG background created: $OUTPUT_FILE"
else
    echo "ImageMagick not found. Install with: brew install imagemagick"
    echo "Skipping background creation (optional)"
fi
