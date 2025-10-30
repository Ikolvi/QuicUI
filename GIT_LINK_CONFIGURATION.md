# Using Git Links for Private QuicUI Dependencies

**Created:** October 30, 2025  
**Status:** Configuration Ready  

---

## ✅ Current Setup Verified

### Repository Status

**QuicUI (Main)**
- URL: `git@github.com:Ikolvi/QuicUI.git`
- Status: ✅ Private repository
- Current Version: 1.0.4
- Access: SSH key-based (yours only)

**QuicUI Supabase Plugin**
- URL: `git@github.com:Ikolvi/QuicUISuperbase.git`
- Status: ✅ Private repository
- Current Version: 2.0.2
- Access: SSH key-based (yours only)

---

## 🔧 Why Git Links Are Perfect for Your Setup

✅ **Advantages:**
- No need to publish to pub.dev yet
- Direct dependency on latest code
- Easy to test changes before pub.dev release
- Perfect for private repos
- Can use specific branches or tags
- Immediate updates across repos

---

## 📝 Option 1: Git Link with Tag (Recommended for Production)

This method pins to a specific release version using git tags.

### Step 1: Create Git Tags for Releases

**For QuicUI (v1.0.4):**
```bash
cd /Users/admin/Documents/advstorysrc/FlutterProjects/QuicUI/quicui
git tag -a v1.0.4 -m "Release v1.0.4 - Callback Action System"
git push origin v1.0.4
```

**For Supabase Plugin (v2.0.3 - future):**
```bash
cd /Users/admin/Documents/advstorysrc/FlutterProjects/QuicUI/quicui_supabase
git tag -a v2.0.3 -m "Release v2.0.3 - Callback Support"
git push origin v2.0.3
```

### Step 2: Update pubspec.yaml with Git Link

**In quicui_supabase/pubspec.yaml:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  quicui:
    git:
      url: git@github.com:Ikolvi/QuicUI.git
      ref: v1.0.4  # Pins to this version/tag
  supabase_flutter: ^2.10.3
  logger: ^2.1.0
  equatable: ^2.0.5
```

---

## 📝 Option 2: Git Link with Branch (For Development)

This method always pulls the latest from a specific branch.

### For Development/Testing

**In quicui_supabase/pubspec.yaml:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  quicui:
    git:
      url: git@github.com:Ikolvi/QuicUI.git
      ref: main  # Always latest from main branch
  supabase_flutter: ^2.10.3
  logger: ^2.1.0
  equatable: ^2.0.5
```

---

## 🚀 Step-by-Step Implementation

### Current Situation
- QuicUI v1.0.4 is ready ✅
- Supabase plugin needs v2.0.3 with updated docs

### What We Do

**Step 1: Update QuicUI (Already Done)**
```bash
cd /Users/admin/Documents/advstorysrc/FlutterProjects/QuicUI/quicui
# Already at v1.0.4 with callbacks ✅
git tag v1.0.4
git push origin v1.0.4
```

**Step 2: Update Supabase Plugin pubspec.yaml**
```yaml
name: quicui_supabase
version: 2.0.3  # Bump version

dependencies:
  quicui:
    git:
      url: git@github.com:Ikolvi/QuicUI.git
      ref: v1.0.4  # Pin to QuicUI v1.0.4
```

**Step 3: Test the Git Link**
```bash
cd /Users/admin/Documents/advstorysrc/FlutterProjects/QuicUI/quicui_supabase
flutter pub get
flutter test
```

**Step 4: Commit and Tag**
```bash
git add pubspec.yaml
git commit -m "chore: Update QuicUI dependency to v1.0.4 via git link"
git tag v2.0.3
git push origin main
git push origin v2.0.3
```

---

## ✨ Git Link Syntax Reference

### With Tag (Recommended)
```yaml
quicui:
  git:
    url: git@github.com:Ikolvi/QuicUI.git
    ref: v1.0.4  # Specific release tag
```

### With Branch
```yaml
quicui:
  git:
    url: git@github.com:Ikolvi/QuicUI.git
    ref: main  # Latest from main
```

### With Specific Commit
```yaml
quicui:
  git:
    url: git@github.com:Ikolvi/QuicUI.git
    ref: dde82c9  # Specific commit hash
```

### With Path (If in same monorepo)
```yaml
quicui:
  git:
    url: git@github.com:Ikolvi/QuicUI.git
    path: quicui  # If QuicUI is in subfolder
```

---

## 🔐 SSH Key Configuration

Your setup uses `git@github.com:` which means SSH keys are needed.

### Verify SSH is configured:
```bash
ssh -T git@github.com
# Should output: Hi Ikolvi! You've successfully authenticated...
```

### If SSH isn't configured:
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add public key to GitHub:
cat ~/.ssh/id_ed25519.pub
# Copy and paste into GitHub Settings → SSH Keys
```

---

## 📋 Complete pubspec.yaml for Supabase Plugin v2.0.3

```yaml
name: quicui_supabase
description: Supabase implementation for QuicUI framework with callback support.
version: 2.0.3
repository: https://github.com/Ikolvi/QuicUISuperbase
homepage: https://github.com/Ikolvi/QuicUISuperbase
issue_tracker: https://github.com/Ikolvi/QuicUISuperbase/issues
documentation: https://github.com/Ikolvi/QuicUISuperbase/wiki
license: MIT

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  quicui:
    git:
      url: git@github.com:Ikolvi/QuicUI.git
      ref: v1.0.4
  supabase_flutter: ^2.10.3
  logger: ^2.1.0
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  mocktail: ^1.0.0

