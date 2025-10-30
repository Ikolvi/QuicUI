# Backend Integration Guide

Complete guide to creating custom `DataSource` implementations for integrating QuicUI with any backend service.

## Overview

This guide teaches you how to:

✅ Create a custom DataSource implementation  
✅ Implement all 15 required methods  
✅ Handle real-time subscriptions  
✅ Implement offline synchronization  
✅ Package as a reusable plugin  
✅ Write comprehensive tests  

**Time Required:** 4-8 hours (depending on backend complexity)  
**Experience Level:** Intermediate Flutter/Dart developer  
**Prerequisites:** Understanding of futures, streams, and async/await

---

## Architecture Overview

```
Your Backend Service
        ↓
   Network Layer
   (HTTP, WebSocket, SDK)
        ↓
   Your DataSource Implementation
   (Convert data to QuicUI models)
        ↓
   QuicUI Framework
   (Use through QuicUIService)
```

## Step 1: Create Your DataSource Class

### Basic Structure

```dart
import 'package:quicui/quicui.dart';

class MyCustomDataSource implements DataSource {
  // Configuration
  final String apiUrl;
  final String apiKey;
  
  // Optional: networking client
  late final http.Client _httpClient;
  
  // Optional: streaming management
  late final Map<String, StreamController> _streamControllers = {};
  
  MyCustomDataSource({
    required this.apiUrl,
    required this.apiKey,
  }) {
    _httpClient = http.Client();
    _initializeConnections();
  }
  
  void _initializeConnections() {
    // Setup real-time connections, authentication, etc.
  }
  
  // TODO: Implement all 15 required methods
  
  @override
  void dispose() {
    // Clean up resources
    _httpClient.close();
    for (final controller in _streamControllers.values) {
      controller.close();
    }
  }
}
```

---

## Step 2: Implement Screen Management Methods

### fetchScreen(String screenId)

```dart
@override
Future<Screen> fetchScreen(String screenId) async {
  if (screenId.isEmpty) {
    throw ValidationException('screenId cannot be empty');
  }
  
  try {
    final response = await _httpClient.get(
      Uri.parse('$apiUrl/screens/$screenId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 404) {
      throw ScreenNotFoundException('Screen not found: $screenId');
    }
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to fetch screen',
        code: 'FETCH_SCREEN_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Screen.fromJson(json);
    
  } on SocketException catch (e) {
    throw NetworkException('Network error: ${e.message}');
  } on TimeoutException {
    throw NetworkException('Request timeout');
  } catch (e) {
    throw DataSourceException(
      message: 'Unexpected error: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}
```

### fetchScreensByTag(String tag)

```dart
@override
Future<List<Screen>> fetchScreensByTag(String tag) async {
  if (tag.isEmpty) {
    throw ValidationException('tag cannot be empty');
  }
  
  try {
    final response = await _httpClient.get(
      Uri.parse('$apiUrl/screens?tag=$tag'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to fetch screens by tag',
        code: 'FETCH_SCREENS_TAG_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => Screen.fromJson(item as Map<String, dynamic>))
        .toList();
        
  } on SocketException catch (e) {
    throw NetworkException('Network error: ${e.message}');
  } catch (e) {
    throw DataSourceException(
      message: 'Error fetching screens: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}
```

---

## Step 3: Implement User Management Methods

### fetchUser(String userId)

```dart
@override
Future<User> fetchUser(String userId) async {
  if (userId.isEmpty) {
    throw ValidationException('userId cannot be empty');
  }
  
  try {
    final response = await _httpClient.get(
      Uri.parse('$apiUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 404) {
      throw UserNotFoundException('User not found: $userId');
    }
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to fetch user',
        code: 'FETCH_USER_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(json);
    
  } on SocketException catch (e) {
    throw NetworkException('Network error: ${e.message}');
  } catch (e) {
    throw DataSourceException(
      message: 'Error fetching user: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}
```

### fetchUsers()

