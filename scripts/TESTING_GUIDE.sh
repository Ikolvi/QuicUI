#!/bin/bash

# QuicUI Code Push - Quick Start Guide for Testing
# This file documents how to run the full test suite

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║           QuicUI Code Push - Complete Testing Setup Guide                ║
║                                                                            ║
║              Backend Server + APK Build + Device Testing                 ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝


🎯 QUICK START (3 STEPS)
═══════════════════════════════════════════════════════════════════════════════

1️⃣  Start Backend Server (Terminal 1)
    ───────────────────────────────────────────────────────────────────────

    $ cd /Users/admin/Documents/quicui2
    $ ./scripts/start_backend.sh

    Expected output:
      🚀 Starting QuicUI Code Push Backend...
      ✅ Server listening on http://0.0.0.0:8080


2️⃣  Build APK (Terminal 2)
    ───────────────────────────────────────────────────────────────────────

    $ cd /Users/admin/Documents/quicui2
    $ ./scripts/build_and_test.sh

    Expected output:
      ✅ Using QuicUI Flutter SDK from: .../forks/flutter-official
      ✅ APK generated: test_apps/quicui_test_app_v1/build/app/outputs/flutter-apk/app-release.apk


3️⃣  Install & Test on Device (Terminal 3)
    ───────────────────────────────────────────────────────────────────────

    $ adb install -r /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1/build/app/outputs/flutter-apk/app-release.apk

    $ adb shell am start -n com.quicui.testapp/MainActivity


═══════════════════════════════════════════════════════════════════════════════

📋 AVAILABLE SCRIPTS
═══════════════════════════════════════════════════════════════════════════════

1. ./scripts/start_backend.sh (BACKEND ONLY)
   ─────────────────────────────────────────────
   Starts the QuicUI Code Push backend server on port 8080
   
   • Good for: Quick backend start when APK already built
   • Output: Server runs in foreground
   • Stop: Press Ctrl+C
   
   Usage:
     $ ./scripts/start_backend.sh


2. ./scripts/build_and_test.sh (APK ONLY)
   ─────────────────────────────────────────────
   Builds APK with QuicUI Flutter SDK + verifies output
   
   • Good for: Iterative APK builds after code changes
   • Output: APK file ready for installation
   • Prerequisites: Backend not required
   
   Usage:
     $ ./scripts/build_and_test.sh


3. ./scripts/run_full_test.sh (COMBINED)
   ─────────────────────────────────────────────
   Starts backend + builds APK in one command
   
   • Good for: Complete fresh setup
   • Output: Backend runs + APK ready
   • Prerequisites: None
   
   Usage:
     $ ./scripts/run_full_test.sh


═══════════════════════════════════════════════════════════════════════════════

🔍 VERIFY SETUP
═══════════════════════════════════════════════════════════════════════════════

Check Backend Health (in new terminal):
  $ curl http://localhost:8080/health
  
Expected response:
  {"status":"healthy","cache_service":true,"database_pool":true,"uptime_seconds":...}


Check API v1:
  $ curl http://localhost:8080/api/v1/apps
  
Expected response:
  {"apps":[]}


View Metrics:
  $ curl http://localhost:8080/metrics/json
  
Expected response:
  {"requests":0,"cache_hits":0,"cache_misses":0,...}


═══════════════════════════════════════════════════════════════════════════════

📱 DEVICE TESTING FLOW
═══════════════════════════════════════════════════════════════════════════════

Phase 1: Baseline (v1.0.0)
  ├─ Install APK on device
  ├─ Launch app
  ├─ Verify SDK detection shows "QuicUI (Custom Fork) ✅"
  ├─ Note: No patches available yet (normal)
  └─ ✅ Phase 1 Complete


Phase 2: Patch Creation
  ├─ Create patch on backend
  ├─ Push patch to backend
  └─ Verify via: curl http://localhost:8080/api/v1/patches


Phase 3: Patch Detection
  ├─ App checks for patches on launch
  ├─ App shows: "Patch Available: v1.0.1"
  └─ Status changes from "None" to "v1.0.1"


Phase 4: Patch Download & Apply
  ├─ User taps "Install" button
  ├─ App downloads patch from backend
  ├─ Patch applied without restart
  ├─ Version updates to v1.0.1
  └─ ✅ ALL TESTS PASS


═══════════════════════════════════════════════════════════════════════════════

🌐 NETWORK CONFIGURATION
═══════════════════════════════════════════════════════════════════════════════

App Configuration (in code):
  Location: test_apps/quicui_test_app_v1/lib/main.dart (line 52)
  Endpoint: http://192.168.20.100:8080

Backend Server:
  Listening on: 0.0.0.0:8080 (all interfaces)
  
