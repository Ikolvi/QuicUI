#!/bin/bash

# QuicUI Backend - Pre-Deployment Verification Checklist
# This script verifies everything is ready for local deployment

echo "╔════════════════════════════════════════════════════════╗"
echo "║  QuicUI Backend - Deployment Readiness Check          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

BACKEND_DIR="/Users/admin/Documents/quicui2/packages/quicui_backend"
PROJECT_ROOT="/Users/admin/Documents/quicui2"

# Counter for checks
PASSED=0
FAILED=0
WARNING=0

check_pass() {
  echo "✅ $1"
  ((PASSED++))
}

check_fail() {
  echo "❌ $1"
  ((FAILED++))
}

check_warn() {
  echo "⚠️  $1"
  ((WARNING++))
}

echo "1️⃣  Environment Checks"
echo "─────────────────────────────────────────────────────────"

# Check Dart
if command -v dart &> /dev/null; then
  DART_VERSION=$(dart --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
  check_pass "Dart found: $DART_VERSION"
else
  check_fail "Dart not found (required)"
fi

# Check Git
if command -v git &> /dev/null; then
  check_pass "Git found"
else
  check_fail "Git not found (optional)"
fi

# Check Docker
if command -v docker &> /dev/null; then
  DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
  check_pass "Docker found: $DOCKER_VERSION"
else
  check_warn "Docker not found (optional, for database)"
fi

echo ""
echo "2️⃣  Backend Code Structure"
echo "─────────────────────────────────────────────────────────"

# Check pubspec
if [ -f "$BACKEND_DIR/pubspec.yaml" ]; then
  check_pass "pubspec.yaml found"
else
  check_fail "pubspec.yaml not found"
fi

# Check main entry point
if [ -f "$BACKEND_DIR/bin/server.dart" ]; then
  check_pass "bin/server.dart found"
else
  check_fail "bin/server.dart not found"
fi

# Check security config
if [ -f "$BACKEND_DIR/lib/src/security_config.dart" ]; then
  check_pass "security_config.dart found"
else
  check_fail "security_config.dart not found"
fi

# Check test directory
if [ -d "$BACKEND_DIR/test" ] && [ "$(ls -A $BACKEND_DIR/test)" ]; then
  TEST_COUNT=$(find "$BACKEND_DIR/test" -name "*_test.dart" | wc -l)
  check_pass "Test suite found ($TEST_COUNT test files)"
else
  check_warn "Test directory empty or missing"
fi

echo ""
echo "3️⃣  Deployment Configuration"
echo "─────────────────────────────────────────────────────────"

# Check .env.local
if [ -f "$BACKEND_DIR/.env.local" ]; then
  check_pass ".env.local found"
  if grep -q "QUICUI_ENVIRONMENT=development" "$BACKEND_DIR/.env.local"; then
    check_pass "Environment set to development"
  else
    check_warn ".env.local not configured for development"
  fi
else
  check_warn ".env.local not found (will be created)"
fi

# Check .env.example
if [ -f "$BACKEND_DIR/.env.example" ]; then
  check_pass ".env.example found"
else
  check_warn ".env.example not found"
fi

echo ""
echo "4️⃣  Deployment Scripts"
echo "─────────────────────────────────────────────────────────"

# Check local deployment script
if [ -f "$BACKEND_DIR/bin/deploy_local.sh" ]; then
  check_pass "bin/deploy_local.sh found"
  if [ -x "$BACKEND_DIR/bin/deploy_local.sh" ]; then
    check_pass "bin/deploy_local.sh is executable"
  else
    check_warn "bin/deploy_local.sh not executable"
  fi
else
  check_warn "bin/deploy_local.sh not found"
fi

# Check root deployment script
if [ -f "$PROJECT_ROOT/local_deploy.sh" ]; then
  check_pass "local_deploy.sh found (root)"
  if [ -x "$PROJECT_ROOT/local_deploy.sh" ]; then
    check_pass "local_deploy.sh is executable"
  else
    check_warn "local_deploy.sh not executable"
  fi
else
  check_warn "local_deploy.sh not found (root)"
fi

echo ""
echo "5️⃣  Documentation"
echo "─────────────────────────────────────────────────────────"

DOCS=(
  "docs/LOCAL_DEPLOYMENT.md:Quick Start Guide"
  "docs/LOCAL_DEPLOYMENT_SUMMARY.md:Deployment Summary"
  "docs/DEPLOYMENT_GUIDE.md:Full Deployment Guide"
  "docs/PHASE_5_1B_COMPLETION.md:Security Details"
  "LOCAL_DEPLOYMENT_INSTRUCTIONS.md:Step-by-Step Instructions"
)

for doc_info in "${DOCS[@]}"; do
  IFS=':' read -r doc_path doc_name <<< "$doc_info"
  if [ -f "$PROJECT_ROOT/$doc_path" ]; then
    check_pass "$doc_name found"
  else
    check_warn "$doc_name not found"
  fi
done

echo ""
echo "6️⃣  Git Status"
echo "─────────────────────────────────────────────────────────"

# Check if in git repo
if [ -d "$PROJECT_ROOT/.git" ]; then
  check_pass "Git repository found"
  
  # Check git status
  cd "$PROJECT_ROOT"
  if git status &> /dev/null; then
    check_pass "Git working directory clean"
    
    # Get last commits
    LAST_COMMIT=$(git rev-parse --short HEAD)
    check_pass "Last commit: $LAST_COMMIT"
  else
    check_warn "Git status check failed"
  fi
else
  check_warn "Not a git repository"
fi

echo ""
echo "7️⃣  Quick Deployment Test"
echo "─────────────────────────────────────────────────────────"

# Test dart pub dry-run
if command -v dart &> /dev/null; then
  cd "$BACKEND_DIR"
  if dart pub get --dry-run &> /dev/null; then
    check_pass "Dependencies check successful"
  else
    check_warn "Could not verify dependencies"
  fi
else
  check_warn "Cannot test dependencies (dart not found)"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "                    RESULTS SUMMARY"
echo "════════════════════════════════════════════════════════"
echo ""
echo "✅ Passed:   $PASSED"
echo "❌ Failed:   $FAILED"
echo "⚠️  Warnings: $WARNING"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "🎉 All checks passed! Backend is ready for deployment."
  echo ""
  echo "Next steps:"
  echo "1. Start PostgreSQL (optional):"
  echo "   docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15"
  echo ""
  echo "2. Deploy the backend:"
  echo "   bash $PROJECT_ROOT/local_deploy.sh"
  echo ""
  echo "3. Test the deployment:"
  echo "   curl http://localhost:8080/health"
  echo ""
  exit 0
else
  echo "⚠️  Some checks failed. Please review above."
  exit 1
fi
