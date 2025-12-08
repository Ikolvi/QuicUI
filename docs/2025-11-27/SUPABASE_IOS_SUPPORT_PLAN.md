# Supabase Backend - iOS Support Implementation Plan

**Date**: November 27, 2025  
**Status**: Planning  
**Prerequisites**: Phase 1 (Engine) ✅, Phase 2 (CLI) ✅

## Overview

The Supabase Edge Functions need minimal modifications to support iOS `.vmcode` patches alongside Android `.so` patches. The current implementation already has most of the infrastructure in place with `platform` and `architecture` fields.

## Current State Analysis

### ✅ Already Implemented

The backend **already supports** most of what we need:

**patches-register** (`/supabase/functions/patches-register/index.ts`):
- ✅ Accepts `platform` field (defaults to 'android')
- ✅ Accepts `architecture` field
- ✅ Stores platform in database
- ✅ Validates architecture enum
- ✅ Handles file uploads (multipart/form-data)
- ✅ Supports compression (xz, gzip, bzip2)
- ✅ Validates file format (checks headers)

**patches-check** (`/supabase/functions/patches-check/index.ts`):
- ✅ Accepts `platform` parameter
- ✅ Filters patches by platform
- ✅ Uses platform-specific default architecture
- ✅ Returns appropriate patches

**patches-download** (`/supabase/functions/patches-download/index.ts`):
- ✅ Platform-agnostic download
- ✅ Handles compressed files
- ✅ Streams any file format

### 🔧 Modifications Needed

**Minor changes required**:

1. **patches-register**: Update file validation to support `.vmcode` format
2. **patches-register**: Update storage path logic for `.vmcode` files
3. **patches-check**: Ensure proper handling of iOS-specific metadata
4. **Documentation**: Update comments to clarify iOS support

## Implementation Plan

### Task 1: Update patches-register - File Validation

**File**: `supabase/functions/patches-register/index.ts`

**Current Code** (lines ~260-295):
```typescript
// Verify compression format
if (compression === 'xz') {
  // XZ files start with magic bytes: 0xFD, '7', 'z', 'X', 'Z', 0x00
  const xzMagic = [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00];
  const hasXzMagic = xzMagic.every((byte, i) => bytes[i] === byte);
  
  if (!hasXzMagic) {
    throw new SecurityError(
      'Invalid compressed patch: XZ magic bytes not found',
      400,
      'INVALID_COMPRESSION'
    );
  }
} else if (compression === 'none' || !compression) {
  // Verify QUICUI01 header for uncompressed patches
  if (bytes.length < 8) {
    throw new SecurityError('Invalid patch file: too small', 400, 'INVALID_PATCH');
  }
  const header = String.fromCharCode(...bytes.slice(0, 8));
  if (header !== 'QUICUI01') {
    throw new SecurityError(
      'Invalid patch file: missing QUICUI01 header',
      400,
      'INVALID_PATCH'
    );
  }
}
```

**Proposed Changes**:
```typescript
// Verify compression format
if (compression === 'xz') {
  // XZ files start with magic bytes: 0xFD, '7', 'z', 'X', 'Z', 0x00
  const xzMagic = [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00];
  const hasXzMagic = xzMagic.every((byte, i) => bytes[i] === byte);
  
  if (!hasXzMagic) {
    throw new SecurityError(
      'Invalid compressed patch: XZ magic bytes not found',
      400,
      'INVALID_COMPRESSION'
    );
  }
  console.log('✓ XZ compression magic verified');
} else if (compression === 'none' || !compression) {
  // Platform-specific validation
  const platform = body.platform || 'android';
  
  if (platform === 'ios') {
    // iOS patches are .vmcode ELF files
    // ELF files start with magic bytes: 0x7F, 'E', 'L', 'F'
    if (bytes.length < 4) {
      throw new SecurityError('Invalid .vmcode file: too small', 400, 'INVALID_PATCH');
    }
    
    const elfMagic = [0x7F, 0x45, 0x4C, 0x46];  // \x7fELF
    const hasElfMagic = elfMagic.every((byte, i) => bytes[i] === byte);
    
    if (!hasElfMagic) {
      throw new SecurityError(
        'Invalid .vmcode file: missing ELF header',
        400,
        'INVALID_PATCH'
      );
    }
    console.log('✓ ELF format verified (.vmcode)');
  } else {
    // Android patches are BsDiff format with QUICUI01 header
    if (bytes.length < 8) {
      throw new SecurityError('Invalid patch file: too small', 400, 'INVALID_PATCH');
    }
    const header = String.fromCharCode(...bytes.slice(0, 8));
    if (header !== 'QUICUI01') {
      throw new SecurityError(
        'Invalid patch file: missing QUICUI01 header',
        400,
        'INVALID_PATCH'
      );
    }
    console.log('✓ QUICUI01 header verified');
  }
}
```

