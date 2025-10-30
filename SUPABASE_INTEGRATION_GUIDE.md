# Supabase Integration Guide for QuicUI

**Last Updated:** October 30, 2025  
**Version:** 1.0.0

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Setup & Configuration](#setup--configuration)
3. [Cloud Data Integration](#cloud-data-integration)
4. [Real-time Synchronization](#real-time-synchronization)
5. [Authentication](#authentication)
6. [Database Operations](#database-operations)
7. [Offline-First Sync](#offline-first-sync)
8. [Examples](#examples)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Overview

QuicUI integrates seamlessly with **Supabase**, a Firebase alternative that provides:

- ✅ **PostgreSQL Database** - Powerful relational database
- ✅ **Real-time Features** - Live data synchronization
- ✅ **Authentication** - Built-in user management
- ✅ **Storage** - File uploads and management
- ✅ **Vector Search** - AI-powered search capabilities

### Architecture

```
┌─────────────────────────────────────────┐
│         Flutter App with QuicUI         │
└────────────────┬────────────────────────┘
                 │
         ┌───────▼────────┐
         │   QuicUIService│
         └───────┬────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼────┐ ┌────▼────┐ ┌─────▼──┐
│ Storage│ │ Supabase│ │ ObjectBox
│Service │ │ Service │ │ (Local)
└───┬────┘ └────┬────┘ └─────┬──┘
    │           │            │
    └───────────┴────────────┘
            │
    ┌───────▼──────────┐
    │  Cloud Database  │
    │   (Supabase)     │
    └──────────────────┘
```

---

## Setup & Configuration

### Step 1: Create Supabase Project

1. Visit [supabase.com](https://supabase.com)
2. Sign up or login
3. Create a new project
4. Get your credentials:
   - **Project URL** (e.g., `https://your-project.supabase.co`)
   - **Anon Key** (Public key for client-side)
   - **Service Role Key** (Private key for server-side)

### Step 2: Initialize QuicUI with Supabase

```dart
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize QuicUI with Supabase
  await QuicUIService().initialize(
    appApiKey: 'your-app-api-key',
    supabaseUrl: 'https://your-project.supabase.co',
    supabaseAnonKey: 'your-supabase-anon-key',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

### Step 3: Configure Your Database

Create tables in Supabase:

```sql
-- Screen configurations table
CREATE TABLE screens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  config JSONB NOT NULL,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User data table
CREATE TABLE user_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  data JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_screens_name ON screens(name);
CREATE INDEX idx_user_data_user_id ON user_data(user_id);
```

---

## Cloud Data Integration

### Fetching Screen Configurations from Cloud

```dart
// Get a screen configuration from Supabase
final service = QuicUIService();
final screenConfig = await service.fetchScreen('home_screen');

// Build the UI from the configuration
Widget buildScreen(ScreenData screen) {
  return Scaffold(
    appBar: AppBar(title: Text(screen.title)),
    body: UIRenderer.renderScreen(screen),
  );
}
```

### Real-time Screen Updates

```dart
// Listen for screen configuration changes
Stream<ScreenData> watchScreen(String screenName) {
  return QuicUIService().watchScreen(screenName);
}

// Usage in a widget
class LiveScreen extends StatelessWidget {
  final String screenName;
  
  const LiveScreen({required this.screenName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScreenData>(
      stream: watchScreen(screenName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final screenData = snapshot.data;
        if (screenData == null) {
          return const Center(child: Text('No data'));
        }
        
        return UIRenderer.renderScreen(screenData);
      },
    );
  }
}
```

### Querying Custom Data

```dart
// Query user data from Supabase
Future<List<Map<String, dynamic>>> getUserData(String userId) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
    .from('user_data')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(response);
}

// Usage
void loadUserData() async {
  final userId = Supabase.instance.client.auth.currentUser!.id;
  final data = await getUserData(userId);
  
  // Process data
  for (var item in data) {
    print('Data: ${item['data']}');
  }
}
```

---

## Real-time Synchronization

### Enable Real-time for Tables

```sql
-- Enable real-time for screens table
ALTER TABLE screens REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE screens;

-- Enable real-time for user_data table
ALTER TABLE user_data REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE user_data;
```

### Listen to Real-time Changes

```dart
class RealtimeDataSync {
  final supabase = Supabase.instance.client;
  
  void subscribeToScreenChanges() {
    supabase
      .from('screens')
      .on(RealtimeListenTypes.all, (payload) {
        print('Screen changed: ${payload.newRecord}');
        _handleScreenUpdate(payload.newRecord);
      })
      .subscribe();
  }
  
  void subscribeToUserDataChanges(String userId) {
    supabase
      .from('user_data')
      .on(RealtimeListenTypes.all, (payload) {
        if (payload.newRecord['user_id'] == userId) {
          print('User data updated: ${payload.newRecord}');
          _handleDataUpdate(payload.newRecord);
        }
      })
      .subscribe();
  }
  
  void _handleScreenUpdate(Map<String, dynamic> screen) {
    // Update local cache and UI
    final screenData = ScreenData.fromJson(screen['config']);
    QuicUIService().cacheScreen(screen['name'], screenData);
  }
  
  void _handleDataUpdate(Map<String, dynamic> data) {
    // Update local storage
    QuicUIService().updateLocalData(data);
  }
}
```

---

## Authentication

### User Registration

```dart
Future<AuthResponse> registerUser({
  required String email,
  required String password,
}) async {
  final response = await Supabase.instance.client.auth.signUp(
    email: email,
    password: password,
  );
  
  return response;
}

// Usage
void signUp() async {
  try {
    final response = await registerUser(
      email: 'user@example.com',
      password: 'secure_password_123',
    );
    
    print('User registered: ${response.user?.id}');
  } catch (e) {
    print('Signup error: $e');
  }
}
```

### User Login

```dart
Future<AuthResponse> loginUser({
  required String email,
  required String password,
}) async {
  final response = await Supabase.instance.client.auth.signInWithPassword(
    email: email,
    password: password,
  );
  
  return response;
}

// Usage
void login() async {
  try {
    final response = await loginUser(
      email: 'user@example.com',
      password: 'secure_password_123',
    );
    
    print('Login successful: ${response.user?.id}');
  } catch (e) {
    print('Login error: $e');
  }
}
```

### Session Management

```dart
class AuthManager {
  final supabase = Supabase.instance.client;
  
  // Check if user is logged in
  bool get isAuthenticated => supabase.auth.currentUser != null;
  
  // Get current user
  User? get currentUser => supabase.auth.currentUser;
  
  // Get user ID
  String? get userId => supabase.auth.currentUser?.id;
  
  // Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
  }
  
  // Listen to auth changes
  void onAuthStateChanged(Function(User?) callback) {
    supabase.auth.onAuthStateChange.listen((data) {
      callback(data.session?.user);
    });
  }
}
```

---

## Database Operations

### Create Records

```dart
Future<void> createScreen({
  required String name,
  required Map<String, dynamic> config,
}) async {
  final supabase = Supabase.instance.client;
  
  await supabase.from('screens').insert({
    'name': name,
    'config': config,
    'version': 1,
  });
}

// Usage
void addNewScreen() async {
  await createScreen(
    name: 'products_screen',
    config: {
      'title': 'Products',
      'widgets': [
        {'type': 'text', 'value': 'Product List'}
      ]
    },
  );
}
```

### Read Records

```dart
Future<Map<String, dynamic>?> getScreen(String name) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
    .from('screens')
    .select()
    .eq('name', name)
    .single();
  
  return response;
}

// Get all screens
Future<List<Map<String, dynamic>>> getAllScreens() async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
    .from('screens')
    .select()
    .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(response);
}
```

### Update Records

```dart
Future<void> updateScreen({
  required String screenId,
  required Map<String, dynamic> config,
}) async {
  final supabase = Supabase.instance.client;
  
  await supabase
    .from('screens')
    .update({
      'config': config,
      'version': SupabaseQueryBuilder.raw('version + 1'),
      'updated_at': DateTime.now().toIso8601String(),
    })
    .eq('id', screenId);
}
```

### Delete Records

```dart
Future<void> deleteScreen(String screenId) async {
  final supabase = Supabase.instance.client;
  
  await supabase
    .from('screens')
    .delete()
    .eq('id', screenId);
}
```

---

## Offline-First Sync

### Architecture

QuicUI implements an **offline-first** pattern:

1. **Write to Local Cache** - Updates saved to ObjectBox immediately
2. **Queue Changes** - Sync operations queued for later
3. **Sync When Online** - Changes pushed to Supabase when connection restored
4. **Conflict Resolution** - Last-write-wins strategy

### Implementation

```dart
class OfflineFirstManager {
  final service = QuicUIService();
  final supabase = Supabase.instance.client;
  
  // Save data locally (works offline)
  Future<void> saveScreenLocally(ScreenData screen) async {
    await service.saveScreenToCache(screen);
    
    // Queue for sync
    await _queueForSync(screen);
  }
  
  // Sync with cloud when online
  Future<void> syncWithCloud() async {
    // Get queued changes
    final queue = await service.getUnsyncedChanges();
    
    for (var change in queue) {
      try {
        // Push to Supabase
        await supabase
          .from('screens')
          .upsert(change)
          .select();
        
        // Mark as synced
        await service.markAsSynced(change['id']);
      } catch (e) {
        print('Sync error: $e');
        // Retry on next sync
      }
    }
  }
  
  // Monitor connectivity
  void monitorConnectivity() {
    final connectivity = Connectivity();
    
    connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.mobile || 
          result == ConnectivityResult.wifi) {
        // Device is online - sync now
        syncWithCloud();
      }
    });
  }
  
  Future<void> _queueForSync(ScreenData screen) async {
    // Implementation details
  }
}
```

### Usage Example

```dart
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({Key? key}) : super(key: key);

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  final manager = OfflineFirstManager();
  
  @override
  void initState() {
    super.initState();
    manager.monitorConnectivity();
  }
  
  void updateScreen() async {
    final newScreen = ScreenData(
      name: 'updated_screen',
      config: {'title': 'Updated Title'},
    );
    
    // Works offline
    await manager.saveScreenLocally(newScreen);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screen saved (will sync when online)')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline First')),
      body: Center(
        child: ElevatedButton(
          onPressed: updateScreen,
          child: const Text('Update Screen'),
        ),
      ),
    );
  }
}
```

---

## Examples

### Example 1: Simple Data App

```dart
// Load screen configuration from cloud
class DataScreen extends StatefulWidget {
  const DataScreen({Key? key}) : super(key: key);

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  late Future<Map<String, dynamic>> screenFuture;
  
  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    screenFuture = supabase
      .from('screens')
      .select()
      .eq('name', 'dashboard')
      .single();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: screenFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final config = snapshot.data!['config'];
          return UIRenderer.renderScreen(ScreenData.fromJson(config));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
```

### Example 2: Real-time Form Sync

```dart
class RealtimeFormApp extends StatefulWidget {
  const RealtimeFormApp({Key? key}) : super(key: key);

