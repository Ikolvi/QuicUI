# QuicUI Visual Architecture & Reference Guide

**Purpose**: Quick visual reference for all system components

---

## 1. System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        DEVELOPER WORKFLOW                       │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │   QuicUI CLI Tool              │
        │ • quicui init                  │
        │ • quicui build                 │
        │ • quicui patch create          │
        │ • quicui release push          │
        │ • quicui analytics show        │
        └────────────┬───────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │   Code Compiler & Differ      │
        │ • Analyze changes             │
        │ • Generate diffs              │
        │ • Sign patches                │
        │ • Compress (Brotli)           │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │   QuicUI Backend Server       │
        │ • Receive patches             │
        │ • Store in database           │
        │ • Serve via API               │
        │ • Track analytics             │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │   CDN / Cloud Storage         │
        │ • Host patch files            │
        │ • High-speed delivery         │
        │ • Global distribution         │
        └────────────┬──────────────────┘
                     │
      ┌──────────────┴────────────────┐
      │                               │
      ▼                               ▼
┌────────────────┐          ┌────────────────┐
│ Modified       │          │ Modified       │
│ Flutter SDK    │          │ Flutter SDK    │
│ (Android)      │          │ (iOS)          │
│ • Patch loader │          │ • Patch loader │
│ • Verifier     │          │ • Verifier     │
└────┬───────────┘          └────┬───────────┘
     │                           │
     ▼                           ▼
┌────────────────┐          ┌────────────────┐
│  User's Android│          │  User's iOS    │
│  App + Runtime │          │  App + Runtime │
│  • Downloads   │          │  • Downloads   │
│  • Verifies    │          │  • Verifies    │
│  • Applies     │          │  • Applies     │
└────────────────┘          └────────────────┘
```

---

## 2. Patch Generation Pipeline

```
DEVELOPER MAKES CHANGE
        │
        ▼
    ┌──────────────┐
    │ Old Code     │
    │ v1.0.0       │
    └──────────────┘
        │
        ▼
    ┌──────────────┐
    │ New Code     │
    │ v1.0.1       │
    └──────────────┘
        │
        ▼
    Compile both to Kernel (intermediate representation)
        │
    ┌───────────┬───────────┐
    ▼           ▼           ▼
  OLD      COMPARE      NEW
 KERNEL   ──────────   KERNEL
         BINARY DIFF
    │           ▼           │
    └────►  Diff Output ◄───┘
            │
            ▼
        ┌─────────────┐
        │ Delta (~50KB) │  ◄─── 98% smaller than full app!
        └──────┬──────┘
               │
               ▼
        ┌──────────────────┐
        │ Compress         │
        │ (Brotli/Zstd)    │
        │ 60-80% reduction │
        └──────┬───────────┘
               │
               ▼
        ┌──────────────────┐
        │ Create Manifest  │
        │ (metadata.json)  │
        └──────┬───────────┘
               │
               ▼
        ┌──────────────────┐
        │ Sign with        │
        │ Ed25519 key      │
        │ (private key)    │
        └──────┬───────────┘
               │
               ▼
        ┌──────────────────┐
        │ PATCH BUNDLE     │
        │ ├─ metadata      │
        │ ├─ kernel.patch  │
        │ ├─ assets.patch  │
        │ └─ signature.txt │
        └──────┬───────────┘
               │
               ▼
        READY TO UPLOAD
```

---

## 3. Runtime Patch Application Flow

```
APP STARTUP (Device)
        │
        ▼
┌──────────────────────────┐
│ 1. Load Flutter Engine   │
│ (with QuicUI patches)    │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│ 2. Check for Patch       │
│ • Connect to backend     │
│ • Send current version   │
│ • Query available patch  │
└──────────┬───────────────┘
           │
           ├─── NO PATCH ───┐
           │                │
           └─ HAS PATCH ─┐  │
                         │  │
                         ▼  ▼
                   ┌──────────────────┐
                   │ 3a. Download     │
                   │ • From CDN       │
                   │ • With progress  │
                   │ • Resume capable │
                   └────────┬─────────┘
                            │
                   ┌────────▼─────────┐
                   │ 3b. Verify       │
                   │ • SHA256 check   │
                   │ • Ed25519 sig    │
                   │ • Size bounds    │
                   └────────┬─────────┘
                            │
                   VERIFICATION PASSED?
                            │
            ┌───── NO ──────┐  └─ YES ─┐
            │               │          │
            ▼               ▼          ▼
        DELETE        USE OLD    ┌──────────────┐
        PATCH         BUNDLED    │ 4. Apply     │
                      CODE       │ • Merge      │
                                 │ • Link refs  │
                                 │ • Save state │
                                 └────┬─────────┘
                                      │
                                      ▼
                              ┌──────────────────┐
                              │ 5. Restart App   │
                              │ (with patches)   │
                              └────┬─────────────┘
                                   │
                                   ▼
                        ┌────────────────────┐
                        │ APP RUNS WITH      │
                        │ LATEST CODE!       │
                        └────────────────────┘
