# QuicUI Compiler - Auto-Register Feature

## Overview

The QuicUI compiler now automatically uploads patches to the backend server after generation, eliminating the need for manual registration steps.

## What Changed

### Before (Manual Registration)
```bash
# Step 1: Generate patch
quicui-compiler diff v1.0.0/libapp.so v1.0.1/libapp.so \
  --output=patch.quicui \
  --compress=none

# Step 2: Manually register patch
quicui-compiler register patch.quicui \
  --app-id=com.example.app \
  --version=1.0.1 \
  --server-url=http://192.168.20.102:8080
```

### After (Automatic Registration)
```bash
# One command does everything!
quicui-compiler diff v1.0.0/libapp.so v1.0.1/libapp.so \
  --output=patch.quicui \
  --compress=none \
  --app-id=com.example.app \
  --version=1.0.1 \
  --server-url=http://192.168.20.102:8080
```

## Usage

### Basic Usage with Auto-Register

Generate a patch and automatically register it with the backend:

```bash
quicui-compiler diff old_snapshot.so new_snapshot.so \
  --output=my_patch.quicui \
  --app-id=com.quicui.myapp \
  --version=1.0.1 \
  --server-url=http://192.168.20.102:8080 \
  --compress=none
```

### Options

| Option | Description | Required | Default |
|--------|-------------|----------|---------|
| `--app-id` | Application package ID | Yes (for auto-register) | - |
| `--version` | Patch version | Yes (for auto-register) | - |
| `--server-url` | Backend server URL | No | `http://192.168.20.102:8080` |
| `--compress` | Compression algorithm (none, xz, gz, bz2) | No | `none` |
| `--output` | Output patch file path | No | `patch.quicui` |
| `--no-register` | Skip automatic registration | No | false |

### Skip Auto-Registration

If you want to generate a patch without registering it:

```bash
quicui-compiler diff old.so new.so \
  --output=patch.quicui \
  --no-register
```

### Partial Parameters

If you omit `--app-id` or `--version`, the patch will be generated but registration will be skipped:

```bash
# This will generate the patch but skip registration
quicui-compiler diff old.so new.so --output=patch.quicui

# Output:
# ✅ Patch generated successfully!
# ⚠️  Skipping auto-registration (--app-id and --version required)
```

## How It Works

1. **Generate Patch**: Uses BsDiff to create binary patch
2. **Apply Compression**: Optionally compresses with xz/gz/bz2
3. **Calculate Hash**: Generates SHA256 hash of patch
4. **Detect Compressed Versions**: Finds all compressed variants (`.xz`, `.gz`, `.bz2`)
5. **Send to Backend**: POST request to `/api/v1/patches/register` endpoint
6. **Verify Success**: Confirms patch is registered and available

## Backend Integration

The compiler sends a registration payload to the backend:

```json
{
  "patchId": "com.quicui.myapp_v1.0.1",
  "version": "1.0.1",
  "appId": "com.quicui.myapp",
  "uncompressedPath": "/absolute/path/to/patch.quicui",
  "compressedPaths": {
    "xz": "/absolute/path/to/patch.quicui.xz"
  },
  "uncompressedSize": 4534523,
  "compressedSizes": {
    "xz": 1342156
  },
  "hash": "a1b2c3d4..."
}
```

## Example Output

```
🔧 QuicUI Binary Diff
════════════════════════════════════════════════════════════
Old file:     v1.0.0/libapp.so
New file:     v1.0.1/libapp.so
Output:       patch.quicui
Compression:  none
Server URL:   http://192.168.20.102:8080
App ID:       com.quicui.test_app_fresh
Version:      1.0.1
════════════════════════════════════════════════════════════

✅ Patch generated successfully!

Patch Statistics:
  Old size:        4.30 MB
  New size:        4.30 MB
  Patch size:      4.30 MB
  Operations:      5421

Old hash: d4e5f6...
New hash: a1b2c3...

📤 Auto-registering patch with backend...

📤 Registering Patch with Backend
════════════════════════════════════════════════════════════
Patch file:  patch.quicui
Server URL:  http://192.168.20.102:8080
App ID:      com.quicui.test_app_fresh
Version:     1.0.1
════════════════════════════════════════════════════════════

📊 Patch Information:
   Uncompressed: 4.30 MB
   SHA256:       a1b2c3d4...

📤 Sending registration request to http://192.168.20.102:8080/api/v1/patches/register...

✅ Patch registered successfully!

Patch Details:
   Patch ID: com.quicui.test_app_fresh_v1.0.1
   Message:  Patch registered successfully

Next Steps:
1. Test patch check:
   curl -X POST http://192.168.20.102:8080/api/v1/patches/check \
     -H "Content-Type: application/json" \
     -d '{"appId": "com.quicui.test_app_fresh", "currentVersion": "1.0.0", "acceptCompression": []}'
```

## Automated Testing

The project includes a complete end-to-end test script using the auto-register feature:

```bash
# Run the automated test
cd test_apps/test_app_fresh
bash test_codepush_auto.sh
```

This script:
1. Builds v1.0.0 (baseline)
2. Installs on device
3. Builds v1.0.1 (with changes)
4. **Generates patch with auto-register** ← Uses new feature
5. Verifies patch availability
6. Launches app for testing

## Benefits

1. **Fewer Commands**: One command instead of two
2. **Less Error-Prone**: No chance of forgetting registration step
3. **Faster Workflow**: Immediate upload after generation
4. **Better UX**: Progress shown in single flow
5. **Atomic Operation**: Generation + registration together

## Configuration File (Future Enhancement)

Consider creating a `.quicuirc` config file to avoid repeating parameters:

```json
{
  "serverUrl": "http://192.168.20.102:8080",
  "appId": "com.quicui.test_app_fresh",
  "compression": "none"
}
```

Then simply:
```bash
quicui-compiler diff old.so new.so --version=1.0.1
```

## Troubleshooting

### Registration Fails

If auto-registration fails, the patch file is still created. You can manually register it:

```bash
quicui-compiler register patch.quicui \
  --app-id=com.example.app \
  --version=1.0.1
```

### Wrong Server URL

Check that the backend server is running:

```bash
curl http://192.168.20.102:8080/health
# Should return: {"status":"OK"}
```

### Patch Not Available

Verify registration:

```bash
curl -X POST http://192.168.20.102:8080/api/v1/patches/check \
  -H "Content-Type: application/json" \
  -d '{"appId": "com.example.app", "currentVersion": "1.0.0"}'
```

## See Also

- [COMPILER_USAGE.md](COMPILER_USAGE.md) - Complete compiler documentation
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Backend deployment
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - End-to-end testing
