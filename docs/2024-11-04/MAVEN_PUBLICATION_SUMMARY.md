# QuicUI Maven Publication Implementation

**Date**: November 4, 2025  
**Status**: ✅ Complete - Testing in progress

## What We Accomplished

### 1. Published QuicUI Engine to Local Maven

**Created**: `scripts/publish_engine_to_maven.sh`

This script:
- ✅ Verifies AttachJNI modifications in built JAR
- ✅ Publishes to `.m2/repository` with version `1.0.0-quicui`
- ✅ Generates proper POM file
- ✅ Creates checksums (MD5, SHA1)
- ✅ Provides configuration instructions

**Published Artifact**:
```
Location: /Users/admin/Documents/quicui2/.m2/repository
Group: io.flutter
Artifact: arm64_v8a_release
Version: 1.0.0-quicui
Size: 5.0MB
Contains: libflutter.so with AttachJNI modifications ✅
```

### 2. Configured Gradle to Use Local Maven

**Modified Files**:
1. `test_apps/quicui_engine_test/android/settings.gradle.kts`
   - Added local Maven repository to `pluginManagement.repositories`

2. `test_apps/quicui_engine_test/android/build.gradle.kts`
   - Added local Maven repository to `allprojects.repositories`
   - Added `resolutionStrategy.force()` to enforce QuicUI version

**Configuration**:
```kotlin
// settings.gradle.kts
pluginManagement {
    repositories {
        maven { url = uri("../../../.m2/repository") }  // QuicUI first!
        google()
        mavenCentral()
    }
}

// build.gradle.kts
allprojects {
    repositories {
        maven { url = uri("../../.m2/repository") }  // QuicUI first!
        google()
        mavenCentral()
    }
    
    configurations.all {
        resolutionStrategy {
            force("io.flutter:arm64_v8a_release:1.0.0-quicui")
        }
    }
}
```

### 3. Documentation Created

1. **ARCHITECTURE_MAPPING_ANALYSIS.md**
   - How Flutter maps arm64 → arm64-v8a → arm64_v8a_release
   - Build system analysis (BUILD.gn)
   - Why SDK flutter.jar doesn't work for Gradle builds
   - Gradle's multi-layer caching system

2. **SHOREBIRD_MAVEN_STRATEGY.md**
   - How Shorebird hosts full Maven repository
   - Environment variable approach (`FLUTTER_STORAGE_BASE_URL`)
   - engine.stamp version control
   - Comparison of Flutter vs Shorebird vs QuicUI approaches

## Key Technical Insights

### Flutter's Dual Artifact System

Flutter creates **two separate artifacts** from same engine build:

| Artifact | Usage | Location |
|----------|-------|----------|
| `flutter.jar` | Flutter CLI (Dart compile) | SDK `bin/cache/artifacts/` |
| `arm64_v8a_release.jar` | Gradle (native libs) | Gradle Maven cache |

**This is why modifying SDK's flutter.jar didn't work!**

### Maven Artifact Naming Convention

```
Architecture: arm64 → android_app_abi: arm64-v8a → artifact_id: arm64_v8a_release
             
                 Replace "-" with "_"    +    "_release"
                 ↓                              ↓
Maven Coordinate: io.flutter:arm64_v8a_release:1.0.0-<version>
```

### Gradle Resolution Order

Repositories are tried in order:
1. ✅ Local Maven (`.m2/repository`) - **We added this first**
2. Google Maven
3. Maven Central

`resolutionStrategy.force()` ensures our version is used even if others are available.

## Shorebird's Production Approach

**What they do differently**:
1. Host complete Maven repo at `download.shorebird.dev`
2. Set `FLUTTER_STORAGE_BASE_URL` environment variable
3. Modify `engine.stamp` to point to their engine hash
4. **No app-level changes needed** - completely transparent

**Why they can do this**:
- Control Flutter SDK distribution
- Have infrastructure to host Maven repo
- Can serve all architectures and build modes

**Why we use local Maven instead**:
- No infrastructure needed for development/testing
- Fast iteration cycles
- Good enough for proof-of-concept
- Can upgrade to hosted Maven later if needed

