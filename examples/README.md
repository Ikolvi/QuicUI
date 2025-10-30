# QuicUI DataSource Examples

This directory contains example implementations of custom `DataSource` backends for QuicUI.

## Available Examples

### 1. REST API DataSource (`rest_api_datasource.dart`)

A complete, production-ready implementation of a REST API backend using:

- **HTTP Requests:** GET, POST, PATCH for CRUD operations
- **Real-Time Updates:** Server-Sent Events (SSE)
- **Caching:** TTL-based caching for performance
- **Offline Support:** Change queuing and sync
- **Error Handling:** Comprehensive exception handling
- **Retry Logic:** Exponential backoff retry mechanism

**Features:**
- All 15 DataSource methods implemented
- Proper HTTP status code handling
- Automatic caching with invalidation
- Offline change queuing
- Streaming real-time updates
- Connection timeout handling

**Usage:**
```dart
final dataSource = RestApiDataSource(
  apiUrl: 'https://api.example.com',
  apiKey: 'your-api-key',
);

await QuicUIService().initializeWithDataSource(dataSource);
```

**Customization:**
- Replace SSE with WebSocket for different backends
- Modify cache duration for your needs
- Adjust retry logic based on API behavior
- Implement persistent storage for offline queue

---

## How to Use These Examples

### 1. Copy and Adapt

```bash
# Copy the REST API example to your project
cp rest_api_datasource.dart ../packages/my_rest_datasource/lib/src/
```

### 2. Customize for Your Backend

Edit the file to:
- Change API endpoints (`/screens` → `/your-endpoint`)
- Adjust authentication headers
- Modify data transformation if needed
- Update caching strategies

### 3. Implement in Your App

```dart
import 'package:my_rest_datasource/my_rest_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dataSource = RestApiDataSource(
    apiUrl: 'https://api.yourserver.com',
    apiKey: 'your-api-key',
  );
  
  await QuicUIService().initializeWithDataSource(dataSource);
  
  runApp(MyApp());
}
```

### 4. Test Your Implementation

```dart
test('RestApiDataSource fetches screens', () async {
  final dataSource = RestApiDataSource(
    apiUrl: 'https://api.example.com',
    apiKey: 'test-key',
  );
  
  final screen = await dataSource.fetchScreen('screen-1');
  expect(screen, isNotNull);
  expect(screen.id, equals('screen-1'));
});
```

---

## Example Architecture

```
Your Application
       ↓
QuicUIService
       ↓
RestApiDataSource
       ├── HTTP Client
       │   ├── GET /screens/{id}
       │   ├── PATCH /screens/{id}
       │   └── ...
       ├── SSE Stream
       │   ├── /screens/{id}/subscribe
       │   └── ...
       ├── Cache Layer
       │   └── TTL-based cache
       └── Offline Queue
           └── Pending changes
       ↓
REST API Server
```

---

## Common Modifications

### Change Transport (WebSocket instead of SSE)

Replace SSE subscription with WebSocket:

```dart
@override
Stream<Screen> subscribeToScreen(String screenId) async* {
  final controller = _getStreamController<Screen>('screen_$screenId');
  
  try {
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://api.example.com/ws/screens/$screenId'),
    );
    
    channel.stream.listen((message) {
      final screen = Screen.fromJson(jsonDecode(message));
      controller.add(screen);
    });
    
    yield* controller.stream;
  } catch (e) {
    yield* Stream.error(e);
  }
}
```

### Implement GraphQL

Replace HTTP with GraphQL queries:

```dart
@override
Future<Screen> fetchScreen(String screenId) async {
  final query = '''
    query {
      screen(id: "$screenId") {
        id
        name
        widgets { ... }
      }
    }
  ''';
  
  final response = await _executeGraphQLQuery(query);
  return Screen.fromJson(response['data']['screen']);
}
```

### Add Persistent Offline Storage

Use local database for offline queue:

