# Custom Backend Implementation Guide

**Target Audience:** Developers implementing custom backends for QuicUI  
**Version:** 2.0.0  
**Status:** 📋 Template & Examples  

---

## 📖 Overview

This guide helps you implement a **custom backend** for QuicUI v2.0.0+ without writing a separate plugin package.

### When to Use This
✅ Custom internal backend  
✅ Quick backend integration  
✅ Testing/prototyping  
✅ Legacy system integration  

### When to Create a Plugin Package
✅ Public backend service  
✅ Reusable across projects  
✅ Publishing on pub.dev  

---

## 🏗️ Step-by-Step Implementation

### Step 1: Create Models (Optional)

If your backend uses different field names or structures:

```dart
/// lib/models/backend_models.dart
import 'package:quicui/quicui.dart';

class BackendScreen {
  final String id;
  final String title;           // Different from QuicUI's "name"
  final Map<String, dynamic> config;
  final DateTime updatedAt;
  
  BackendScreen({
    required this.id,
    required this.title,
    required this.config,
    required this.updatedAt,
  });
  
  /// Convert from backend model to QuicUI model
  Screen toQuicUIScreen() {
    return Screen(
      id: id,
      name: title,
      config: config,
      lastModified: updatedAt,
    );
  }
  
  /// Convert from QuicUI model to backend model
  factory BackendScreen.fromQuicUI(Screen screen) {
    return BackendScreen(
      id: screen.id,
      title: screen.name,
      config: screen.config,
      updatedAt: screen.lastModified,
    );
  }
}
```

### Step 2: Create Custom DataSource

