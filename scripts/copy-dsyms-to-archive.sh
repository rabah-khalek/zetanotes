#!/bin/bash
# Copy dSYM files from llama.cpp build to Xcode archive
# This script should be run as a "Run Script" build phase in Xcode AFTER the CopyFiles phase
# Only runs during archiving (not regular builds)

# Only run during archive builds
if [ "$ACTION" != "install" ]; then
    echo "Not an archive build, skipping dSYM copy"
    exit 0
fi

echo "Copying llama.cpp dSYM files to archive..."

LLAMA_BUILD_DIR="${SRCROOT}/llama.cpp/build/bin"

if [ ! -d "$LLAMA_BUILD_DIR" ]; then
    echo " Warning: llama.cpp build directory not found at: $LLAMA_BUILD_DIR"
    exit 0
fi

# The DWARF_DSYM_FOLDER_PATH is set by Xcode during archiving
if [ -z "$DWARF_DSYM_FOLDER_PATH" ]; then
    echo " Warning: DWARF_DSYM_FOLDER_PATH not set"
    exit 0
fi

mkdir -p "$DWARF_DSYM_FOLDER_PATH"

# Copy all dSYM files
DSYM_COUNT=0
for dsym in "$LLAMA_BUILD_DIR"/*.dSYM; do
    if [ -d "$dsym" ]; then
        dsym_name=$(basename "$dsym")
        echo "  Copying: $dsym_name"
        cp -R "$dsym" "$DWARF_DSYM_FOLDER_PATH/"
        DSYM_COUNT=$((DSYM_COUNT + 1))
    fi
done

if [ $DSYM_COUNT -eq 0 ]; then
    echo " Warning: No dSYM files found in $LLAMA_BUILD_DIR"
    echo "   Run ./scripts/build-llama.sh to generate them"
else
    echo "Copied $DSYM_COUNT dSYM files to archive"
fi
