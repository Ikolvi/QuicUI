# Supabase Backend - iOS Support Implementation Complete

**Date**: November 27, 2025  
**Status**: ✅ Complete  
**Phase**: Phase 2.5 (Backend Updates)

## Summary

Successfully updated the Supabase Edge Functions to support iOS `.vmcode` patches alongside Android `.quicui` patches. The backend now validates, stores, and serves both patch types correctly.

## Changes Implemented

### 1. patches-register Function

**File**: `supabase/functions/patches-register/index.ts`

#### Added Platform Validation
```typescript
platform: {
  type: 'string',
  enum: ['android', 'ios'],
},
```
- Validates platform is either 'android' or 'ios'
- Prevents typos and invalid values

#### Updated File Format Validation
```typescript
if (platform === 'ios') {
  // iOS patches are .vmcode ELF files
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
```
- iOS: Validates ELF magic bytes (0x7F 0x45 0x4C 0x46)
- Android: Validates QUICUI01 header
- Clear error messages for each platform

#### Updated Storage Path Logic
```typescript
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

console.log(`📤 Storage path: ${uploadPath}`);
```
- iOS patches get `.vmcode` extension
- Android patches keep `.quicui` extension
- Clear differentiation in storage

#### Enhanced Logging
```typescript
const platform = body.platform || 'android';
const defaultArch = platform === 'ios' ? 'arm64' : 'arm64-v8a';
const fileType = platform === 'ios' ? '.vmcode' : '.quicui';

console.log('📝 Registering patch:', {
  patchId,
  version,
  appId,
  platform,
  architecture: architecture || defaultArch,
  compression: compression || 'none',
  uncompressedSize,
  compressedSize: compressedSize || uncompressedSize,
  fileType,
});
```
- Shows platform and file type
- Uses platform-appropriate defaults
- Better debugging information

#### Updated Documentation
```typescript
// QuicUI Patch Registration Function
// Registers a new patch with the backend after compiler generates it
//
// Supported Platforms:
// - Android: BsDiff patches (.quicui) with QUICUI01 header
// - iOS: Dart VM snapshots (.vmcode) with ELF format
//
// Security Features:
// - Platform-specific format validation
// ...
```

### 2. patches-check Function

**File**: `supabase/functions/patches-check/index.ts`

**Status**: ✅ No changes needed

Already correctly handles:
- Platform filtering in queries
- Platform-specific default architecture
- Returns appropriate patches per platform

### 3. patches-download Function

**File**: `supabase/functions/patches-download/index.ts`

**Status**: ✅ No changes needed

Already correctly handles:
- Platform-agnostic downloads
- All file types (.quicui, .vmcode, .xz, etc.)
- Proper content types

## Storage Structure

### Before (Android only)
```
storage/patches/
└── com.example.app/
    ├── patch_3.0.37_12345.quicui
    └── patch_3.0.37_12345.quicui.xz
```

### After (Android + iOS)
```
storage/patches/
└── com.example.app/
    ├── patch_3.0.37_12345.quicui.xz     # Android
    └── patch_3.0.37_12346.vmcode.xz     # iOS
```

Different patch IDs ensure no conflicts between platforms.

## API Examples

### Register Android Patch
```bash
curl -X POST https://project.supabase.co/functions/v1/patches-register \
  -H "Authorization: Bearer API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F "patchId=patch_3.0.37_12345" \
  -F "version=3.0.37" \
  -F "appId=com.example.app" \
  -F "platform=android" \
  -F "architecture=arm64-v8a" \
  -F "compression=xz" \
  -F "patchFile=@patch.quicui.xz" \
  -F "uncompressedSize=5242880" \
  -F "compressedSize=1310720" \
  -F "hash=abc123..."
```

**Response**:
```json
{
  "success": true,
  "patchId": "patch_3.0.37_12345",
  "message": "Patch patch_3.0.37_12345 registered successfully"
}
```

**Storage**: `patches/com.example.app/patch_3.0.37_12345.quicui.xz`

### Register iOS Patch
```bash
curl -X POST https://project.supabase.co/functions/v1/patches-register \
  -H "Authorization: Bearer API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F "patchId=patch_3.0.37_12346" \
  -F "version=3.0.37" \
  -F "appId=com.example.app" \
  -F "platform=ios" \
  -F "architecture=arm64" \
  -F "compression=xz" \
  -F "patchFile=@patch.vmcode.xz" \
  -F "uncompressedSize=8912896" \
  -F "compressedSize=2228224" \
  -F "hash=def456..."
```

**Response**:
```json
{
  "success": true,
  "patchId": "patch_3.0.37_12346",
  "message": "Patch patch_3.0.37_12346 registered successfully"
}
```

**Storage**: `patches/com.example.app/patch_3.0.37_12346.vmcode.xz`

### Check for iOS Updates
```bash
curl -X POST https://project.supabase.co/functions/v1/patches-check \
  -H "Authorization: Bearer API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "appId": "com.example.app",
    "currentVersion": "3.0.36",
    "platform": "ios",
    "architecture": "arm64",
    "acceptCompression": ["xz"]
  }'
```

**Response**:
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

### Download iOS Patch
```bash
curl -X GET \
  "https://project.supabase.co/functions/v1/patches-download?patchId=patch_3.0.37_12346&compression=xz" \
  -H "Authorization: Bearer API_KEY" \
  -o patch_3.0.37.vmcode.xz
```

**Headers**:
```
Content-Type: application/x-xz
Content-Length: 2228224
Content-Disposition: attachment; filename="patch_3.0.37_12346.xz"
X-Patch-Version: 3.0.37
X-Patch-Hash: def456...
```

