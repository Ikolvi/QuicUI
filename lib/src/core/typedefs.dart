/// Type definitions and type aliases for QuicUI


import 'dart:async';

/// JSON data type - typically Map<String, dynamic>
typedef Json = Map<String, dynamic>;

/// JSON list type
typedef JsonList = List<dynamic>;

/// Async callback that returns nothing
typedef AsyncCallback = Future<void> Function();

/// Async callback with a value parameter
typedef AsyncValueCallback<T> = Future<void> Function(T value);

/// Callback for widget events
typedef WidgetEventCallback = void Function(String eventName, dynamic data);

/// Function type for network requests
typedef NetworkRequest<T> = Future<T> Function();

/// Function type for local storage operations
typedef StorageOperation<T> = Future<T> Function();

/// Function type for validation
typedef ValidatorFunction = String? Function(String? value);

/// Function type for UI builder with context and data
typedef UIBuilder = dynamic Function(dynamic data);

/// Stream of JSON data
typedef JsonStream = Stream<Json>;

/// Callback for sync state changes
typedef SyncStateCallback = void Function(SyncStatus status);

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  offline,
  conflict,
}
