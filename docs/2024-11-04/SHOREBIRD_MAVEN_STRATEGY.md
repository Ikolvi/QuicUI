# Shorebird Maven Publication & Distribution Strategy

**Date**: November 4, 2025  
**Analysis of**: Shorebird v1.6.66 Flutter fork

## Overview

Shorebird uses a **Maven repository proxy** approach rather than publishing custom engine artifacts. They intercept Flutter's normal Maven dependency resolution and redirect it to their own storage infrastructure.

## Key Components

### 1. Custom Storage URL

**Primary Storage**: `https://download.shorebird.dev`

```dart
// packages/flutter_tools/lib/src/cache.dart
const kShorebirdStorageUrl = 'https://download.shorebird.dev';
```

Shorebird sets `FLUTTER_STORAGE_BASE_URL` environment variable to replace Google's default:
- **Default Flutter**: `https://storage.googleapis.com`
- **Shorebird**: `https://download.shorebird.dev`

### 2. Gradle Maven Repository Configuration

**File**: `packages/flutter_tools/gradle/resolve_dependencies.gradle.kts`

```kotlin
val storageUrl: String = System.getenv("FLUTTER_STORAGE_BASE_URL") 
    ?: "https://storage.googleapis.com"

val engineVersion = Paths.get(
    flutterRoot.absolutePath,
    "bin",
    "cache",
    "engine.stamp"
).toFile().readText().trim()

var engineRealm = Paths.get(
    flutterRoot.absolutePath,
    "bin",
    "cache",
    "engine.realm"
).toFile().readText().trim()

if (engineRealm.isNotEmpty()) {
    engineRealm += "/"
}

repositories {
    google()
    mavenCentral()
    maven {
        url = uri("$storageUrl/${engineRealm}download.flutter.io")
    }
}
```

**Resolved URL Structure**:
```
https://download.shorebird.dev/download.flutter.io/io/flutter/arm64_v8a_release/1.0.0-<engine_version>/arm64_v8a_release-1.0.0-<engine_version>.jar
```

### 3. Maven Dependency Declaration

```kotlin
dependencies {
    "flutterRelease"("io.flutter:flutter_embedding_release:1.0.0-$engineVersion")
    "flutterRelease"("io.flutter:armeabi_v7a_release:1.0.0-$engineVersion")
    "flutterRelease"("io.flutter:arm64_v8a_release:1.0.0-$engineVersion")

    "flutterProfile"("io.flutter:flutter_embedding_profile:1.0.0-$engineVersion")
    "flutterProfile"("io.flutter:armeabi_v7a_profile:1.0.0-$engineVersion")
    "flutterProfile"("io.flutter:arm64_v8a_profile:1.0.0-$engineVersion")

    "flutterDebug"("io.flutter:flutter_embedding_debug:1.0.0-$engineVersion")
    "flutterDebug"("io.flutter:armeabi_v7a_debug:1.0.0-$engineVersion")
    "flutterDebug"("io.flutter:arm64_v8a_debug:1.0.0-$engineVersion")
    "flutterDebug"("io.flutter:x86_debug:1.0.0-$engineVersion")
    "flutterDebug"("io.flutter:x86_64_debug:1.0.0-$engineVersion")
}
```

**Same artifact IDs as Flutter** - no custom naming!

### 4. Engine Version Control

Shorebird controls which engine version is used via:

**File**: `bin/cache/engine.stamp`
```
d2913632a4fc16ad5722dd5344efb1855e65df9f
```

This hash determines:
1. Which engine artifacts to download
2. The Maven artifact version: `1.0.0-d2913632a4fc16ad5722dd5344efb1855e65df9f`

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter Build (gradle)                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Read FLUTTER_STORAGE_BASE_URL env var                  │
│     └─> "https://download.shorebird.dev"                   │
│                                                             │
│  2. Read engine.stamp                                       │
│     └─> "d2913632a4..."                                     │
│                                                             │
│  3. Resolve Maven dependency:                               │
│     io.flutter:arm64_v8a_release:1.0.0-d2913632a4...       │
│                                                             │
│  4. Gradle fetches from:                                    │
│     https://download.shorebird.dev/download.flutter.io/     │
│     io/flutter/arm64_v8a_release/1.0.0-d2913632a4.../      │
│     arm64_v8a_release-1.0.0-d2913632a4....jar              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Shorebird Storage (download.shorebird.dev)                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Hosts modified Flutter engine artifacts                    │
│  with Shorebird's code push integration                     │
│                                                             │
│  Structure matches Flutter's exactly:                       │
│  /download.flutter.io/io/flutter/...                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Key Insights

### 1. No Custom Maven Artifact Names

Shorebird **does NOT** create custom artifacts like `io.flutter:arm64_v8a_release_shorebird`.

They use the **exact same naming convention** as Flutter:
- `io.flutter:arm64_v8a_release:1.0.0-<hash>`
- `io.flutter:flutter_embedding_release:1.0.0-<hash>`

### 2. Version Control via engine.stamp

The magic is in the **engine.stamp** file, which contains a specific engine commit hash that points to Shorebird's modified engine.

**Flutter's approach**:
```
engine.stamp: 035316565ad77281a75305515e4682e6c4c6f7ca
URL: https://storage.googleapis.com/download.flutter.io/...
```

**Shorebird's approach**:
```
engine.stamp: d2913632a4fc16ad5722dd5344efb1855e65df9f  (Shorebird engine)
URL: https://download.shorebird.dev/download.flutter.io/...
```

### 3. Complete Maven Repository Hosting

