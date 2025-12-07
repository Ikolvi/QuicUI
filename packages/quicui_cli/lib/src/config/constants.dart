/// QuicUI CLI Constants
/// 
/// This file contains configuration constants for the QuicUI CLI.
/// The Supabase anon key is intentionally public - it's designed for 
/// client-side use and is safe to commit to version control.
/// See: https://supabase.com/docs/guides/api/api-keys

/// Default QuicUI server URL (Supabase project endpoint)
const String kDefaultServerUrl = 'https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1';

/// Supabase project anon key (public - safe to commit)
/// This key only provides access to public endpoints and respects RLS policies.
/// It is NOT a secret and is designed to be used in client applications.
const String kSupabaseAnonKey = 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXh2YW5qaHRmYWVpbWZsZ2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNzE3MzIsImV4cCI6MjA3ODk0NzczMn0.'
    'XqPTK5bw2IukeGs-XBv0pfLHKAqkGKRmQUEvE1L14lU';

/// Supabase storage base URL
const String kSupabaseStorageUrl = 'https://pcaxvanjhtfaeimflgfk.supabase.co/storage/v1';

/// Supabase REST API base URL  
const String kSupabaseRestUrl = 'https://pcaxvanjhtfaeimflgfk.supabase.co/rest/v1';
