#!/bin/zsh

# Run from the repository root regardless of the current directory
cd "$(dirname "$0")/.." || exit 1

# Build ZetaNotes and show summary of errors/warnings
# This script builds the project and filters output to show only errors, warnings, and build status

xcodebuild -project ZetaNotes.xcodeproj -scheme ZetaNotes build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | head -20
