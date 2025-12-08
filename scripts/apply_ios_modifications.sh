#!/bin/bash

# Apply iOS Engine Modifications for QuicUI Code Push
# This script modifies the Flutter iOS engine source to support QuicUI patches

set -e

ENGINE_SRC="/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src"
IOS_SOURCE="$ENGINE_SRC/flutter/shell/platform/darwin/ios/framework/Source"

echo "=================================================="
echo "QuicUI iOS Engine Modification Script"
echo "=================================================="
echo ""

# Step 1: Backup original files
echo "Step 1: Creating backups..."
cd "$IOS_SOURCE"

if [ ! -f "FlutterDartProject.mm.quicui_backup" ]; then
    cp FlutterDartProject.mm FlutterDartProject.mm.quicui_backup
    echo "✅ Backed up FlutterDartProject.mm"
else
    echo "⚠️  Backup already exists: FlutterDartProject.mm.quicui_backup"
fi

if [ ! -f "FlutterEngine.mm.quicui_backup" ]; then
    cp FlutterEngine.mm FlutterEngine.mm.quicui_backup
    echo "✅ Backed up FlutterEngine.mm"
else
    echo "⚠️  Backup already exists: FlutterEngine.mm.quicui_backup"
fi

echo ""

# Step 2: Verify QuicUICodePushLoader.mm was copied
echo "Step 2: Verifying iOS wrapper..."
if [ -f "QuicUICodePushLoader.mm" ]; then
    echo "✅ QuicUICodePushLoader.mm exists ($(wc -l < QuicUICodePushLoader.mm) lines)"
else
    echo "❌ QuicUICodePushLoader.mm not found!"
    echo "   Please run: cp /Users/admin/Documents/quicui2/docs/2025-11-25/ios_implementation/QuicUICodePushLoader.mm $IOS_SOURCE/"
    exit 1
fi

echo ""

# Step 3: Modify FlutterDartProject.mm
echo "Step 3: Modifying FlutterDartProject.mm..."

# Check if already modified
if grep -q "QuicUICodePushLoader" FlutterDartProject.mm; then
    echo "⚠️  FlutterDartProject.mm already contains QuicUI modifications"
else
    # Add import after existing imports (around line 16)
    sed -i '' '16a\
#import "QuicUICodePushLoader.mm"  // QuicUI Code Push
' FlutterDartProject.mm

    # Add property to @implementation block (after line 269: @implementation FlutterDartProject {)
    sed -i '' '270a\
  NSString* _patchedAOTPath;  // QuicUI: Cached patched AOT path
' FlutterDartProject.mm

    # Add new methods at the end of the file (before @end)
    # Find the last @end
    LINE_NUM=$(grep -n "^@end" FlutterDartProject.mm | tail -1 | cut -d: -f1)
    
    # Insert before @end
    ed -s FlutterDartProject.mm << EOF
${LINE_NUM}i

#pragma mark - QuicUI Code Push

/**
 * Check for QuicUI code push patches
 */
- (void)checkForCodePushPatches {
  @autoreleasepool {
    // Get iOS cache directory
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, 
                                                         NSUserDomainMask, 
                                                         YES);
    NSString* cacheDir = [paths firstObject];
    
    if (!cacheDir) {
      NSLog(@"[QuicUI] Failed to get cache directory, patches disabled");
      return;
    }
    
    NSLog(@"[QuicUI] QuicUI cache directory: %@", cacheDir);
    
    // Create QuicUI patch loader
    QuicUICodePushLoader* loader = [[QuicUICodePushLoader alloc] 
                                     initWithCacheDirectory:cacheDir];
    
    // Check for patched AOT
    NSString* patchedPath = [loader getPatchedAOTPath];
    
    if (patchedPath) {
      _patchedAOTPath = patchedPath;
      NSLog(@"[QuicUI] ✅ Will use patched AOT from: %@", patchedPath);
      
      // Log patch info for debugging
      NSDictionary* patchInfo = [loader getPatchInfo];
      if (patchInfo) {
        NSLog(@"[QuicUI] Patch version: %@", patchInfo[@"version"]);
        NSLog(@"[QuicUI] Patch architecture: %@", patchInfo[@"architecture"]);
      }
    } else {
      NSLog(@"[QuicUI] No patch found, using original AOT from app bundle");
      _patchedAOTPath = nil;
    }
  }
}

/**
 * Get patched AOT path if available
 */
- (NSString*)patchedAOTPath {
  return _patchedAOTPath;
}

.
w
q
EOF

    echo "✅ Modified FlutterDartProject.mm"
fi

echo ""

# Step 4: Modify FlutterEngine.mm
echo "Step 4: Modifying FlutterEngine.mm..."

# Check if already modified
if grep -q "checkForCodePushPatches" FlutterEngine.mm; then
    echo "⚠️  FlutterEngine.mm already contains QuicUI modifications"
else
    # Find the createShell method and add patch check
    # Search for "- (BOOL)createShell:" and add check after validation
    
    # This is complex, so we'll use a more targeted approach
    # Find line with "NSAssert(_shell == nullptr" in createShell method
    LINE_NUM=$(grep -n "NSAssert(_shell == nullptr" FlutterEngine.mm | head -1 | cut -d: -f1)
    
    if [ -n "$LINE_NUM" ]; then
        # Add patch check a few lines after
        let INSERT_LINE=$LINE_NUM+2
        
        sed -i '' "${INSERT_LINE}a\\
