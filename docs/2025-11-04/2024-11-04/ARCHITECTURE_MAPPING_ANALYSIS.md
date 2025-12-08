# Flutter Engine Architecture Mapping Analysis

## Key Discovery: How Flutter Maps CPU Architecture to Gradle Artifact Names

### 1. Architecture Mapping (build/config/android/config.gni)

```gn
if (current_cpu == "x86") {
  android_app_abi = "x86"
} else if (current_cpu == "arm") {
  android_app_abi = "armeabi-v7a"
} else if (current_cpu == "x64") {
  android_app_abi = "x86_64"
} else if (current_cpu == "arm64") {
  android_app_abi = "arm64-v8a"
}
```

**For arm64 build:**
- `current_cpu` = "arm64"
- `android_app_abi` = "arm64-v8a"

### 2. Artifact ID Generation (shell/platform/android/BUILD.gn)

```gn
artifact_id = string_replace(android_app_abi, "-", "_") + "_" + flutter_runtime_mode
```

**For arm64 release build:**
- `android_app_abi` = "arm64-v8a"
- Replace "-" with "_" → "arm64_v8a"
- Append runtime mode → "arm64_v8a_release"

**Final artifact:** `io.flutter:arm64_v8a_release:1.0.0-<engine_version>`

### 3. JAR Packaging Process

#### Step 1: Create android_jar (line 477)
```gn
action("android_jar") {
  script = "//build/android/gyp/create_flutter_jar.py"
  
  inputs = [
    "$root_build_dir/flutter_embedding_release.jar",
    "$root_build_dir/lib.stripped/libflutter.so"  # 11.3MB stripped
  ]
  
  outputs = [
    "$root_build_dir/flutter.jar",              # SDK artifact
    "$root_build_dir/arm64_v8a_release.jar"     # Gradle artifact
  ]
  
  args = [
    "--native_lib", "lib.stripped/libflutter.so",
    "--android_abi", "arm64-v8a"
  ]
}
```

**Output files:**
- `flutter.jar` → Goes to SDK (used by Flutter CLI)
- `arm64_v8a_release.jar` → Goes to Gradle Maven cache (used by Gradle builds)

#### Step 2: Rename for Maven (abi_jars action, line 880)
```gn
action("abi_jars") {
  artifact_id = string_replace(android_app_abi, "-", "_") + "_" + flutter_runtime_mode
  # artifact_id = "arm64_v8a_release"
  
  sources = [
    "$root_out_dir/arm64_v8a_release.jar",
    "$root_out_dir/arm64_v8a_release.pom"
  ]
  
  base_name = "$root_out_dir/zip_archives/download.flutter.io/io/flutter/" +
              "arm64_v8a_release/1.0.0-$engine_version/" +
              "arm64_v8a_release-1.0.0-${engine_version}"
  
  # Copies arm64_v8a_release.jar to:
  # out/android_release_arm64/zip_archives/download.flutter.io/io/flutter/
  #   arm64_v8a_release/1.0.0-<hash>/arm64_v8a_release-1.0.0-<hash>.jar
}
```

### 4. Directory Structure in Build Output

```
out/android_release_arm64/
├── flutter.jar                          # 5.7MB - Goes to SDK
├── arm64_v8a_release.jar                # 5.7MB - Intermediate
├── libflutter.so                        # 158MB - Unstripped
├── lib.stripped/
│   └── libflutter.so                    # 11.3MB - Stripped version
└── zip_archives/
    └── download.flutter.io/
        └── io/
            └── flutter/
                └── arm64_v8a_release/
                    └── 1.0.0-<engine_version>/
                        ├── arm64_v8a_release-1.0.0-<hash>.jar
                        └── arm64_v8a_release-1.0.0-<hash>.pom
```

### 5. Gradle Cache Structure

When Flutter Gradle plugin resolves `io.flutter:arm64_v8a_release:1.0.0-<hash>`:

```
~/.gradle/caches/modules-2/files-2.1/
└── io.flutter/
    └── arm64_v8a_release/
        └── 1.0.0-<engine_version>/
            └── <hash>/
                ├── arm64_v8a_release-1.0.0-<hash>.jar    # 38-41MB
                └── arm64_v8a_release-1.0.0-<hash>.pom
```

**JAR contents:**
```
arm64_v8a_release-*.jar
└── lib/
    └── arm64-v8a/
        └── libflutter.so        # 147MB unstripped (Gradle keeps unstripped!)
```

### 6. Key Insights for QuicUI Deployment

**Problem:** Two separate artifacts with different names:
1. **SDK artifact**: `flutter.jar` (in `bin/cache/artifacts/engine/android-arm64-release/`)
2. **Gradle artifact**: `arm64_v8a_release.jar` (in Gradle Maven cache as `io.flutter:arm64_v8a_release:1.0.0-<hash>`)

**Why modifying SDK flutter.jar doesn't work:**
- Flutter CLI uses SDK's `flutter.jar` for Dart compilation
- Gradle build uses Maven artifact `io.flutter:arm64_v8a_release:1.0.0-<hash>` for native libraries
- They are **separate files** despite containing the same libflutter.so

**Solution Options:**

**A. Build both artifacts together:**
```bash
cd official_engine/src
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release
ninja -C out/android_release_arm64 flutter.jar arm64_v8a_release.jar
```

**B. Replace in correct Gradle location:**
```bash
# Find the actual cached JAR
GRADLE_JAR=$(find ~/.gradle/caches/modules-2/files-2.1/io.flutter/arm64_v8a_release/ -name "*.jar")

# Extract, replace libflutter.so, repackage
mkdir /tmp/gradle_mod
cd /tmp/gradle_mod
unzip "$GRADLE_JAR"
cp /Volumes/.../out/android_release_arm64/lib.stripped/libflutter.so lib/arm64-v8a/
zip -r modified.jar *
cp modified.jar "$GRADLE_JAR"
```

**C. Use local Maven repository:**
```bash
# Publish to local Maven repo
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release
ninja -C out/android_release_arm64 :abi_jars

# Copy to local Maven repo
mkdir -p ~/.m2/repository/io/flutter/arm64_v8a_release/1.0.0-quicui/
cp out/android_release_arm64/arm64_v8a_release.jar \
   ~/.m2/repository/io/flutter/arm64_v8a_release/1.0.0-quicui/arm64_v8a_release-1.0.0-quicui.jar

# Configure Gradle to use local repo with higher priority
```

### 7. Architecture-Specific Gradle Artifacts

Flutter creates **separate Maven artifacts for each architecture:**

| CPU Architecture | Gradle Artifact ID |
|-----------------|-------------------|
| arm64-v8a       | `io.flutter:arm64_v8a_release:1.0.0-<hash>` |
| armeabi-v7a     | `io.flutter:armeabi_v7a_release:1.0.0-<hash>` |
| x86_64          | `io.flutter:x86_64_release:1.0.0-<hash>` |
| x86             | `io.flutter:x86_release:1.0.0-<hash>` |

**Important:** Gradle resolves these based on `android.defaultConfig.ndk.abiFilters` in app's build.gradle.

### 8. Shorebird's Approach

Shorebird maintains the **same artifact naming convention** as Flutter:
- Uses `string_replace(android_app_abi, "-", "_")` to generate artifact IDs
- Publishes to custom Maven repository at `download.shorebird.dev`
- Flutter Gradle plugin resolves artifacts the same way

**Key difference:** Shorebird replaces the entire Maven repository URL, not individual JARs.