```dart
/// lib/services/custom_backend_data_source.dart
import 'package:quicui/quicui.dart';
import 'package:dio/dio.dart';
import 'models/backend_models.dart';

class CustomBackendDataSource implements DataSource {
  final Dio _http;
  final String _baseUrl;
  
  CustomBackendDataSource({
    required String baseUrl,
    required String apiKey,
  })  : _baseUrl = baseUrl,
        _http = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));
  
  /// ==================== Screen Operations ====================
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    try {
      final response = await _http.get('/screens/$screenId');
      final backendScreen = BackendScreen.fromJson(response.data);
      return backendScreen.toQuicUIScreen();
    } on DioException catch (e) {
      throw DataSourceException(
        'Failed to fetch screen: ${e.message}',
        originalException: e,
      );
    }
  }
  
  @override
  Future<List<Screen>> fetchScreens({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _http.get(
        '/screens',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      
      final screens = (response.data['screens'] as List)
          .map((item) => BackendScreen.fromJson(item).toQuicUIScreen())
          .toList();
      
      return screens;
    } on DioException catch (e) {
      throw DataSourceException(
        'Failed to fetch screens: ${e.message}',
        originalException: e,
      );
    }
  }
  
  @override
  Future<void> saveScreen(String screenId, Screen screen) async {
    try {
      final backendScreen = BackendScreen.fromQuicUI(screen);
      
      final response = await _http.put(
        '/screens/$screenId',
        data: backendScreen.toJson(),
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DataSourceException(
          'Failed to save screen: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DataSourceException(
        'Failed to save screen: ${e.message}',
        originalException: e,
      );
    }
  }
  
  @override
  Future<void> deleteScreen(String screenId) async {
    try {
      await _http.delete('/screens/$screenId');
    } on DioException catch (e) {
      throw DataSourceException(
        'Failed to delete screen: ${e.message}',
        originalException: e,
      );
    }
  }
  
  /// ==================== Search & Query ====================
  
  @override
  Future<List<Screen>> searchScreens(String query) async {
    try {
      final response = await _http.get(
        '/screens/search',
        queryParameters: {'q': query},
      );
      
      final screens = (response.data['results'] as List)
          .map((item) => BackendScreen.fromJson(item).toQuicUIScreen())
          .toList();
      
      return screens;
    } on DioException catch (e) {
      throw DataSourceException(
        'Search failed: ${e.message}',
        originalException: e,
      );
    }
  }
  
  @override
  Future<int> getScreenCount() async {
    try {
      final response = await _http.get('/screens/count');
      return response.data['count'] as int;
    } on DioException catch (e) {
      throw DataSourceException(
        'Failed to get screen count: ${e.message}',
        originalException: e,
      );
    }
  }
  
  /// ==================== Sync Operations ====================
  
  @override
  Future<SyncResult> syncData(List<SyncItem> pendingItems) async {
    final List<SyncError> errors = [];
    int synced = 0;
    
    for (final item in pendingItems) {
      try {
        switch (item.operation) {
          case SyncOperation.create:
            await saveScreen(item.screenId, item.screen!);
            synced++;
            break;
            
          case SyncOperation.update:
            await saveScreen(item.screenId, item.screen!);
            synced++;
            break;
            
          case SyncOperation.delete:
            await deleteScreen(item.screenId);
            synced++;
            break;
        }
      } catch (e) {
        errors.add(
          SyncError(
            itemId: item.id,
            operation: item.operation,
            error: e.toString(),
          ),
        );
      }
    }
    
    return SyncResult(
      synced: synced,
      failed: errors.length,
      errors: errors,
    );
  }
  
  @override
  Future<List<SyncItem>> getPendingItems() async {
    // This would typically read from local database
    // For now, return empty list (user manages this via repositories)
    return [];
  }
  
  @override
  Future<ConflictResolution> resolveConflict(ConflictCase conflict) async {
    // Simple conflict resolution: backend version wins
    // You can implement custom logic here
    return ConflictResolution.useRemote;
  }
  
  /// ==================== Connection ====================
  
  @override
  Future<void> connect() async {
    try {
      // Test connection with a health check
      await _http.get('/health');
    } catch (e) {
      throw DataSourceException('Failed to connect: $e');
    }
  }
  
  @override
  Future<void> disconnect() async {
    // Cleanup if needed
    _http.close();
  }
  
  @override
  Future<bool> isConnected() async {
    try {
      await _http.get('/health');
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// ==================== Realtime (Optional) ====================
  
  @override
  Stream<RealtimeEvent<Screen>> subscribeToScreen(String screenId) {
    // If your backend supports WebSockets:
    return _subscribeViaWebSocket(screenId);
    
    // Or polling fallback:
    // return _subscribeViaPolling(screenId);
  }
  
  /// Example WebSocket implementation
  Stream<RealtimeEvent<Screen>> _subscribeViaWebSocket(String screenId) {
    // Implementation depends on your backend
    throw UnimplementedError('WebSocket not configured');
  }
  
  /// Example polling fallback
  Stream<RealtimeEvent<Screen>> _subscribeViaPolling(String screenId) {
    return Stream.periodic(
      const Duration(seconds: 5),
      (_) => screenId,
    ).asyncMap((_) async {
      try {
        final screen = await fetchScreen(screenId);
        return RealtimeEvent(
          type: EventType.update,
          data: screen,
          timestamp: DateTime.now(),
        );
      } catch (e) {
        throw DataSourceException('Poll failed: $e');
      }
    });
  }
  
  @override
  Future<void> unsubscribe(String screenId) async {
    // Cleanup subscriptions
  }
}
```

### Step 3: Create Initialization Service

```dart
/// lib/services/backend_init.dart
import 'package:quicui/quicui.dart';
import 'custom_backend_data_source.dart';

/// Helper service for initializing QuicUI with custom backend
class BackendInit {
  /// Initialize QuicUI with your custom backend
  static Future<void> init({
    required String backendUrl,
    required String apiKey,
  }) async {
    // Create custom data source
    final dataSource = CustomBackendDataSource(
      baseUrl: backendUrl,
      apiKey: apiKey,
    );
    
    // Test connection before initialization
    try {
      await dataSource.connect();
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
    
    // Register with QuicUI
    DataSourceProvider.register(dataSource);
    
    // Initialize QuicUI
    await QuicUI.initialize();
  }
}
```

### Step 4: Use in Main App

```dart
/// lib/main.dart
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';
import 'services/backend_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with custom backend
  await BackendInit.init(
    backendUrl: 'https://api.mybackend.com',
    apiKey: 'your-api-key',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI + Custom Backend',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScreenListPage(),
    );
  }
}
```

