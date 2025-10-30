# Backend Integration Guide - QuicUI v1.0.3+

Complete guide to integrating QuicUI with cloud backends. **Backends are completely optional** - this guide covers how to add them.

**What you'll learn:**
- 🔌 Optional backend architecture
- 🔑 Implementing the DataSource interface
- 📡 Building custom backends
- 🔄 Real-time synchronization
- 🌐 Offline-first strategy

**Time required:** 30-45 minutes

---

## Overview: Optional Backends

QuicUI works in two modes:

### 1. Standalone (No Backend)
- Use local JSON data
- No internet required
- Perfect for offline apps

### 2. With Backend Plugin (Optional)
- Fetch screens from cloud
- Real-time updates
- Multi-device sync

This guide covers **Option 2** - adding optional backend support.

---

## Architecture

### Core Abstraction: DataSource Interface

All backends implement the `DataSource` interface:

```dart
abstract class DataSource {
  // Screen Management
  Future<Screen> fetchScreen(String screenId);
  Future<List<Screen>> fetchScreens({int limit = 20, int offset = 0});
  Future<Screen> saveScreen(String screenId, Screen screen);
  Future<void> deleteScreen(String screenId);
  Future<List<Screen>> searchScreens(String query);
  Future<int> getScreenCount();
  
  // Real-Time (Optional)
  Stream<RealtimeEvent> subscribeToScreen(String screenId);
  Future<void> unsubscribe(String screenId);
  
  // Sync (Optional)
  Future<SyncResult> syncData(List<SyncItem> items);
  Future<List<SyncItem>> getPendingItems();
  
  // Connection
  Future<void> connect();
  Future<void> disconnect();
  bool isConnected();
}
```

### Official Plugins

- **Supabase** (`quicui_supabase`) - Recommended
  - Real-time WebSocket updates
  - PostgreSQL backend
  - Built-in authentication
  - Version: ^2.0.2

- **Firebase** (future)
- **REST API** (future)

---

## Using Official Plugins

### Supabase Backend

#### 1. Install

```bash
flutter pub add quicui_supabase
flutter pub add supabase_flutter
```

#### 2. Initialize in main()

```dart
import 'package:quicui/quicui.dart';
import 'package:quicui_supabase/quicui_supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dataSource = SupabaseDataSource(
    'https://your-project.supabase.co',
    'your-anon-key',
  );
  
  await dataSource.connect();
  DataSourceProvider.instance.register(dataSource);
  
  runApp(const MyApp());
}
```

#### 3. Use in Your App

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late Future<Screen> screenFuture;

  @override
  void initState() {
    super.initState();
    final dataSource = DataSourceProvider.instance.get();
    screenFuture = dataSource.fetchScreen('home_screen');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Screen>(
      future: screenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        return UIRenderer().renderScreen(snapshot.data!);
      },
    );
  }
}
```

#### 4. Setup Database Schema

On Supabase, create these tables:

```sql
-- Main screens table
create table screens (
  id text primary key,
  name text not null,
  version integer default 1,
  root_widget jsonb not null,
  metadata jsonb,
  config jsonb,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- For real-time updates
alter table screens replica identity full;

-- Enable real-time replication
create publication supabase_realtime for table screens;
```

See [QuicUI Supabase Plugin](https://pub.dev/packages/quicui_supabase) for complete setup.

---

## Building Custom Backends

### Step 1: Create a New Package

```bash
flutter pub new my_backend
cd my_backend
```

### Step 2: Implement DataSource

```dart
import 'package:quicui/quicui.dart';

class MyDataSource extends DataSource {
  final String baseUrl;
  
  MyDataSource(this.baseUrl);
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/screens/$screenId'),
    );
    
    if (response.statusCode != 200) {
      throw DataSourceException('Failed to fetch screen');
    }
    
    final json = jsonDecode(response.body);
    return Screen.fromJson(json);
  }
  
  @override
  Future<void> connect() async {
    // Initialize your backend connection
  }
  
  @override
  Future<void> disconnect() async {
    // Cleanup
  }
  
  @override
  bool isConnected() => true;
  
  // Implement other methods...
  @override
  Future<List<Screen>> fetchScreens({int limit = 20, int offset = 0}) async {
    // ...
  }
  
  @override
  Future<Screen> saveScreen(String screenId, Screen screen) async {
    // ...
  }
  
  // ... implement remaining abstract methods
}
```

### Step 3: Register with QuicUI

```dart
final myDataSource = MyDataSource('https://api.example.com');
await myDataSource.connect();
DataSourceProvider.instance.register(myDataSource);
```

### Step 4: Use in Your App

```dart
final dataSource = DataSourceProvider.instance.get();
final screen = await dataSource.fetchScreen('home_screen');
```

---

## Common Backend Patterns

### REST API Backend

```dart
class RestDataSource extends DataSource {
  final String baseUrl;
  final http.Client client;
  
