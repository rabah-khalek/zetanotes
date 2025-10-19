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
fi

# Check if library already built
if [ -f "$LIB_PATH" ]; then
    echo "✅ llama.cpp already built at: $LIB_PATH"
    exit 0
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
    -DLLAMA_BUILD_SERVER=OFF

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
else
    echo "❌ Build failed: libllama.dylib not found"
    echo "Expected location: $LIB_PATH"
    echo ""
    echo "Contents of build directory:"
    find "${BUILD_DIR}" -name "*.dylib" -o -name "*.a" 2>/dev/null || true
    exit 1
fi