```dart
@override
Future<List<User>> fetchUsers() async {
  try {
    final response = await _httpClient.get(
      Uri.parse('$apiUrl/users'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 403) {
      throw PermissionException('Not authorized to fetch users');
    }
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to fetch users',
        code: 'FETCH_USERS_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();
        
  } on SocketException catch (e) {
    throw NetworkException('Network error: ${e.message}');
  } catch (e) {
    throw DataSourceException(
      message: 'Error fetching users: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}
```

---

## Step 4: Implement Component Management Methods

### fetchComponent(String componentId) & fetchComponents()

```dart
@override
Future<Component> fetchComponent(String componentId) async {
  if (componentId.isEmpty) {
    throw ValidationException('componentId cannot be empty');
  }
  
  try {
    final response = await _httpClient.get(
      Uri.parse('$apiUrl/components/$componentId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 404) {
      throw ComponentNotFoundException('Component not found: $componentId');
    }
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to fetch component',
        code: 'FETCH_COMPONENT_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Component.fromJson(json);
    
  } on SocketException catch (e) {
    throw NetworkException('Network error: ${e.message}');
  } catch (e) {
    throw DataSourceException(
      message: 'Error fetching component: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}

@override
Future<List<Component>> fetchComponents() async {
  try {
    final response = await _httpClient.get(
      Uri.parse('$apiUrl/components'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to fetch components',
        code: 'FETCH_COMPONENTS_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => Component.fromJson(item as Map<String, dynamic>))
        .toList();
        
  } on SocketException catch (e) {
    throw NetworkException('Network error: ${e.message}');
  } catch (e) {
    throw DataSourceException(
      message: 'Error fetching components: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}
```

---

## Step 5: Implement Real-Time Subscriptions

### Using WebSockets (Recommended)

```dart
// Helper method to create or reuse stream controller
StreamController<T> _getStreamController<T>(String key) {
  if (_streamControllers.containsKey(key)) {
    return _streamControllers[key] as StreamController<T>;
  }
  
  final controller = StreamController<T>.broadcast();
  _streamControllers[key] = controller;
  return controller;
}

@override
Stream<Screen> subscribeToScreen(String screenId) async* {
  final controller = _getStreamController<Screen>('screen_$screenId');
  
  try {
    // Emit current state immediately
    final current = await fetchScreen(screenId);
    yield current;
    
    // Connect to WebSocket for updates
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://${apiUrl.replaceFirst('https://', '')}/ws/screens/$screenId'),
    );
    
    // Listen for messages
    channel.stream.listen(
      (message) {
        try {
          final json = jsonDecode(message) as Map<String, dynamic>;
          final screen = Screen.fromJson(json);
          controller.add(screen);
        } catch (e) {
          controller.addError(DataSourceException(
            message: 'Failed to parse screen update',
            code: 'PARSE_ERROR',
          ));
        }
      },
      onError: (error) {
        controller.addError(NetworkException('WebSocket error: $error'));
      },
      onDone: () {
        controller.close();
        _streamControllers.remove('screen_$screenId');
      },
    );
    
    // Yield stream values
    yield* controller.stream;
    
  } catch (e) {
    yield* Stream.error(e);
  }
}

@override
Stream<User> subscribeToUser(String userId) async* {
  final controller = _getStreamController<User>('user_$userId');
  
  try {
    final current = await fetchUser(userId);
    yield current;
    
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://${apiUrl.replaceFirst('https://', '')}/ws/users/$userId'),
    );
    
    channel.stream.listen(
      (message) {
        try {
          final json = jsonDecode(message) as Map<String, dynamic>;
          final user = User.fromJson(json);
          controller.add(user);
        } catch (e) {
          controller.addError(DataSourceException(
            message: 'Failed to parse user update',
            code: 'PARSE_ERROR',
          ));
        }
      },
      onError: (error) {
        controller.addError(NetworkException('WebSocket error: $error'));
      },
    );
    
    yield* controller.stream;
    
  } catch (e) {
    yield* Stream.error(e);
  }
}

@override
Stream<Component> subscribeToComponent(String componentId) async* {
  final controller = _getStreamController<Component>('component_$componentId');
  
  try {
    final current = await fetchComponent(componentId);
    yield current;
    
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://${apiUrl.replaceFirst('https://', '')}/ws/components/$componentId'),
    );
    
    channel.stream.listen(
      (message) {
        try {
          final json = jsonDecode(message) as Map<String, dynamic>;
          final component = Component.fromJson(json);
          controller.add(component);
        } catch (e) {
          controller.addError(DataSourceException(
            message: 'Failed to parse component update',
            code: 'PARSE_ERROR',
          ));
        }
      },
      onError: (error) {
        controller.addError(NetworkException('WebSocket error: $error'));
      },
    );
    
    yield* controller.stream;
    
  } catch (e) {
    yield* Stream.error(e);
  }
}
```

