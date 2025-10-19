#!/bin/bash

# Install ZetaNotes Helper Script
# This script automatically installs ZetaNotes and removes quarantine

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║         ZetaNotes Installation Helper                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "This will:"
echo "  1. Copy ZetaNotes to your Applications folder"
echo "  2. Remove security quarantine (requires password)"
echo "  3. Set correct permissions"
echo ""

# Get the directory where this script is located (inside DMG)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DMG_APP="$SCRIPT_DIR/ZetaNotes.app"

# Check if app exists in DMG
if [ ! -d "$DMG_APP" ]; then
    echo "❌ Error: ZetaNotes.app not found in DMG"
    echo "   Expected at: $DMG_APP"
    exit 1
fi

echo "📦 Found ZetaNotes.app in DMG"
echo ""

# Check if already installed
if [ -d "/Applications/ZetaNotes.app" ]; then
    echo "⚠️  ZetaNotes is already installed."
    read -p "   Overwrite existing installation? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo "🗑️  Removing old version..."
    sudo rm -rf /Applications/ZetaNotes.app
fi

# Copy app to Applications
echo "📋 Copying ZetaNotes to Applications..."
sudo cp -R "$DMG_APP" /Applications/

# Remove quarantine
echo "🔓 Removing security quarantine (password required)..."
sudo xattr -cr /Applications/ZetaNotes.app

# Fix permissions
echo "🔧 Setting permissions..."
sudo chmod -R 755 /Applications/ZetaNotes.app
sudo chmod +x /Applications/ZetaNotes.app/Contents/MacOS/ZetaNotes

# Verify installation
if [ -x "/Applications/ZetaNotes.app/Contents/MacOS/ZetaNotes" ]; then
    echo ""
    echo "✅ Installation complete!"
    echo ""
    echo "You can now:"
    echo "  • Close this window"
    echo "  • Eject the ZetaNotes disk image"
    echo "  • Open ZetaNotes from your Applications folder"
    echo ""
    read -p "Press any key to exit..."
else
    echo ""
    echo "❌ Installation failed!"
    echo "   Please try manual installation:"
    echo "   1. Drag ZetaNotes to Applications"
    echo "   2. Run in Terminal: sudo xattr -cr /Applications/ZetaNotes.app"
    echo ""
    read -p "Press any key to exit..."
    exit 1
fi
