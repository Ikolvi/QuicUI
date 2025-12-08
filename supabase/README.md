# QuicUI Backend - Supabase Deployment

This directory contains the Supabase-based backend for QuicUI code push system.

## Structure

```
supabase/
├── config.toml                  # Supabase local configuration
├── .env.example                 # Environment variables template
├── functions/                   # Edge Functions (serverless)
│   ├── patches-check/           # Check for available patches
│   ├── patches-register/        # Register new patches
│   └── patches-download/        # Download patch files
├── migrations/                  # Database schema migrations
│   ├── 001_create_patches_table.sql
│   └── 002_create_download_stats_table.sql
└── README.md                    # This file
```

## Setup

### 1. Install Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Or using npm
npm install -g supabase
```

### 2. Initialize Local Development

```bash
cd supabase
supabase login
supabase link --project-ref pcaxvanjhtfaeimflgfk
```

### 3. Configure Environment Variables

```bash
cp .env.example .env
# Edit .env with your credentials
```

### 4. Run Migrations

```bash
supabase db push
```

### 5. Deploy Edge Functions

```bash
# Deploy all functions
supabase functions deploy patches-check
supabase functions deploy patches-register
supabase functions deploy patches-download

# Or deploy all at once
supabase functions deploy
```

## Database Schema

### Patches Table

Stores metadata about code push patches:

- `patch_id` - Unique identifier (e.g., com.example.app_v1.0.1_arm64-v8a)
- `version` - Patch version (e.g., 1.0.1)
- `app_id` - Application package name
- `architecture` - CPU architecture (arm64-v8a, armeabi-v7a, x86_64)
- `uncompressed_path` - Path to uncompressed patch file
- `compressed_paths` - JSON with compressed file paths (xz, gz, bz2)
- `uncompressed_size` - Size in bytes
- `compressed_sizes` - JSON with compressed file sizes
- `hash` - SHA-256 hash for integrity verification
- `compression` - Compression type used
- `release_notes` - Optional release notes
- `critical` - Whether this is a critical update
- `download_count` - Number of downloads
- `success_count` - Successful applications
- `failure_count` - Failed applications
- `rollout_percentage` - Staged rollout percentage (0-100)

### Download Stats Table

Tracks individual downloads and applications:

- Device information (ID, model, OS version)
- Download metrics (size, duration, compression)
- Application results (success/failure, error messages)
- Performance metrics

## Edge Functions

### 1. patches-check

**Endpoint**: `POST /patches-check`

Checks if updates are available for a client.

**Request**:
```json
{
  "appId": "com.example.app",
  "currentVersion": "1.0.0",
  "architecture": "arm64-v8a",
  "acceptCompression": ["xz", "gzip"]
}
```

**Response**:
```json
{
  "updateAvailable": true,
  "patchId": "com.example.app_v1.0.1_arm64-v8a",
  "version": "1.0.1",
  "downloadUrl": "/patches-download?patchId=...",
  "size": 1070000,
  "hash": "86b8833bf...",
  "compression": "xz",
  "critical": false,
  "releaseNotes": "Bug fixes and improvements"
}
```

### 2. patches-register

**Endpoint**: `POST /patches-register`

Registers a new patch (called by compiler).

**Request**:
```json
{
  "patchId": "com.example.app_v1.0.1_arm64-v8a",
  "version": "1.0.1",
  "appId": "com.example.app",
  "architecture": "arm64-v8a",
  "uncompressedPath": "patch.quicui",
  "compressedPaths": {"xz": "patch.quicui.xz"},
  "uncompressedSize": 3611081,
  "compressedSizes": {"xz": 1070000},
  "hash": "86b8833bf...",
  "compression": "xz"
}
```

**Response**:
```json
{
  "success": true,
  "patchId": "com.example.app_v1.0.1_arm64-v8a",
  "message": "Patch registered successfully"
}
```

### 3. patches-download

**Endpoint**: `GET /patches-download?patchId=...&compression=xz`

Downloads a patch file.

**Response**: Binary patch file with appropriate Content-Encoding header

## Update Compiler Configuration

Update `quicui.yaml` to use Supabase backend:

```yaml
server:
  url: "https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1"
  api_key: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

The compiler's upload will now POST to:
```
https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1/patches-register
```

## Storage Integration (Future)

To serve actual patch files:

1. Upload patches to Supabase Storage:
   ```typescript
   const { data, error } = await supabase.storage
     .from('patches')
     .upload(`${patchId}.quicui.xz`, file);
   ```

2. Update patches-download function to stream from Storage:
   ```typescript
   const { data, error } = await supabase.storage
     .from('patches')
     .download(`${patchId}.quicui.xz`);
   ```

3. Set up Storage bucket policies for authenticated access

## Testing

### Local Testing

```bash
# Start local Supabase
supabase start

# Test patch check
curl -X POST http://localhost:54329/functions/v1/patches-check \
  -H "Content-Type: application/json" \
  -d '{
    "appId": "com.example.app",
    "currentVersion": "1.0.0",
    "architecture": "arm64-v8a",
    "acceptCompression": ["xz"]
  }'

# Test patch registration
curl -X POST http://localhost:54329/functions/v1/patches-register \
  -H "Content-Type: application/json" \
  -d '{
    "patchId": "test_v1.0.1_arm64-v8a",
    "version": "1.0.1",
    "appId": "com.example.app",
    "hash": "abc123",
    "uncompressedPath": "test.quicui",
    "uncompressedSize": 1000000
  }'
```

### Production Testing

```bash
# Test against production
curl -X POST https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1/patches-check \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{"appId": "com.example.app", "currentVersion": "1.0.0"}'
```

## Monitoring

Access Supabase Dashboard:
- URL: https://app.supabase.com/project/pcaxvanjhtfaeimflgfk
- Database: View patches and download_stats tables
- Edge Functions: View logs and metrics
- Storage: View uploaded patch files

## Security

1. **Row Level Security (RLS)**: Enable on patches table
2. **API Keys**: Use service role key for compiler, anon key for clients
3. **Rate Limiting**: Configure in Supabase dashboard
4. **CORS**: Configured in Edge Functions for web clients

## Cost Optimization

- Enable gzip compression on all responses
- Use CDN for patch file delivery (Supabase Storage has CDN)
- Implement caching headers for immutable patch files
- Monitor bandwidth usage in Supabase dashboard

## Backup

Database is automatically backed up by Supabase. To create manual backup:

```bash
supabase db dump -f backup.sql
```

## Next Steps

1. Set up Supabase Storage bucket for patch files
2. Implement file upload in compiler
3. Add authentication for compiler API
4. Set up monitoring and alerts
5. Configure staged rollouts
6. Add analytics dashboard