---

## 🔄 Handling Sync & Offline

### Local-First with Sync

```dart
/// lib/repositories/custom_screen_repository.dart
import 'package:quicui/quicui.dart';

class CustomScreenRepository extends ScreenRepository {
  final StorageService _storage;
  
  CustomScreenRepository({
    required DataSource dataSource,
    required StorageService storage,
  })  : _storage = storage,
        super(dataSource: dataSource);
  
  @override
  Future<Screen?> getScreen(String id) async {
    try {
      // Try remote first
      return await dataSource.fetchScreen(id);
    } catch (e) {
      // Fallback to local cache
      final cached = await _storage.get('screen_$id');
      if (cached != null) {
        return Screen.fromJson(cached);
      }
      rethrow;
    }
  }
  
  @override
  Future<void> saveScreen(String id, Screen screen) async {
    // Save locally first (offline support)
    await _storage.put('screen_$id', screen.toJson());
    
    try {
      // Then sync with backend
      await dataSource.saveScreen(id, screen);
      // Mark as synced
      await _storage.markSynced('screen_$id');
    } catch (e) {
      // Keep local, mark for later sync
      await _storage.markPending('screen_$id');
      rethrow;
    }
  }
}
```

### Sync on Reconnect

```dart
/// lib/services/sync_manager.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:quicui/quicui.dart';

class SyncManager {
  final DataSource _dataSource;
  final StorageService _storage;
  late StreamSubscription _connectivitySubscription;
  
  SyncManager({
    required DataSource dataSource,
    required StorageService storage,
  })  : _dataSource = dataSource,
        _storage = storage;
  
  /// Start monitoring connectivity
  void startMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (result) async {
        if (result != ConnectivityResult.none) {
          // Device is back online - sync pending items
          await _syncPendingItems();
        }
      },
    );
  }
  
  /// Sync all pending items
  Future<void> _syncPendingItems() async {
    try {
      // Get pending items
      final pendingItems = await _storage.getPending();
      if (pendingItems.isEmpty) return;
      
      // Convert to sync items
      final syncItems = pendingItems
          .map((item) => SyncItem.fromJson(item))
          .toList();
      
      // Sync with backend
      final result = await _dataSource.syncData(syncItems);
      
      // Handle errors
      if (result.errors.isNotEmpty) {
        print('Sync errors: ${result.errors.length}');
        for (final error in result.errors) {
          print('  - ${error.itemId}: ${error.error}');
        }
      }
      
      // Mark synced items
      for (final item in syncItems) {
        if (!result.errors.any((e) => e.itemId == item.id)) {
          await _storage.markSynced(item.id);
        }
      }
    } catch (e) {
      print('Sync failed: $e');
    }
  }
  
  void dispose() {
    _connectivitySubscription.cancel();
  }
}
```

---

## 🧪 Testing Your Implementation

### Unit Tests

```dart
/// test/custom_backend_data_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('CustomBackendDataSource', () {
    late CustomBackendDataSource dataSource;
    late MockDio mockDio;
    
    setUp(() {
      mockDio = MockDio();
      dataSource = CustomBackendDataSource(
        baseUrl: 'https://api.test.com',
        apiKey: 'test-key',
      );
      // Replace _http with mock
      dataSource.http = mockDio;
    });
    
    test('fetchScreen returns Screen', () async {
      // Arrange
      const screenId = 'screen-1';
      when(mockDio.get('/screens/$screenId')).thenAnswer(
        (_) async => Response<dynamic>(
          data: {
            'id': screenId,
            'title': 'Test Screen',
            'config': {},
            'updatedAt': '2025-01-01T00:00:00Z',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      
      // Act
      final result = await dataSource.fetchScreen(screenId);
      
      // Assert
      expect(result.id, screenId);
      expect(result.name, 'Test Screen');
      verify(mockDio.get('/screens/$screenId')).called(1);
    });
    
    test('saveScreen throws on error', () async {
      // Arrange
      when(mockDio.put('/screens/screen-1', data: any))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Network error',
      ));
      
      // Act & Assert
      expect(
        () => dataSource.saveScreen('screen-1', Screen.empty()),
        throwsA(isA<DataSourceException>()),
      );
    });
  });
}
```