**Benefits**:
- Validates iOS `.vmcode` files have correct ELF format
- Maintains backward compatibility with Android patches
- Clear error messages for debugging

### Task 2: Update patches-register - Storage Path Logic

**File**: `supabase/functions/patches-register/index.ts`

**Current Code** (lines ~295-310):
```typescript
// Determine storage path based on compression
let uploadPath = `patches/${appId}/${patchId}.quicui`;

if (compression === 'xz') {
  // Verify XZ compression...
  uploadPath = `patches/${appId}/${patchId}.quicui.xz`;
} else if (compression === 'none' || !compression) {
  // Verify QUICUI01 header...
}
```

**Proposed Changes**:
```typescript
// Determine storage path based on platform and compression
const platform = body.platform || 'android';
let uploadPath: string;

if (platform === 'ios') {
  // iOS uses .vmcode extension
  uploadPath = compression === 'xz' 
    ? `patches/${appId}/${patchId}.vmcode.xz`
    : `patches/${appId}/${patchId}.vmcode`;
} else {
  // Android uses .quicui extension
  uploadPath = compression === 'xz'
    ? `patches/${appId}/${patchId}.quicui.xz`
    : `patches/${appId}/${patchId}.quicui`;
}

console.log(`📤 Upload path: ${uploadPath}`);
```

**Benefits**:
- iOS patches get `.vmcode` extension
- Android patches keep `.quicui` extension
- Clear differentiation in storage
- Easier debugging and file management

### Task 3: Update patches-register - Logging

**File**: `supabase/functions/patches-register/index.ts`

**Current Code** (lines ~210-220):
```typescript
console.log('📝 Registering patch:', {
  patchId,
  version,
  appId,
  architecture: architecture || 'arm64-v8a',
  compression: compression || 'none',
  uncompressedSize,
  compressedSize: compressedSize || uncompressedSize,
});
```

**Proposed Changes**:
```typescript
const platform = body.platform || 'android';
const defaultArch = platform === 'ios' ? 'arm64' : 'arm64-v8a';

console.log('📝 Registering patch:', {
  patchId,
  version,
  appId,
  platform,
  architecture: architecture || defaultArch,
  compression: compression || 'none',
  uncompressedSize,
  compressedSize: compressedSize || uncompressedSize,
  fileType: platform === 'ios' ? '.vmcode' : '.quicui',
});
```

**Benefits**:
- Clearer logging shows platform
- Shows file type for debugging
- Uses platform-appropriate defaults

### Task 4: Update Architecture Validation

**File**: `supabase/functions/patches-register/index.ts`

**Current Code** (lines ~189):
```typescript
architecture: {
  type: 'string',
  enum: ['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64', 'arm64', 'armv7', 'x86_64_sim'],
},
```

**Already Correct!** ✅
- Already includes `arm64` (iOS)
- Already includes `armv7` (older iOS)
- No changes needed

### Task 5: Add Platform Validation

**File**: `supabase/functions/patches-register/index.ts`

**After line 188**, add:
```typescript
platform: {
  type: 'string',
  enum: ['android', 'ios'],
},
```

**Benefits**:
- Explicit platform validation
- Prevents typos (e.g., "iOS" vs "ios")
- Better error messages

### Task 6: Update Documentation

**File**: `supabase/functions/patches-register/index.ts`

**Update header comment**:
```typescript
// QuicUI Patch Registration Function
// Registers a new patch with the backend after compiler generates it
//
// Supported Platforms:
// - Android: BsDiff patches (.quicui) with QUICUI01 header
// - iOS: Dart VM snapshots (.vmcode) with ELF format
//
// Security Features:
// - Rate limiting (10 requests/minute for registration)
// - Input validation and sanitization
// - API key authentication required
// - CORS with origin whitelisting
// - Security headers
// - Audit logging
// - Duplicate patch detection
// - File upload to Supabase Storage
// - Platform-specific format validation
```

