# QuicUI Plugin Architecture

## Overview

QuicUI uses a **plugin-based architecture** to decouple the framework from specific backend implementations. This design allows you to:

- ✅ Use different backends (Supabase, Firebase, custom REST API, local database, etc.)
- ✅ Swap backends without changing application code
- ✅ Create custom implementations for proprietary systems
- ✅ Test with mock implementations easily
- ✅ Support multiple backends simultaneously in different app instances

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    QuicUI Application                        │
│                                                              │
│  ┌────────────────┐         ┌────────────────┐             │
│  │  BLoC Layer    │         │ State Manager  │             │
│  └────────┬───────┘         └────────┬───────┘             │
│           │                          │                      │
│           └──────────────┬───────────┘                      │
│                          │                                   │
│                   ┌──────▼──────┐                           │
│                   │QuicUIService│◄─── Singleton             │
│                   │  (Backend-  │     Factory               │
│                   │  Agnostic)  │                           │
│                   └──────┬──────┘                           │
│                          │                                   │
│                   ┌──────▼──────────────┐                   │
│                   │DataSourceProvider   │◄─── Service       │
│                   │(Service Locator)    │     Locator       │
│                   └──────┬──────────────┘                   │
│                          │                                   │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           │ Registered at Runtime
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   DataSource Plugins                         │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Supabase    │  │  Firebase    │  │ Custom REST  │     │
│  │  DataSource  │  │  DataSource  │  │  DataSource  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │  Mock/Test   │  │   Your Own   │                        │
│  │  DataSource  │  │  DataSource  │                        │
│  └──────────────┘  └──────────────┘                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      Supabase          Firebase         REST API
      Database          Database         Server
```

## Core Components

### 1. **DataSource Interface** (Abstract)

Location: `lib/src/repositories/abstract/data_source.dart`

Defines the contract that all backend implementations must fulfill. All 15 methods are required:

```dart
abstract class DataSource {
  // Screen Management
  Future<Screen> fetchScreen(String screenId);
  Future<List<Screen>> fetchScreensByTag(String tag);
  
  // User Management
  Future<User> fetchUser(String userId);
  Future<List<User>> fetchUsers();
  
  // Component Management
  Future<Component> fetchComponent(String componentId);
  Future<List<Component>> fetchComponents();
  
  // Real-time Subscriptions
  Stream<Screen> subscribeToScreen(String screenId);
  Stream<User> subscribeToUser(String userId);
  Stream<Component> subscribeToComponent(String componentId);
  
  // Mutations
  Future<Screen> updateScreen(String screenId, Map<String, dynamic> data);
  Future<User> updateUser(String userId, Map<String, dynamic> data);
  Future<Component> updateComponent(String componentId, Map<String, dynamic> data);
  
  // Offline Sync
  Future<void> syncOfflineChanges();
  Future<List<Map<String, dynamic>>> getOfflineQueue();
}
```

**Key Properties:**
- All methods are `async` (Future-based)
- Real-time subscriptions use `Stream` for change notifications
- Error handling via exceptions
- All data types use QuicUI's model layer (Screen, User, Component)

### 2. **DataSourceProvider** (Service Locator)

Location: `lib/src/repositories/data_source_provider.dart`

Manages registration and retrieval of DataSource implementations:

```dart
class DataSourceProvider {
  static final DataSourceProvider _instance = DataSourceProvider._internal();
  
  factory DataSourceProvider() => _instance;
  
  DataSourceProvider._internal();
  
  static DataSourceProvider get instance => _instance;
  
  void register(DataSource dataSource);
  DataSource? get();
}
```

**Responsibilities:**
- Singleton pattern ensures single instance across app
- Stores registered DataSource
- Provides lazy access via `.get()`
- Thread-safe operations
- Clear error messages when no DataSource registered

**Usage:**
```dart
// Register a DataSource
DataSourceProvider.instance.register(myDataSource);

// Retrieve the DataSource
final dataSource = DataSourceProvider.instance.get();
```

### 3. **QuicUIService** (Main Service)

Location: `lib/src/services/quicui_service.dart`

Framework entry point that coordinates initialization and data fetching:

```dart
class QuicUIService {
  static final QuicUIService _instance = QuicUIService._internal();
  
  factory QuicUIService() => _instance;
  
  QuicUIService._internal();
  
  // Initialize with any DataSource plugin
  Future<void> initializeWithDataSource(DataSource dataSource);
  
  // Fetch screen using registered DataSource
  Future<Map<String, dynamic>> fetchScreen(String screenId);
}
```

**Responsibilities:**
- Singleton factory pattern
- Backend-agnostic initialization
- Delegates to DataSourceProvider
- Provides clean API for BLoC and UI layers
- Comprehensive error handling and logging

## Initialization Flow

### Plugin-Based Initialization

```dart
// 1. Create your backend implementation
final dataSource = SupabaseDataSource(
  url: 'https://project.supabase.co',
  anonKey: 'your-anon-key',
);

// 2. Initialize QuicUIService with the plugin
await QuicUIService().initializeWithDataSource(dataSource);