  RestDataSource(this.baseUrl, {http.Client? client})
    : client = client ?? http.Client();
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/screens/$screenId'),
      );
      
      if (response.statusCode == 404) {
        throw ScreenNotFoundException('Screen not found');
      }
      
      if (response.statusCode != 200) {
        throw DataSourceException('Server error');
      }
      
      return Screen.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on SocketException {
      throw NetworkException('No internet connection');
    }
  }
  
  @override
  Future<List<Screen>> fetchScreens({int limit = 20, int offset = 0}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/screens?limit=$limit&offset=$offset'),
    );
    
    if (response.statusCode != 200) {
      throw DataSourceException('Failed to fetch screens');
    }
    
    final list = jsonDecode(response.body) as List;
    return list
      .map((item) => Screen.fromJson(item as Map<String, dynamic>))
      .toList();
  }
  
  // ... implement other methods
}
```

### Firebase Backend

```dart
class FirebaseDataSource extends DataSource {
  final FirebaseFirestore firestore;
  
  FirebaseDataSource(this.firestore);
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    try {
      final doc = await firestore.collection('screens').doc(screenId).get();
      
      if (!doc.exists) {
        throw ScreenNotFoundException('Screen not found');
      }
      
      return Screen.fromJson(doc.data()!);
    } catch (e) {
      throw DataSourceException('Error fetching screen: $e');
    }
  }
  
  @override
  Stream<RealtimeEvent> subscribeToScreen(String screenId) {
    return firestore
      .collection('screens')
      .doc(screenId)
      .snapshots()
      .map((doc) => RealtimeEvent(
        type: 'update',
        data: Screen.fromJson(doc.data()!),
        timestamp: DateTime.now(),
      ));
  }
  
  // ... implement other methods
}
```

### Hybrid Approach (REST + Local Cache)

```dart
class CachedDataSource extends DataSource {
  final DataSource remote;
  final LocalDataSource local;
  
  CachedDataSource(this.remote, this.local);
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    try {
      // Try remote first
      final screen = await remote.fetchScreen(screenId);
      
      // Cache locally
      await local.saveScreen(screenId, screen);
      
      return screen;
    } catch (e) {
      // Fall back to local cache
      return local.fetchScreen(screenId);
    }
  }
  
  // ... implement other methods
}
```

---

## Real-Time Updates

### With Supabase Plugin

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription screenSubscription;

  @override
  void initState() {
    super.initState();
    
    final dataSource = DataSourceProvider.instance.get();
    
    // Subscribe to real-time updates
    screenSubscription = dataSource
      .subscribeToScreen('home_screen')
      .listen((event) {
        setState(() {
          // Update UI with new screen data
        });
      });
  }

  @override
  void dispose() {
    screenSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your UI
  }
}
```

---

## Offline-First Strategy

### Implementing Offline Sync

