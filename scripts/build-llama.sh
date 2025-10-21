#!/bin/bash
#
# build-llama.sh
# Automatically builds llama.cpp as part of Xcode build process
# This script is called from an Xcode "Run Script" build phase
#

set -e  # Exit on error

LLAMA_DIR="${SRCROOT}/llama.cpp"
BUILD_DIR="${LLAMA_DIR}/build"
LIB_PATH="${BUILD_DIR}/bin/libllama.dylib"

echo "🔨 Checking llama.cpp build status..."

# Check if llama.cpp directory exists
if [ ! -d "$LLAMA_DIR" ]; then
    echo "📥 Cloning llama.cpp..."
    cd "${SRCROOT}"
    git clone --depth 1 https://github.com/ggerganov/llama.cpp.git
else
    # Check if library already built
    if [ -f "$LIB_PATH" ]; then
        echo "✅ llama.cpp already built at: $LIB_PATH"
        exit 0
    fi
fi

echo "🔨 Building llama.cpp with Metal support..."

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake - build shared libraries for macOS
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_METAL=ON \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0

# Build library
cmake --build . --config Release -j 8

# Verify build
if [ -f "$LIB_PATH" ]; then
    echo "✅ llama.cpp built successfully!"
    echo "📦 Library: $LIB_PATH"
    ls -lh "$LIB_PATH"

    # List all built libraries
    echo ""
    echo "📦 All built libraries:"
    ls -lh "${BUILD_DIR}/bin/"*.dylib 2>/dev/null || true

    # Code sign all dynamic libraries with hardened runtime
    echo ""
    echo "🔐 Code signing libraries with hardened runtime..."

    # Determine signing identity - ALWAYS use Developer ID for notarization
    if [ -n "$GITHUB_ACTIONS" ]; then
        SIGNING_IDENTITY="Developer ID Application"
    elif security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        # Use Developer ID Application certificate (required for notarization)
        SIGNING_IDENTITY="Developer ID Application: Rabah Abdul Khalek (HDA4C6CU89)"
    else
        echo "❌ ERROR: Developer ID Application certificate not found!"
        echo "   Notarization requires a Developer ID Application certificate."
        echo "   Available certificates:"
        security find-identity -v -p codesigning
        exit 1
    fi

    echo "Using signing identity: $SIGNING_IDENTITY"

    for dylib in "${BUILD_DIR}/bin/"*.dylib; do
        if [ -f "$dylib" ]; then
            echo "  Signing: $(basename "$dylib")"
            codesign --force --sign "$SIGNING_IDENTITY" \
                --options runtime \
                --timestamp \
                "$dylib" || {
                echo "❌ ERROR: Failed to sign $(basename "$dylib")"
                echo "   All libraries must be properly signed for notarization."
                exit 1
            }
        fi
    done

    echo "✅ All libraries signed with Developer ID"
else
    echo "❌ Build failed: libllama.dylib not found"
    echo "Expected location: $LIB_PATH"
    echo ""
    echo "Contents of build directory:"
    find "${BUILD_DIR}" -name "*.dylib" -o -name "*.a" 2>/dev/null || true
    exit 1
fi
