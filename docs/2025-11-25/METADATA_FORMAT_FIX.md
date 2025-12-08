# Metadata Format Fix - C++ Patch Loader Compatibility

**Date:** November 25, 2025  
**Status:** ✅ RESOLVED  
**Impact:** CRITICAL - Enabled C++ patch loader to function correctly

---

## Problem Summary

The QuicUI C++ patch loader was failing to load patches despite successful BsDiff installation. The root cause was a **metadata format incompatibility** between what Kotlin was writing and what C++ expected.

### Symptoms

```
I flutter : [INFO:quicui_patch_loader.cc(25)] Code cache directory set to: /data/user/0/.../code_cache
W flutter : [WARNING:quicui_patch_loader.cc(80)] Failed to load patch metadata
I FlutterMain: [QuicUI] No patch installed, using original AOT
```

The C++ loader could not parse the metadata file, even though:
- ✅ Patch file installed correctly (`libapp_patched_arm64-v8a.so`)
- ✅ BsDiff application successful with hash validation
- ✅ Metadata file existed in patches directory

---

## Root Causes

### 1. Incorrect Filename

**Problem:** Kotlin saved metadata as `patch_metadata.json`, but C++ expected `metadata.json`

**Location:** `packages/quicui_code_push_client/android/src/main/kotlin/com/quicui/codepush/CodePushMethodHandler.kt`

**Original Code (Line 395):**
```kotlin
val metadataFile = File(patchesDir, "patch_metadata.json")  // ❌ Wrong filename
```

**Fixed Code:**
```kotlin
val metadataFile = File(patchesDir, "metadata.json")  // ✅ Correct filename
```

### 2. Overly Complex JSON Structure

**Problem:** Kotlin wrote 8 fields, but C++ only needed/expected 3 fields

**Original JSON (incompatible):**
```json
{
  "version": "3.0.6",
  "platform": "android",
  "architecture": "arm64-v8a",
  "patch_hash": "d8a645efbca7c41041e79b8fd49b3a0511055834ab376d23457a088fa863d98a",
  "patch_size": 3802032,
  "signature": "",
  "install_date": "2025-11-25T15:41:41.339Z",
  "requires_restart": true
}
```

**New JSON (C++ compatible):**
```json
{
  "version": "3.0.6",
  "hash": "d8a645efbca7c41041e79b8fd49b3a0511055834ab376d23457a088fa863d98a",
  "architecture": "arm64-v8a"
}
```

**Key Changes:**
- Removed: `platform`, `patch_size`, `signature`, `install_date`, `requires_restart`
- Renamed: `patch_hash` → `hash`
- Kept only: `version`, `hash`, `architecture`

---

## The Fix

### Modified File: `CodePushMethodHandler.kt`

**Location:** Lines 395-407

```kotlin
// CRITICAL: filename must be 'metadata.json' for C++ loader compatibility
val metadataFile = File(patchesDir, "metadata.json")

// Write simplified metadata (C++ compatible format)
val metadata = buildString {
    appendLine("{")
    appendLine("  \"version\": \"$version\",")
    appendLine("  \"hash\": \"${hash ?: ""}\",")
    appendLine("  \"architecture\": \"$arch\"")
    appendLine("}")
}

metadataFile.writeText(metadata)
Log.i(TAG, "📝 Metadata: version=$version, arch=$arch")
```

**Also Updated (Line 504):**
```kotlin
// Clear patch metadata file
val metadataFile = File(patchesDir, "metadata.json")  // Updated reference
```

---

## Verification Process

### 1. Applied the Fix
- Modified Kotlin code to use correct filename and format
- Rebuilt baseline v3.0.2 with the fix
- Installed updated baseline APK

### 2. Generated New Patch
- Created patch v3.0.6 with visual changes (blue/cyan gradient, rocket icon)
- Uploaded to Supabase backend

### 3. Tested End-to-End
**Download & Install:**
```
✅ Patch downloaded: 1110300 bytes (XZ compressed)
✅ Decompressed: 3717027 bytes
✅ BsDiff applied successfully
✅ Hash validation passed
✅ Metadata created: metadata.json
```

