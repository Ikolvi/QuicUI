#!/bin/bash
# QuicUI Backend Load Testing Script
# Runs comprehensive performance benchmarks against the backend

set -e

BACKEND_URL="${1:-http://localhost:8080}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/../.."

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║    QuicUI Backend Load Testing - Performance Benchmarks         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if backend is running
echo "🔍 Checking backend at: $BACKEND_URL"
if ! curl -s "$BACKEND_URL/health" > /dev/null; then
    echo "❌ Backend not running at $BACKEND_URL"
    echo "   Please start the backend with: dart run lib/quicui_backend.dart"
    exit 1
fi
echo "✅ Backend is running"
echo ""

# Run load tests
echo "🚀 Running load tests..."
cd "$BACKEND_DIR"

export BACKEND_URL="$BACKEND_URL"
dart run lib/src/load_test_client.dart

echo ""
echo "✅ Load testing complete!"
