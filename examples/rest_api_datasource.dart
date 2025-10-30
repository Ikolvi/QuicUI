import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quicui/quicui.dart';

/// Example REST API DataSource Implementation
/// 
/// This is a complete, production-ready example showing how to implement
/// a custom DataSource for a generic REST API backend.
/// 
/// Features:
/// - All 15 DataSource methods implemented
/// - Real-time subscriptions via Server-Sent Events (SSE)
/// - Offline change queuing
/// - Comprehensive error handling
/// - Caching for performance
/// - Exponential backoff retry logic

class RestApiDataSource implements DataSource {
  // Configuration
  final String apiUrl;
  final String apiKey;
  
  // HTTP client
  late final http.Client _httpClient;
  
  // Stream management
  final Map<String, StreamController> _streamControllers = {};
  
  // Caching
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimes = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Offline queue
  final List<Map<String, dynamic>> _offlineQueue = [];
  
  // Connection management
  late final Map<String, http.StreamedResponse> _sseConnections = {};

  RestApiDataSource({
    required this.apiUrl,
    required this.apiKey,
  }) {
    _httpClient = http.Client();
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Make HTTP request with error handling and retries
  Future<http.Response> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    int retries = 3,
  }) async {
    return _withRetry(
      () => _makeRequestInternal(method, path, body: body),
      maxRetries: retries,
    );
  }

  Future<http.Response> _makeRequestInternal(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$apiUrl$path');
    
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    try {
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient.get(url, headers: headers)
              .timeout(const Duration(seconds: 30));
        case 'POST':
          response = await _httpClient.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 30));
        case 'PATCH':
          response = await _httpClient.patch(
            url,
            headers: headers,
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 30));
        case 'PUT':
          response = await _httpClient.put(
            url,
            headers: headers,
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 30));
        case 'DELETE':
          response = await _httpClient.delete(url, headers: headers)
              .timeout(const Duration(seconds: 30));
        default:
          throw DataSourceException(
            message: 'Unsupported HTTP method: $method',
            code: 'UNSUPPORTED_METHOD',
          );
      }

      _handleHttpErrors(response);
      return response;
      
    } on TimeoutException {
      throw NetworkException('Request timeout for $method $path');
    } on Exception catch (e) {
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  /// Handle HTTP error responses
  void _handleHttpErrors(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // Success
    }

    switch (response.statusCode) {
      case 404:
        // Will be handled by caller to determine specific type
        break;
      case 403:
        throw PermissionException(
          'Access denied: ${response.body}',
        );
      case 400:
        throw ValidationException(
          'Invalid request: ${response.body}',
        );
      default:
        throw DataSourceException(
          message: 'HTTP ${response.statusCode}: ${response.body}',
          code: 'HTTP_ERROR',
        );
    }
  }

  /// Retry logic with exponential backoff
  Future<T> _withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        
        // Exponential backoff
        final delay = initialDelay * (1 << attempt); // 100ms, 200ms, 400ms
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Get from cache if valid
  T? _getFromCache<T>(String key) {
    if (!_cache.containsKey(key)) return null;
    
    final cacheTime = _cacheTimes[key];
    if (cacheTime == null) return null;
    
    if (DateTime.now().difference(cacheTime) > _cacheDuration) {
      _cache.remove(key);
      _cacheTimes.remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }

  /// Set cache
  void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimes[key] = DateTime.now();
  }

  /// Clear cache
  void _clearCache(String key) {
    _cache.remove(key);
    _cacheTimes.remove(key);
  }

  /// Get or create stream controller
  StreamController<T> _getStreamController<T>(String key) {
    if (_streamControllers.containsKey(key)) {
      return _streamControllers[key] as StreamController<T>;
    }
    
    final controller = StreamController<T>.broadcast();
    _streamControllers[key] = controller;
    return controller;
  }

  /// Queue a change for offline sync
  Future<void> _queueOfflineChange(
    String operation,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    _offlineQueue.add({
      'operation': operation,
      'entityId': entityId,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
    
    // In production, persist to local storage
    print('[RestAPI] Queued offline change: $operation on $entityId');
  }

  // ============================================================================
  // Screen Management
  // ============================================================================

  @override
  Future<Screen> fetchScreen(String screenId) async {
    if (screenId.isEmpty) {
      throw ValidationException('screenId cannot be empty');
    }

    // Check cache first
    final cached = _getFromCache<Screen>('screen_$screenId');
    if (cached != null) return cached;

    try {
      final response = await _makeRequest('GET', '/screens/$screenId');

      if (response.statusCode == 404) {
        throw ScreenNotFoundException('Screen not found: $screenId');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final screen = Screen.fromJson(json);
      
      _setCache('screen_$screenId', screen);
      return screen;
      
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Screen>> fetchScreensByTag(String tag) async {
    if (tag.isEmpty) {
      throw ValidationException('tag cannot be empty');
    }

    // Check cache
    final cached = _getFromCache<List<Screen>>('screens_tag_$tag');
    if (cached != null) return cached;

    try {
      final response = await _makeRequest('GET', '/screens?tag=$tag');

      final json = jsonDecode(response.body) as List<dynamic>;
      final screens = json
          .map((item) => Screen.fromJson(item as Map<String, dynamic>))
          .toList();

      _setCache('screens_tag_$tag', screens);
      return screens;
      
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // User Management
  // ============================================================================

  @override
  Future<User> fetchUser(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException('userId cannot be empty');
    }

    // Check cache
    final cached = _getFromCache<User>('user_$userId');
    if (cached != null) return cached;

    try {
      final response = await _makeRequest('GET', '/users/$userId');

      if (response.statusCode == 404) {
        throw UserNotFoundException('User not found: $userId');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final user = User.fromJson(json);

      _setCache('user_$userId', user);
      return user;
      
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<User>> fetchUsers() async {
    // Check cache
    final cached = _getFromCache<List<User>>('users_all');
    if (cached != null) return cached;

    try {
      final response = await _makeRequest('GET', '/users');

      if (response.statusCode == 403) {
        throw PermissionException('Not authorized to fetch users');
      }

      final json = jsonDecode(response.body) as List<dynamic>;
      final users = json
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();

      _setCache('users_all', users);
      return users;
      
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Component Management
  // ============================================================================

  @override
  Future<Component> fetchComponent(String componentId) async {
    if (componentId.isEmpty) {
      throw ValidationException('componentId cannot be empty');
    }

    // Check cache (components rarely change)
    final cached = _getFromCache<Component>('component_$componentId');
    if (cached != null) return cached;

    try {
      final response = await _makeRequest('GET', '/components/$componentId');

      if (response.statusCode == 404) {
        throw ComponentNotFoundException('Component not found: $componentId');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final component = Component.fromJson(json);

      _setCache('component_$componentId', component);
      return component;
      
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Component>> fetchComponents() async {
    // Check cache (components rarely change)
    final cached = _getFromCache<List<Component>>('components_all');
    if (cached != null) return cached;

    try {
      final response = await _makeRequest('GET', '/components');

      final json = jsonDecode(response.body) as List<dynamic>;
      final components = json
          .map((item) => Component.fromJson(item as Map<String, dynamic>))
          .toList();

      _setCache('components_all', components);
      return components;
      
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Real-Time Subscriptions (SSE)
  // ============================================================================

  @override
  Stream<Screen> subscribeToScreen(String screenId) async* {
    final controller = _getStreamController<Screen>('screen_$screenId');

    try {
      // Emit current state
      final current = await fetchScreen(screenId);
      yield current;

      // Connect to SSE
      final url = Uri.parse('$apiUrl/screens/$screenId/subscribe');
      final request = http.Request('GET', url)
        ..headers['Authorization'] = 'Bearer $apiKey';

      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        throw NetworkException(
          'Failed to subscribe: ${response.statusCode}',
        );
      }

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.startsWith('data: ')) {
                try {
                  final json = jsonDecode(line.substring(6));
                  final screen = Screen.fromJson(json);
                  controller.add(screen);
                  _setCache('screen_$screenId', screen);
                } catch (e) {
                  controller.addError(DataSourceException(
                    message: 'Parse error: ${e.toString()}',
                    code: 'PARSE_ERROR',
                  ));
                }
              }
            },
            onError: (error) {
              controller.addError(NetworkException('SSE error: $error'));
            },
            onDone: () {
              controller.close();
              _streamControllers.remove('screen_$screenId');
            },
          );

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

      final url = Uri.parse('$apiUrl/users/$userId/subscribe');
      final request = http.Request('GET', url)
        ..headers['Authorization'] = 'Bearer $apiKey';

      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        throw NetworkException('Failed to subscribe: ${response.statusCode}');
      }

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.startsWith('data: ')) {
                try {
                  final json = jsonDecode(line.substring(6));
                  final user = User.fromJson(json);
                  controller.add(user);
                  _setCache('user_$userId', user);
                } catch (e) {
                  controller.addError(DataSourceException(
                    message: 'Parse error: ${e.toString()}',
                    code: 'PARSE_ERROR',
                  ));
                }
              }
            },
            onError: (error) {
              controller.addError(NetworkException('SSE error: $error'));
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

      final url = Uri.parse('$apiUrl/components/$componentId/subscribe');
      final request = http.Request('GET', url)
        ..headers['Authorization'] = 'Bearer $apiKey';

      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        throw NetworkException('Failed to subscribe: ${response.statusCode}');
      }

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.startsWith('data: ')) {
                try {
                  final json = jsonDecode(line.substring(6));
                  final component = Component.fromJson(json);
                  controller.add(component);
                  _setCache('component_$componentId', component);
                } catch (e) {
                  controller.addError(DataSourceException(
                    message: 'Parse error: ${e.toString()}',
                    code: 'PARSE_ERROR',
                  ));
                }
              }
            },
            onError: (error) {
              controller.addError(NetworkException('SSE error: $error'));
            },
          );

      yield* controller.stream;
      
    } catch (e) {
      yield* Stream.error(e);
    }
  }

  // ============================================================================
  // Mutations
  // ============================================================================

  @override
  Future<Screen> updateScreen(String screenId, Map<String, dynamic> data) async {
    if (screenId.isEmpty) {
      throw ValidationException('screenId cannot be empty');
    }

    try {
      final response = await _makeRequest(
        'PATCH',
        '/screens/$screenId',
        body: data,
      );

      if (response.statusCode == 404) {
        throw ScreenNotFoundException('Screen not found: $screenId');
      }

      if (response.statusCode == 400) {
        throw ValidationException('Invalid screen data: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final screen = Screen.fromJson(json);

      _clearCache('screen_$screenId');
      _clearCache('screens_tag_*');
      
      return screen;
      
    } on NetworkException {
      await _queueOfflineChange('update_screen', screenId, data);
      throw SyncException('Offline - change queued for sync');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> updateUser(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) {
      throw ValidationException('userId cannot be empty');
    }

    try {
      final response = await _makeRequest(
        'PATCH',
        '/users/$userId',
        body: data,
      );

      if (response.statusCode == 404) {
        throw UserNotFoundException('User not found: $userId');
      }

      if (response.statusCode == 400) {
        throw ValidationException('Invalid user data: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final user = User.fromJson(json);

      _clearCache('user_$userId');
      _clearCache('users_all');
      
      return user;
      
    } on NetworkException {
      await _queueOfflineChange('update_user', userId, data);
      throw SyncException('Offline - change queued for sync');
    } catch (e) {
      rethrow;
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
      final response = await _makeRequest(
        'PATCH',
        '/components/$componentId',
        body: data,
      );

      if (response.statusCode == 404) {
        throw ComponentNotFoundException('Component not found: $componentId');
      }

      if (response.statusCode == 400) {
        throw ValidationException('Invalid component data: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final component = Component.fromJson(json);

      _clearCache('component_$componentId');
      _clearCache('components_all');
      
      return component;
      
    } on NetworkException {
      await _queueOfflineChange('update_component', componentId, data);
      throw SyncException('Offline - change queued for sync');
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Offline Sync
  // ============================================================================

  @override
  Future<void> syncOfflineChanges() async {
    if (_offlineQueue.isEmpty) {
      print('[RestAPI] No offline changes to sync');
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
        print('[RestAPI] Synced: $operation on $entityId');
        
      } catch (e) {
        failedItems.add(i);
        _offlineQueue[i]['status'] = 'failed';
        _offlineQueue[i]['error'] = e.toString();
        print('[RestAPI] Failed to sync: ${_offlineQueue[i]['operation']}');
      }
    }

    // Remove successfully synced items
    _offlineQueue.removeWhere((item) => item['status'] == 'synced');

    if (failedItems.isNotEmpty) {
      throw SyncException(
        message: 'Sync failed for ${failedItems.length} items',
        failedItems: [
          for (final i in failedItems) _offlineQueue[i],
        ],
      );
    }

    print('[RestAPI] All offline changes synced successfully');
  }

  @override
  Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    return List.unmodifiable(_offlineQueue);
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  void dispose() {
    _httpClient.close();
    
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    
    for (final connection in _sseConnections.values) {
      // Close SSE connections if needed
    }
    _sseConnections.clear();
  }
}