## Storage Structure

### Current (Android only)
```
storage/
└── patches/
    └── com.example.app/
        ├── 1234567890.quicui
        └── 1234567890.quicui.xz
```

### Proposed (Android + iOS)
```
storage/
└── patches/
    └── com.example.app/
        ├── 1234567890_android.quicui         # Android uncompressed
        ├── 1234567890_android.quicui.xz      # Android compressed
        ├── 1234567890_ios.vmcode             # iOS uncompressed
        └── 1234567890_ios.vmcode.xz          # iOS compressed
```

**Alternative** (simpler, recommended):
```
storage/
└── patches/
    └── com.example.app/
        ├── patch_3.0.37_12345.quicui.xz     # Android
        └── patch_3.0.37_12346.vmcode.xz     # iOS
```

Since `patchId` already includes timestamp and is unique per build, we don't need platform suffixes.

## Database Schema

### Current Schema (Already Sufficient!)

```sql
CREATE TABLE patches (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  patch_id text UNIQUE NOT NULL,
  version text NOT NULL,
  app_id text NOT NULL,
  platform text DEFAULT 'android',           -- ✅ Already exists
  architecture text,                         -- ✅ Already exists
  uncompressed_path text NOT NULL,
  compressed_paths jsonb,
  uncompressed_size bigint NOT NULL,
  compressed_sizes jsonb,
  hash text NOT NULL,
  compression text,
  release_notes text,
  critical boolean DEFAULT false,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  download_count integer DEFAULT 0,
  success_count integer DEFAULT 0,
  failure_count integer DEFAULT 0
);

CREATE INDEX idx_patches_app_platform_arch 
  ON patches(app_id, platform, architecture);
```

**No schema changes needed!** ✅

## Testing Plan

### Test Case 1: Register Android Patch

**Request**:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/patches-register \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F "patchId=patch_3.0.37_12345" \
  -F "version=3.0.37" \
  -F "appId=com.example.app" \
  -F "platform=android" \
  -F "architecture=arm64-v8a" \
  -F "uncompressedSize=5242880" \
  -F "compressedSize=1310720" \
  -F "hash=abc123..." \
  -F "compression=xz" \
  -F "patchFile=@patch_3.0.37.quicui.xz"
```

**Expected**:
- ✅ File uploaded to `patches/com.example.app/patch_3.0.37_12345.quicui.xz`
- ✅ Database record created with `platform=android`
- ✅ XZ magic bytes verified

### Test Case 2: Register iOS Patch

**Request**:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/patches-register \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F "patchId=patch_3.0.37_12346" \
  -F "version=3.0.37" \
  -F "appId=com.example.app" \
  -F "platform=ios" \
  -F "architecture=arm64" \
  -F "uncompressedSize=8912896" \
  -F "compressedSize=2228224" \
  -F "hash=def456..." \
  -F "compression=xz" \
  -F "patchFile=@patch_3.0.37.vmcode.xz"
```

**Expected**:
- ✅ File uploaded to `patches/com.example.app/patch_3.0.37_12346.vmcode.xz`
- ✅ Database record created with `platform=ios`
- ✅ XZ magic bytes verified
- ✅ ELF format verified (after decompression)

### Test Case 3: Check Updates (Android)

**Request**:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/patches-check \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "appId": "com.example.app",
    "currentVersion": "3.0.36",
    "platform": "android",
    "architecture": "arm64-v8a",
    "acceptCompression": ["xz"]
  }'
```

**Expected**:
```json
{
  "updateAvailable": true,
  "patchId": "patch_3.0.37_12345",
  "version": "3.0.37",
  "downloadUrl": "/patches-download?patchId=patch_3.0.37_12345&compression=xz",
  "size": 1310720,
  "hash": "abc123...",
  "compression": "xz"
}
```

### Test Case 4: Check Updates (iOS)

**Request**:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/patches-check \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "appId": "com.example.app",
    "currentVersion": "3.0.36",
    "platform": "ios",
    "architecture": "arm64",
    "acceptCompression": ["xz"]
  }'
```

