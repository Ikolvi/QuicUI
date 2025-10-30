# Migration Guide: From Old Supabase-Specific to Plugin Architecture

## Overview

This guide walks you through migrating your QuicUI application from the old Supabase-specific initialization to the new **backend-agnostic plugin architecture**.

**Key Benefits of Migrating:**
- 🔄 Switch backends without changing app code
- 🧪 Easier testing with mock implementations
- 🎯 Cleaner, more maintainable code
- 🚀 Future-proof architecture
- 📦 Support for multiple backends

**Migration Time:** 15-30 minutes  
**Breaking Changes:** None - old code still works (deprecated)  
**Complexity:** Easy

## Quick Start (5 minutes)

### Before (Old Way)
```dart
// OLD: Supabase-specific
await QuicUIService().initialize(
  'https://project.supabase.co',
  'your-anon-key',
);
```

### After (New Way)
```dart
// NEW: Backend-agnostic
final dataSource = SupabaseDataSource(
  'https://project.supabase.co',
  'your-anon-key',
);
await QuicUIService().initializeWithDataSource(dataSource);
```

That's it! Everything else stays the same.

---

## Step-by-Step Migration

### Step 1: Update Imports

Add import for SupabaseDataSource:

```dart
// Add this import
import 'package:quicui_supabase/quicui_supabase.dart';
```

If you don't have the `quicui_supabase` package yet:

```bash
flutter pub add quicui_supabase
```

### Step 2: Locate Initialization Code

Find where you're calling `QuicUIService().initialize()`. Common locations:

- **main.dart** - App startup
- **main_bloc.dart** - BLoC initialization
- **app_bootstrap.dart** - Bootstrap function
- **setup.dart** - Setup/initialization module

Example - **Before Migration:**

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // OLD: Direct initialization
  await QuicUIService().initialize(
    'https://xyzabc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  );
  
  runApp(MyApp());
}
```

### Step 3: Replace Initialization

Update the initialization code:

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NEW: Plugin-based initialization
  final dataSource = SupabaseDataSource(
    'https://xyzabc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  );
  await QuicUIService().initializeWithDataSource(dataSource);
  
  runApp(MyApp());
}
```

### Step 4: Update Error Handling (Optional)

If you have error handling around initialization, update it:

```dart
// OLD: Simple try-catch
try {
  await QuicUIService().initialize(url, key);
} catch (e) {
  print('Initialization failed: $e');
}

// NEW: More informative error handling
try {
  final dataSource = SupabaseDataSource(url, key);
  await QuicUIService().initializeWithDataSource(dataSource);
} on SupabaseException catch (e) {
  print('Supabase error: ${e.message}');
} on DataSourceException catch (e) {
  print('DataSource error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

### Step 5: Test Your Changes

Run your app to verify everything works:

```bash
flutter run
```

Expected behavior:
- ✅ App initializes normally
- ✅ Screens load correctly
- ✅ Real-time updates work (if subscribed)
- ✅ No compilation errors

---

## Common Migration Patterns

### Pattern 1: Simple Configuration

**Before:**
```dart
const String SUPABASE_URL = 'https://xyzabc.supabase.co';
const String SUPABASE_KEY = 'eyJhbGci...';

void initializeApp() async {
  await QuicUIService().initialize(SUPABASE_URL, SUPABASE_KEY);
}
```

**After:**
```dart
const String SUPABASE_URL = 'https://xyzabc.supabase.co';
const String SUPABASE_KEY = 'eyJhbGci...';

