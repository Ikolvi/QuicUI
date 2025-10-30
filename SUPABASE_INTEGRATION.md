# Supabase Integration & App Registration System

## 🔑 Your Supabase Configuration

```
URL: https://tzxaqatozdxgwhjphbrs.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6eGFxYXRvemR4Z3doanBoYnJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NDM1MDQsImV4cCI6MjA3NzMxOTUwNH0.ipdp9RP6ZDNgZR06yPb5YTaANOzvTE-1WrS-22ss7cU
```

---

## 📋 Database Schema Setup

### Step 1: Create Tables in Supabase

Copy and paste this SQL in Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Apps table - Register each QuicUI application
CREATE TABLE public.apps (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  bundle_id text UNIQUE NOT NULL,
  package_name text UNIQUE NOT NULL,
  ai_agent_key text UNIQUE NOT NULL,
  api_key text NOT NULL DEFAULT gen_random_uuid()::text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  status text DEFAULT 'active'::text,
  owner_id uuid,
  metadata jsonb DEFAULT '{}'::jsonb,
  CONSTRAINT apps_status_check CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text]))
);

-- 2. UI Screens table - Store screen JSON definitions
CREATE TABLE public.ui_screens (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  screen_id text NOT NULL,
  screen_name text NOT NULL,
  json_definition jsonb NOT NULL,
  version integer DEFAULT 1,
  ai_generated boolean DEFAULT false,
  ai_agent_id text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  published_at timestamp with time zone,
  status text DEFAULT 'draft'::text,
  CONSTRAINT ui_screens_status_check CHECK (status = ANY (ARRAY['draft'::text, 'published'::text, 'archived'::text])),
  UNIQUE(app_id, screen_id)
);