```dart
Future<void> _queueOfflineChange(
  String operation,
  String entityId,
  Map<String, dynamic> data,
) async {
  final box = await Hive.openBox('offline_queue');
  
  await box.add({
    'operation': operation,
    'entityId': entityId,
    'data': data,
    'timestamp': DateTime.now().toIso8601String(),
  });
}
```

### Add Encryption

Encrypt offline queue data:

```dart
Future<void> _queueOfflineChange(...) async {
  final encrypted = _encryptData(jsonEncode(changeData));
  _offlineQueue.add(encrypted);
}
```

---

## Testing Examples

### Mock Testing

```dart
void main() {
  group('RestApiDataSource', () {
    late MockHttpClient mockHttpClient;
    late RestApiDataSource dataSource;
    
    setUp(() {
      mockHttpClient = MockHttpClient();
      dataSource = RestApiDataSource(
        apiUrl: 'https://test.com',
        apiKey: 'test-key',
      );
    });
    
    test('fetches screen successfully', () async {
      when(() => mockHttpClient.get(...))
          .thenAnswer((_) async => http.Response('{"id":"1","name":"Home"}', 200));
      
      final screen = await dataSource.fetchScreen('1');
      expect(screen.id, equals('1'));
    });
  });
}
```

---

## Performance Tips

### 1. Caching Strategy

```dart
// Cache screens for 5 minutes
const Duration _screenCacheDuration = Duration(minutes: 5);

// Cache components for 1 day (rarely change)
const Duration _componentCacheDuration = Duration(days: 1);

// Cache users for 10 minutes
const Duration _userCacheDuration = Duration(minutes: 10);
```

### 2. Batch Operations

```dart
// Fetch multiple screens in one request
Future<List<Screen>> fetchScreensByTag(String tag) async {
  // API: GET /screens?tag=onboarding
  // Returns multiple screens in one response
}
```

### 3. Streaming Optimization

```dart
// Use backpressure to avoid overwhelming the app
Stream<Screen> subscribeToScreen(String screenId) {
  return _eventStream
      .where((event) => event.screenId == screenId)
      .throttle(const Duration(milliseconds: 100));
}
```

---

## Migration Guide

### From Firebase to REST API

```dart
// Firebase
final firebaseDataSource = FirebaseDataSource(config);
await QuicUIService().initializeWithDataSource(firebaseDataSource);

// Switch to REST API
final restDataSource = RestApiDataSource(
  apiUrl: 'https://api.example.com',
  apiKey: 'api-key',
);
await QuicUIService().initializeWithDataSource(restDataSource);

// No app code changes needed!
```

---

## Troubleshooting

### Issue: Offline changes not syncing

**Solution:** Check getOfflineQueue() to see pending changes:
```dart
final queue = await dataSource.getOfflineQueue();
print('Pending: ${queue.length} changes');
```

### Issue: Cache not updating

**Solution:** Ensure cache is cleared after mutations:
```dart
await dataSource.updateScreen('id', data);
// Cache is automatically cleared
final fresh = await dataSource.fetchScreen('id'); // Fetches from backend
```

### Issue: Real-time updates not working

**Solution:** Verify SSE/WebSocket connection:
```dart
dataSource.subscribeToScreen('id').listen(
  (screen) => print('Updated: $screen'),
  onError: (error) => print('Connection error: $error'),
);
```

---

## Resources

- [Backend Integration Guide](../docs/BACKEND_INTEGRATION.md)
- [API Reference](../docs/API_REFERENCE.md)
- [Plugin Architecture](../docs/PLUGIN_ARCHITECTURE.md)
- [HTTP Package Documentation](https://pub.dev/packages/http)
- [WebSocket Channel](https://pub.dev/packages/web_socket_channel)

---

## Contributing

To add new examples:

1. Create a new file: `examples/{backend}_datasource.dart`
2. Implement all 15 DataSource methods
3. Add comprehensive comments
4. Include error handling
5. Create a README section above
6. Commit with example documentation

---

## License

Examples are provided as-is for educational purposes. Use and modify freely for your projects.