```

---

## 4. File Structure Reference

```
quicui-platform/
│
├── packages/                          # Monorepo packages
│   ├── quicui_cli/
│   │   ├── bin/
│   │   │   └── quicui.dart          # Executable entry point
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── commands/        # CLI commands
│   │   │   │   ├── services/        # API, compiler, storage
│   │   │   │   ├── models/          # Data models
│   │   │   │   └── utils/           # Helpers
│   │   │   └── quicui_cli.dart      # Main export
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── quicui_compiler/
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── analyzer/        # Kernel analysis
│   │   │   │   ├── compiler/        # Patch compilation
│   │   │   │   ├── compressor/      # Brotli/delta
│   │   │   │   └── signer/          # Ed25519 signing
│   │   │   └── quicui_compiler.dart
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── quicui_code_push_client/
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── models/
│   │   │   │   ├── services/
│   │   │   │   └── utils/
│   │   │   └── quicui_code_push_client.dart
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   └── quicui_backend/
│       ├── lib/
│       │   ├── src/
│       │   │   ├── routes/          # API endpoints
│       │   │   ├── handlers/        # Request handlers
│       │   │   ├── database/        # Models, migrations
│       │   │   ├── services/        # Business logic
│       │   │   └── middleware/      # Auth, CORS, etc
│       │   └── server.dart
│       ├── bin/
│       │   └── server.dart
│       ├── test/
│       └── pubspec.yaml
│
├── forks/                             # External forks
│   ├── flutter/                       # Modified Flutter SDK
│   │   ├── engine/src/
│   │   │   ├── runtime/
│   │   │   │   ├── codepush_loader.cc   # NEW
│   │   │   │   ├── patch_manager.cc     # NEW
│   │   │   │   └── dart_vm.cc           # MODIFIED
│   │   │   ├── platform/
│   │   │   │   ├── android/
│   │   │   │   │   └── codepush_channel.cc # NEW
│   │   │   │   └── ios/
│   │   │   │       └── CodePushChannel.mm  # NEW
│   │   │   └── shell/common/
│   │   │       └── engine.cc          # MODIFIED
│   │   │
│   │   └── lib/src/
│   │       ├── services/
│   │       │   └── binding.dart      # MODIFIED
│   │       └── code_push/            # NEW directory
│   │           ├── code_push_manager.dart
│   │           ├── patch_loader.dart
│   │           ├── signature_verifier.dart
│   │           └── storage_manager.dart
│   │
│   └── shorebird-reference/           # For comparison
│
├── infrastructure/
│   ├── docker/
│   │   ├── Dockerfile.backend
│   │   └── docker-compose.yaml
│   ├── kubernetes/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   └── terraform/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── docs/
│   ├── architecture/
│   │   └── system-design.md
│   ├── guides/
│   │   ├── developer-guide.md
│   │   ├── deployment-guide.md
│   │   └── troubleshooting.md
│   └── api/
│       └── openapi-spec.yaml
│
├── scripts/
│   ├── ci/
│   │   ├── test.sh
│   │   ├── build.sh
│   │   └── deploy.sh
│   ├── deploy/
│   │   ├── setup-backend.sh
│   │   ├── migrate-db.sh
│   │   └── deploy-k8s.sh
│   └── util/
│       ├── format.sh
│       └── lint.sh
│
├── .github/
│   └── workflows/
│       ├── test.yaml
│       ├── build.yaml
│       └── deploy.yaml
│
├── QUICUI_IMPLEMENTATION_PLAN.md
├── SHOREBIRD_ANALYSIS.md
├── GETTING_STARTED.md
├── TECHNICAL_DEEP_DIVE.md
├── PROJECT_SUMMARY.md
├── README.md
├── ROADMAP.md
├── pubspec.yaml
├── analysis_options.yaml
└── .gitignore
```

---

## 5. Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    QUICUI DATA FLOW                           │
└──────────────────────────────────────────────────────────────┘

DEVELOPER
   │
   ├─→ CLI: quicui build
   │       ↓
   │   ┌─────────────────┐
   │   │ Read Flutter    │
   │   │ source & config │
   │   └────────┬────────┘
   │            ↓
   │   ┌─────────────────┐
   │   │ Compile to      │
   │   │ Kernel + Assets │
   │   └────────┬────────┘
   │            └─→ BUILD ARTIFACTS
   │
   ├─→ CLI: quicui patch create
   │       ↓
   │   ┌─────────────────────────┐
   │   │ Compare with previous   │
   │   │ build artifacts         │
   │   └────────┬────────────────┘
   │            ↓
   │   ┌─────────────────────────┐
   │   │ Generate diff (delta)   │
   │   │ kernel.patch (50KB)     │
   │   └────────┬────────────────┘
   │            └─→ PATCH FILE
   │
   ├─→ CLI: quicui release push
   │       ↓
   │   ┌──────────────────────┐
   │   │ Sign patch with      │
   │   │ private key (Ed25519)│
   │   └────────┬─────────────┘
   │            ↓
   │   ┌──────────────────────┐
   │   │ Upload to Backend    │
   │   │ API via HTTPS        │
   │   └────────┬─────────────┘
   │            ↓
   │   ┌──────────────────────┐
   │   │ Backend stores:      │
   │   │ • DB: metadata       │
   │   │ • CDN: patch file    │
   │   └────────┬─────────────┘
   │            └─→ DEPLOYED
   │
   └─→ CLI: quicui release activate 50%
           ↓
        ┌────────────────────┐
        │ Set rollout % in   │
        │ database (gradual) │
        └────────┬───────────┘
                 └─→ USERS GET UPDATES

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

USER'S DEVICE
   │
   ├─→ App starts
   │      ↓
   │   ┌────────────────────┐
   │   │ Initialize Code    │
   │   │ Push Manager       │
   │   └────────┬───────────┘
   │            ↓
   │   ┌────────────────────┐
   │   │ Check /api/check   │
   │   │ send: curr_version │
   │   └────────┬───────────┘
   │            ↓
   │   Backend checks if user (50% rollout) gets patch
   │            ↓
   │   ┌────────────────────┐
   │   │ Receive patch URL  │
   │   │ and metadata       │
   │   └────────┬───────────┘
   │            ↓
   │   ┌────────────────────┐
   │   │ Download from CDN  │
   │   │ (50KB, fast!)      │
   │   └────────┬───────────┘
   │            ↓
   │   ┌────────────────────┐
   │   │ Verify signature   │
   │   │ using public key   │
   │   └────────┬───────────┘
   │            ├─ INVALID? → DELETE & USE OLD CODE
   │            │
   │            └─ VALID?
   │                 ↓
   │   ┌────────────────────┐
   │   │ Apply patch:       │
   │   │ • Merge kernel     │
   │   │ • Link methods     │
   │   │ • Save to storage  │
   │   └────────┬───────────┘
   │            ↓
   │   ┌────────────────────┐
   │   │ Restart app        │
   │   │ (cold start)       │
   │   └────────┬───────────┘
   │            ↓
   │   ┌────────────────────┐
   │   │ Load patched code  │
   │   │ from engine        │
   │   └────────┬───────────┘
   │            ↓
   │   ┌────────────────────┐
   │   │ App runs NEW CODE  │
   │   │ v1.0.1 features!   │
   │   └────────┬───────────┘
   │            ↓
   │   ┌────────────────────┐
   │   │ Log event:         │
   │   │ patch_applied      │
   │   └────────┬───────────┘
   │            └─→ BACKEND RECEIVES ANALYTICS
```

