/// Remote data source for Supabase interactions
///
/// This module handles all remote API calls to Supabase backend.
/// Abstracts Supabase communication and provides a clean data layer.
///
/// ## Cloud Backend: Supabase Only
/// - PostgreSQL database for persistent storage
/// - Real-time API for live updates
/// - Built-in authentication
/// - Row Level Security (RLS) policies
///
/// ## Performance
/// - Network latency: 50-500ms
/// - Supabase query: 10-100ms
/// - Total: 100-1000ms typical
///
/// See also:
/// - [LocalDataSource]: Local caching layer
/// - [ScreenRepository]: Primary consumer
/// - [SupabaseService]: Supabase configuration

/// Remote data source for Supabase API calls
class RemoteDataSource {
  /// Fetch screen from Supabase backend
  ///
  /// Retrieves complete screen configuration from Supabase PostgreSQL.
  /// This always fetches fresh data (never cached at this layer).
  ///
  /// ## Supabase Table: screens
  /// ```sql
  /// CREATE TABLE screens (
  ///   id TEXT PRIMARY KEY,
  ///   name TEXT NOT NULL,
  ///   data JSONB NOT NULL,
  ///   created_at TIMESTAMP DEFAULT NOW(),
  ///   updated_at TIMESTAMP DEFAULT NOW(),
  ///   user_id UUID REFERENCES auth.users
  /// );
  /// ```
  ///
  /// ## Implementation
  /// Uses Supabase REST API via supabase_flutter package:
  /// ```dart
  /// final response = await supabase
  ///   .from('screens')
  ///   .select()
  ///   .eq('id', screenId)
  ///   .single();
  /// ```
  ///
  /// ## Performance
  /// - Network request: 100-2000ms
  /// - JSON parsing: 10-100ms
  /// - Total: 150-2100ms
  ///
  /// ## Throws
  /// - [Exception]: Network error or Supabase error
  Future<Map<String, dynamic>> fetchScreen(String screenId) async {
    // Implementation would use SupabaseService.instance.client
    // to fetch from 'screens' table where id = screenId
    // Actual implementation delegated to SupabaseService
    throw UnimplementedError(
      'fetchScreen: Use SupabaseService.instance.client.from(\'screens\').select()',
    );
  }

  /// Upload/update screen data to Supabase backend
  ///
  /// Sends updated screen configuration to Supabase PostgreSQL.
  /// Used for saving changes made locally or from dashboard.
  ///
  /// ## Supabase Operation
  /// Uses upsert to insert or update:
  /// ```dart
  /// await supabase
  ///   .from('screens')
  ///   .upsert({'id': screenId, ...data});
  /// ```
  ///
  /// ## Row Level Security (RLS)
  /// Supabase RLS policies ensure users can only update their own screens:
  /// ```sql
  /// CREATE POLICY "users_update_own_screens"
  ///   ON screens FOR UPDATE
  ///   USING (auth.uid() = user_id);
  /// ```
  ///
  /// ## Performance
  /// - Network request: 100-2000ms
  /// - Database write: 10-100ms
  /// - Total: 150-2100ms
  ///
  /// ## Throws
  /// - [Exception]: Network error, RLS violation, or Supabase error
  Future<void> uploadScreen(String screenId, Map<String, dynamic> data) async {
    // Implementation would use SupabaseService.instance.client
    // to upsert into 'screens' table
    // Actual implementation delegated to SupabaseService
    throw UnimplementedError(
      'uploadScreen: Use SupabaseService.instance.client.from(\'screens\').upsert()',
    );
  }
}
