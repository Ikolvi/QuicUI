# QuicUI Code Push - Testing Guide

This document provides comprehensive instructions for running tests across all layers of the QuicUI Code Push system.

## Overview

The testing strategy consists of three levels:

1. **Unit Tests** - Individual component testing (C++ loader, Android/iOS handlers)
2. **Integration Tests** - Cross-layer communication (Dart/platform channel flow)
3. **E2E Tests** - Full application workflow verification

Target: **90%+ code coverage**

## C++ Unit Tests

### Prerequisites

```bash
# macOS
brew install googletest cmake

# Linux
apt-get install libgtest-dev cmake

# Windows (MSVC)
vcpkg install gtest:x64-windows
```

### Build and Run

```bash
cd packages/quicui_client/cpp/test

# Create build directory
mkdir -p build
cd build

# Configure CMake
cmake .. -DENABLE_COVERAGE=ON

# Build tests
cmake --build . --config Release

# Run tests
ctest --output-on-failure
# or
./codepush_tests

# Generate coverage report
lcov --directory . --capture --output-file coverage.info
lcov --remove coverage.info '/usr/*' --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
open coverage_html/index.html
```

### Test Categories

#### 1. PatchMetadata Tests
- ✅ Constructor initialization
- ✅ Field validation (IsValid)
- ✅ Serialization/Deserialization

#### 2. CodePushLoader Tests
- ✅ Configuration initialization
- ✅ Async patch checking
- ✅ Patch verification
- ✅ Caching mechanism
- ✅ Kernel loading
- ✅ Storage cleanup
- ✅ Error handling
- ✅ Concurrent operations (thread safety)

#### 3. Thread Safety Tests
- ✅ Concurrent patch checking (5 threads)
- ✅ Concurrent caching (10 threads)
- ✅ Cache consistency under load

### Expected Output

```
Running main() from /path/to/gtest_main.cc
[==========] Running 25 tests from 3 test cases.
[----------] Global test environment set-up.
[----------] 4 tests from PatchMetadataTest
[ RUN      ] PatchMetadataTest.ConstructorInitializesFields
[       OK ] PatchMetadataTest.ConstructorInitializesFields (0 ms)
...
[----------] Test environment tear-down
[==========] 25 tests from 3 test cases ran. (250 ms total)
[  PASSED  ] 25 tests
```

## Dart Integration Tests

### Prerequisites

```bash
cd packages/quicui_code_push_client

# Install dependencies
flutter pub get

# Install mockito
flutter pub add dev:mockito dev:build_runner
flutter pub run build_runner build
```

### Run Tests

```bash
# Run all integration tests
flutter test test/integration_test.dart

# Run specific test suite
flutter test test/integration_test.dart -k "Initialization"

# Run with coverage
flutter test --coverage test/integration_test.dart

# View coverage report
open coverage/lcov.html
```

### Test Categories

#### 1. Initialization Tests
- ✅ Valid configuration initialization
- ✅ Empty service URL validation
- ✅ Empty app ID validation
- ✅ Empty app version validation
- ✅ Configuration persistence

#### 2. Patch Checking Tests
- ✅ Successful patch check
- ✅ Network error handling
- ✅ Patch metadata structure validation
- ✅ Concurrent checks

#### 3. Patch Loading Tests
- ✅ Load with valid version
- ✅ Fail with empty version
- ✅ Patch caching
- ✅ Verification failure handling

#### 4. Error Handling Tests
- ✅ Platform exception catching
- ✅ Meaningful error messages
- ✅ Missing platform channel handling

#### 5. Performance Tests
- ✅ Initialization speed (<5s)
- ✅ Patch checking speed (<30s)

### Expected Output

```
$ flutter test test/integration_test.dart

00:00 +0: CodePushClient Integration Tests
00:00 +1: CodePushClient Integration Tests > Initialization > initializes with valid configuration
00:02 +2: CodePushClient Integration Tests > Initialization > fails with empty service URL
...
00:45 +18: All tests passed!
```

## E2E Application Tests

### Run Demo App