Access from:
  • PC (localhost):     http://localhost:8080 ✅
  • Android Device:     http://192.168.20.100:8080 ✅
  • Network peers:      http://192.168.20.100:8080 ✅


═══════════════════════════════════════════════════════════════════════════════

🛠️ TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════════════════

❌ Problem: "QuicUI Flutter SDK not found"
   ✅ Solution:
      $ export FLUTTER_ROOT=/Users/admin/Documents/quicui2/forks/flutter-official
      $ export PATH=$FLUTTER_ROOT/bin:$PATH
      $ flutter --version


❌ Problem: "Backend not reachable at 192.168.20.100:8080"
   ✅ Solution:
      1. Check backend is running: curl http://localhost:8080/health
      2. Verify network: ping 192.168.20.100
      3. Check firewall allows port 8080


❌ Problem: "APK build fails"
   ✅ Solution:
      1. Clean: flutter clean
      2. Get deps: flutter pub get
      3. Verify QuicUI SDK is active:
         $ flutter config --list | grep flutter-root


❌ Problem: "Device not detected (adb)"
   ✅ Solution:
      1. Check ADB: adb devices
      2. Enable USB debugging on device
      3. Reconnect device


═══════════════════════════════════════════════════════════════════════════════

📊 EXPECTED RESULTS
═══════════════════════════════════════════════════════════════════════════════

Successful APK Build:
  ✅ Size: ~55MB (expected range: 45-60MB)
  ✅ Signed: Yes
  ✅ Contains QuicUI SDK: Yes (verified in build output)


Successful Backend Start:
  ✅ Listening on 0.0.0.0:8080
  ✅ Health check passes
  ✅ Metrics endpoint responds


Successful Device Test:
  ✅ App installs without errors
  ✅ App launches on first try
  ✅ SDK shows "QuicUI (Custom Fork) ✅"
  ✅ App connects to backend on 192.168.20.100:8080
  ✅ Patch detection works
  ✅ Patch downloads successfully
  ✅ Patch applies (no restart required)
  ✅ Version updates to 1.0.1


═══════════════════════════════════════════════════════════════════════════════

💡 PRO TIPS
═══════════════════════════════════════════════════════════════════════════════

Tip 1: Keep backend running in dedicated terminal
  $ ./scripts/start_backend.sh

Tip 2: Watch backend logs in real-time
  Watch for API calls when app checks for patches


Tip 3: Test locally first before device
  $ curl http://localhost:8080/health


Tip 4: Rebuild APK when code changes
  $ ./scripts/build_and_test.sh


Tip 5: Reinstall APK without uninstalling
  $ adb install -r /path/to/apk


═══════════════════════════════════════════════════════════════════════════════

📝 NEXT STEPS
═══════════════════════════════════════════════════════════════════════════════

1. Terminal 1: Start Backend
   $ ./scripts/start_backend.sh

2. Wait for "✅ Server listening on http://0.0.0.0:8080"

3. Terminal 2: Verify backend health
   $ curl http://localhost:8080/health

4. Terminal 3: Build APK
   $ ./scripts/build_and_test.sh

5. Install on device:
   $ adb install -r <APK_PATH>

6. Open app and test patch detection


═══════════════════════════════════════════════════════════════════════════════

🎯 PHASE 5.4 TESTING CHECKLIST
═══════════════════════════════════════════════════════════════════════════════

Infrastructure:
  ☐ Backend server running on 192.168.20.100:8080
  ☐ APK built with QuicUI Flutter SDK
  ☐ Network connectivity verified (192.168.20.100 reachable)

Device Preparation:
  ☐ Android device connected via ADB
  ☐ USB debugging enabled
  ☐ App uninstalled (if re-testing)

Testing Phases:
  ☐ Phase 1: Install baseline v1.0.0
  ☐ Phase 2: SDK detection shows QuicUI ✅
  ☐ Phase 3: Create and push v1.0.1 patch
  ☐ Phase 4: App detects patch
  ☐ Phase 5: App downloads patch
  ☐ Phase 6: Patch applied (NO restart)
  ☐ Phase 7: Verify version = v1.0.1

Success Criteria:
  ✅ All 7 phases complete
  ✅ App never crashed
  ✅ No restart occurred during patch
  ✅ Version properly updated
  ✅ Performance unchanged


═══════════════════════════════════════════════════════════════════════════════

Questions? Check these files:
  • .azure/TEST_PLAN_INDEX.md         - Navigation guide
  • .azure/TEST_EXECUTION_PLAN.md     - Detailed 7-phase plan
  • .azure/LOCAL_NETWORK_TESTING.md   - Comprehensive testing guide
  • .azure/BUILD_CONFIG.md            - Build configuration

═══════════════════════════════════════════════════════════════════════════════

EOF
