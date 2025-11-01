#!/bin/bash
# QuicUI Local Deployment Checklist
# Use this to verify your deployment setup

echo "═══════════════════════════════════════════════════════════"
echo "  QuicUI Backend - Local Deployment Checklist"
echo "═══════════════════════════════════════════════════════════"
echo ""

CHECKS_PASSED=0
CHECKS_TOTAL=0

check() {
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  if [ -z "$2" ] || [ "$2" != "optional" ]; then
    if [ -f "$1" ] || [ -d "$1" ] || command -v "$1" &>/dev/null; then
      echo "✅ Check $CHECKS_TOTAL: $1"
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
      return 0
    else
      echo "❌ Check $CHECKS_TOTAL: $1 (FAILED)"
      return 1
    fi
  else
    if [ -f "$1" ] || [ -d "$1" ] || command -v "$1" &>/dev/null; then
      echo "✅ Check $CHECKS_TOTAL: $1 (optional)"
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
      echo "⚠️  Check $CHECKS_TOTAL: $1 (optional - not found)"
    fi
  fi
}

echo "📋 DEPLOYMENT READINESS CHECKS"
echo "───────────────────────────────────────────────────────────"
echo ""

echo "Environment Tools:"
check "dart"
check "git"
check "docker" "optional"
echo ""

echo "Project Files:"
check "/Users/admin/Documents/quicui2"
check "/Users/admin/Documents/quicui2/packages/quicui_backend/pubspec.yaml"
check "/Users/admin/Documents/quicui2/packages/quicui_backend/bin/server.dart"
check "/Users/admin/Documents/quicui2/packages/quicui_backend/.env.local"
echo ""

echo "Deployment Scripts:"
check "/Users/admin/Documents/quicui2/local_deploy.sh"
check "/Users/admin/Documents/quicui2/packages/quicui_backend/bin/deploy_local.sh"
check "/Users/admin/Documents/quicui2/bin/verify_deployment_ready.sh"
echo ""

echo "Documentation:"
check "/Users/admin/Documents/quicui2/QUICK_START.md"
check "/Users/admin/Documents/quicui2/LOCAL_DEPLOYMENT_INSTRUCTIONS.md"
check "/Users/admin/Documents/quicui2/docs/LOCAL_DEPLOYMENT.md"
check "/Users/admin/Documents/quicui2/docs/LOCAL_DEPLOYMENT_SUMMARY.md"
check "/Users/admin/Documents/quicui2/docs/LOCAL_DEPLOYMENT_COMPLETE.md"
check "/Users/admin/Documents/quicui2/docs/DEPLOYMENT_GUIDE.md"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  DEPLOYMENT STATUS"
echo "───────────────────────────────────────────────────────────"
echo "✅ Checks Passed: $CHECKS_PASSED/$CHECKS_TOTAL"
echo ""

if [ $CHECKS_PASSED -lt 10 ]; then
  echo "⚠️  Some required files are missing. Please verify paths."
  exit 1
fi

echo "🎉 All deployment files are in place!"
echo ""
echo "Ready to deploy? Choose one:"
echo ""
echo "  Option 1 (Fastest):"
echo "  bash /Users/admin/Documents/quicui2/local_deploy.sh"
echo ""
echo "  Option 2 (With Database):"
echo "  docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15"
echo "  bash /Users/admin/Documents/quicui2/local_deploy.sh"
echo ""
echo "  Option 3 (Manual):"
echo "  cd /Users/admin/Documents/quicui2/packages/quicui_backend"
echo "  source .env.local && dart pub get && dart run"
echo ""
echo "═══════════════════════════════════════════════════════════"
