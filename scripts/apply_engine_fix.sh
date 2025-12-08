#!/bin/bash

# QuicUI Engine Patch Fix Script
# Applies FlutterLoader.java modification to enable code push

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     QuicUI Code Push Engine Fix - FlutterLoader      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Engine path
ENGINE_SRC="/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src"
FLUTTER_LOADER="$ENGINE_SRC/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java"

# Check if engine exists
if [ ! -d "$ENGINE_SRC" ]; then
    echo -e "${RED}❌ Engine not found at: $ENGINE_SRC${NC}"
    echo ""
    echo "Please ensure the QuicUI engine is built at this location."
    exit 1
fi

# Check if FlutterLoader.java exists
if [ ! -f "$FLUTTER_LOADER" ]; then
    echo -e "${RED}❌ FlutterLoader.java not found at: $FLUTTER_LOADER${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found engine at: $ENGINE_SRC${NC}"
echo -e "${GREEN}✅ Found FlutterLoader.java${NC}"
echo ""

# Check if already patched
if grep -q "QuicUI Code Push: Check for patched AOT library" "$FLUTTER_LOADER"; then
    echo -e "${YELLOW}⚠️  FlutterLoader.java is already patched!${NC}"
    echo ""
    read -p "Do you want to reapply the patch? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping patch application."
        exit 0
    fi
fi

# Create backup
BACKUP_FILE="$FLUTTER_LOADER.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${BLUE}📁 Creating backup: $BACKUP_FILE${NC}"
cp "$FLUTTER_LOADER" "$BACKUP_FILE"
echo ""

# Apply patch
echo -e "${BLUE}🔧 Applying FlutterLoader modification...${NC}"
echo ""

# Create temporary patch file
PATCH_FILE=$(mktemp)

cat > "$PATCH_FILE" << 'EOF'
--- FlutterLoader.java.orig
+++ FlutterLoader.java
@@ -356,6 +356,29 @@
         shellArgs.add(
             "--" + ISOLATE_SNAPSHOT_DATA_KEY + "=" + flutterApplicationInfo.isolateSnapshotData);
       } else {
+        // QuicUI Code Push: Check for patched AOT library
+        String patchedLibPath = null;
+        String codeCachePath = applicationContext.getCodeCacheDir().getAbsolutePath();
+        String[] architectures = {"arm64-v8a", "armeabi-v7a", "x86_64", "x86"};
+        
+        for (String arch : architectures) {
+          String candidatePath = codeCachePath + File.separator + "quicui_patches" + 
+                                 File.separator + "libapp_patched_" + arch + ".so";
+          File candidateFile = new File(candidatePath);
+          if (candidateFile.exists()) {
+            patchedLibPath = candidatePath;
+            Log.i(TAG, "QuicUI: Found patched AOT library at: " + patchedLibPath);
+            break;
+          }
+        }
+
+        if (patchedLibPath != null) {
+          // Use the patched library
+          shellArgs.add(aotSharedLibraryNameFlag + patchedLibPath);
+          Log.i(TAG, "QuicUI: Using patched AOT library");
+        } else {
+          // Use the default library from APK
+        }
         // Add default AOT shared library name arg.
         shellArgs.add(aotSharedLibraryNameFlag + flutterApplicationInfo.aotSharedLibraryName);
 
@@ -367,6 +390,7 @@
                 + flutterApplicationInfo.nativeLibraryDir
                 + File.separator
                 + flutterApplicationInfo.aotSharedLibraryName);
+        }
 
         // In profile mode, provide a separate library containing a snapshot for
         // launching the Dart VM service isolate.
EOF

# Note: The above patch won't work directly with patch command due to context
# So we'll do a manual replacement using sed

# Instead of using patch, let's use a more reliable approach with awk
echo -e "${YELLOW}Note: Using manual code insertion (patch command may not work reliably)${NC}"
echo ""

# Check if we need to manually edit
echo -e "${YELLOW}⚠️  This script requires manual verification.${NC}"
echo ""
echo "Please manually edit the file:"
echo "  $FLUTTER_LOADER"
echo ""
echo "Add the QuicUI patch detection code after line 356 (in the 'else' block for AOT)."
echo ""
echo "See: /Users/admin/Documents/quicui2/docs/CODE_PUSH_ENGINE_FIX.md for exact code."
echo ""

read -p "Have you manually applied the modification? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${RED}❌ Modification not applied. Exiting.${NC}"
    echo ""
    echo "Backup created at: $BACKUP_FILE"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Modification applied (or confirmed)${NC}"
echo ""

# Rebuild engine
echo -e "${BLUE}🔨 Rebuilding Android engine...${NC}"
echo ""

cd "$ENGINE_SRC"

if [ ! -d "out/android_release_arm64" ]; then
    echo -e "${RED}❌ Build directory not found: out/android_release_arm64${NC}"
    echo "Please configure the build first with GN."
    exit 1
fi

echo "Running: ninja -C out/android_release_arm64"
echo ""

ninja -C out/android_release_arm64

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Engine rebuilt successfully!${NC}"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  BUILD SUCCESSFUL                     ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Build new baseline APK with modified engine"
    echo "  2. Install baseline on test device"
    echo "  3. Generate and upload patch"
    echo "  4. Test that visual changes appear"
    echo ""
    echo "Example:"
    echo "  cd test_apps/quicui_production_test"
    echo "  quicui build-apk --version 2.0.9 --baseline"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Engine build failed!${NC}"
    echo ""
    echo "Check the error messages above."
    echo "You can restore the backup:"
    echo "  cp $BACKUP_FILE $FLUTTER_LOADER"
    exit 1
fi

# Cleanup
rm -f "$PATCH_FILE"

echo -e "${GREEN}✅ All done!${NC}"
echo ""