---

## 6. Component Dependencies

```
quicui_cli
  ├── quicui_compiler  (call to compile patches)
  ├── http             (API communication)
  ├── args             (command line parsing)
  └── path             (file operations)

quicui_compiler
  ├── analyzer         (Dart AST analysis)
  ├── crypto           (Ed25519 signing)
  └── path             (file operations)

quicui_code_push_client
  ├── http             (API calls)
  ├── crypto           (signature verification)
  ├── path_provider    (local file storage)
  ├── shared_preferences (settings)
  └── flutter          (framework integration)

quicui_backend
  ├── shelf            (HTTP server)
  ├── postgres         (database)
  ├── crypto           (signature verification)
  └── http             (outbound API calls)

Modified Flutter SDK
  ├── Dart runtime     (code execution)
  ├── C++ engine       (platform layer)
  └── OpenSSL          (cryptography)
```

---

## 7. Key Algorithms Quick Reference

```
┌─────────────────────────────────────────────────────┐
│              PATCH GENERATION                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Input:  Old Kernel + New Kernel                   │
│                                                     │
│  Algorithm:                                        │
│  1. Load both kernels                              │
│  2. Compare SHA256 hashes of libraries             │
│     → Find changed libraries                       │
│  3. For each changed library:                      │
│     a. Compare SHA256 hashes of classes            │
│        → Find changed classes                      │
│     b. Generate BSDIFF for each class bytecode     │
│  4. Combine all diffs                              │
│  5. Compress with Brotli/Zstd                      │
│  6. Generate manifest.json                         │
│  7. Sign manifest with Ed25519                     │
│                                                     │
│  Output: Patch Bundle (~50-500KB)                  │
│          Usually 95%+ smaller than full app        │
│                                                     │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│          SIGNATURE VERIFICATION                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Device has:  Public Key (in app assets)           │
│  Patch has:   Signature (from developer)           │
│                                                     │
│  Algorithm:                                        │
│  1. Extract signature from patch                   │
│  2. Compute SHA256 of patch data                   │
│  3. Ed25519.verify(                                │
│       patch_data,                                  │
│       signature,                                   │
│       public_key                                   │
│     )                                              │
│  4. If valid:  Apply patch                         │
│     If invalid: Delete patch, use old code         │
│                                                     │
│  Result:  100% tamper-proof patches                │
│                                                     │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│          PATCH APPLICATION                          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Process (in Flutter engine):                      │
│  1. Load base kernel                               │
│  2. If patch exists:                               │
│     a. Load patch diffs                            │
│     b. Apply each diff to kernel                   │
│     c. Merge into single kernel                    │
│     d. Validate result                             │
│  3. Load merged kernel into Dart VM                │
│  4. Continue normal app startup                    │
│                                                     │
│  Result:  Seamless to app, no code changes needed  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 8. Configuration Files Reference

### pubspec.yaml (CLI Package)
```yaml
name: quicui_cli
description: CLI for QuicUI code push
version: 0.1.0