Shorebird hosts a **full Maven repository structure** at `download.shorebird.dev`, maintaining compatibility with:
- Flutter's Gradle plugin
- Standard Maven repository layout
- All architectures and build modes

### 4. Transparent to Application Code

Applications don't need any changes:
- No custom Gradle configuration
- No special dependency declarations
- Works with standard `flutter build` commands

The entire switch happens at the **Flutter SDK level** via:
1. Modified `engine.stamp`
2. `FLUTTER_STORAGE_BASE_URL` environment variable
3. Flutter tools automatically uses Shorebird's Maven repo

## Directory Structure on Shorebird Storage

```
download.shorebird.dev/
└── download.flutter.io/
    └── io/
        └── flutter/
            ├── arm64_v8a_release/
            │   └── 1.0.0-d2913632a4.../
            │       ├── arm64_v8a_release-1.0.0-d2913632a4....jar
            │       ├── arm64_v8a_release-1.0.0-d2913632a4....pom
            │       ├── *.jar.md5
            │       └── *.jar.sha1
            ├── armeabi_v7a_release/
            │   └── 1.0.0-d2913632a4.../
            ├── x86_64_release/
            │   └── 1.0.0-d2913632a4.../
            └── flutter_embedding_release/
                └── 1.0.0-d2913632a4.../
```

## Comparison: Flutter vs Shorebird vs QuicUI

| Aspect | Flutter | Shorebird | QuicUI (Our Approach) |
|--------|---------|-----------|----------------------|
| **Storage** | storage.googleapis.com | download.shorebird.dev | Local .m2/repository |
| **Artifact Names** | io.flutter:arm64_v8a_release | io.flutter:arm64_v8a_release | io.flutter:arm64_v8a_release |
| **Version Format** | 1.0.0-<official_hash> | 1.0.0-<shorebird_hash> | 1.0.0-quicui |
| **Distribution** | Full Maven repo hosting | Full Maven repo hosting | Local Maven only |
| **SDK Modification** | None | engine.stamp + FLUTTER_STORAGE_BASE_URL | Force version in build.gradle |
| **Gradle Config** | Standard | Standard | Requires maven { url } + resolutionStrategy |

## Advantages of Shorebird's Approach

✅ **Transparent Integration**: No app-level changes required  
✅ **Version Control**: engine.stamp controls exact engine version  
✅ **Standard Tooling**: Works with unmodified Gradle plugin  
✅ **Complete Solution**: Handles all architectures and build modes  
✅ **Update Mechanism**: Can push new engine versions by updating engine.stamp  

## Disadvantages

❌ **Infrastructure Required**: Must host full Maven repository  
❌ **Bandwidth Costs**: Serving large JAR files (40MB+ each)  
❌ **Maintenance**: Need to keep Maven repo in sync with engine builds  
❌ **Network Dependency**: Requires internet access for builds  

## QuicUI Implementation Options

### Option A: Full Shorebird-Style (Production-Ready)

**Requirements**:
1. Host Maven repository at `download.quicui.io` or similar
2. Modify Flutter SDK:
   - Update `engine.stamp` with QuicUI engine hash
   - Set `FLUTTER_STORAGE_BASE_URL=https://download.quicui.io`
3. Build and publish all architecture variants:
   - arm64_v8a_release
   - armeabi_v7a_release
   - x86_64_release
   - x86_release
   - All debug/profile variants

**Benefits**: Production-ready, transparent to users

### Option B: Local Maven (Development/Testing)

**Current Implementation** ✅:
1. Publish to local `.m2/repository`
2. Configure Gradle to use local repo first
3. Force version with `resolutionStrategy`

**Benefits**: 
- No infrastructure needed
- Fast iteration
- Works for testing/development

**Limitations**:
- Not shareable across machines
- Requires per-project Gradle configuration
- Manual version forcing needed

### Option C: Hybrid Approach (Recommended)

1. **Development**: Use local Maven (Option B)
2. **CI/CD**: Publish to private Maven repo (Artifactory, Nexus, GitHub Packages)
3. **Distribution**: Provide custom Flutter SDK fork with modified engine.stamp

## Implementation for QuicUI

Based on our current progress, we're using **Option B** successfully:

```kotlin
// settings.gradle.kts
repositories {
    maven { url = uri("../../../.m2/repository") }  // QuicUI local Maven
    google()
    mavenCentral()
}

// build.gradle.kts
configurations.all {
    resolutionStrategy {
        force("io.flutter:arm64_v8a_release:1.0.0-quicui")
    }
}
```

**Published Artifact**:
- Location: `/Users/admin/Documents/quicui2/.m2/repository`
- Coordinate: `io.flutter:arm64_v8a_release:1.0.0-quicui`
- Size: 5.0MB (with AttachJNI modifications verified ✅)

## Next Steps for QuicUI

1. ✅ **Local Maven Publishing** - Complete
2. ✅ **Gradle Configuration** - Complete
3. ⏳ **Build & Test** - In progress
4. ⏸️ **CI/CD Publishing** - Future (if needed for team)
5. ⏸️ **Production Distribution** - Future (if needed for users)

## References

- Shorebird Flutter fork: `shorebird_research/shorebird_flutter/`
- Shorebird Engine: `shorebird_research/shorebird_engine/`
- Key files analyzed:
  - `packages/flutter_tools/gradle/resolve_dependencies.gradle.kts`
  - `packages/flutter_tools/lib/src/cache.dart`
  - `bin/cache/engine.stamp`
  - `bin/cache/engine.realm`

---

**Conclusion**: Shorebird's approach is elegant and production-ready, but requires hosting infrastructure. For QuicUI development/testing, our local Maven approach provides the same technical capability without the hosting overhead.