// 3. Use QuicUIService normally
final screenData = await QuicUIService().fetchScreen('screen-1');
```

### Step-by-Step Process

1. **Create DataSource Implementation**
   - Implement all 15 required methods
   - Handle backend-specific logic
   - Configure credentials/URLs

2. **Register with Service**
   - Call `QuicUIService().initializeWithDataSource(dataSource)`
   - Service logs initialization progress
   - DataSource is registered with DataSourceProvider

3. **Use Throughout App**
   - BLoCs call `QuicUIService().fetchScreen()`
   - Service delegates to DataSourceProvider
   - DataSourceProvider retrieves registered DataSource
   - Backend is called and data returned

## Data Flow: Fetching a Screen

```
UI/BLoC
   │
   │ await QuicUIService().fetchScreen('screen-id')
   ▼
QuicUIService.fetchScreen()
   │
   │ Get DataSource from DataSourceProvider
   ▼
DataSourceProvider.get()
   │
   │ Returns registered SupabaseDataSource
   ▼
SupabaseDataSource.fetchScreen()
   │
   │ Query: SELECT * FROM screens WHERE id = 'screen-id'
   ▼
Supabase Backend
   │
   │ Return Screen object
   ▼
QuicUIService converts to JSON
   │
   │ Return Map<String, dynamic>
   ▼
UI/BLoC receives screen data
```

## Real-Time Subscriptions

QuicUI supports real-time updates through DataSource streams:

```dart
// Subscribe to screen changes
final screenStream = dataSource.subscribeToScreen('screen-id');

streamSubscription = screenStream.listen((updatedScreen) {
  // React to changes in real-time
  print('Screen updated: ${updatedScreen.name}');
});

// Don't forget to cancel when done
streamSubscription.cancel();
```

**Benefits:**
- Automatic UI updates when data changes
- Reduced polling overhead
- Better user experience
- Works with BLoC event streams

## Offline Support

DataSources can implement offline capabilities:

```dart
// Queue changes made while offline
await dataSource.updateScreen('screen-id', {'name': 'New Name'});

// When connectivity returns
await dataSource.syncOfflineChanges();

// Check pending changes
final queue = await dataSource.getOfflineQueue();
```

## Error Handling

DataSources throw consistent exceptions:

```dart
try {
  final screen = await QuicUIService().fetchScreen('screen-id');
} on ScreenNotFoundException catch (e) {
  print('Screen not found: ${e.message}');
} on DataSourceException catch (e) {
  print('Backend error: ${e.message}');
} on SyncException catch (e) {
  print('Sync error: ${e.message}');
}
```

## Testing with Mock DataSource

```dart
// Create a mock for testing
class MockDataSource extends Mock implements DataSource {}

// Configure mock responses
final mockDataSource = MockDataSource();
when(() => mockDataSource.fetchScreen('screen-1'))
    .thenAnswer((_) async => testScreen);

// Use in tests
await QuicUIService().initializeWithDataSource(mockDataSource);
final result = await QuicUIService().fetchScreen('screen-1');
```

## Supported Backends (Included)

### Supabase
- **File:** `packages/quicui_supabase/lib/src/datasource/supabase_data_source.dart`
- **Package:** `quicui_supabase`
- **Setup:** [See Supabase Integration Guide](SUPABASE_INTEGRATION.md)

### Firebase (Coming Soon)
- Planned Firebase Realtime Database implementation
- Will be in `packages/quicui_firebase`

### REST API (Coming Soon)
- Generic HTTP-based implementation
- Will be in `packages/quicui_rest`

## Custom Backend Implementation

To implement a custom DataSource:

1. Create a new class extending `DataSource`
2. Implement all 15 required methods
3. Handle your backend's authentication/networking
4. Manage error handling and offline state
5. Write comprehensive tests

See [Backend Integration Guide](BACKEND_INTEGRATION.md) for detailed instructions.

## Performance Considerations

### Caching
- Implement caching in your DataSource to reduce backend calls
- Cache Screen, User, Component objects
- Invalidate cache on updates

### Batch Operations
- Fetch multiple screens/users in single calls
- Reduce network round-trips
- Available through `fetchScreensByTag()`, `fetchUsers()`, etc.

### Streaming
- Use subscriptions for real-time updates instead of polling
- More efficient use of bandwidth and battery
- Automatically updates UI when data changes

### Offline Queuing
- Queue mutations while offline
- Batch sync when connectivity returns
- Reduces data loss and improves reliability

## Thread Safety

All DataSource operations are thread-safe:

```dart
// Safe to call from multiple threads/isolates
final screen1 = await QuicUIService().fetchScreen('screen-1');
final screen2 = await QuicUIService().fetchScreen('screen-2');

// Both calls work concurrently
```

## Custom Backend Implementation

To implement a custom DataSource:

1. Create a new class extending `DataSource`
2. Implement all 15 required methods
3. Handle your backend's authentication/networking
4. Manage error handling and offline state
5. Write comprehensive tests

See [Backend Integration Guide](BACKEND_INTEGRATION.md) for detailed instructions.

## Summary

The plugin architecture provides:

✅ **Flexibility** - Use any backend  
✅ **Maintainability** - Clean separation of concerns  
✅ **Testability** - Mock implementations for testing  
✅ **Extensibility** - Custom backends easily  
✅ **Scalability** - Support multiple backends simultaneously  

This architecture enables QuicUI to evolve without requiring changes to application code.
