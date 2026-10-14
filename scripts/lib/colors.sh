#!/bin/bash
# Output colors and formatting

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

print_step() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_banner() {
    local version="$1"
    local environment="$2"

    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      ZetaNotes Release Builder v5.0          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Version:${NC} ${version}"
    echo -e "${GREEN}Environment:${NC} ${environment}"
    echo ""
}
