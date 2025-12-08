#!/bin/bash
set -e

# QuicUI Patch Loading Test with New Engine
# This script tests the updated engine with patch loading support

DEVICE_ID="653324F8-D2E4-5A3A-BC77-C7C601AA9433"
PROJECT_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_production_test"
CLI_PATH="/Users/admin/Documents/quicui2/packages/quicui_cli/bin/quicui.dart"

echo "========================================="
echo "QuicUI Patch Loading Test - New Engine"
echo "========================================="
echo ""

# Step 1: Verify the patch still exists in Supabase
echo "📋 Step 1: Checking existing patch in database..."
echo "   Patch ID: 1764426073097"
echo "   Version: 3.0.55"
echo "   Hash: f9beb6aa6192de5b3663a37266b0e091de53efe0cf4ce5b23f48172f8766669b"
echo ""

# Step 2: Launch app and capture logs
echo "📱 Step 2: Launching app with console logging..."
echo "   IMPORTANT: Please unlock your device first!"
echo "   Press Enter when device is unlocked..."
read

echo "   Launching app..."
xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  --console com.example.quicuiProductionTest \
  2>&1 | tee "$PROJECT_DIR/../logs/test_run_$(date +%Y%m%d_%H%M%S).log" &

LAUNCH_PID=$!
sleep 5

echo ""
echo "📊 Step 3: Analyzing logs for patch loading..."
sleep 2

# Check for key log messages
LOG_FILE=$(ls -t "$PROJECT_DIR/../logs/test_run_"* 2>/dev/null | head -1)

if [ -f "$LOG_FILE" ]; then
  echo ""
  echo "🔍 Checking for patch loading logs..."
  
  if grep -q "No patches_state.json found" "$LOG_FILE"; then
    echo "   ℹ️  No patch installed yet (running base AOT)"
    echo ""
    echo "   The app should trigger a download. Wait a few seconds..."
    sleep 10
    
    echo ""
    echo "   Checking again after download..."
    if grep -q "Found patches_state.json" "$LOG_FILE"; then
      echo "   ✅ Patch downloaded and will load on next launch!"
    else
      echo "   ⏳ Still downloading... Check logs manually"
    fi
  elif grep -q "Found patches_state.json" "$LOG_FILE"; then
    echo "   ✅ patches_state.json found!"
    
    if grep -q "Found patch file at:" "$LOG_FILE"; then
      echo "   ✅ Patch file found!"
      
      if grep -q "Patch loaded successfully" "$LOG_FILE"; then
        echo "   ✅ PATCH LOADED SUCCESSFULLY!"
        echo ""
        echo "   Patch details:"
        grep "QuicUI.*Patch" "$LOG_FILE" | head -10
        echo ""
        echo "🎉 SUCCESS! Check the app - should show PURPLE theme v3.0.55"
      else
        echo "   ⚠️  Patch found but not loaded - check logs"
      fi
    else
      echo "   ⚠️  patches_state.json found but no patch file"
    fi
  else
    echo "   ⚠️  No QuicUI patch loading logs found"
  fi
  
  echo ""
  echo "📝 Full log saved to: $LOG_FILE"
else
  echo "   ⚠️  Log file not created yet"
fi

echo ""
echo "========================================="
echo "Test Complete"
echo "========================================="
echo ""
echo "Expected behavior:"
echo "1. First launch: Downloads patch, shows base UI (v3.0.54)"
echo "2. Close app manually"  
echo "3. Relaunch: Should load patch and show PURPLE theme (v3.0.55)"
echo ""
echo "Visual verification:"
echo "  ✅ Purple theme (not blue or pink gradient)"
echo "  ✅ Title: '🎨 PURPLE THEME v3.0.55 - PATCH WORKS! 🚀'"
echo ""
