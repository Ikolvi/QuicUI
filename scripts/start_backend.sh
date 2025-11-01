#!/bin/bash

# QuicUI Code Push - Backend Server Only
# Starts the backend server for local patch testing
# Runs at http://localhost:8080

set -e

# Configuration
BACKEND_DIR="/Users/admin/Documents/quicui2/packages/quicui_backend"
BACKEND_HOST="${SERVER_HOST:-0.0.0.0}"
BACKEND_PORT="${SERVER_PORT:-8080}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
log_step() {
    echo -e "${BLUE}>>> $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║     QuicUI Code Push - Backend Server                ║"
echo "║                                                        ║"
echo "║     Local Development & Testing                       ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Date: $(date)"
echo ""

# Check directory
if [ ! -d "$BACKEND_DIR" ]; then
    log_error "Backend directory not found: $BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"
log_success "Working directory: $BACKEND_DIR"

# Get dependencies
log_step "Step 1: Prepare Backend"
log_info "Installing dependencies..."
dart pub get
log_success "Dependencies installed"

# Start server
log_step "Step 2: Start Backend Server"
echo ""
log_info "Server Configuration:"
echo "  Host: $BACKEND_HOST"
echo "  Port: $BACKEND_PORT"
echo "  URLs:"
echo "    - Health: http://localhost:$BACKEND_PORT/health"
echo "    - Metrics: http://localhost:$BACKEND_PORT/metrics/json"
echo "    - API: http://localhost:$BACKEND_PORT/api/v1"
echo ""
log_info "Starting server..."
echo ""

export SERVER_HOST="$BACKEND_HOST"
export SERVER_PORT="$BACKEND_PORT"

dart run lib/quicui_backend.dart

# If we get here, server stopped
log_warning "Server stopped"