environment:
  sdk: ^3.0.0

dependencies:
  args: ^2.4.0
  http: ^1.1.0
  yaml: ^3.1.0

executables:
  quicui: quicui
```

### Backend docker-compose.yaml
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: quicui_db
      POSTGRES_PASSWORD: dev

  backend:
    build: .
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgresql://...
      JWT_SECRET: dev-secret
```

---

## 9. API Response Examples

### Check for Updates Response
```json
{
  "available": true,
  "patch": {
    "patch_id": "patch_abc123",
    "from_version": "1.0.0",
    "to_version": "1.0.1",
    "download_url": "https://cdn.quicui.dev/patch_abc123.bin",
    "size_bytes": 45120,
    "signature": "base64_encoded_signature_here",
    "requires_restart": false
  }
}
```

### Upload Patch Response
```json
{
  "patch_id": "patch_abc123",
  "status": "uploaded",
  "size_bytes": 45120,
  "compression_ratio": 0.85,
  "url": "https://api.quicui.dev/patches/patch_abc123",
  "created_at": "2025-11-01T10:30:00Z"
}
```

---

## 10. Success Metrics Dashboard

```
┌──────────────────────────────────────────┐
│         QUICUI SUCCESS METRICS            │
├──────────────────────────────────────────┤
│                                          │
│  Compilation                             │
│  ├─ Time to compile patch: < 5 min       │
│  ├─ Patch size reduction: 85-95%         │
│  └─ Success rate: 100%                   │
│                                          │
│  Deployment                              │
│  ├─ API response time: < 500ms           │
│  ├─ Patch upload time: < 1 min           │
│  ├─ Download speed: > 10 Mbps            │
│  └─ CDN uptime: 99.99%                   │
│                                          │
│  Runtime                                 │
│  ├─ Startup overhead: < 100ms            │
│  ├─ Patch apply time: < 1 sec            │
│  ├─ Memory usage: < 10 MB                │
│  └─ Success rate: 99%+                   │
│                                          │
│  Security                                │
│  ├─ Signature verification: 100%         │
│  ├─ Tamper detection: 100%               │
│  ├─ Secure storage: Yes                  │
│  └─ Audit passed: Yes                    │
│                                          │
└──────────────────────────────────────────┘
```

---

## Quick Command Reference

```bash
# Development
quicui init                    # Initialize project
quicui auth login             # Login to service
quicui build                  # Build for patches
quicui patch create           # Create patch
quicui patch preview          # See what would change
quicui patch validate         # Validate patch

# Deployment
quicui release push           # Push to backend
quicui release activate 50%   # Activate for 50% of users
quicui release rollback       # Rollback to previous
quicui release schedule       # Schedule for later

# Monitoring
quicui analytics show         # Show deployment stats
quicui analytics monitor      # Real-time monitoring
quicui status check           # Check patch status

# Configuration
quicui config set key value   # Set config
quicui config show            # Show current config
quicui keys generate          # Generate signing keys
```

---

