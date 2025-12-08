#!/bin/bash
# Deploy QuicUI Backend to Supabase
# Run this script to deploy Edge Functions and migrations

set -e

echo "🚀 QuicUI Backend - Supabase Deployment"
echo "════════════════════════════════════════"
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found"
    echo ""
    echo "Install with:"
    echo "  brew install supabase/tap/supabase"
    echo "  OR"
    echo "  npm install -g supabase"
    echo ""
    exit 1
fi

echo "✓ Supabase CLI found"
echo ""

# Check if logged in
if ! supabase projects list &> /dev/null; then
    echo "🔐 Please login to Supabase..."
    supabase login
fi

echo "✓ Authenticated"
echo ""

# Get project ref
PROJECT_REF="pcaxvanjhtfaeimflgfk"
echo "📌 Project: $PROJECT_REF"
echo ""

# Link project
echo "🔗 Linking project..."
cd "$(dirname "$0")/../supabase" || exit 1

if ! supabase link --project-ref "$PROJECT_REF" 2>/dev/null; then
    echo "⚠️  Already linked or link failed"
fi

echo ""
echo "═══════════════════════════════════════"
echo "Step 1: Database Migrations"
echo "═══════════════════════════════════════"
echo ""

# Apply migrations
echo "📊 Applying database migrations..."
if supabase db push; then
    echo "✅ Migrations applied successfully"
else
    echo "⚠️  Migrations failed or already applied"
fi

echo ""
echo "═══════════════════════════════════════"
echo "Step 2: Deploy Edge Functions"
echo "═══════════════════════════════════════"
echo ""

# Deploy Edge Functions
FUNCTIONS=(
    "patches-check"
    "patches-register"
    "patches-download"
)

for func in "${FUNCTIONS[@]}"; do
    echo "📤 Deploying $func..."
    if supabase functions deploy "$func" --no-verify-jwt; then
        echo "✅ $func deployed"
    else
        echo "❌ Failed to deploy $func"
        exit 1
    fi
    echo ""
done

echo "═══════════════════════════════════════"
echo "✅ Deployment Complete!"
echo "═══════════════════════════════════════"
echo ""
echo "Backend URL: https://$PROJECT_REF.supabase.co/functions/v1"
echo ""
echo "Endpoints:"
echo "  • POST /patches-check       - Check for updates"
echo "  • POST /patches-register    - Register new patch"
echo "  • GET  /patches-download    - Download patch file"
echo ""
echo "Next Steps:"
echo "1. Update quicui.yaml in your Flutter project:"
echo "   server:"
echo "     url: https://$PROJECT_REF.supabase.co/functions/v1"
echo "     api_key: YOUR_ANON_KEY"
echo ""
echo "2. Test the deployment:"
echo "   curl -X POST https://$PROJECT_REF.supabase.co/functions/v1/patches-check \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -H 'apikey: YOUR_ANON_KEY' \\"
echo "     -d '{\"appId\": \"com.test.app\", \"currentVersion\": \"1.0.0\"}'"
echo ""
echo "3. Deploy a patch with the compiler:"
echo "   dart run packages/quicui_compiler/bin/quicui_compiler.dart auto-deploy"
echo ""