**App Restart (C++ Loader Test):**
```
I flutter : [INFO:quicui_patch_loader.cc(25)] Code cache directory set to: /data/user/0/.../code_cache
I flutter : [INFO:quicui_patch_loader.cc(91)] QuicUI: Found valid patch at: .../libapp_patched_arm64-v8a.so
I flutter : [INFO:quicui_patch_loader.cc(92)] QuicUI: Patch version: 3.0.6
I FlutterMain: [QuicUI] Found patched AOT at: .../libapp_patched_arm64-v8a.so
I FlutterMain: [QuicUI] Patch file size: 3802032 bytes
I FlutterMain: [QuicUI] ✅ Configured to use patched AOT snapshot
```

### 4. Visual Confirmation
**Baseline v3.0.2:**
- Purple/deep purple gradient
- ⭐ Stars icon
- "💜 QuicUI v3.0.2 - ULTRA PATCH"

**Patched v3.0.6:**
- Blue/cyan gradient
- 🚀 Rocket launch icon
- "🚀 QuicUI v3.0.6 - ROCKET BOOST"

---

## Technical Details

### C++ Expectations

The C++ patch loader (`quicui_patch_loader.cc`) expects:
1. **File location:** `<code_cache>/quicui_patches/metadata.json`
2. **JSON format:** Simple structure with version, hash, architecture
3. **Encoding:** UTF-8 text

### File Structure After Successful Patch

```
/data/user/0/com.example.quicui_production_test/code_cache/quicui_patches/
├── libapp_patched_arm64-v8a.so  (3,802,032 bytes)
└── metadata.json                 (131 bytes)
```

**metadata.json content:**
```json
{
  "version": "3.0.6",
  "hash": "d8a645efbca7c41041e79b8fd49b3a0511055834ab376d23457a088fa863d98a",
  "architecture": "arm64-v8a"
}
```

---

## Impact

### Before Fix
❌ C++ loader could not parse metadata  
❌ Patches installed but never loaded  
❌ App always used original AOT snapshot  
❌ Visual changes never appeared  

### After Fix
✅ C++ loader successfully parses metadata.json  
✅ Patches detected and loaded on app restart  
✅ Patched AOT snapshot used by Flutter engine  
✅ Visual changes and code updates work end-to-end  

---

## Related Issues Resolved

### Issue 1: Hash Mismatch
- **Problem:** BsDiff failed with "Old file hash mismatch"
- **Cause:** Wrong baseline APK installed
- **Solution:** Rebuilt baseline with correct code state

### Issue 2: Database Conflicts
- **Problem:** Patch upload failed with unique constraint violation
- **Cause:** Same version already existed in database
- **Solution:** Incremented version number (v3.0.4 → v3.0.5 → v3.0.6)

### Issue 3: Metadata Format (Critical)
- **Problem:** C++ loader reported "Failed to load patch metadata"
- **Cause:** Wrong filename and overly complex JSON structure
- **Solution:** This fix - simplified format and correct filename

---

## Lessons Learned

1. **Cross-Language Contracts:** Always verify data format expectations between different language components (Kotlin ↔ C++)

2. **Documentation is Critical:** The C++ code expected specific format, but this wasn't clearly documented in Kotlin side

3. **Incremental Testing:** Test each layer independently:
   - ✅ Patch generation (CLI)
   - ✅ Patch download (Dart client)
   - ✅ Patch installation (Kotlin native)
   - ✅ Patch loading (C++ engine) ← This was the missing piece

4. **Log Everything:** Detailed logging at each step helped identify exactly where the failure occurred (line 80 in C++ loader)

---

## Verification Commands

### Check Metadata File
```bash
adb shell "run-as com.example.quicui_production_test cat code_cache/quicui_patches/metadata.json"
```

### Check C++ Loader Logs
```bash
adb logcat -d | grep quicui_patch_loader
```

### Expected Output (Success)
```
I flutter : [INFO:quicui_patch_loader.cc(25)] Code cache directory set to: /data/user/0/.../code_cache
I flutter : [INFO:quicui_patch_loader.cc(91)] QuicUI: Found valid patch at: .../libapp_patched_arm64-v8a.so
I flutter : [INFO:quicui_patch_loader.cc(92)] QuicUI: Patch version: X.X.X
```

---

## Status

**✅ RESOLVED - November 25, 2025**

The QuicUI code push system now works end-to-end:
1. Build baseline with QuicUI engine
2. Generate BsDiff patch with XZ compression
3. Upload to Supabase backend
4. Client downloads and installs patch
5. **C++ loader successfully detects and loads patched library**
6. Visual changes and code updates appear after app restart

This fix was the final piece needed to make the C++ patch loader functional.