## Validation

### iOS Patch Validation
```typescript
// XZ Compression (if present)
if (compression === 'xz') {
  const xzMagic = [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00];
  // Validates XZ magic bytes
}

// ELF Format (iOS .vmcode)
if (platform === 'ios') {
  const elfMagic = [0x7F, 0x45, 0x4C, 0x46];  // \x7fELF
  // Validates ELF magic bytes
}
```

### Android Patch Validation
```typescript
// XZ Compression (if present)
if (compression === 'xz') {
  const xzMagic = [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00];
  // Validates XZ magic bytes
}

// QUICUI01 Format (Android patches)
if (platform === 'android') {
  const header = String.fromCharCode(...bytes.slice(0, 8));
  // Validates header === 'QUICUI01'
}
```

## Error Scenarios

### Invalid iOS Patch (Not ELF)
```json
{
  "error": "Invalid .vmcode file: missing ELF header",
  "code": "INVALID_PATCH",
  "status": 400
}
```

### Invalid Android Patch (Not QUICUI01)
```json
{
  "error": "Invalid patch file: missing QUICUI01 header",
  "code": "INVALID_PATCH",
  "status": 400
}
```

### Invalid Platform
```json
{
  "error": "Validation failed: platform must be one of: android, ios",
  "code": "VALIDATION_ERROR",
  "status": 400
}
```

### Invalid XZ Compression
```json
{
  "error": "Invalid compressed patch: XZ magic bytes not found",
  "code": "INVALID_COMPRESSION",
  "status": 400
}
```

## Database Records

### Android Patch Record
```json
{
  "patch_id": "patch_3.0.37_12345",
  "version": "3.0.37",
  "app_id": "com.example.app",
  "platform": "android",
  "architecture": "arm64-v8a",
  "uncompressed_path": "patches/com.example.app/patch_3.0.37_12345.quicui.xz",
  "compressed_paths": { "xz": "patches/com.example.app/patch_3.0.37_12345.quicui.xz" },
  "uncompressed_size": 5242880,
  "compressed_sizes": { "xz": 1310720 },
  "hash": "abc123...",
  "compression": "xz",
  "status": "active"
}
```

### iOS Patch Record
```json
{
  "patch_id": "patch_3.0.37_12346",
  "version": "3.0.37",
  "app_id": "com.example.app",
  "platform": "ios",
  "architecture": "arm64",
  "uncompressed_path": "patches/com.example.app/patch_3.0.37_12346.vmcode.xz",
  "compressed_paths": { "xz": "patches/com.example.app/patch_3.0.37_12346.vmcode.xz" },
  "uncompressed_size": 8912896,
  "compressed_sizes": { "xz": 2228224 },
  "hash": "def456...",
  "compression": "xz",
  "status": "active"
}
```

## Testing Checklist

- [x] ✅ Platform validation works
- [x] ✅ iOS ELF format validation
- [x] ✅ Android QUICUI01 validation
- [x] ✅ XZ compression validation
- [x] ✅ Storage path uses correct extension
- [x] ✅ Logging shows platform info
- [x] ✅ Database stores platform correctly
- [x] ✅ patches-check filters by platform
- [x] ✅ patches-download serves both formats

## Integration Status

### ✅ Completed Phases

**Phase 1: Engine Modifications** ✅
- Engine supports .vmcode loading
- Dart_LoadELF integration
- iOS interpreter mode

**Phase 2: CLI Updates** ✅
- generate-patch creates .vmcode for iOS
- build-ipa extracts app.dill
- Platform detection automatic

**Phase 2.5: Backend Updates** ✅ (THIS PHASE)
- patches-register validates .vmcode
- Storage uses .vmcode extension
- Platform-specific validation
- Enhanced logging

### ⏳ Remaining Phases

**Phase 3: Client Library** (Next)
- Update quicui_client for iOS
- Handle .vmcode downloads
- Platform detection
- Save with correct extension

**Phase 4: End-to-End Testing**
- Build baseline iOS app
- Generate .vmcode patch
- Upload to backend
- Download and apply
- Verify on device

## Deployment

### Prerequisites
- Supabase project configured
- Edge Functions deployed
- Storage bucket 'patches' created
- Database schema with platform field

### Deploy Command
```bash
supabase functions deploy patches-register
supabase functions deploy patches-check
# patches-download doesn't need redeployment
```

### Verify Deployment
```bash
# Test iOS patch registration
curl -X POST https://project.supabase.co/functions/v1/patches-register \
  -H "Authorization: Bearer API_KEY" \
  --data-binary @test_ios_patch.json

# Check function logs
supabase functions logs patches-register
```

## Benefits Achieved

✅ **Platform Support**: Both Android and iOS patches supported  
✅ **Format Validation**: ELF for iOS, QUICUI01 for Android  
✅ **Storage Organization**: Clear file extensions (.vmcode vs .quicui)  
✅ **Backward Compatible**: Existing Android patches still work  
✅ **Type Safe**: Platform validation prevents errors  
✅ **Well Documented**: Clear logs and error messages  
✅ **Production Ready**: Robust validation and error handling  

## Summary

The Supabase backend is now fully configured to support iOS code push:

- ✅ Validates iOS .vmcode ELF format
- ✅ Stores files with .vmcode extension
- ✅ Filters patches by platform
- ✅ Maintains Android compatibility
- ✅ Clear logging and error messages
- ✅ Ready for client integration

**Next Step**: Update client library (Phase 3) to download and handle .vmcode files on iOS devices.
