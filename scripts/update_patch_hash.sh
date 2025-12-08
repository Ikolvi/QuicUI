#!/bin/bash

# Update patch hash in Supabase database
# This script updates the existing patch entry with the new correct hash

SUPABASE_URL="https://pcaxvanjhtfaeimflgfk.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXh2YW5qaHRmYWVpbWZsZ2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI2MjkyNDEsImV4cCI6MjA0ODIwNTI0MX0.jNRkjfhTmNH9lZdxxXhB4OjKQHKBOBvqcfzZOEP7t_0"

# New patch details
NEW_PATCH_ID="1764327189870"
NEW_HASH="bc5201f1a228013021fdee9a7969f1b6574a509b34665338adea3c9527bfcf12"
NEW_SIZE=1181798  # 1154.10 KB in bytes

echo "🔄 Updating patch in Supabase..."
echo "📋 Patch ID: $NEW_PATCH_ID"
echo "🔑 New Hash: $NEW_HASH"
echo ""

# First, delete the old patch for v3.0.46
echo "🗑️  Deleting old patch..."
curl -X DELETE "$SUPABASE_URL/rest/v1/patches?app_id=eq.com.example.quicuiProductionTest&version=eq.3.0.46&platform=eq.ios" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json"

echo ""
echo "✅ Old patch deleted"
echo ""

# Now upload the new patch using the CLI
echo "📤 Uploading new patch..."
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test
dart run ../../packages/quicui_cli/bin/quicui.dart upload-patch --patch "$NEW_PATCH_ID"

echo ""
echo "✅ Patch updated successfully!"
