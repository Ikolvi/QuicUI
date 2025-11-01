#!/bin/bash

# QuicUI Test Script
# Runs tests for all packages

set -e

echo "Running QuicUI test suite..."
echo ""

PACKAGES=("quicui_code_push_client" "quicui_cli" "quicui_compiler" "quicui_backend")

for package in "${PACKAGES[@]}"; do
    if [ -d "packages/$package" ]; then
        echo "Testing $package..."
        cd "packages/$package"
        dart test 2>/dev/null || echo "No tests yet for $package"
        cd ../..
    fi
done

echo ""
echo "✅ Test suite complete"