-- 3. App State Sync table - Track state synchronization
CREATE TABLE public.app_state_sync (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  device_id text NOT NULL,
  state_key text NOT NULL,
  state_value jsonb NOT NULL,
  device_version integer DEFAULT 0,
  server_version integer DEFAULT 0,
  conflict_resolution text DEFAULT 'server_wins'::text,
  synced_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Form Submissions table - Store form data
CREATE TABLE public.form_submissions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  form_id text NOT NULL,
  submission_data jsonb NOT NULL,
  device_id text NOT NULL,
  submitted_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. AI Actions Log table - Track all AI operations
CREATE TABLE public.ai_actions_log (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  ai_agent_id text NOT NULL,
  action_type text NOT NULL,
  action_payload jsonb NOT NULL,
  result_status text,
  result_data jsonb,
  error_message text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Registered Devices table - Track app installations
CREATE TABLE public.registered_devices (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  device_id text NOT NULL,
  device_name text,
  device_os text,
  app_version text,
  last_sync_at timestamp with time zone,
  is_online boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create indexes for performance
CREATE INDEX idx_apps_bundle_id ON public.apps(bundle_id);
CREATE INDEX idx_apps_ai_agent_key ON public.apps(ai_agent_key);
CREATE INDEX idx_ui_screens_app_id ON public.ui_screens(app_id);
CREATE INDEX idx_ui_screens_status ON public.ui_screens(status);
CREATE INDEX idx_app_state_sync_app_id ON public.app_state_sync(app_id);
CREATE INDEX idx_app_state_sync_device_id ON public.app_state_sync(device_id);
CREATE INDEX idx_form_submissions_app_id ON public.form_submissions(app_id);
CREATE INDEX idx_ai_actions_log_app_id ON public.ai_actions_log(app_id);
CREATE INDEX idx_registered_devices_app_id ON public.registered_devices(app_id);

-- Enable RLS (Row Level Security)
ALTER TABLE public.apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ui_screens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_state_sync ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_actions_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registered_devices ENABLE ROW LEVEL SECURITY;
```

### Step 2: Create Row-Level Security Policies

```sql
-- Apps table policies
CREATE POLICY "Anon users can register apps" ON public.apps
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can view their own apps" ON public.apps
  FOR SELECT
  USING (owner_id = auth.uid() OR owner_id IS NULL);

-- UI Screens table policies
CREATE POLICY "Anyone can read published screens" ON public.ui_screens
  FOR SELECT
  USING (status = 'published' OR status = 'draft');

CREATE POLICY "Apps can create screens" ON public.ui_screens
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Apps can update their screens" ON public.ui_screens
  FOR UPDATE
  USING (true);

-- App State Sync table policies
CREATE POLICY "Devices can sync their state" ON public.app_state_sync
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Devices can read synced state" ON public.app_state_sync
  FOR SELECT
  USING (true);

CREATE POLICY "Devices can update state" ON public.app_state_sync
  FOR UPDATE
  USING (true);

-- Form Submissions table policies
CREATE POLICY "Anyone can submit forms" ON public.form_submissions
  FOR INSERT
  WITH CHECK (true);

-- Registered Devices policies
CREATE POLICY "Apps can register devices" ON public.registered_devices
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Apps can view devices" ON public.registered_devices
  FOR SELECT
  USING (true);

CREATE POLICY "Apps can update devices" ON public.registered_devices
  FOR UPDATE
  USING (true);

-- AI Actions Log policies
CREATE POLICY "AI agents can log actions" ON public.ai_actions_log
  FOR INSERT
  WITH CHECK (true);
```

---

## 🚀 Flutter App Integration

### Step 1: Add Dependencies

```yaml
# pubspec.yaml

dependencies:
  supabase_flutter: ^2.11.0
  supabase: ^2.11.0
  realtime_client: ^2.1.0
  shared_preferences: ^2.2.3
  device_info_plus: ^11.1.1
  uuid: ^4.2.1
  package_info_plus: ^8.1.0
```

### Step 2: Initialize Supabase

```dart
// lib/src/config/supabase_config.dart

class SupabaseConfig {
  static const String supabaseUrl = 'https://tzxaqatozdxgwhjphbrs.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6eGFxYXRvemR4Z3doanBoYnJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NDM1MDQsImV4cCI6MjA3NzMxOTUwNH0.ipdp9RP6ZDNgZR06yPb5YTaANOzvTE-1WrS-22ss7cU';
}

// Initialize in main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const MyApp());
}
```

### Step 3: App Registration Service

```dart
// lib/src/services/app_registration_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class AppRegistrationService {
  static const String _deviceIdKey = 'quicui_device_id';
  static const String _appIdKey = 'quicui_app_id';
  
  static final _supabase = Supabase.instance.client;
  
  /// Register app on first launch
  static Future<String> registerApp({
    required String appBundleId,
    required String packageName,
    required String appName,
  }) async {
    try {
      // Check if already registered
      final prefs = await SharedPreferences.getInstance();
      final existingAppId = prefs.getString(_appIdKey);
      
      if (existingAppId != null) {
        return existingAppId;
      }
      
      // Check if bundle already registered
      final existing = await _supabase
          .from('apps')
          .select()
          .eq('bundle_id', appBundleId)
          .maybeSingle();
      
      String appId;
      if (existing != null) {
        appId = existing['id'];
      } else {
        // Register new app
        final response = await _supabase.from('apps').insert({
          'name': appName,
          'bundle_id': appBundleId,
          'package_name': packageName,
          'ai_agent_key': 'quicui_${const Uuid().v4()}',
          'status': 'active',
        }).select().single();
        
        appId = response['id'];
      }
      
      // Save app ID locally
      await prefs.setString(_appIdKey, appId);
      
      return appId;
    } catch (e) {
      logger.e('App registration failed: $e');
      rethrow;
    }
  }
  
  /// Get or create device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }
  
  /// Register device with app
  static Future<void> registerDevice({
    required String appId,
    required String appBundleId,
  }) async {
    try {
      final deviceId = await getDeviceId();
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Check if already registered
      final existing = await _supabase
          .from('registered_devices')
          .select()
          .eq('app_id', appId)
          .eq('device_id', deviceId)
          .maybeSingle();
      
      if (existing != null) {
        // Update last sync
        await _supabase
            .from('registered_devices')
            .update({'is_online': true})
            .eq('id', existing['id']);
      } else {
        // Register new device
        await _supabase.from('registered_devices').insert({
          'app_id': appId,
          'device_id': deviceId,
          'device_name': deviceInfo['deviceName'],
          'device_os': deviceInfo['os'],
          'app_version': packageInfo.version,
          'is_online': true,
        });
      }
    } catch (e) {
      logger.e('Device registration failed: $e');
      rethrow;
    }
  }
  
  /// Get device info
  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'os': 'Android',
        'deviceName': '${androidInfo.manufacturer} ${androidInfo.model}',
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'os': 'iOS',
        'deviceName': iosInfo.model ?? 'iPhone',
      };
    } else if (Platform.isWeb) {
      return {
        'os': 'Web',
        'deviceName': 'Web Browser',
      };
    }
    
    return {
      'os': 'Unknown',
      'deviceName': 'Unknown Device',
    };
  }
  
  /// Mark device as online
  static Future<void> markOnline(String appId) async {
    try {
      final deviceId = await getDeviceId();
      await _supabase
          .from('registered_devices')
          .update({'is_online': true})
          .eq('app_id', appId)
          .eq('device_id', deviceId);
    } catch (e) {
      logger.e('Failed to mark device online: $e');
    }
  }
  
  /// Mark device as offline
  static Future<void> markOffline(String appId) async {
    try {
      final deviceId = await getDeviceId();
      await _supabase
          .from('registered_devices')
          .update({'is_online': false})
          .eq('app_id', appId)
          .eq('device_id', deviceId);
    } catch (e) {
      logger.e('Failed to mark device offline: $e');
    }
  }
}
```

### Step 4: Screen Management Service

```dart
// lib/src/services/screen_service_supabase.dart