flutter:
```

---

## 🧪 Testing Git Link Dependencies

### Step 1: Test Supabase Plugin

```bash
cd /Users/admin/Documents/advstorysrc/FlutterProjects/QuicUI/quicui_supabase

# Get dependencies (will fetch from git)
flutter pub get

# Run tests
flutter test

# Check if QuicUI v1.0.4 loaded correctly
flutter pub deps | grep quicui
```

### Expected Output:
```
quicui 1.0.4 from git
```

### Step 2: Test in an Example App

If you have an example app:
```bash
cd your-example-app

# Update pubspec.yaml to use the plugin from git
dependencies:
  quicui_supabase:
    git:
      url: git@github.com:Ikolvi/QuicUISuperbase.git
      ref: v2.0.3

# Get and test
flutter pub get
flutter test
flutter run
```

---

## 🚀 Publishing Strategy with Git Links

### Option A: Keep Both on Git (Recommended Initially)

**Pros:**
- Keep both repos private
- No pub.dev maintenance
- Faster iteration
- Full control

**When to use:**
- Development phase
- Frequent changes
- Private use only

### Option B: Publish to pub.dev Later

**Timeline:**
1. ✅ Use git links now (both repos private)
2. ⏳ Test thoroughly
3. ⏳ Gather feedback
4. 📦 Publish to pub.dev when ready

**Transition:**
```bash
# When ready, publish to pub.dev
flutter pub publish

# Then users can use: quicui: ^1.0.4
# Instead of git link
```

---

## 💡 Recommended Setup for You

Since both repos are private and belong to you:

### Current Setup (Recommended)
```yaml
# quicui_supabase/pubspec.yaml
dependencies:
  quicui:
    git:
      url: git@github.com:Ikolvi/QuicUI.git
      ref: v1.0.4
```

**Benefits:**
✅ Both repos stay private
✅ Easy to manage versions
✅ Can test changes before releasing
✅ No pub.dev friction
✅ Full control over releases

### Future Setup (When Publishing)
```yaml
# After publishing to pub.dev
dependencies:
  quicui: ^1.0.4  # Simple version constraint
```

---

## 🔄 Version Management with Git Links

### Create Release Tags

**For QuicUI:**
```bash
cd quicui
git tag v1.0.4
git push origin v1.0.4
```

**For Supabase Plugin:**
```bash
cd quicui_supabase
git tag v2.0.3
git push origin v2.0.3
```

### Update between versions

When QuicUI releases v1.0.5:
```yaml
# In quicui_supabase/pubspec.yaml
quicui:
  git:
    url: git@github.com:Ikolvi/QuicUI.git
    ref: v1.0.5  # Update tag
```

Then:
```bash
flutter pub get
```

---

## ⚠️ Important Notes

### SSH Authentication Required
- Git links require SSH access
- Both developers need SSH keys configured
- No HTTPS alternative with private repos

### Limitations
- Can't use git links if publishing to pub.dev
  - pub.dev requires published packages only
  - Git links only work in private projects

### When to Publish to pub.dev
- When you want public access
- When you want `flutter pub add quicui`
- When you want to maintain pub.dev versions

---

## 🎯 Recommended Action Plan

### Now (October 30, 2025)

1. ✅ QuicUI v1.0.4 is ready with callbacks
2. 📝 Update Supabase plugin pubspec.yaml with git link
3. 🧪 Test via git link
4. 🏷️  Create git tags for both (v1.0.4, v2.0.3)
5. 🚀 Push to GitHub

### Later (When Ready to Go Public)

1. 📦 Publish QuicUI v1.0.4 to pub.dev
2. 📦 Publish Supabase plugin v2.0.3 to pub.dev
3. 🔄 Update pubspec.yaml to remove git links
4. 📢 Announce both packages

---

## 📊 Comparison: Git Links vs pub.dev

| Feature | Git Link | pub.dev |
|---------|----------|---------|
| Private repos | ✅ Yes | ❌ No |
| Free hosting | ✅ GitHub | ✅ Yes |
| Version control | ✅ Git | ✅ Semver |
| Speed | 🟡 Slower | ✅ Fast |
| Public access | ❌ No | ✅ Yes |
| Easy to use | 🟡 Need SSH | ✅ Simple |
| Dependency updates | 🟡 Manual tags | ✅ Auto-detect |

---

## ✅ Summary

**Your Setup:**
- Both repos are private ✅
- Both use SSH keys ✅
- Perfect for git links ✅

**Next Steps:**
1. Update Supabase pubspec.yaml with git link
2. Test via `flutter pub get`
3. Create version tags
4. Push to GitHub
5. Later: Publish to pub.dev if needed

---

## 🔗 Git Link Resources

- [Pub.dev Git Dependencies](https://dart.dev/tools/pub/pubspec#git)
- [Flutter Package Dependencies](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
- [GitHub SSH Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

---

Ready to implement? Follow the step-by-step in the section "Step-by-Step Implementation" above! 🚀