## Build Process

### Maven Publication
```bash
./scripts/publish_engine_to_maven.sh
```

Output:
```
🔥 QuicUI Engine Maven Publication
✅ AttachJNI modifications verified!
📦 Publishing artifacts...
✅ Publication complete!

📋 Published artifacts:
-rwx------  5.0M arm64_v8a_release-1.0.0-quicui.jar
-rw-r--r--   585B arm64_v8a_release-1.0.0-quicui.pom
+ checksums
```

### App Build (Testing)
```bash
cd test_apps/quicui_engine_test
flutter clean
flutter build apk --release --target-platform android-arm64
```

**Expected**: Gradle resolves `io.flutter:arm64_v8a_release:1.0.0-quicui` from local Maven

## Verification Steps

1. ✅ **Engine contains modifications**
   ```bash
   strings libflutter.so | grep "AttachJNI called"
   # Output: 🔥 AttachJNI called!
   ```

2. ✅ **JAR contains modified engine**
   ```bash
   unzip arm64_v8a_release-1.0.0-quicui.jar
   strings lib/arm64-v8a/libflutter.so | grep "AttachJNI called"
   # Output: 🔥 AttachJNI called!
   ```

3. ⏳ **Gradle uses QuicUI artifact** (testing in progress)
   ```bash
   unzip app-release.apk
   strings lib/arm64-v8a/libflutter.so | grep "AttachJNI called"
   # Expected: 🔥 AttachJNI called!
   ```

4. ⏳ **Runtime verification**
   ```bash
   adb logcat | grep QuicUI
   # Expected: I/QuicUI: 🔥 AttachJNI called!
   ```

## Success Criteria

- [x] Maven artifact published with AttachJNI modifications
- [x] Gradle configured to use local Maven repo
- [x] Gradle configured to force QuicUI version
- [x] Documentation complete
- [ ] Build succeeds with QuicUI engine
- [ ] APK contains modified libflutter.so
- [ ] AttachJNI logs appear in logcat
- [ ] OTA update loads patched libapp.so

## Next Steps

1. **Complete current build** - Verify Gradle picks up QuicUI artifact
2. **Install and test** - Check logcat for AttachJNI logs
3. **Push OTA update** - Test if orange theme appears
4. **Document results** - Update findings in today's docs

## Files Modified/Created

### Created
- `scripts/publish_engine_to_maven.sh` - Maven publication script
- `docs/2024-11-04/ARCHITECTURE_MAPPING_ANALYSIS.md`
- `docs/2024-11-04/SHOREBIRD_MAVEN_STRATEGY.md`
- `.m2/repository/io/flutter/arm64_v8a_release/1.0.0-quicui/` - Maven artifacts

### Modified
- `test_apps/quicui_engine_test/android/settings.gradle.kts` - Added local Maven repo
- `test_apps/quicui_engine_test/android/build.gradle.kts` - Added force version

## Lessons Learned

1. **Flutter's build system is complex** - Multiple artifacts, multiple caches
2. **Gradle cache is fragile** - Can get corrupted, need to clear occasionally
3. **Shorebird's approach is elegant** - But requires infrastructure
4. **Local Maven works great** - For development/testing purposes
5. **Documentation is critical** - Easy to forget how things work

## Future Enhancements

### For Production
- Set up hosted Maven repository (Artifactory, Nexus, or GitHub Packages)
- Build all architecture variants (arm64, armv7a, x86_64, x86)
- Build all modes (debug, profile, release)
- Automate publishing in CI/CD

### For Distribution
- Fork Flutter SDK with modified engine.stamp
- Set FLUTTER_STORAGE_BASE_URL to our Maven host
- Distribute QuicUI Flutter SDK to users
- Transparent integration like Shorebird

### For Development
- Script to rebuild and republish engine quickly
- Automated testing of AttachJNI integration
- Verify OTA updates work end-to-end
- Performance benchmarking

---

**Status**: Maven publication complete ✅, build testing in progress ⏳