### Integration Tests

```dart
/// test/integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quicui/quicui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Custom Backend Integration', () {
    late CustomScreenRepository repository;
    
    setUpAll(() async {
      // Initialize app
      await BackendInit.init(
        backendUrl: 'https://api.test.com',
        apiKey: 'test-key',
      );
      
      repository = CustomScreenRepository(
        dataSource: DataSourceProvider.instance,
        storage: StorageService(),
      );
    });
    
    test('Full CRUD cycle', () async {
      // Create
      final screen = Screen(
        id: 'test-1',
        name: 'Test Screen',
        config: {},
      );
      
      await repository.saveScreen('test-1', screen);
      
      // Read
      final fetched = await repository.getScreen('test-1');
      expect(fetched?.id, 'test-1');
      
      // Update
      final updated = screen.copyWith(name: 'Updated');
      await repository.saveScreen('test-1', updated);
      
      // Delete
      await repository.deleteScreen('test-1');
    });
  });
}
```

---

## 📋 Configuration Examples

### Environment-Specific Setup

```dart
/// lib/config/backend_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  static String get baseUrl {
    final env = const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    
    switch (env) {
      case 'prod':
        return 'https://api.production.com';
      case 'staging':
        return 'https://api.staging.com';
      default:
        return 'https://api.dev.local';
    }
  }
  
  static String get apiKey {
    return dotenv.env['API_KEY'] ?? 'dev-key';
  }
}
```

### Using Configuration

```dart
void main() async {
  await dotenv.load();
  
  await BackendInit.init(
    backendUrl: BackendConfig.baseUrl,
    apiKey: BackendConfig.apiKey,
  );
  
  runApp(const MyApp());
}
```

---

## 🚀 Advanced Patterns

### Custom Error Handling

```dart
/// lib/services/error_handler.dart
class BackendErrorHandler {
  static DataSourceException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return DataSourceException(
          'Connection timeout',
          isRetryable: true,
        );
      
      case DioExceptionType.sendTimeout:
        return DataSourceException(
          'Request timeout',
          isRetryable: true,
        );
      
      case DioExceptionType.receiveTimeout:
        return DataSourceException(
          'Response timeout',
          isRetryable: true,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 401) {
          return DataSourceException(
            'Unauthorized - check your credentials',
            isRetryable: false,
          );
        }
        if (statusCode >= 500) {
          return DataSourceException(
            'Server error ($statusCode)',
            isRetryable: true,
          );
        }
        return DataSourceException(
          'HTTP $statusCode error',
          isRetryable: false,
        );
      
      default:
        return DataSourceException(
          error.message ?? 'Unknown error',
          isRetryable: true,
        );
    }
  }
}
```

### Retry Logic

```dart
Future<T> _withRetry<T>(
  Future<T> Function() request, {
  int maxRetries = 3,
  Duration delayFactor = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      return await request();
    } catch (e) {
      attempt++;
      
      if (attempt >= maxRetries) rethrow;
      
      // Exponential backoff
      final delay = delayFactor * (2 * attempt);
      await Future.delayed(delay);
    }
  }
  
  throw Exception('Max retries exceeded');
}
```

---

## ✅ Checklist Before Deployment

- [ ] All DataSource methods implemented
- [ ] Error handling for all network calls
- [ ] Offline support with local caching
- [ ] Sync on reconnect working
- [ ] 80%+ test coverage
- [ ] Health check endpoint tested
- [ ] API key/credentials secured (use env vars)
- [ ] Timeout values configured
- [ ] Retry logic for transient errors
- [ ] Conflict resolution strategy defined
- [ ] Rate limiting handled
- [ ] Logging implemented (no sensitive data)
- [ ] Performance tested with realistic data
- [ ] Edge cases handled (empty results, duplicates, etc.)

---

**Status:** 📖 Reference & Template  
**Ready to:** Customize for your backend  
**Next Steps:** Implement and test in your project

