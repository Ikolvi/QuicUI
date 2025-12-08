# Quick Engine Rebuild Guide
**Status:** Ready to rebuild with differential patch support

## Prerequisites

✅ **Engine modifications complete:**
- `elf_loader.cc` - Modified with QUIC detection
- `macho_loader.cc` - Modified with QUIC detection

✅ **Backups saved:**
- `/Users/admin/Documents/quicui2/docs/2025-11-30/engine_modifications/`

## Rebuild Commands

### 1. Navigate to Engine Source
```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
```

### 2. Configure iOS Release Build
```bash
./flutter/tools/gn --ios --ios-cpu=arm64 --runtime-mode=release --local-engine
```

Expected output: `Done. Made X targets from Y files in Zms`

### 3. Build Engine
```bash
ninja -C out/ios_release
```

Expected: 
- Duration: ~10-30 minutes (depending on system)
- Output: `[XXXX/XXXX] STAMP obj/default.stamp`

### 4. Verify Build
```bash
ls -lh out/ios_release/Flutter.framework/Flutter
```

Expected: Framework binary exists with reasonable size (~50-100 MB)

### 5. Check for Errors
```bash
# If build fails, check logs
cat out/ios_release/build.log | tail -100

# Search for our modifications
grep -r "DetectQuicHeaderOffset" out/ios_release/*.o 2>/dev/null || echo "Symbol may be inlined"
```

## Quick Test

### Build Test App
```bash
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test

# Use local engine
flutter build ios --release \
  --local-engine-src-path=/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src \
  --local-engine=ios_release
```

### Install and Test
```bash
# Install baseline
flutter install

# Launch app and test patch download
# Expected logs:
#   [QuicUI] ✓ Detected QUIC differential patch format
#   [QuicUI] ✓ Skipping 65536 bytes to reach ELF data
```

## Troubleshooting

### Build Fails
```bash
# Clean and retry
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
rm -rf out/ios_release
./flutter/tools/gn --ios --ios-cpu=arm64 --runtime-mode=release --local-engine
ninja -C out/ios_release
```

### Syntax Errors in Modifications
```bash
# Check modified files
grep -n "DetectQuicHeaderOffset" flutter/third_party/dart/runtime/bin/elf_loader.cc
grep -n "DetectQuicHeaderOffset" flutter/third_party/dart/runtime/bin/macho_loader.cc

# If issues found, restore from backups and re-apply
```

### Can't Find Engine
```bash
# Verify engine location
ls -la /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src

# Check gn tool
which gn || echo "gn not in PATH, use full path: ./flutter/tools/gn"
```

## Time Estimates

| Step | Duration |
|------|----------|
| Configure (gn) | 5-10 seconds |
| Initial Build | 20-40 minutes |
| Incremental Build | 2-5 minutes |
| Test App Build | 2-3 minutes |
| Install on Device | 1-2 minutes |

## Success Indicators

✅ gn completes without errors  
✅ ninja completes: `[XXXX/XXXX] STAMP obj/default.stamp`  
✅ Flutter.framework exists in `out/ios_release/`  
✅ Test app builds successfully  
✅ App installs on device  
✅ Engine logs show QUIC detection  

## What to Watch For

⚠️ **Build Errors:**
- Syntax errors in C++ modifications
- Missing includes
- Type mismatches

⚠️ **Runtime Errors:**
- Crashes on patch load
- Invalid memory access
- Code signing violations

⚠️ **Performance Issues:**
- Slow patch loading
- Memory leaks
- High CPU usage

## Next Steps After Successful Build

1. ✅ Engine rebuilt
2. → Build test app with modified engine
3. → Install baseline (v3.0.60) on device
4. → Test differential patch download (2.1 MB)
5. → Verify patch application
6. → Confirm app updates to v3.0.61
7. → Document results

## Rollback if Needed

```bash
# Restore original files
cp /Users/admin/Documents/quicui2/docs/2025-11-30/engine_modifications/*.original \
   /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/bin/

# Rebuild
ninja -C out/ios_release
```

---

**Ready to proceed?** Run the commands in order and monitor for errors at each step.
