#!/bin/bash
#
# configure-xcode.sh
# Automatically configures Xcode build settings for llama.cpp integration
# Run this after setup-dev.sh completes
#

set -e

echo "🔧 Configuring Xcode Build Settings"
echo "===================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XCODE_PROJECT="$PROJECT_ROOT/NoteTaker.xcodeproj/project.pbxproj"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if project file exists
if [ ! -f "$XCODE_PROJECT" ]; then
    print_error "Xcode project not found at: $XCODE_PROJECT"
    exit 1
fi

print_status "Found Xcode project"

# Backup project file
cp "$XCODE_PROJECT" "$XCODE_PROJECT.backup"
print_status "Created backup: project.pbxproj.backup"

# Note: For dynamic libraries (.dylib), we need different settings
echo ""
print_warning "Configuring for dynamic library (.dylib)..."
echo ""

cat << 'EOF'

⚠️  IMPORTANT: Xcode Build Settings Configuration ⚠️

Since llama.cpp now builds dynamic libraries (.dylib), you need to configure:

1. Open NoteTaker.xcodeproj in Xcode
2. Select NoteTaker target → Build Settings
3. Add these settings:

   Bridging Header:
   $(SRCROOT)/NoteTaker/NoteTaker-Bridging-Header.h

   Header Search Paths:
   $(SRCROOT)/llama.cpp/include
   $(SRCROOT)/llama.cpp/ggml/include

   Library Search Paths:
   $(SRCROOT)/llama.cpp/build/bin

   Other Linker Flags:
   -Wl,-rpath,@executable_path/../Frameworks
   -Wl,-rpath,$(SRCROOT)/llama.cpp/build/bin
   -lllama
   -lggml
   -lc++

   Runpath Search Paths:
   @executable_path/../Frameworks
   @loader_path/../Frameworks
   $(SRCROOT)/llama.cpp/build/bin

4. Copy dynamic libraries to app bundle:
   - Go to Build Phases → New Copy Files Phase
   - Set Destination: Frameworks
   - Add these files from llama.cpp/build/bin/:
     * libllama.dylib
     * libggml.dylib
     * libggml-metal.dylib
     * libggml-cpu.dylib
     * libggml-base.dylib

Alternative: Use the commands below to modify project.pbxproj directly

EOF

echo ""
read -p "Do you want to see the manual pbxproj editing commands? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat << 'EOF'

# Manual pbxproj Editing Commands (Advanced)
# Use these if you're comfortable editing project files:

# Add bridging header
# Find the line with "SWIFT_OBJC_BRIDGING_HEADER" and update it

# Add header search paths
# Find "HEADER_SEARCH_PATHS" and add:
# "$(SRCROOT)/llama.cpp/include",
# "$(SRCROOT)/llama.cpp/ggml/include",

# Add library search paths
# Find "LIBRARY_SEARCH_PATHS" and add:
# "$(SRCROOT)/llama.cpp/build/bin",

# Add other linker flags
# Find "OTHER_LDFLAGS" and add:
# "-lllama",
# "-lggml",
# "-lc++",
# "-Wl,-rpath,@executable_path/../Frameworks",
# "-Wl,-rpath,$(SRCROOT)/llama.cpp/build/bin",

# Add runpath search paths
# Find "LD_RUNPATH_SEARCH_PATHS" and add:
# "@executable_path/../Frameworks",
# "@loader_path/../Frameworks",
# "$(SRCROOT)/llama.cpp/build/bin",

EOF
fi

echo ""
echo "================================"
echo -e "${GREEN}Next Steps:${NC}"
echo ""
echo "1. Open NoteTaker.xcodeproj in Xcode"
echo "2. Configure build settings (see above)"
echo "3. Add Copy Files Phase for dylibs"
echo "4. Build and run (Cmd+R)"
echo ""
echo "Or restore backup if needed:"
echo "  mv $XCODE_PROJECT.backup $XCODE_PROJECT"
echo ""