---

## Step 6: Implement Mutations

### updateScreen, updateUser, updateComponent

```dart
@override
Future<Screen> updateScreen(String screenId, Map<String, dynamic> data) async {
  if (screenId.isEmpty) {
    throw ValidationException('screenId cannot be empty');
  }
  
  try {
    final response = await _httpClient.patch(
      Uri.parse('$apiUrl/screens/$screenId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 404) {
      throw ScreenNotFoundException('Screen not found: $screenId');
    }
    
    if (response.statusCode == 400) {
      throw ValidationException('Invalid screen data: ${response.body}');
    }
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to update screen',
        code: 'UPDATE_SCREEN_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Screen.fromJson(json);
    
  } on SocketException catch (e) {
    // Queue for offline sync
    await _queueOfflineChange('update_screen', screenId, data);
    throw SyncException('Offline - change queued');
  } catch (e) {
    throw DataSourceException(
      message: 'Error updating screen: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}

@override
Future<User> updateUser(String userId, Map<String, dynamic> data) async {
  if (userId.isEmpty) {
    throw ValidationException('userId cannot be empty');
  }
  
  try {
    final response = await _httpClient.patch(
      Uri.parse('$apiUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 403) {
      throw PermissionException('Not authorized to update user');
    }
    
    if (response.statusCode == 400) {
      throw ValidationException('Invalid user data: ${response.body}');
    }
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to update user',
        code: 'UPDATE_USER_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(json);
    
  } on SocketException catch (e) {
    await _queueOfflineChange('update_user', userId, data);
    throw SyncException('Offline - change queued');
  } catch (e) {
    throw DataSourceException(
      message: 'Error updating user: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}

@override
Future<Component> updateComponent(
  String componentId,
  Map<String, dynamic> data,
) async {
  if (componentId.isEmpty) {
    throw ValidationException('componentId cannot be empty');
  }
  
  try {
    final response = await _httpClient.patch(
      Uri.parse('$apiUrl/components/$componentId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 403) {
      throw PermissionException('Not authorized to update components');
    }
    
    if (response.statusCode == 400) {
      throw ValidationException('Invalid component data: ${response.body}');
    }
    
    if (response.statusCode != 200) {
      throw DataSourceException(
        message: 'Failed to update component',
        code: 'UPDATE_COMPONENT_ERROR',
      );
    }
    
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Component.fromJson(json);
    
  } on SocketException catch (e) {
    await _queueOfflineChange('update_component', componentId, data);
    throw SyncException('Offline - change queued');
  } catch (e) {
    throw DataSourceException(
      message: 'Error updating component: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
    );
  }
}
```

---

## Step 7: Implement Offline Sync

### Offline Queue Management