**Expected**:
```json
{
  "updateAvailable": true,
  "patchId": "patch_3.0.37_12346",
  "version": "3.0.37",
  "downloadUrl": "/patches-download?patchId=patch_3.0.37_12346&compression=xz",
  "size": 2228224,
  "hash": "def456...",
  "compression": "xz"
}
```

### Test Case 5: Download iOS Patch

**Request**:
```bash
curl -X GET \
  "https://your-project.supabase.co/functions/v1/patches-download?patchId=patch_3.0.37_12346&compression=xz" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -o patch_3.0.37.vmcode.xz
```

**Expected**:
- ✅ File downloads successfully
- ✅ Content-Type: `application/x-xz`
- ✅ File size: ~2.2 MB
- ✅ XZ decompresses to valid ELF file

## Error Scenarios

### Invalid iOS Patch (Not ELF)

**Upload**:
```bash
# Upload non-ELF file as iOS patch
```

**Expected Error**:
```json
{
  "error": "Invalid .vmcode file: missing ELF header",
  "code": "INVALID_PATCH",
  "status": 400
}
```

### Invalid Android Patch (Not QUICUI01)

**Upload**:
```bash
# Upload non-QUICUI file as Android patch
```

**Expected Error**:
```json
{
  "error": "Invalid patch file: missing QUICUI01 header",
  "code": "INVALID_PATCH",
  "status": 400
}
```

### Platform Mismatch

**Query**:
```json
{
  "platform": "ios",
  "architecture": "arm64-v8a"  // Android architecture
}
```

**Expected**:
- ✅ Validation passes (both are valid values)
- ❌ Query returns no results (no iOS patches with Android arch)
- Client should handle gracefully

## Migration Strategy

### Phase 1: Deploy Backend Updates (0 Downtime)

1. **Update patches-register function**
   - Add platform validation
   - Add iOS file format validation
   - Update storage path logic
   - Update logging

2. **Test with iOS patches**
   - Upload test `.vmcode` file
   - Verify storage path
   - Verify database record

3. **Verify Android still works**
   - Upload test `.quicui` file
   - Ensure backward compatibility
   - Verify existing patches still downloadable

### Phase 2: CLI Integration (Already Done ✅)

The CLI already sends `platform` field in metadata:
```dart
final metadata = {
  'platform': 'ios',
  'architecture': 'arm64',
  'appDillPath': appDillPath,
  // ...
};
```

### Phase 3: Client Integration (Next)

Update `quicui_client` to:
- Send `platform` in check request
- Handle `.vmcode` downloads on iOS
- Save with `.vmcode` extension

## Summary of Changes

### patches-register/index.ts
1. ✅ Add platform validation to schema
2. 🔧 Update file format validation (add ELF check for iOS)
3. 🔧 Update storage path logic (add `.vmcode` extension)
4. 🔧 Update logging (show platform and file type)
5. 📝 Update documentation comments

### patches-check/index.ts
- ✅ Already handles platform filtering
- ✅ Already uses platform-specific default architecture
- No changes needed!

### patches-download/index.ts
- ✅ Already platform-agnostic
- ✅ Already handles all file types
- No changes needed!

### Database Schema
- ✅ Already has `platform` field
- ✅ Already has proper indexes
- No changes needed!

## Estimated Implementation Time

| Task | Time | Priority |
|------|------|----------|
| Update file validation | 15 min | High |
| Update storage path logic | 10 min | High |
| Add platform validation | 5 min | Medium |
| Update logging | 10 min | Low |
| Update documentation | 10 min | Medium |
| Testing | 30 min | High |
| **Total** | **80 min** | |

## Next Steps

1. **Implement backend changes** (this plan)
2. **Deploy to Supabase** (test environment first)
3. **Test end-to-end**:
   - CLI upload → Supabase register → Storage
   - Client check → Supabase query → Patch available
   - Client download → Supabase download → .vmcode file
4. **Update client library** (Phase 3)
5. **Device testing** (Phase 4)

## Conclusion

The Supabase backend needs **minimal changes** to support iOS:

✅ **Already Has**:
- Platform field in database
- Platform filtering in queries
- Platform-agnostic downloads
- Proper architecture handling

🔧 **Needs**:
- iOS file format validation (ELF check)
- iOS storage path (.vmcode extension)
- Platform validation in schema

The backend is 90% ready for iOS support. The remaining 10% consists of minor validation and path logic updates that can be completed in ~1 hour.
