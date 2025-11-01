# Phase 1: Flutter Runtime Integration - Detailed Execution Plan

**Date Started**: November 1, 2025  
**Duration**: 2-3 weeks estimated  
**Goal**: Integrate QuicUI patch loading into Flutter engine and framework  

---

## Phase 1 Overview

### What We're Doing
Modifying the Flutter engine and framework to support code push patches. This involves:
1. Forking Flutter repository
2. Creating C++ patch loader in engine
3. Modifying Dart framework for integration
4. Adding platform-specific implementations (iOS/Android)

### Expected Outcomes
- ✅ Flutter fork with code push support
- ✅ C++ patch loading mechanism
- ✅ Dart framework integration
- ✅ Platform channel setup
- ✅ End-to-end patch application flow

---

## Step 1: Analyze Shorebird Architecture

### What We Need to Understand
1. How Shorebird forks Flutter
2. Which files they modify
3. How they hook into engine startup
4. How they load patched kernels
5. How they handle rollback

### Files to Analyze from Shorebird
- `flutter/shell/common/engine.cc` - Engine startup flow
- `flutter/runtime/dart_vm.cc` - Kernel loading
- `flutter/lib/src/services/binding.dart` - Framework initialization

### Plan
```bash
# We'll create analysis documents in docs/
docs/
├── FLUTTER_FORK_ANALYSIS.md      # How Shorebird does it
├── MODIFICATION_POINTS.md         # Exact files to modify
├── FLUTTER_PATCHES.md             # Our specific changes
└── IMPLEMENTATION_PLAN.md         # Step-by-step guide
```

---

## Step 2: Clone Flutter Repository

### Why We Need Flutter Source
- Need to understand engine architecture
- Need to make C++ modifications
- Need to build custom Flutter SDK

### Setup Process
```bash
# Create forks directory structure
mkdir -p forks/flutter-official
mkdir -p forks/flutter-quicui

# Clone official Flutter
cd forks/flutter-official
git clone https://github.com/flutter/flutter.git .

# Create QuicUI branch
git checkout -b quicui/main
git push origin quicui/main
```

### What We're Looking For
1. **Engine Initialization** (`engine.cc`)
   - Where does engine start?
   - Where are kernels loaded?
   - Where can we inject patch checking?

2. **Dart VM** (`dart_vm.cc`)
   - How is kernel loaded into VM?
   - Can we load patched kernels?
   - What's the kernel format?

3. **Framework** (`binding.dart`)
   - How does Flutter framework start?
   - Where can we integrate patches?
   - What events can we hook into?

---

## Step 3: Create Patch Loader Implementation

### C++ Patch Loader (`codepush_loader.cc/h`)

This will:
1. Check for available patches on startup
2. Verify patch signatures
3. Load patched kernel into Dart VM
4. Handle rollback on errors

### Key Classes
```cpp
class CodePushLoader {
  // Check for patches on device
  Status CheckForPatches();
  
  // Verify patch signature
  Status VerifyPatchSignature(const Patch& patch);
  
  // Load patched kernel
  Status LoadPatchedKernel(const Patch& patch);
  
  // Rollback to previous version
  Status Rollback();
};
```

### Implementation Location
```
flutter/runtime/codepush_loader.h
flutter/runtime/codepush_loader.cc
```

---

## Step 4: Modify Engine Startup

### In `engine.cc`
Add code to:
1. Initialize code push on engine start
2. Check for patches before loading kernel
3. Load patch if available
4. Fall back to original kernel if needed

### Modification Points
```cpp
// In Engine::Engine()
Engine::Engine(...) {
  // ... existing code ...
  
  // Initialize code push
  code_push_loader_ = std::make_unique<CodePushLoader>();
  code_push_loader_->Initialize();
}

// In Engine::Run()
void Engine::Run(...) {
  // Check for patches
  auto status = code_push_loader_->CheckForPatches();
  if (status.ok()) {
    // Use patched kernel
    kernel = code_push_loader_->GetPatchedKernel();
  } else {
    // Use default kernel
    kernel = GetDefaultKernel();
  }
  
  // Load kernel into VM
  dart_vm_->LoadKernel(kernel);
}
```

---

## Step 5: Modify Dart VM

### In `dart_vm.cc`
Support loading patched kernels:

```cpp
// Support custom kernel loading
void DartVM::LoadKernel(const uint8_t* kernel_data, size_t kernel_size) {
  if (kernel_data != nullptr) {
    // Load custom kernel (from patch)
    LoadCustomKernel(kernel_data, kernel_size);
  } else {
    // Load default kernel
    LoadDefaultKernel();
  }
}
```

---

## Step 6: Integrate with Framework

### In `binding.dart`
Add code push initialization:

```dart
class WidgetsBinding {
  Future<void> initInstances() async {
    // ... existing initialization ...
    
    // Initialize code push
    if (kIsWeb == false) {
      await _initializeCodePush();
    }
  }
  
  Future<void> _initializeCodePush() async {
    try {
      // Get code push service from platform channel
      final codePush = CodePushService.instance;
      
      // Check for patches periodically
      // This will be handled by the client library
      codePush.initialize();
    } catch (e) {
      // Fallback - continue without code push
      debugPrint('Code push initialization failed: $e');
    }
  }
}
```

---

## Step 7: Add Platform Channels

### Platform Channel Communication
Client library ↔ Engine ↔ Platform Code

### Android Implementation
```kotlin
// android/app/src/main/kotlin/CodePushService.kt
class CodePushService : MethodChannel.MethodCallHandler {
  fun setupChannel(flutterEngine: FlutterEngine) {
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "com.quicui.codepush/service"
    ).setMethodCallHandler(this)
  }
  
  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "checkForPatches" -> checkForPatches(result)
      "applyPatch" -> applyPatch(call, result)
      "rollback" -> rollback(result)
    }
  }
}
```

