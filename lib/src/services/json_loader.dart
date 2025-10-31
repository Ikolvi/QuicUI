import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/logger_util.dart';

/// Service for loading, caching, and managing JSON files
/// Supports loading from assets, URLs, and local files with caching
class JSONLoader {
  static final Map<String, dynamic> _cache = {};
  static final Set<String> _loadingFlows = {};

  /// Load JSON from assets
  /// Path should be relative to assets folder (e.g., 'flows/auth.json')
  static Future<Map<String, dynamic>> loadJsonFromAssets(String path) async {
    try {
      // Check cache first
      if (_cache.containsKey(path)) {
        LoggerUtil.info('JSONLoader: Using cached JSON for $path');
        return Map<String, dynamic>.from(_cache[path]);
      }

      // Prevent concurrent loads of the same file
      if (_loadingFlows.contains(path)) {
        LoggerUtil.info('JSONLoader: Waiting for concurrent load of $path');
        while (_loadingFlows.contains(path)) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        return Map<String, dynamic>.from(_cache[path]);
      }

      _loadingFlows.add(path);
      LoggerUtil.info('JSONLoader: Loading JSON from assets: $path');

      final jsonString = await rootBundle.loadString('assets/$path');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate structure
      validateJsonStructure(json);

      // Cache it
      _cache[path] = json;
      _loadingFlows.remove(path);

      LoggerUtil.info('JSONLoader: Successfully loaded and cached $path');
      return Map<String, dynamic>.from(json);
    } catch (e) {
      _loadingFlows.remove(path);
      LoggerUtil.error(
        'JSONLoader: Failed to load JSON from assets: $path',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Load JSON from file path
  static Future<Map<String, dynamic>> loadJsonFromFile(String filePath) async {
    try {
      if (_cache.containsKey(filePath)) {
        LoggerUtil.info('JSONLoader: Using cached JSON for $filePath');
        return Map<String, dynamic>.from(_cache[filePath]);
      }

      LoggerUtil.info('JSONLoader: Loading JSON from file: $filePath');
      // This is a placeholder - actual implementation would use File I/O
      throw UnimplementedError('File loading not yet implemented');
    } catch (e) {
      LoggerUtil.error(
        'JSONLoader: Failed to load JSON from file: $filePath',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Load JSON from URL
  static Future<Map<String, dynamic>> loadJsonFromUrl(String url) async {
    try {
      if (_cache.containsKey(url)) {
        LoggerUtil.info('JSONLoader: Using cached JSON for $url');
        return Map<String, dynamic>.from(_cache[url]);
      }

      LoggerUtil.info('JSONLoader: Loading JSON from URL: $url');
      // This is a placeholder - actual implementation would use http package
      throw UnimplementedError('URL loading not yet implemented');
    } catch (e) {
      LoggerUtil.error(
        'JSONLoader: Failed to load JSON from URL: $url',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Cache a JSON object
  static void cacheJson(String key, Map<String, dynamic> json) {
    LoggerUtil.info('JSONLoader: Caching JSON with key: $key');
    _cache[key] = json;
  }

  /// Get cached JSON
  static Map<String, dynamic>? getCachedJson(String key) {
    return _cache[key] != null ? Map<String, dynamic>.from(_cache[key]) : null;
  }

  /// Clear cache for specific flow or all flows
  static void clearCache({String? key}) {
    if (key != null) {
      LoggerUtil.info('JSONLoader: Clearing cache for key: $key');
      _cache.remove(key);
    } else {
      LoggerUtil.info('JSONLoader: Clearing entire cache');
      _cache.clear();
    }
  }

  /// Preload multiple JSON files
  static Future<void> preloadJsons(List<String> paths) async {
    LoggerUtil.info('JSONLoader: Preloading ${paths.length} JSON files');
    try {
      final futures = paths.map((path) => loadJsonFromAssets(path));
      await Future.wait(futures);
      LoggerUtil.info('JSONLoader: Preload completed successfully');
    } catch (e) {
      LoggerUtil.error(
        'JSONLoader: Error during preload',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Validate JSON structure
  static Map<String, dynamic> validateJsonStructure(Map<String, dynamic> json) {
    // Basic validation - can be extended
    if (!json.containsKey('type') && !json.containsKey('screens')) {
      throw FormatException('JSON must contain "type" or "screens" key');
    }
    return json;
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedFlows': _cache.length,
      'cachedKeys': _cache.keys.toList(),
      'isLoading': _loadingFlows.toList(),
    };
  }
}
