# Publishing QuicUI Flutter Engine to GitHub Packages

**Date:** November 18, 2025  
**Recommended Method:** GitHub Packages (Maven Registry)

## Why GitHub Packages?

✅ **Free for public repositories**  
✅ **Integrated with GitHub Actions**  
✅ **No waiting for approval** (unlike Maven Central)  
✅ **Simple authentication with PAT**  
✅ **Works well with Flutter engines**

## Prerequisites

- GitHub repository: `Ikolvi/QuicUICodepush`
- GitHub Personal Access Token (PAT)
- Built engine artifacts (✅ already have these)

## Step 1: Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name: "QuicUI Engine Publishing"
4. Select scopes:
   - ✅ `write:packages` (upload packages)
   - ✅ `read:packages` (download packages)
   - ✅ `delete:packages` (optional - manage versions)
5. Click "Generate token"
6. **COPY THE TOKEN** - you won't see it again!

## Step 2: Store Token Securely

Add to `~/.gradle/gradle.properties`:

```properties
# GitHub Packages Authentication
gpr.user=Ikolvi
gpr.token=YOUR_GITHUB_TOKEN_HERE
```

Or use environment variables:
```bash
export GPR_USER=Ikolvi
export GPR_TOKEN=ghp_your_token_here
```

## Step 3: Create Publishing Configuration

I'll create a Gradle build file for publishing:

### File: `publish-engine.gradle`

```gradle
apply plugin: 'maven-publish'

publishing {
    publications {
        arm64Release(MavenPublication) {
            groupId = 'io.github.ikolvi'
            artifactId = 'quicui-flutter-engine-arm64'
            version = '1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65'
            
            artifact("$buildDir/libs/arm64_v8a_release.jar") {
                extension 'jar'
            }
            
            pom {
                name = 'QuicUI Flutter Engine ARM64'
                description = 'Custom Flutter engine with QuicUI code push support for arm64-v8a'
                url = 'https://github.com/Ikolvi/QuicUICodepush'
                
                licenses {
                    license {
                        name = 'BSD 3-Clause License'
                        url = 'https://opensource.org/licenses/BSD-3-Clause'
                    }
                }
                
                developers {
                    developer {
                        id = 'ikolvi'
                        name = 'QuicUI Team'
                        email = 'your-email@example.com'
                    }
                }
                
                scm {
                    connection = 'scm:git:git://github.com/Ikolvi/QuicUICodepush.git'
                    developerConnection = 'scm:git:ssh://github.com/Ikolvi/QuicUICodepush.git'
                    url = 'https://github.com/Ikolvi/QuicUICodepush'
                }
            }
        }
        
        flutterEmbedding(MavenPublication) {
            groupId = 'io.github.ikolvi'
            artifactId = 'quicui-flutter-embedding'
            version = '1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65'
            
            artifact("$buildDir/libs/flutter_embedding_release.jar") {
                extension 'jar'
            }
            
            pom {
                name = 'QuicUI Flutter Embedding'
                description = 'Flutter embedding layer for QuicUI engine'
                url = 'https://github.com/Ikolvi/QuicUICodepush'
                
                licenses {
                    license {
                        name = 'BSD 3-Clause License'
                        url = 'https://opensource.org/licenses/BSD-3-Clause'
                    }
                }
            }
        }
    }
    
    repositories {
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/Ikolvi/QuicUICodepush")
            credentials {
                username = project.findProperty("gpr.user") ?: System.getenv("GPR_USER")
                password = project.findProperty("gpr.token") ?: System.getenv("GPR_TOKEN")
            }
        }
    }
}
```

## Step 4: Prepare Artifacts for Publishing

```bash
# Create build directory structure
cd /Users/admin/Documents/quicui2
mkdir -p infrastructure/engine-publishing/build/libs

# Copy engine artifacts
cp ~/.m2/repository/io/flutter/arm64_v8a_release/1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65/arm64_v8a_release-1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65.jar \
   infrastructure/engine-publishing/build/libs/arm64_v8a_release.jar

cp ~/.m2/repository/io/flutter/flutter_embedding_release/1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65/flutter_embedding_release-1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65.jar \
   infrastructure/engine-publishing/build/libs/flutter_embedding_release.jar
```

## Step 5: Create build.gradle

### File: `infrastructure/engine-publishing/build.gradle`

```gradle
plugins {
    id 'maven-publish'
}

group = 'io.github.ikolvi'
version = '1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65'

apply from: 'publish-engine.gradle'
```

## Step 6: Publish to GitHub Packages

```bash
cd infrastructure/engine-publishing

# Publish both artifacts
gradle publish
```

## Step 7: Using the Published Engine