### iOS Implementation
```swift
// ios/Runner/CodePushService.swift
class CodePushService: NSObject, FlutterPlugin {
  static let channelName = "com.quicui.codepush/service"
  
  static func register(with registry: FlutterPluginRegistry) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registry.messenger(forPlugin: "CodePushService")
    )
    let instance = CodePushService()
    registry.addMethodCallDelegate(instance, channel: channel)
  }
  
  func dummyMethodToEnforceBundling(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkForPatches":
      checkForPatches(result: result)
    case "applyPatch":
      applyPatch(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
```

---

## Step 8: Testing Strategy

### Unit Tests
```dart
// Test patch loader basic functionality
test('CodePushLoader initializes correctly', () async {
  final loader = CodePushLoader();
  expect(await loader.initialize(), isTrue);
});

// Test patch verification
test('Verifies valid patches', () async {
  final patch = createTestPatch();
  expect(await loader.verifyPatch(patch), isTrue);
});

// Test invalid patches are rejected
test('Rejects invalid patches', () async {
  final patch = createInvalidPatch();
  expect(await loader.verifyPatch(patch), isFalse);
});
```

### Integration Tests
```dart
// Test full patch flow
testWidgets('Applies patch successfully', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Simulate patch availability
  simulatePatchAvailable();
  
  // Wait for patch to be checked and applied
  await tester.pumpAndSettle(const Duration(seconds: 5));
  
  // Verify patch was applied
  expect(find.text('Patched Version'), findsOneWidget);
});
```

### Platform Tests
```bash
# Test native Android code
./gradlew :app:test

# Test native iOS code
xcodebuild test -scheme Runner
```

---

## Phase 1 Task Breakdown

### Week 1: Analysis & Setup
- [ ] Day 1-2: Analyze Shorebird Flutter fork
- [ ] Day 2-3: Create analysis documents
- [ ] Day 3-4: Clone Flutter repository
- [ ] Day 4-5: Setup Flutter build environment
- [ ] Day 5: Create detailed modification plan

### Week 2: Implementation
- [ ] Day 1-2: Implement codepush_loader.cc
- [ ] Day 2-3: Modify engine.cc
- [ ] Day 3: Modify dart_vm.cc
- [ ] Day 4: Integrate with binding.dart
- [ ] Day 5: Test locally

### Week 3: Platform Integration
- [ ] Day 1-2: Implement Android platform channel
- [ ] Day 2-3: Implement iOS platform channel
- [ ] Day 3-4: End-to-end testing
- [ ] Day 4-5: Documentation and polish

---

## Risks & Mitigation

### Risk 1: Flutter Source Complexity
**Problem**: Flutter codebase is massive  
**Mitigation**: Study Shorebird first, follow their pattern  
**Contingency**: Create detailed modification guide

### Risk 2: Build System Issues
**Problem**: GN build system is complex  
**Mitigation**: Learn GN basics, get help from Flutter docs  
**Contingency**: Use published Flutter releases if needed

### Risk 3: Platform Channel Communication
**Problem**: iOS/Android integration can be tricky  
**Mitigation**: Use standard Flutter patterns  
**Contingency**: Simplify initially, enhance later

### Risk 4: Testing Challenges
**Problem**: Hard to test engine modifications  
**Mitigation**: Comprehensive unit tests, sample apps  
**Contingency**: Use real devices for testing

---

## Success Criteria for Phase 1

### Must Have ✅
- [ ] Flutter fork with quicui/main branch
- [ ] codepush_loader implementation compiles
- [ ] Patch checking on engine startup works
- [ ] Patch signature verification works
- [ ] Platform channels functional

### Should Have
- [ ] Rollback mechanism works
- [ ] Comprehensive error handling
- [ ] Good logging for debugging
- [ ] Documentation complete

### Nice to Have
- [ ] Performance optimized
- [ ] Security hardened
- [ ] CI/CD tests pass
- [ ] Sample app works end-to-end

---

## Files That Will Be Created

### Analysis Documents
```
docs/
├── FLUTTER_FORK_ANALYSIS.md
├── MODIFICATION_POINTS.md
├── FLUTTER_PATCHES.md
└── PLATFORM_CHANNELS.md
```

### Flutter Modifications
```
forks/flutter-quicui/
├── flutter/runtime/
│   ├── codepush_loader.h
│   ├── codepush_loader.cc
│   └── (modifications to other files)
├── flutter/shell/common/
│   └── engine.cc (modifications)
└── flutter/lib/src/services/
    └── binding.dart (modifications)
```

### Platform Implementations
```
forks/flutter-quicui/
├── ios/Runner/
│   └── CodePushService.swift
└── android/app/src/main/kotlin/
    └── CodePushService.kt
```

---

## Communication & Checkpoints

### Daily Standup
- What's blocking?
- What's next?
- Any help needed?

### Weekly Checkpoint
- Progress on each day's tasks
- Blockers identified
- Adjustments to plan

### Phase Complete Checkpoint
- All success criteria met?
- Quality acceptable?
- Ready for Phase 2?

---

## Next Steps

1. **Create Shorebird Analysis** - Understand how they do it
2. **Document Modification Points** - Exact files and changes needed
3. **Clone Flutter Repository** - Get source code locally
4. **Begin Implementation** - Start with codepush_loader

---

**Phase 1 Status**: Ready to begin  
**Estimated Completion**: 2-3 weeks  
**Next Phase**: Phase 2 - Compiler & CLI Tool

