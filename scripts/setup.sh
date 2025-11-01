#!/bin/bash

# QuicUI Development Setup Script
# This script sets up the development environment

set -e

echo "=================================="
echo "QuicUI Development Environment Setup"
echo "=================================="
echo ""

# Check Dart version
echo "Checking Dart SDK..."
if ! command -v dart &> /dev/null; then
    echo "ERROR: Dart SDK not found. Please install Flutter/Dart SDK."
    exit 1
fi

DART_VERSION=$(dart --version 2>&1 | awk '{print $2}')
echo "✓ Dart SDK version: $DART_VERSION"
echo ""

# Create necessary directories
echo "Creating directory structure..."
mkdir -p packages
mkdir -p forks
mkdir -p infrastructure
mkdir -p docs
mkdir -p scripts
echo "✓ Directories created"
echo ""

# Get root dependencies
echo "Setting up root workspace dependencies..."
dart pub get
echo "✓ Root dependencies installed"
echo ""

# Setup packages
PACKAGES=("quicui_code_push_client" "quicui_cli" "quicui_compiler" "quicui_backend")

for package in "${PACKAGES[@]}"; do
    if [ -d "packages/$package" ]; then
        echo "Installing dependencies for $package..."
        cd "packages/$package"
        dart pub get
        cd ../..
        echo "✓ $package ready"
    fi
done
echo ""

echo "=================================="
echo "✅ Setup complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Read PROJECT_SUMMARY.md for an overview"
echo "2. Read QUICUI_IMPLEMENTATION_PLAN.md for detailed plan"
echo "3. Check docs/ directory for detailed documentation"
echo "4. Run: ./scripts/test.sh to verify setup"
echo ""