  @override
  State<RealtimeFormApp> createState() => _RealtimeFormAppState();
}

class _RealtimeFormAppState extends State<RealtimeFormApp> {
  final supabase = Supabase.instance.client;
  final formDataController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Subscribe to form data changes
    supabase
      .from('user_data')
      .on(RealtimeListenTypes.all, (payload) {
        setState(() {
          formDataController.text = payload.newRecord['data'].toString();
        });
      })
      .subscribe();
  }
  
  void saveFormData() async {
    final userId = supabase.auth.currentUser!.id;
    
    await supabase.from('user_data').insert({
      'user_id': userId,
      'data': formDataController.text,
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: formDataController,
              decoration: const InputDecoration(
                labelText: 'Form Data',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: saveFormData,
              child: const Text('Save to Supabase'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    formDataController.dispose();
    super.dispose();
  }
}
```

### Example 3: User Profile with Cloud Storage

```dart
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  
  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }
  
  Future<void> loadUserProfile() async {
    final userId = supabase.auth.currentUser!.id;
    
    final response = await supabase
      .from('user_profiles')
      .select()
      .eq('user_id', userId)
      .single();
    
    setState(() {
      userProfile = response;
    });
  }
  
  Future<void> uploadProfilePicture(File imageFile) async {
    final userId = supabase.auth.currentUser!.id;
    final fileName = '$userId/profile_picture.jpg';
    
    await supabase.storage.from('profiles').upload(
      fileName,
      imageFile,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );
    
    final imageUrl = supabase.storage
      .from('profiles')
      .getPublicUrl(fileName);
    
    // Update profile with image URL
    await supabase
      .from('user_profiles')
      .update({'profile_picture_url': imageUrl})
      .eq('user_id', userId);
    
    loadUserProfile();
  }
  
  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                userProfile!['profile_picture_url'] ?? '',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userProfile!['name'] ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle file picker and upload
              },
              child: const Text('Upload Profile Picture'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Best Practices

### 1. Security Rules

Set up RLS (Row Level Security) in Supabase:

```sql
-- Enable RLS on user_data table
ALTER TABLE user_data ENABLE ROW LEVEL SECURITY;

-- Only users can see their own data
CREATE POLICY "Users can view their own data"
ON user_data FOR SELECT
USING (auth.uid() = user_id);

-- Only users can insert their own data
CREATE POLICY "Users can insert their own data"
ON user_data FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Only users can update their own data
CREATE POLICY "Users can update their own data"
ON user_data FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
```

### 2. Error Handling

```dart
Future<Map<String, dynamic>?> safeGetScreen(String name) async {
  try {
    final supabase = Supabase.instance.client;
    
    final response = await supabase
      .from('screens')
      .select()
      .eq('name', name)
      .single()
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timeout'),
      );
    
    return response;
  } on TimeoutException {
    print('Request timeout');
    return null;
  } on PostgrestException catch (e) {
    print('Database error: ${e.message}');
    return null;
  } catch (e) {
    print('Unexpected error: $e');
    return null;
  }
}
```

### 3. Caching Strategy

```dart
class CacheManager {
  static const cacheDuration = Duration(minutes: 10);
  final _cache = <String, CacheEntry>{};
  
  bool isCacheValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    final isExpired = DateTime.now().difference(entry.timestamp) > cacheDuration;
    return !isExpired;
  }
  
  T? get<T>(String key) {
    if (isCacheValid(key)) {
      return _cache[key]!.data as T?;
    }
    _cache.remove(key);
    return null;
  }
  
  void set(String key, dynamic value) {
    _cache[key] = CacheEntry(value, DateTime.now());
  }
  
  void clear() => _cache.clear();
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  
  CacheEntry(this.data, this.timestamp);
}
```

### 4. Performance Optimization

```dart
// Use indexes for frequently queried columns
CREATE INDEX idx_user_data_created_at ON user_data(created_at DESC);

// Paginate large result sets
Future<List<Map<String, dynamic>>> getPagedScreens({
  required int page,
  required int pageSize,
}) async {
  final supabase = Supabase.instance.client;
  final start = (page - 1) * pageSize;
  
  return supabase
    .from('screens')
    .select()
    .range(start, start + pageSize - 1)
    .order('created_at', ascending: false);
}

// Use select() to fetch only needed columns
final response = await supabase
  .from('user_data')
  .select('id, data, updated_at')  // Only fetch these columns
  .eq('user_id', userId);
```

---

## Troubleshooting

### Connection Issues

```dart
// Check internet connectivity
Future<bool> isConnected() async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();
  return result != ConnectivityResult.none;
}

// Test Supabase connection
Future<bool> testSupabaseConnection() async {
  try {
    final response = await Supabase.instance.client
      .from('screens')
      .select('count')
      .limit(1)
      .timeout(const Duration(seconds: 5));
    
    return response.isNotEmpty;
  } catch (e) {
    print('Connection test failed: $e');
    return false;
  }
}
```

### Authentication Errors

```dart
// Handle auth errors
Future<void> handleAuthError(Object error) async {
  if (error is AuthException) {
    switch (error.statusCode) {
      case '401':
        print('Invalid credentials');
        break;
      case '422':
        print('User already exists');
        break;
      case '429':
        print('Too many requests - rate limited');
        break;
      default:
        print('Auth error: ${error.message}');
    }
  }
}
```

### Sync Issues

```dart
// Debug sync status
class SyncDebugger {
  final service = QuicUIService();
  
  Future<void> debugSync() async {
    final unsyncedCount = await service.getUnsyncedChangesCount();
    print('Unsynced changes: $unsyncedCount');
    
    final lastSyncTime = await service.getLastSyncTime();
    print('Last sync: $lastSyncTime');
    
    final isOnline = await checkConnectivity();
    print('Online: $isOnline');
    
    if (isOnline && unsyncedCount > 0) {
      await service.forceSync();
      print('Sync completed');
    }
  }
}
```

---

## Resources

- **Supabase Documentation:** https://supabase.com/docs
- **Flutter Supabase Package:** https://pub.dev/packages/supabase
- **QuicUI GitHub:** https://github.com/Ikolvi/QuicUI
- **Real-time Database Guide:** https://supabase.com/docs/guides/realtime

---

## Support

For issues or questions:

1. **GitHub Issues:** https://github.com/Ikolvi/QuicUI/issues
2. **Supabase Docs:** https://supabase.com/docs
3. **Stack Overflow:** Tag with `quicui` and `supabase`

---

**Last Updated:** October 30, 2025  
**QuicUI Version:** 1.0.0  
**License:** MIT
