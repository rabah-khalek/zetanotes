#!/bin/bash
#
# setup-dev.sh
# One-command setup for ZetaNotes development environment
# Run this once to set up everything needed for development
#

set -e  # Exit on error

echo "🚀 ZetaNotes Development Setup"
echo "================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LLAMA_DIR="$PROJECT_ROOT/llama.cpp"
MODEL_DIR="$HOME/Library/Application Support/ZetaNotes/Models"
MODEL_FILE="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/$MODEL_FILE"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Initialize Homebrew environment if available
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Step 1: Check prerequisites
echo "📋 Step 1/5: Checking prerequisites..."
echo ""

# Check for Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    print_error "Xcode Command Line Tools not found"
    echo "   Install with: xcode-select --install"
    exit 1
fi
print_status "Xcode Command Line Tools installed"

# Check for CMake
if ! command -v cmake &> /dev/null; then
    print_warning "CMake not found. Installing via Homebrew..."

    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not found. Install it first:"
        echo '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo ""
        echo "   After installation, run this script again."
        exit 1
    fi

    brew install cmake
fi
print_status "CMake installed: $(cmake --version | head -n1)"# Check for Git
if ! command -v git &> /dev/null; then
    print_error "Git not found. Install Xcode Command Line Tools."
    exit 1
fi
print_status "Git installed: $(git --version)"

echo ""

# Step 2: Clone and build llama.cpp
echo "📦 Step 2/5: Setting up llama.cpp..."
echo ""

# Check if llama.cpp exists and if it needs rebuilding
BUILD_DIR="$LLAMA_DIR/build"
STATIC_LIB="$BUILD_DIR/src/libllama.a"
DYNAMIC_LIB="$BUILD_DIR/bin/libllama.dylib"

if [ -d "$LLAMA_DIR" ] && [ -d "$BUILD_DIR" ]; then
    # Check if build is complete
    if [ ! -f "$STATIC_LIB" ] && [ ! -f "$DYNAMIC_LIB" ]; then
        print_warning "Found incomplete llama.cpp build. Cleaning and rebuilding..."
        rm -rf "$BUILD_DIR"
    fi
fi

if [ ! -d "$LLAMA_DIR" ]; then
    print_warning "Cloning llama.cpp..."
    cd "$PROJECT_ROOT"
    git clone --depth 1 https://github.com/ggerganov/llama.cpp.git
    print_status "llama.cpp cloned"
else
    print_status "llama.cpp already cloned"
fi

# Check if we need to build
if [ -f "$STATIC_LIB" ] || [ -f "$DYNAMIC_LIB" ]; then
    print_status "llama.cpp already built"
    [ -f "$STATIC_LIB" ] && echo "   Found: $STATIC_LIB"
    [ -f "$DYNAMIC_LIB" ] && echo "   Found: $DYNAMIC_LIB"
else
    print_warning "Building llama.cpp (this may take 2-3 minutes)..."

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Configure with CMake (use GGML_METAL instead of deprecated LLAMA_METAL)
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_METAL=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DLLAMA_BUILD_EXAMPLES=OFF \
        -DLLAMA_BUILD_TESTS=OFF \
        -DLLAMA_BUILD_SERVER=OFF

    # Build (use all CPU cores)
    cmake --build . --config Release --target llama -j $(sysctl -n hw.ncpu)

    # Verify build - check for either static or dynamic library
    if [ -f "$STATIC_LIB" ]; then
        print_status "llama.cpp built successfully (static library)"
        echo "   Library: $STATIC_LIB ($(du -h "$STATIC_LIB" | cut -f1))"
    elif [ -f "$DYNAMIC_LIB" ]; then
        print_status "llama.cpp built successfully (dynamic library)"
        echo "   Library: $DYNAMIC_LIB ($(du -h "$DYNAMIC_LIB" | cut -f1))"
    else
        print_error "Build failed: Neither libllama.a nor libllama.dylib found"
        exit 1
    fi
fi

echo ""

# Step 3: Create bridging header
echo "🔗 Step 3/5: Setting up Swift-C++ bridge..."
echo ""

BRIDGING_HEADER="$PROJECT_ROOT/ZetaNotes/ZetaNotes-Bridging-Header.h"

if [ -f "$BRIDGING_HEADER" ]; then
    print_status "Bridging header already exists"
else
    cat > "$BRIDGING_HEADER" << 'EOF'
//
//  ZetaNotes-Bridging-Header.h
//  Bridge between Swift and llama.cpp C API
//

#ifndef ZetaNotes_Bridging_Header_h
#define ZetaNotes_Bridging_Header_h

// Include llama.cpp public API
#include "llama.h"

#endif /* ZetaNotes_Bridging_Header_h */
EOF
    print_status "Bridging header created"
fi

echo ""

# Step 4: Download AI model
echo "🤖 Step 4/5: Downloading AI model..."
echo ""

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
    MODEL_SIZE=$(du -h "$MODEL_DIR/$MODEL_FILE" | cut -f1)
    print_status "Model already downloaded ($MODEL_SIZE)"
else
    print_warning "Downloading TinyLlama model (~669MB, may take 2-5 minutes)..."
    echo "   From: $MODEL_URL"
    echo "   To: $MODEL_DIR/"
    echo ""

    # Download with progress bar
    if command -v wget &> /dev/null; then
        wget -O "$MODEL_DIR/$MODEL_FILE" "$MODEL_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o "$MODEL_DIR/$MODEL_FILE" "$MODEL_URL"
    else
        print_error "Neither wget nor curl found. Install one of them."
        exit 1
    fi

    if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
        MODEL_SIZE=$(du -h "$MODEL_DIR/$MODEL_FILE" | cut -f1)
        print_status "Model downloaded successfully ($MODEL_SIZE)"
    else
        print_error "Model download failed"
        exit 1
    fi
fi

echo ""

# Step 5: Verify setup
echo "✅ Step 5/5: Verifying setup..."
echo ""

# Check all components
CHECKS_PASSED=true

# Check for llama library (either static or dynamic)
if [ -f "$STATIC_LIB" ] || [ -f "$DYNAMIC_LIB" ]; then
    print_status "llama.cpp library: OK"
    [ -f "$STATIC_LIB" ] && echo "   Type: Static (.a)"
    [ -f "$DYNAMIC_LIB" ] && echo "   Type: Dynamic (.dylib)"
else
    print_error "llama.cpp library: MISSING"
    CHECKS_PASSED=false
fi

if [ -f "$BRIDGING_HEADER" ]; then
    print_status "Bridging header: OK"
else
    print_error "Bridging header: MISSING"
    CHECKS_PASSED=false
fi

if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
    print_status "AI model: OK"
else
    print_error "AI model: MISSING"
    CHECKS_PASSED=false
fi

echo ""
echo "================================"

if [ "$CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✨ Setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Open ZetaNotes.xcodeproj in Xcode"
    echo ""
    echo "2. Build and run (Cmd+R)"
    echo ""
    echo "📖 Full integration guide: LLAMA_CPP_INTEGRATION.md"
else
    echo -e "${RED}⚠️  Setup incomplete - please check errors above${NC}"
    exit 1
fi