```dart
// Storage for offline queue (use local database like Hive, sqlite, etc.)
final List<Map<String, dynamic>> _offlineQueue = [];

Future<void> _queueOfflineChange(
  String operation,
  String entityId,
  Map<String, dynamic> data,
) async {
  final change = {
    'operation': operation,
    'entityId': entityId,
    'data': data,
    'timestamp': DateTime.now().toIso8601String(),
    'status': 'pending',
  };
  
  _offlineQueue.add(change);
  
  // Persist to local storage (recommended)
  await _persistQueueToStorage();
}

Future<void> _persistQueueToStorage() async {
  // Use Hive, sqflite, or SharedPreferences
  // Implementation depends on your storage choice
}

@override
Future<void> syncOfflineChanges() async {
  if (_offlineQueue.isEmpty) {
    return;
  }
  
  final failedItems = <int>[];
  
  for (int i = 0; i < _offlineQueue.length; i++) {
    final item = _offlineQueue[i];
    
    try {
      final operation = item['operation'] as String;
      final entityId = item['entityId'] as String;
      final data = item['data'] as Map<String, dynamic>;
      
      switch (operation) {
        case 'update_screen':
          await updateScreen(entityId, data);
          break;
        case 'update_user':
          await updateUser(entityId, data);
          break;
        case 'update_component':
          await updateComponent(entityId, data);
          break;
        default:
          throw DataSourceException(
            message: 'Unknown operation: $operation',
            code: 'UNKNOWN_OPERATION',
          );
      }
      
      _offlineQueue[i]['status'] = 'synced';
      
    } catch (e) {
      failedItems.add(i);
      _offlineQueue[i]['status'] = 'failed';
      _offlineQueue[i]['error'] = e.toString();
    }
  }
  
  // Remove successfully synced items
  _offlineQueue.removeWhere((item) => item['status'] == 'synced');
  
  // Persist updated queue
  await _persistQueueToStorage();
  
  // Throw exception if any items failed
  if (failedItems.isNotEmpty) {
    throw SyncException(
      message: 'Sync failed for ${failedItems.length} items',
      failedItems: [
        for (final i in failedItems) _offlineQueue[i],
      ],
    );
  }
}

@override
Future<List<Map<String, dynamic>>> getOfflineQueue() async {
  return List.unmodifiable(_offlineQueue);
}
```

---

## Step 8: Error Handling

### Defining Custom Exceptions

```dart
class MyCustomException extends DataSourceException {
  MyCustomException({
    required String message,
    String code = 'CUSTOM_ERROR',
    Exception? originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );
}
```

### Consistent Error Responses

```dart
Future<T> _executeWithErrorHandling<T>(
  Future<T> Function() operation,
  String operationName,
) async {
  try {
    return await operation();
  } on DataSourceException {
    rethrow; // Already properly formatted
  } on SocketException catch (e) {
    throw NetworkException('Network error during $operationName: ${e.message}');
  } on TimeoutException {
    throw NetworkException('Timeout during $operationName');
  } on FormatException catch (e) {
    throw DataSourceException(
      message: 'Data format error: ${e.message}',
      code: 'FORMAT_ERROR',
    );
  } catch (e) {
    throw DataSourceException(
      message: 'Unexpected error during $operationName: ${e.toString()}',
      code: 'UNKNOWN_ERROR',
      originalException: e as Exception?,
    );
  }
}
```

---

## Step 9: Package as Plugin

### Create Package Structure

```
my_custom_datasource/
├── pubspec.yaml
├── README.md
├── lib/
│   ├── src/
│   │   └── my_custom_data_source.dart
│   └── my_custom_datasource.dart
└── test/
    └── my_custom_data_source_test.dart
```

### pubspec.yaml

```yaml
name: my_custom_datasource
description: Custom DataSource implementation for QuicUI
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
  quicui: ^1.0.0
  http: ^1.1.0
  web_socket_channel: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```

### Export Public API

```dart
// lib/my_custom_datasource.dart
export 'src/my_custom_data_source.dart';
```

---

## Step 10: Write Tests

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_custom_datasource/my_custom_datasource.dart';

