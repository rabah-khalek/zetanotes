#!/bin/bash

# Auto-rebuild and run NoteTaker in debug mode when files change
# Uses fswatch to monitor for changes

set -e  # Exit on error

PROJECT_DIR="/Users/projects/Documents/notetaker"
PROJECT_NAME="NoteTaker"
SCHEME="NoteTaker"
APP_PID=""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup function to kill all processes
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Shutting down...${NC}"

    # Kill the app if running
    if [ -n "$APP_PID" ] && kill -0 "$APP_PID" 2>/dev/null; then
        echo -e "${YELLOW}Stopping app (PID: $APP_PID)${NC}"
        kill "$APP_PID" 2>/dev/null || true
    fi

    # Kill any remaining NoteTaker processes
    killall "$PROJECT_NAME" 2>/dev/null || true

    echo -e "${GREEN}✓ Cleanup complete${NC}"
    exit 0
}

# Trap Ctrl+C and call cleanup
trap cleanup SIGINT SIGTERM

echo -e "${BLUE}🔍 Starting watch mode for $PROJECT_NAME${NC}"
echo -e "${BLUE}📂 Watching: $PROJECT_DIR/NoteTaker${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Function to build and run
build_and_run() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔄 Changes detected at $(date '+%H:%M:%S')${NC}"
    echo -e "${BLUE}🔨 Building $PROJECT_NAME...${NC}"

    # Kill existing instance
    if [ -n "$APP_PID" ] && kill -0 "$APP_PID" 2>/dev/null; then
        echo -e "${YELLOW}🛑 Stopping previous instance (PID: $APP_PID)${NC}"
        kill "$APP_PID" 2>/dev/null || true
        wait "$APP_PID" 2>/dev/null || true
    fi
    killall "$PROJECT_NAME" 2>/dev/null || true

    # Build the project and capture output
    cd "$PROJECT_DIR"

    BUILD_OUTPUT=$(mktemp)

    # Run build and capture exit code
    xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
               -scheme "$SCHEME" \
               -configuration Debug \
               build 2>&1 | tee "$BUILD_OUTPUT"
    BUILD_EXIT_CODE=${PIPESTATUS[0]}

    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✅ Build succeeded!${NC}"

        # Show warnings if any
        if grep -q "warning:" "$BUILD_OUTPUT"; then
            echo -e "${YELLOW}⚠️  Warnings:${NC}"
            grep "warning:" "$BUILD_OUTPUT" | head -5
            echo ""
        fi

        rm "$BUILD_OUTPUT"

        # Find the Debug build directory
        DEBUG_DIR=$(find ~/Library/Developer/Xcode/DerivedData/${PROJECT_NAME}-* \
                    -name "Debug" -type d 2>/dev/null | head -1)

        if [ -z "$DEBUG_DIR" ]; then
            echo -e "${RED}❌ Could not find Debug build directory${NC}"
            return 1
        fi

        # Run the app in debug mode (foreground)
        echo -e "${GREEN}🚀 Launching $PROJECT_NAME in debug mode...${NC}"
        echo -e "${BLUE}📋 Debug output:${NC}"
        echo -e "${YELLOW}────────────────────────────────────────${NC}"

        # Run using 'open' to properly launch the app GUI
        cd "$DEBUG_DIR"
        open -a "${PROJECT_NAME}.app" --stdout "$(tty)" --stderr "$(tty)" &

        APP_PID=$!
        echo -e "${GREEN}✓ App launched${NC}"
        echo ""
    else
        echo -e "${RED}❌ Build failed${NC}"
        echo ""
        echo -e "${RED}Build Errors:${NC}"
        echo -e "${YELLOW}────────────────────────────────────────${NC}"

        # Show comprehensive error information
        grep -iE "error\s*:|fatal|undefined|clang: error|ld: " "$BUILD_OUTPUT" | \
            grep -v "0 errors" | \
            head -30

        echo -e "${YELLOW}────────────────────────────────────────${NC}"
        echo ""
        rm "$BUILD_OUTPUT"
        return 1
    fi
}

# Initial build
build_and_run

# Watch for changes
fswatch -o "$PROJECT_DIR/NoteTaker" \
        --exclude '.*\.DS_Store' \
        --exclude '.*/\..*' \
        --exclude '.*~' \
        --exclude '.*/DerivedData/.*' \
        --exclude '.*/build/.*' | while read num_changes; do
    build_and_run
done
