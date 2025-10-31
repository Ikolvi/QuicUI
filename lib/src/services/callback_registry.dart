import '../utils/logger_util.dart';

/// Registry for managing named callbacks
/// Allows registering, retrieving, and executing callbacks by name
class CallbackRegistry {
  static final Map<String, Function> _registeredCallbacks = {};

  /// Register a callback with a name
  static void registerCallback(String name, Function callback) {
    LoggerUtil.info('CallbackRegistry: Registering callback: $name');
    _registeredCallbacks[name] = callback;
  }

  /// Get a registered callback by name
  static Function? getCallback(String name) {
    if (!_registeredCallbacks.containsKey(name)) {
      LoggerUtil.warning('CallbackRegistry: Callback not found: $name');
      return null;
    }
    return _registeredCallbacks[name];
  }

  /// Execute a registered callback with parameters
  static Future<dynamic> executeCallback(
    String name, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final callback = getCallback(name);
      if (callback == null) {
        throw Exception('Callback not registered: $name');
      }

      LoggerUtil.info('CallbackRegistry: Executing callback: $name');
      LoggerUtil.debug('CallbackRegistry: Callback params: $params');

      // Check if callback is async
      final result = callback(params ?? {});
      if (result is Future) {
        return await result;
      }
      return result;
    } catch (e) {
      LoggerUtil.error(
        'CallbackRegistry: Error executing callback: $name',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Unregister a callback
  static void unregisterCallback(String name) {
    LoggerUtil.info('CallbackRegistry: Unregistering callback: $name');
    _registeredCallbacks.remove(name);
  }

  /// Get all registered callback names
  static List<String> getRegisteredCallbackNames() {
    return _registeredCallbacks.keys.toList();
  }

  /// Check if a callback is registered
  static bool isCallbackRegistered(String name) {
    return _registeredCallbacks.containsKey(name);
  }

  /// Clear all registered callbacks
  static void clearAllCallbacks() {
    LoggerUtil.info('CallbackRegistry: Clearing all callbacks');
    _registeredCallbacks.clear();
  }

  /// Get callback statistics
  static Map<String, dynamic> getStats() {
    return {
      'totalCallbacks': _registeredCallbacks.length,
      'registeredNames': getRegisteredCallbackNames(),
    };
  }
}