class ScreenServiceSupabase {
  static final _supabase = Supabase.instance.client;
  
  /// Fetch screen definition from cloud
  static Future<Map<String, dynamic>> fetchScreen({
    required String appId,
    required String screenId,
  }) async {
    try {
      final response = await _supabase
          .from('ui_screens')
          .select()
          .eq('app_id', appId)
          .eq('screen_id', screenId)
          .eq('status', 'published')
          .single();
      
      return response['json_definition'] as Map<String, dynamic>;
    } catch (e) {
      logger.e('Failed to fetch screen: $e');
      rethrow;
    }
  }
  
  /// Subscribe to screen updates (real-time)
  static RealtimeChannel subscribeToScreenUpdates({
    required String appId,
    required String screenId,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    final channel = _supabase.channel('screen_updates:$appId:$screenId');
    
    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'UPDATE',
        schema: 'public',
        table: 'ui_screens',
        filter: 'app_id=eq.$appId,screen_id=eq.$screenId',
      ),
      (payload, [ref]) {
        final updated = payload['new'] as Map<String, dynamic>;
        if (updated['status'] == 'published') {
          onUpdate(updated['json_definition'] as Map<String, dynamic>);
        }
      },
    ).subscribe();
    
    return channel;
  }
  
  /// Publish screen (for web UI)
  static Future<void> publishScreen({
    required String appId,
    required String screenId,
    required String screenName,
    required Map<String, dynamic> jsonDefinition,
  }) async {
    try {
      await _supabase.from('ui_screens').upsert({
        'app_id': appId,
        'screen_id': screenId,
        'screen_name': screenName,
        'json_definition': jsonDefinition,
        'status': 'published',
        'published_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      logger.e('Failed to publish screen: $e');
      rethrow;
    }
  }
}
```

### Step 5: Real-time Sync Service

```dart
// lib/src/services/sync_service_supabase.dart

class SyncServiceSupabase {
  static final _supabase = Supabase.instance.client;
  static late final RealtimeChannel _syncChannel;
  
  /// Initialize real-time sync
  static Future<void> initializeSync({
    required String appId,
  }) async {
    try {
      final deviceId = await AppRegistrationService.getDeviceId();
      
      _syncChannel = _supabase.channel('app_sync:$appId:$deviceId');
      
      _syncChannel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',
          schema: 'public',
          table: 'app_state_sync',
          filter: 'app_id=eq.$appId,device_id=eq.$deviceId',
        ),
        (payload, [ref]) {
          _handleSyncUpdate(payload['new'] as Map<String, dynamic>);
        },
      ).subscribe();
    } catch (e) {
      logger.e('Failed to initialize sync: $e');
    }
  }
  
  /// Handle incoming sync updates
  static void _handleSyncUpdate(Map<String, dynamic> update) {
    final stateKey = update['state_key'] as String;
    final stateValue = update['state_value'];
    
    // Save to local storage
    ObjectBoxProvider.saveState(stateKey, stateValue);
    
    // Update app state
    QuicStateManager.instance.set(stateKey, stateValue);
  }
  
  /// Push state changes to server
  static Future<void> pushState({
    required String appId,
    required Map<String, dynamic> changes,
  }) async {
    try {
      final deviceId = await AppRegistrationService.getDeviceId();
      
      for (final entry in changes.entries) {
        await _supabase.from('app_state_sync').upsert({
          'app_id': appId,
          'device_id': deviceId,
          'state_key': entry.key,
          'state_value': entry.value,
          'device_version': DateTime.now().millisecondsSinceEpoch,
          'synced_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      logger.e('Failed to push state: $e');
    }
  }
  
  /// Cleanup sync
  static Future<void> cleanup() async {
    await _syncChannel.unsubscribe();
  }
}
```

---

## 📊 Testing Your Setup

### Test App Registration

```dart
void testAppRegistration() async {
  // Register app
  final appId = await AppRegistrationService.registerApp(
    appBundleId: 'com.example.quicui',
    packageName: 'com.example.quicui',
    appName: 'My QuicUI App',
  );
  
  print('App registered: $appId');
  
  // Register device
  await AppRegistrationService.registerDevice(
    appId: appId,
    appBundleId: 'com.example.quicui',
  );
  
  print('Device registered');
}
```

### Test Screen Fetching

```dart
void testScreenFetching() async {
  final screen = await ScreenServiceSupabase.fetchScreen(
    appId: 'your_app_id',
    screenId: 'home_screen',
  );
  
  print('Screen fetched: ${screen['type']}');
}
```

### Test Real-time Sync

```dart
void testRealtimeSync() async {
  await SyncServiceSupabase.initializeSync(
    appId: 'your_app_id',
  );
  
  // Push some state
  await SyncServiceSupabase.pushState(
    appId: 'your_app_id',
    changes: {'user_name': 'John Doe', 'theme': 'dark'},
  );
}
```

---

## 🔍 Debugging & Monitoring

### View Sync Status

```sql
-- Check app state sync status
SELECT 
  device_id,
  COUNT(*) as sync_count,
  MAX(updated_at) as last_update,
  COUNT(CASE WHEN conflict_resolution != 'server_wins' THEN 1 END) as conflicts
FROM public.app_state_sync
WHERE app_id = 'your_app_id'
GROUP BY device_id;
```

### View Device Status

```sql
-- Check registered devices
SELECT 
  device_id,
  device_name,
  device_os,
  is_online,
  last_sync_at
FROM public.registered_devices
WHERE app_id = 'your_app_id'
ORDER BY last_sync_at DESC;
```

### View AI Actions

```sql
-- Check AI agent actions
SELECT 
  ai_agent_id,
  action_type,
  result_status,
  COUNT(*) as count,
  MAX(created_at) as latest
FROM public.ai_actions_log
WHERE app_id = 'your_app_id'
GROUP BY ai_agent_id, action_type, result_status;
```

---

## ✅ Checklist

- [ ] Create Supabase account
- [ ] Copy credentials
- [ ] Run SQL migrations
- [ ] Setup RLS policies
- [ ] Add Flutter dependencies
- [ ] Initialize Supabase in main.dart
- [ ] Implement AppRegistrationService
- [ ] Implement ScreenServiceSupabase
- [ ] Implement SyncServiceSupabase
- [ ] Test app registration
- [ ] Test screen fetching
- [ ] Test real-time sync
- [ ] Deploy to production

---

*Last Updated: October 30, 2025*