\ \ // QuicUI Code Push: Check for patches BEFORE creating shell\\
\ \ NSLog(@\"[QuicUI] Checking for code push patches...\");\\
\ \ [_dartProject checkForCodePushPatches];\\
" FlutterEngine.mm
        
        echo "✅ Modified FlutterEngine.mm"
    else
        echo "⚠️  Could not find insertion point in FlutterEngine.mm"
        echo "   Manual modification may be required"
    fi
fi

echo ""

# Step 5: Update BUILD.gn
echo "Step 5: Updating BUILD.gn..."

BUILD_GN="$ENGINE_SRC/flutter/shell/platform/darwin/ios/BUILD.gn"

if [ ! -f "$BUILD_GN" ]; then
    echo "❌ BUILD.gn not found at: $BUILD_GN"
    echo "   Searching for BUILD.gn..."
    find "$ENGINE_SRC/flutter/shell/platform/darwin/ios" -name "BUILD.gn" -type f
    exit 1
fi

# Backup BUILD.gn
if [ ! -f "$BUILD_GN.quicui_backup" ]; then
    cp "$BUILD_GN" "$BUILD_GN.quicui_backup"
    echo "✅ Backed up BUILD.gn"
fi

# Check if already modified
if grep -q "QuicUICodePushLoader" "$BUILD_GN"; then
    echo "⚠️  BUILD.gn already contains QuicUI modifications"
else
    # Find the sources array in ios_framework_sources and add our file
    # This requires finding the right section
    
    # Simple approach: add to the end of sources array
    # Look for a line like: sources = [
    LINE_NUM=$(grep -n 'sources = \[' "$BUILD_GN" | head -1 | cut -d: -f1)
    
    if [ -n "$LINE_NUM" ]; then
        # Find the next closing bracket
        CLOSE_LINE=$(tail -n +$LINE_NUM "$BUILD_GN" | grep -n "^\s*\]" | head -1 | cut -d: -f1)
        let INSERT_LINE=$LINE_NUM+$CLOSE_LINE-1
        
        sed -i '' "${INSERT_LINE}i\\
\ \ \ \ \"framework/Source/QuicUICodePushLoader.mm\",  # QuicUI Code Push
" "$BUILD_GN"
        
        echo "✅ Added QuicUICodePushLoader.mm to BUILD.gn sources"
    fi
    
    # Add dependency on C++ patch loader
    # Find deps array
    LINE_NUM=$(grep -n 'deps = \[' "$BUILD_GN" | head -1 | cut -d: -f1)
    
    if [ -n "$LINE_NUM" ]; then
        CLOSE_LINE=$(tail -n +$LINE_NUM "$BUILD_GN" | grep -n "^\s*\]" | head -1 | cut -d: -f1)
        let INSERT_LINE=$LINE_NUM+$CLOSE_LINE-1
        
        sed -i '' "${INSERT_LINE}i\\
\ \ \ \ \"//flutter/shell/common:quicui_patch_loader\",  # QuicUI Code Push
" "$BUILD_GN"
        
        echo "✅ Added quicui_patch_loader dependency to BUILD.gn"
    fi
fi

echo ""

# Step 6: Verify modifications
echo "Step 6: Verifying modifications..."

echo ""
echo "Checking FlutterDartProject.mm:"
grep -c "QuicUICodePushLoader" "$IOS_SOURCE/FlutterDartProject.mm" && echo "  ✅ Contains QuicUI references" || echo "  ❌ Missing QuicUI references"
grep -c "checkForCodePushPatches" "$IOS_SOURCE/FlutterDartProject.mm" && echo "  ✅ Has checkForCodePushPatches method" || echo "  ⚠️  Missing checkForCodePushPatches"

echo ""
echo "Checking FlutterEngine.mm:"
grep -c "checkForCodePushPatches" "$IOS_SOURCE/FlutterEngine.mm" && echo "  ✅ Calls checkForCodePushPatches" || echo "  ⚠️  Missing patch check call"

echo ""
echo "Checking BUILD.gn:"
grep -c "QuicUICodePushLoader" "$BUILD_GN" && echo "  ✅ Contains QuicUICodePushLoader.mm" || echo "  ❌ Missing source file"
grep -c "quicui_patch_loader" "$BUILD_GN" && echo "  ✅ Contains dependency" || echo "  ❌ Missing dependency"

echo ""
echo "=================================================="
echo "iOS Modifications Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Configure iOS build: flutter/tools/gn --ios --runtime-mode=release --ios-cpu=arm64"
echo "2. Build iOS engine: ninja -C out/ios_release"
echo "3. Test on iOS device/simulator"
echo ""
echo "To restore originals:"
echo "  cd $IOS_SOURCE"
echo "  cp FlutterDartProject.mm.quicui_backup FlutterDartProject.mm"
echo "  cp FlutterEngine.mm.quicui_backup FlutterEngine.mm"
echo "  cp $BUILD_GN.quicui_backup $BUILD_GN"
echo ""