```dart
class OfflineDataSource extends DataSource {
  final DataSource remote;
  final LocalDataSource local;
  final Connectivity connectivity;
  
  OfflineDataSource({
    required this.remote,
    required this.local,
    required this.connectivity,
  });
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    // Check if online
    final connectionResult = await connectivity.checkConnectivity();
    final isOnline = connectionResult != ConnectivityResult.none;
    
    if (isOnline) {
      try {
        // Fetch from remote
        final screen = await remote.fetchScreen(screenId);
        
        // Cache locally
        await local.saveScreen(screenId, screen);
        
        return screen;
      } catch (e) {
        // Fall back to cache
        return local.fetchScreen(screenId);
      }
    } else {
      // Offline - use cache
      return local.fetchScreen(screenId);
    }
  }
  
  @override
  Future<SyncResult> syncData(List<SyncItem> items) async {
    final results = <String, bool>{};
    final errors = <SyncError>[];
    
    for (final item in items) {
      try {
        await remote.saveScreen(item.screenId, item.screen);
        results[item.screenId] = true;
      } catch (e) {
        results[item.screenId] = false;
        errors.add(SyncError(
          itemId: item.screenId,
          error: e.toString(),
        ));
      }
    }
    
    return SyncResult(
      synced: results.values.where((v) => v).length,
      failed: results.values.where((v) => !v).length,
      errors: errors,
    );
  }
}
```

---

## Error Handling

### Custom Exceptions

```dart
class MyDataSource extends DataSource {
  @override
  Future<Screen> fetchScreen(String screenId) async {
    if (screenId.isEmpty) {
      throw ArgumentError('screenId cannot be empty');
    }
    
    try {
      // Fetch logic
    } on SocketException {
      throw NetworkException('Failed to connect to server');
    } on TimeoutException {
      throw DataSourceException('Request timeout');
    } catch (e) {
      throw DataSourceException('Unknown error: $e');
    }
  }
}
```

### Exception Handling in UI

```dart
FutureBuilder<Screen>(
  future: screenFuture,
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      if (snapshot.error is ScreenNotFoundException) {
        return Center(child: Text('Screen not found'));
      } else if (snapshot.error is NetworkException) {
        return Center(child: Text('No internet connection'));
      } else {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
    }
    
    // ... handle other states
  },
)
```

---

## Testing Custom Backends

### Mock Implementation

```dart
class MockDataSource extends DataSource {
  final screens = <String, Screen>{};
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (!screens.containsKey(screenId)) {
      throw ScreenNotFoundException('Mock: Screen not found');
    }
    
    return screens[screenId]!;
  }
  
  @override
  Future<Screen> saveScreen(String screenId, Screen screen) async {
    screens[screenId] = screen;
    return screen;
  }
  
  // ... implement other methods
}
```

### Unit Tests

```dart
test('Fetch screen from custom backend', () async {
  final dataSource = MockDataSource();
  
  dataSource.saveScreen('test', Screen(
    id: 'test',
    name: 'Test Screen',
    version: 1,
    rootWidget: WidgetData(type: 'text', properties: {}),
    // ...
  ));
  
  final screen = await dataSource.fetchScreen('test');
  
  expect(screen.id, equals('test'));
  expect(screen.name, equals('Test Screen'));
});
```

---

## Publishing Your Backend

### 1. Create Pub Package

```bash
flutter pub publish --dry-run
flutter pub publish
```

### 2. Update README

Include:
- Installation instructions
- API key setup
- Example usage
- Link to main QuicUI package

### 3. Example README Section

```markdown
# QuicUI Custom Backend

Custom backend implementation for QuicUI.

## Installation

\`\`\`bash
flutter pub add quicui_custom
\`\`\`

## Usage

\`\`\`dart
final dataSource = CustomDataSource('your-api-key');
DataSourceProvider.instance.register(dataSource);
\`\`\`

See [QuicUI Documentation](https://pub.dev/packages/quicui) for complete setup.
```

---

## Next Steps

- 📖 Read [API Reference](API_REFERENCE.md) for detailed method documentation
- 🔌 Check [Plugin Architecture](PLUGIN_ARCHITECTURE.md) for design patterns
- 🧪 See `examples/` directory for working backend implementations
- 💬 Join Discord/GitHub for community support

---

## Resources

- **QuicUI:** https://pub.dev/packages/quicui
- **Supabase Plugin:** https://pub.dev/packages/quicui_supabase
- **GitHub:** https://github.com/Ikolvi/QuicUI
- **Issues:** https://github.com/Ikolvi/QuicUI/issues
