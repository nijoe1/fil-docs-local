#!/bin/bash
#
# Gitbook Build Script
# Handles Node.js version management for legacy gitbook-cli compatibility
#
# Usage:
#   ./build.sh         - Build the gitbook
#   ./build.sh serve   - Build and serve on port 4003
#   ./build.sh serve 8080  - Build and serve on custom port
#

set -e

REQUIRED_NODE_VERSION="10"
DEFAULT_PORT="4003"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if nvm is available
check_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
        return 0
    elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
        # Homebrew installation on macOS
        . "/usr/local/opt/nvm/nvm.sh"
        return 0
    elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
        # Homebrew on Apple Silicon
        . "/opt/homebrew/opt/nvm/nvm.sh"
        return 0
    else
        return 1
    fi
}

# Get current Node.js major version
get_node_major_version() {
    if command -v node &> /dev/null; then
        node -v | cut -d'.' -f1 | tr -d 'v'
    else
        echo "0"
    fi
}

# Store current Node version before switching
ORIGINAL_NODE_VERSION=""

save_current_node_version() {
    if command -v node &> /dev/null; then
        ORIGINAL_NODE_VERSION=$(node -v)
        log_info "Current Node.js version: $ORIGINAL_NODE_VERSION"
    fi
}

restore_node_version() {
    if [ -n "$ORIGINAL_NODE_VERSION" ] && [ "$ORIGINAL_NODE_VERSION" != "v${REQUIRED_NODE_VERSION}"* ]; then
        log_info "Restoring original Node.js version: $ORIGINAL_NODE_VERSION"
        if check_nvm; then
            nvm use "${ORIGINAL_NODE_VERSION}" &> /dev/null || true
        fi
    fi
}

# Setup trap to restore Node version on exit
cleanup() {
    restore_node_version
}
trap cleanup EXIT

# Main version check and switch logic
setup_node_version() {
    local current_version=$(get_node_major_version)

    if [ "$current_version" = "$REQUIRED_NODE_VERSION" ]; then
        log_success "Node.js v${REQUIRED_NODE_VERSION} is already active"
        return 0
    fi

    log_warn "Gitbook-cli requires Node.js v${REQUIRED_NODE_VERSION}.x (current: v${current_version})"

    if ! check_nvm; then
        log_error "nvm is not installed. Please install nvm first:"
        echo ""
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo ""
        echo "Or install Node.js v${REQUIRED_NODE_VERSION} manually."
        exit 1
    fi

    # List available Node versions
    log_info "Checking available Node.js versions..."
    local available_versions=$(nvm ls 2>/dev/null | grep -o "v${REQUIRED_NODE_VERSION}\.[0-9.]*" | head -5)

    if [ -n "$available_versions" ]; then
        log_info "Available Node.js v${REQUIRED_NODE_VERSION}.x versions:"
        echo "$available_versions" | while read -r v; do
            echo "    - $v"
        done
    fi

    # Check if required version is installed
    if nvm ls "${REQUIRED_NODE_VERSION}" &> /dev/null; then
        log_info "Switching to Node.js v${REQUIRED_NODE_VERSION}..."
        nvm use "${REQUIRED_NODE_VERSION}"
    else
        log_warn "Node.js v${REQUIRED_NODE_VERSION} is not installed"
        log_info "Installing Node.js v${REQUIRED_NODE_VERSION}..."
        nvm install "${REQUIRED_NODE_VERSION}"
        nvm use "${REQUIRED_NODE_VERSION}"
    fi

    log_success "Now using Node.js $(node -v)"
}

# Check if gitbook-cli is installed
check_gitbook() {
    if ! command -v gitbook &> /dev/null; then
        log_warn "gitbook-cli is not installed globally"
        log_info "Installing gitbook-cli..."
        npm install -g gitbook-cli
    fi

    # Install gitbook plugins if needed
    if [ ! -d "node_modules/gitbook-plugin-tabs" ]; then
        log_info "Installing gitbook plugins..."
        npm install
    fi
}

# Build gitbook
build_gitbook() {
    log_info "Building gitbook..."
    gitbook build .
    log_success "Build completed successfully!"
}

# Kill any existing gitbook servers
kill_existing_servers() {
    local port="${1:-$DEFAULT_PORT}"
    local livereload_port="35729"

    # Kill process on livereload port (gitbook's live reload server)
    if lsof -ti:"$livereload_port" &> /dev/null; then
        log_warn "Killing existing livereload server on port $livereload_port..."
        lsof -ti:"$livereload_port" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi

    # Kill process on the specified port
    if lsof -ti:"$port" &> /dev/null; then
        log_warn "Killing existing server on port $port..."
        lsof -ti:"$port" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

# Serve gitbook
serve_gitbook() {
    local port="${1:-$DEFAULT_PORT}"

    # Kill any existing servers first
    kill_existing_servers "$port"

    log_info "Starting gitbook server on port $port..."
    log_info "Press Ctrl+C to stop the server"
    echo ""
    gitbook serve . --port "$port"
}

# Main script
main() {
    local command="${1:-build}"
    local port="${2:-$DEFAULT_PORT}"

    echo ""
    echo "========================================"
    echo "  Filecoin Docs - Gitbook Build Script"
    echo "========================================"
    echo ""

    # Save current Node version
    save_current_node_version

    # Setup correct Node version
    setup_node_version

    # Check gitbook installation
    check_gitbook

    case "$command" in
        build)
            build_gitbook
            ;;
        serve)
            build_gitbook
            serve_gitbook "$port"
            ;;
        serve-only)
            serve_gitbook "$port"
            ;;
        stop)
            log_info "Stopping any running gitbook servers..."
            kill_existing_servers "$port"
            log_success "Servers stopped"
            ;;
        *)
            echo "Usage: $0 [build|serve|serve-only|stop] [port]"
            echo ""
            echo "Commands:"
            echo "  build       - Build the gitbook (default)"
            echo "  serve       - Build and serve the gitbook"
            echo "  serve-only  - Serve without rebuilding"
            echo "  stop        - Stop any running gitbook servers"
            echo ""
            echo "Options:"
            echo "  port        - Port number for serve (default: $DEFAULT_PORT)"
            exit 1
            ;;
    esac
}

main "$@"