void main() {
  group('MyCustomDataSource', () {
    late MyCustomDataSource dataSource;
    
    setUp(() {
      dataSource = MyCustomDataSource(
        apiUrl: 'https://api.example.com',
        apiKey: 'test-key',
      );
    });
    
    tearDown(() {
      dataSource.dispose();
    });
    
    test('fetchScreen returns Screen object', () async {
      final screen = await dataSource.fetchScreen('screen-1');
      expect(screen, isNotNull);
      expect(screen.id, equals('screen-1'));
    });
    
    test('fetchScreen throws ScreenNotFoundException for missing screen', () async {
      expect(
        () => dataSource.fetchScreen('nonexistent'),
        throwsA(isA<ScreenNotFoundException>()),
      );
    });
    
    test('updateScreen queues changes when offline', () async {
      // Simulate offline condition
      expect(
        () => dataSource.updateScreen('screen-1', {'name': 'New Name'}),
        throwsA(isA<SyncException>()),
      );
      
      // Verify change is queued
      final queue = await dataSource.getOfflineQueue();
      expect(queue, isNotEmpty);
    });
    
    test('subscribeToScreen yields current and future values', () async {
      final screens = <Screen>[];
      
      final subscription = dataSource.subscribeToScreen('screen-1').listen(
        (screen) => screens.add(screen),
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(screens, isNotEmpty);
      
      subscription.cancel();
    });
  });
}
```

---

## Implementation Checklist

- [ ] Extend DataSource abstract class
- [ ] Implement all 15 required methods
- [ ] Implement fetchScreen()
- [ ] Implement fetchScreensByTag()
- [ ] Implement fetchUser()
- [ ] Implement fetchUsers()
- [ ] Implement fetchComponent()
- [ ] Implement fetchComponents()
- [ ] Implement subscribeToScreen()
- [ ] Implement subscribeToUser()
- [ ] Implement subscribeToComponent()
- [ ] Implement updateScreen()
- [ ] Implement updateUser()
- [ ] Implement updateComponent()
- [ ] Implement syncOfflineChanges()
- [ ] Implement getOfflineQueue()
- [ ] Handle all exception types
- [ ] Implement error handling
- [ ] Add logging/debugging
- [ ] Create unit tests
- [ ] Create integration tests
- [ ] Write README documentation
- [ ] Package as plugin (optional)

---

## Example: Complete Firebase DataSource

See `examples/firebase_datasource.dart` for a complete, production-ready Firebase implementation.

---

## Best Practices

1. **Use Service Locators**
   - Consider using GetIt for dependency management
   - Makes testing and swapping implementations easier

2. **Implement Caching**
   - Cache frequently accessed data
   - Implement TTL (time-to-live) for cache invalidation
   - Use memory cache + persistent cache (Hive, sqflite)

3. **Error Handling**
   - Always throw appropriate exceptions
   - Include context in error messages
   - Log errors for debugging

4. **Real-Time Updates**
   - Use WebSockets for efficiency
   - Implement connection recovery
   - Gracefully handle connection losses

5. **Offline Support**
   - Queue mutations when offline
   - Implement conflict resolution strategy
   - Provide sync status to UI

6. **Security**
   - Never log sensitive data
   - Validate all input
   - Use HTTPS only
   - Implement rate limiting

7. **Performance**
   - Batch requests when possible
   - Implement pagination
   - Use compression for large payloads
   - Monitor response times

8. **Testing**
   - Mock external services
   - Test error scenarios
   - Test offline behavior
   - Test concurrent operations

---

## Common Patterns

### Retry Logic

```dart
Future<T> _withRetry<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(delay * (i + 1)); // Exponential backoff
    }
  }
  throw Exception('Max retries exceeded');
}
```

### Caching

```dart
final Map<String, Screen> _screenCache = {};
final Map<String, DateTime> _screenCacheTimes = {};

Future<Screen> fetchScreen(String screenId) async {
  // Check cache
  if (_screenCache.containsKey(screenId)) {
    final cachedTime = _screenCacheTimes[screenId]!;
    if (DateTime.now().difference(cachedTime).inMinutes < 5) {
      return _screenCache[screenId]!;
    }
  }
  
  // Fetch from backend
  final screen = await _fetchFromBackend(screenId);
  
  // Update cache
  _screenCache[screenId] = screen;
  _screenCacheTimes[screenId] = DateTime.now();
  
  return screen;
}
```

---

## Resources

- [Flutter HTTP Documentation](https://pub.dev/packages/http)
- [WebSocket Channel](https://pub.dev/packages/web_socket_channel)
- [Hive (Local Storage)](https://pub.dev/packages/hive)
- [Mocktail (Testing)](https://pub.dev/packages/mocktail)

---

## Summary

Creating a custom DataSource:

1. ✅ Extend `DataSource` abstract class
2. ✅ Implement 15 required methods
3. ✅ Handle all error scenarios
4. ✅ Implement real-time subscriptions
5. ✅ Support offline synchronization
6. ✅ Write comprehensive tests
7. ✅ Package and document

You now have a reusable plugin for any backend service!