void initializeApp() async {
  final dataSource = SupabaseDataSource(SUPABASE_URL, SUPABASE_KEY);
  await QuicUIService().initializeWithDataSource(dataSource);
}
```

### Pattern 2: Environment-Specific Configuration

**Before:**
```dart
void initializeApp(String environment) async {
  final url = environment == 'prod'
      ? 'https://prod.supabase.co'
      : 'https://dev.supabase.co';
  
  final key = environment == 'prod'
      ? 'prod-key'
      : 'dev-key';
  
  await QuicUIService().initialize(url, key);
}
```

**After:**
```dart
void initializeApp(String environment) async {
  final url = environment == 'prod'
      ? 'https://prod.supabase.co'
      : 'https://dev.supabase.co';
  
  final key = environment == 'prod'
      ? 'prod-key'
      : 'dev-key';
  
  final dataSource = SupabaseDataSource(url, key);
  await QuicUIService().initializeWithDataSource(dataSource);
}
```

### Pattern 3: Initialization with Logging

**Before:**
```dart
void initializeApp() async {
  print('Starting QuicUI initialization...');
  
  try {
    await QuicUIService().initialize(url, key);
    print('✓ QuicUI initialized successfully');
  } catch (e) {
    print('✗ QuicUI initialization failed: $e');
    rethrow;
  }
}
```

**After:**
```dart
void initializeApp() async {
  print('Starting QuicUI initialization...');
  
  try {
    final dataSource = SupabaseDataSource(url, key);
    await QuicUIService().initializeWithDataSource(dataSource);
    print('✓ QuicUI initialized successfully');
  } catch (e) {
    print('✗ QuicUI initialization failed: $e');
    rethrow;
  }
}
```

### Pattern 4: Testing with Mock

**Before:**
```dart
// Couldn't easily mock initialization
void testScreenFetching() async {
  // Had to use real Supabase connection
  await QuicUIService().initialize(url, key);
  final screen = await QuicUIService().fetchScreen('test-1');
  expect(screen, isNotNull);
}
```

**After:**
```dart
// Easy mocking with plugin architecture
void testScreenFetching() async {
  final mockDataSource = MockDataSource();
  when(() => mockDataSource.fetchScreen('test-1'))
      .thenAnswer((_) async => testScreen);
  
  await QuicUIService().initializeWithDataSource(mockDataSource);
  final screen = await QuicUIService().fetchScreen('test-1');
  expect(screen, isNotNull);
}
```

### Pattern 5: Multi-Backend Support

**Before:**
```dart
// Only Supabase was supported
await QuicUIService().initialize(supabaseUrl, supabaseKey);
```

**After:**
```dart
// Easy to switch backends
if (useFirebase) {
  final dataSource = FirebaseDataSource(firebaseConfig);
  await QuicUIService().initializeWithDataSource(dataSource);
} else {
  final dataSource = SupabaseDataSource(supabaseUrl, supabaseKey);
  await QuicUIService().initializeWithDataSource(dataSource);
}
```

---

## Backward Compatibility

The old `initialize()` method still exists but is deprecated:

```dart
@Deprecated('Use initializeWithDataSource instead')
Future<void> initialize(String supabaseUrl, String supabaseAnonKey)
```

If you call it, you'll get:
```
UnimplementedError: initialize: Use SupabaseService().initialize(supabaseUrl, supabaseAnonKey)
```

This is intentional - it guides you to the new approach.

---

## Testing Migration

### Verify Old Method Fails (Expected)

```dart
test('Old initialize method throws helpful error', () async {
  expect(
    () => QuicUIService().initialize('url', 'key'),
    throwsUnimplementedError,
  );
});
```

### Verify New Method Works

```dart
test('New initializeWithDataSource works', () async {
  final mockDataSource = MockDataSource();
  
  // Should not throw
  await QuicUIService().initializeWithDataSource(mockDataSource);
  
  // DataSource should be registered
  final registered = DataSourceProvider.instance.get();
  expect(registered, equals(mockDataSource));
});
```

---

## Troubleshooting

### Issue 1: "SupabaseDataSource not found"

**Solution:** Install the `quicui_supabase` package:
```bash
flutter pub add quicui_supabase
```

### Issue 2: "Can't find initializeWithDataSource"

**Solution:** Make sure you're using the latest version:
```bash
flutter pub upgrade quicui
```

### Issue 3: "DataSourceProvider is null"

**Solution:** Make sure to call `initializeWithDataSource()` before using `QuicUIService()`:
```dart
// ✓ Correct
final dataSource = SupabaseDataSource(url, key);
await QuicUIService().initializeWithDataSource(dataSource);
final screen = await QuicUIService().fetchScreen('id');

// ✗ Wrong - forgot to initialize
final screen = await QuicUIService().fetchScreen('id'); // Will fail
```

### Issue 4: Import conflicts

**Solution:** Use qualified imports:
```dart
// Avoid naming conflicts
import 'package:quicui/quicui.dart' as quicui;
import 'package:quicui_supabase/quicui_supabase.dart' as quicui_supabase;

final dataSource = quicui_supabase.SupabaseDataSource(url, key);
await quicui.QuicUIService().initializeWithDataSource(dataSource);
```

---

## What Doesn't Change

After migration, these remain exactly the same:

✅ **Screen fetching:**
```dart
final screenData = await QuicUIService().fetchScreen('screen-id');
```

✅ **Real-time subscriptions:**
```dart
final stream = dataSource.subscribeToScreen('screen-id');
stream.listen((screen) { /* ... */ });
```

✅ **Error handling:**
```dart
try {
  final screen = await QuicUIService().fetchScreen('id');
} catch (e) {
  print('Error: $e');
}
```

✅ **BLoC integration:**
```dart
class ScreenBloc extends Bloc<ScreenEvent, ScreenState> {
  ScreenBloc() : super(ScreenInitial()) {
    on<FetchScreenEvent>((event, emit) async {
      final screen = await QuicUIService().fetchScreen(event.id);
      // ... handle screen
    });
  }
}
```

---

## Migration Checklist

- [ ] Install/update `quicui_supabase` package
- [ ] Add import for SupabaseDataSource
- [ ] Locate initialization code in main.dart or setup file
- [ ] Create SupabaseDataSource instance
- [ ] Replace `initialize()` with `initializeWithDataSource()`
- [ ] Remove any try-catch blocks around old `initialize()` (update if needed)
- [ ] Run `flutter run` to verify
- [ ] Run tests: `flutter test`
- [ ] Verify screens load correctly
- [ ] Check real-time updates work
- [ ] Deploy to test environment
- [ ] Deploy to production

---

## Next Steps

After migration, consider:

1. **Explore Plugin Options**
   - See [Backend Integration Guide](BACKEND_INTEGRATION.md) to learn about other backends
   - Consider Firebase or REST API implementations for future flexibility

2. **Testing Improvements**
   - Use mock DataSources in tests for faster, isolated testing
   - Remove dependency on real backend services in CI/CD

3. **Performance Optimization**
   - Review [Performance Guide](PERFORMANCE.md)
   - Implement caching strategies

4. **Custom Backends**
   - Build custom DataSource for proprietary systems
   - Follow [Custom Backend Guide](BACKEND_INTEGRATION.md)

---

## Support

If you encounter issues during migration:

1. Check [Architecture Overview](PLUGIN_ARCHITECTURE.md)
2. Review [Troubleshooting Section](#troubleshooting) above
3. Check existing tests for usage examples
4. Open an issue on GitHub with error details

---

## Summary

The migration is straightforward:

1. Install `quicui_supabase`
2. Create `SupabaseDataSource` instance
3. Call `initializeWithDataSource()` instead of `initialize()`
4. Test and deploy

**You'll gain flexibility and testability with minimal code changes!**
