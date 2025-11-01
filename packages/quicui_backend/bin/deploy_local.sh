#!/bin/bash

# QuicUI Code Push - Local Deployment Script
# This script sets up and starts the backend locally for development

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../.."
BACKEND_DIR="$PROJECT_ROOT/packages/quicui_backend"

echo "🚀 QuicUI Code Push - Local Deployment"
echo "======================================"
echo ""

# Step 1: Check Dart installation
echo "📋 Step 1: Checking Dart SDK..."
if ! command -v dart &> /dev/null; then
    echo "❌ Dart SDK not found. Please install Dart 3.0+"
    echo "   https://dart.dev/get-dart"
    exit 1
fi
DART_VERSION=$(dart --version 2>&1 | awk '{print $3}')
echo "✅ Dart $DART_VERSION installed"
echo ""

# Step 2: Check PostgreSQL
echo "📋 Step 2: Checking PostgreSQL..."
if ! command -v psql &> /dev/null; then
    echo "⚠️ PostgreSQL not found on PATH"
    echo "   Install PostgreSQL or set up a Docker database:"
    echo "   docker run -d --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:15"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ PostgreSQL installed"
fi
echo ""

# Step 3: Navigate to backend directory
echo "📋 Step 3: Navigating to backend..."
cd "$BACKEND_DIR"
echo "✅ Working directory: $PWD"
echo ""

# Step 4: Load environment variables
echo "📋 Step 4: Loading environment configuration..."
if [ -f ".env.local" ]; then
    set -a
    source .env.local
    set +a
    echo "✅ Loaded .env.local"
else
    echo "⚠️ .env.local not found, using defaults"
fi
echo ""

# Step 5: Get dependencies
echo "📋 Step 5: Getting Dart dependencies..."
dart pub get
echo "✅ Dependencies installed"
echo ""

# Step 6: Verify configuration
echo "📋 Step 6: Verifying security configuration..."
echo "   Running: dart run bin/verify_security_config.dart"
echo ""
dart run bin/verify_security_config.dart
VERIFY_EXIT=$?
echo ""

if [ $VERIFY_EXIT -ne 0 ]; then
    echo "⚠️ Configuration verification found critical issues"
    echo "   Address the issues above and try again"
    exit 1
fi

# Step 7: Run tests (optional)
echo "📋 Step 7: Running tests..."
read -p "Run test suite before starting? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧪 Running tests..."
    dart test --reporter=compact
    echo "✅ Tests passed"
fi
echo ""

# Step 8: Start backend
echo "📋 Step 8: Starting backend server..."
echo ""
echo "=========================================="
echo "🚀 Backend is starting..."
echo "📡 Host: 0.0.0.0"
echo "🔌 Port: ${SERVER_PORT:-8080}"
echo "🌐 Protocol: ${QUICUI_ENVIRONMENT:-development} mode"
echo "📍 Origins: $QUICUI_ALLOWED_ORIGINS"
echo "📊 Database: $DATABASE_HOST:${DATABASE_PORT:-5432}/$DATABASE_NAME"
echo ""
echo "🔒 Security Status:"
echo "   HTTPS: $([ "$QUICUI_ENVIRONMENT" = "production" ] && echo "✅ ENFORCED" || echo "⚠️ DISABLED (dev mode)")"
echo "   CORS: ✅ Configured"
echo "   Headers: ✅ Enabled"
echo ""
echo "📚 Endpoints:"
echo "   Health: GET http://localhost:${SERVER_PORT:-8080}/health"
echo "   API: http://localhost:${SERVER_PORT:-8080}/api/v1/"
echo ""
echo "💡 To stop the server: Press Ctrl+C"
echo "=========================================="
echo ""

# Start the backend
dart run

# Cleanup on exit
echo ""
echo "🛑 Backend stopped"
