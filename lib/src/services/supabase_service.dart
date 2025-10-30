/// Supabase backend service integration
/// 
/// Provides synchronization and data management with Supabase backend.
/// Handles CRUD operations for screens and offline sync coordination.

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for Supabase integration
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  late SupabaseClient _client;
  bool _initialized = false;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  /// Initialize Supabase
  /// 
  /// Must be called once at app startup with valid credentials
  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      print('Supabase initialized successfully');
    } catch (e) {
      print('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Get the Supabase client
  SupabaseClient getClient() {
    return _client;
  }

  /// Check if Supabase is initialized
  bool isInitialized() {
    return _initialized;
  }

  /// Fetch screens from Supabase
  Future<List<Map<String, dynamic>>> fetchScreens() async {
    try {
      final response = await _client
          .from('screens')
          .select() as List<dynamic>;

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching screens: $e');
      rethrow;
    }
  }

  /// Fetch single screen by ID
  Future<Map<String, dynamic>> fetchScreen(String screenId) async {
    try {
      final response = await _client
          .from('screens')
          .select()
          .eq('id', screenId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching screen: $e');
      rethrow;
    }
  }

  /// Create screen on Supabase
  Future<Map<String, dynamic>> createScreen(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('screens')
          .insert([data])
          .select() as List<dynamic>;

      return response.first as Map<String, dynamic>;
    } catch (e) {
      print('Error creating screen: $e');
      rethrow;
    }
  }

  /// Update screen on Supabase
  Future<Map<String, dynamic>> updateScreen(
    String screenId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('screens')
          .update(data)
          .eq('id', screenId)
          .select() as List<dynamic>;

      return response.first as Map<String, dynamic>;
    } catch (e) {
      print('Error updating screen: $e');
      rethrow;
    }
  }

  /// Delete screen from Supabase
  Future<void> deleteScreen(String screenId) async {
    try {
      await _client
          .from('screens')
          .delete()
          .eq('id', screenId);
    } catch (e) {
      print('Error deleting screen: $e');
      rethrow;
    }
  }

  /// Batch sync multiple screens
  Future<void> batchSync(List<Map<String, dynamic>> screens) async {
    try {
      for (final screen in screens) {
        try {
          await fetchScreen(screen['id']);
          await updateScreen(screen['id'], screen);
        } catch (_) {
          await createScreen(screen);
        }
      }
    } catch (e) {
      print('Error batch syncing: $e');
      rethrow;
    }
  }

  /// Search screens with query
  Future<List<Map<String, dynamic>>> searchScreens(String query) async {
    try {
      final response = await _client
          .from('screens')
          .select()
          .ilike('name', '%$query%')
          as List<dynamic>;

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error searching screens: $e');
      rethrow;
    }
  }

  /// Get screen count
  Future<int> getScreenCount() async {
    try {
      final response = await _client
          .from('screens')
          .select() as List<dynamic>;

      return response.length;
    } catch (e) {
      print('Error getting screen count: $e');
      return 0;
    }
  }

  /// Subscribe to screen changes via polling
  /// 
  /// For real-time updates, call this periodically
  Future<void> pollForChanges() async {
    try {
      await fetchScreens();
    } catch (e) {
      print('Error polling for changes: $e');
    }
  }

  /// Close Supabase connection
  Future<void> close() async {
    try {
      await Supabase.instance.client.removeAllChannels();
    } catch (e) {
      print('Error closing Supabase: $e');
    }
  }
}