```bash
cd packages/quicui_code_push_client/example

# iOS
flutter run -d "iPhone 15"

# Android
flutter run -d emulator-5554

# macOS (desktop)
flutter run -d macos
```

### Manual Test Scenarios

#### Scenario 1: Normal Patch Update
1. Launch app
2. Verify "Initializing..." status
3. Tap "Check for Patches"
4. Verify patch appears
5. Tap "Load Patch X.X.X"
6. Verify success message
7. Verify version updates

#### Scenario 2: Network Failure Recovery
1. Disable network
2. Tap "Check for Patches"
3. Verify error handling
4. Re-enable network
5. Tap "Check for Patches"
6. Verify normal operation

#### Scenario 3: Critical Patch Handling
1. Check for critical patch
2. Verify UI indicates criticality
3. Load critical patch
4. Verify force-load behavior

#### Scenario 4: Disable and Re-enable
1. Tap "Disable Code Push"
2. Confirm dialog
3. Verify disabled state
4. Close and relaunch app
5. Code push should re-initialize

### Platform-Specific Verification

#### Android
- Check Logcat for method channel calls
- Verify patch files in app cache directory
- Test on Android 6.0+ devices

#### iOS
- Check Console for method channel calls
- Verify patch files in app sandboxed cache
- Test on iOS 13+ devices

## GitHub Actions CI

The project includes automated test runs on every push:

```yaml
# .github/workflows/test.yml
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: bash <(curl -s https://codecov.io/bash)
```

## Coverage Goals

Target coverage by component:

| Component | Target | Current |
|-----------|--------|---------|
| codepush_loader.cc | 95%+ | - |
| binding.dart | 90%+ | - |
| Android handler | 90%+ | - |
| iOS handler | 90%+ | - |
| Integration layer | 85%+ | - |
| Overall | 90%+ | - |

## Troubleshooting

### C++ Tests

**Issue**: GoogleTest not found
```bash
# Solution: Install via package manager or manually
brew install googletest
export GTEST_ROOT=/usr/local/opt/googletest
cmake .. -DGTEST_ROOT=$GTEST_ROOT
```

**Issue**: Linker errors
```bash
# Solution: Ensure pthread is linked
cmake .. -DCMAKE_CXX_FLAGS="-lpthread"
```

### Dart Tests

**Issue**: MockIto build fails
```bash
flutter pub cache clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build
```

**Issue**: Platform channel communication fails
```bash
# Ensure platform handlers are available
# Check that method channel name matches: "com.quicui/codepush"
```

### E2E Tests

**Issue**: App crashes on launch
```bash
flutter clean
flutter pub get
flutter run -v  # verbose mode
```

**Issue**: Patch download fails
```bash
# Check network connectivity
# Verify service URL is accessible
# Check firewall/proxy settings
```

## Performance Benchmarks

Expected performance metrics:

| Operation | Target | Acceptable |
|-----------|--------|------------|
| Initialization | <1s | <5s |
| Patch check | <5s | <30s |
| Patch download (10MB) | <30s | <60s |
| Patch verification | <2s | <10s |
| Kernel loading | <5s | <15s |

## Continuous Integration

All tests are run on every commit:

1. **Pre-commit**: Local tests (C++ quick tests)
2. **Push**: Full test suite (C++, Dart, E2E)
3. **Pull Request**: Comprehensive testing with coverage reports
4. **Nightly**: Performance benchmarking

## Debugging

### Enable Verbose Logging

```dart
// In Dart
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

CodePushClient(enableLogging: true)
```

```kotlin
// In Android
CodePushMethodHandler.enableDebugLogging = true
```

```swift
// In iOS
CodePushMethodHandler.debugLoggingEnabled = true
```

### Attach Debugger

```bash
# Android
flutter run -d emulator-5554 --debug

# iOS
flutter run -d "iPhone 15" --debug

# macOS
flutter run -d macos --debug
```

## Next Steps

After tests pass:
1. Review coverage report (target: 90%+)
2. Perform manual regression testing
3. Document known issues
4. Prepare for Phase 2 (Compiler & CLI Tool)

---

Last Updated: November 1, 2025