### In your Flutter project's `android/build.gradle`:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        
        // GitHub Packages
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/Ikolvi/QuicUICodepush")
            credentials {
                username = project.findProperty("gpr.user") ?: System.getenv("GPR_USER")
                password = project.findProperty("gpr.token") ?: System.getenv("GPR_TOKEN")
            }
        }
    }
}
```

### Add dependencies:

```gradle
dependencies {
    implementation 'io.github.ikolvi:quicui-flutter-engine-arm64:1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65'
    implementation 'io.github.ikolvi:quicui-flutter-embedding:1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65'
}
```

## Step 8: Team Access

For others to download:
1. They need a GitHub account
2. Generate their own PAT with `read:packages` scope
3. Add to their `~/.gradle/gradle.properties`:
   ```properties
   gpr.user=THEIR_GITHUB_USERNAME
   gpr.token=THEIR_TOKEN
   ```

## Alternative: Public Access via JitPack

If you want **no authentication required**, use JitPack instead:

### 1. Create Git Tag

```bash
cd /Users/admin/Documents/quicui2
git add docs/2025-11-18/
git commit -m "Add QuicUI engine artifacts and documentation"
git tag -a v1.0.0-engine -m "QuicUI Flutter Engine v1.0.0"
git push origin develop --tags
```

### 2. Users Access Via JitPack

```gradle
repositories {
    maven { url 'https://jitpack.io' }
}

dependencies {
    implementation 'com.github.Ikolvi:QuicUICodepush:v1.0.0-engine'
}
```

**Note:** JitPack builds automatically from your GitHub tag!

## Recommended Approach

### For Team/Private Use: GitHub Packages
- Better control over versions
- Direct from your repository
- Integrated with GitHub

### For Public/Open Source: JitPack
- Zero configuration
- No authentication needed
- Automatic builds from tags

## Version Naming Convention

Since engine commit is long, use semantic versioning + commit:

```
1.0.0-b5990e5ccc  (shortened commit hash)
1.0.1-b5990e5ccc  (same engine, patch update)
1.1.0-abc123def   (new engine version)
```

## Script for Easy Publishing

### File: `scripts/publish_engine.sh`

```bash
#!/bin/bash
set -e

ENGINE_VERSION="b5990e5ccc5e325fd24f0746e7d6689bbebc7c65"
SHORT_VERSION="1.0.0-b5990e5ccc"

echo "🚀 Publishing QuicUI Flutter Engine..."

# Prepare artifacts
echo "📦 Preparing artifacts..."
mkdir -p infrastructure/engine-publishing/build/libs
cp ~/.m2/repository/io/flutter/arm64_v8a_release/1.0.0-${ENGINE_VERSION}/*.jar \
   infrastructure/engine-publishing/build/libs/arm64_v8a_release.jar
cp ~/.m2/repository/io/flutter/flutter_embedding_release/1.0.0-${ENGINE_VERSION}/*.jar \
   infrastructure/engine-publishing/build/libs/flutter_embedding_release.jar

# Publish
echo "📤 Publishing to GitHub Packages..."
cd infrastructure/engine-publishing
gradle publish

echo "✅ Published successfully!"
echo ""
echo "📌 Version: ${SHORT_VERSION}"
echo "📦 Artifacts:"
echo "   - io.github.ikolvi:quicui-flutter-engine-arm64:${SHORT_VERSION}"
echo "   - io.github.ikolvi:quicui-flutter-embedding:${SHORT_VERSION}"
echo ""
echo "📖 See GITHUB_PACKAGES_PUBLISHING_GUIDE.md for usage instructions"
```

Make it executable:
```bash
chmod +x scripts/publish_engine.sh
```

## Troubleshooting

### Error: "Could not find com.github.Ikolvi:..."

**Cause:** Token not configured or expired

**Fix:**
1. Check `~/.gradle/gradle.properties` has valid token
2. Verify token has `read:packages` scope
3. Try re-generating token

### Error: "401 Unauthorized"

**Cause:** Token doesn't have correct permissions

**Fix:** Generate new token with `write:packages` scope

### Error: "409 Conflict - Package version already exists"

**Cause:** Version already published (GitHub Packages doesn't allow overwrites)

**Fix:** Increment version number:
```
1.0.0-b5990e5ccc → 1.0.1-b5990e5ccc
```

## Summary

1. ✅ Create GitHub PAT with `write:packages`
2. ✅ Add token to `~/.gradle/gradle.properties`
3. ✅ Create publishing Gradle files (I'll do this next)
4. ✅ Run `gradle publish`
5. ✅ Others can use with their own PAT

**Ready to proceed?** Let me know and I'll create the actual Gradle files for publishing!
