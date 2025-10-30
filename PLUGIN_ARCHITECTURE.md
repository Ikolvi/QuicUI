# QuicUI Plugin Architecture

**Version:** 2.0.0 (Planned)  
**Type:** Architecture Reference  
**Audience:** Developers, Users, Contributors  

---

## 🎯 Overview

QuicUI v2.0.0 will introduce a **plugin architecture** that decouples the core framework from backend implementations.

### Core Principle
> QuicUI handles **UI rendering, state management, and local caching**.  
> Plugins handle **backend communication and data synchronization**.

---

## 🏗️ Architecture Layers

```
┌────────────────────────────────────────────────────────┐
│              QuicUI Application (Your App)              │
├────────────────────────────────────────────────────────┤
│    ┌──────────────────────────────────────────────┐    │
│    │       Presentation Layer (BLoC + UI)         │    │
│    │  - Screens, Widgets, State Management         │    │
│    └──────────────────────────────────────────────┘    │
│              ↓                      ↓                   │
│    ┌──────────────────┐  ┌───────────────────────┐    │
│    │  Repositories    │  │  Storage Service      │    │
│    │  (Interface)     │  │  (ObjectBox/Hive)     │    │
│    └──────────────────┘  └───────────────────────┘    │
└────────────────────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────────────────────┐
│         Plugin Contract Layer (Abstract)                │
├────────────────────────────────────────────────────────┤
│    ┌──────────────────────────────────────────────┐    │
│    │  abstract class DataSource                   │    │
│    │  - fetchScreen()  - saveScreen()             │    │
│    │  - deleteScreen() - searchScreens()          │    │
│    │  - syncData()     - resolveConflict()        │    │
│    │  - connect()      - disconnect()             │    │
│    └──────────────────────────────────────────────┘    │
│    ┌──────────────────────────────────────────────┐    │
│    │  abstract class RealtimeSource               │    │
│    │  - subscribe()   - unsubscribe()             │    │
│    │  - Stream<RealtimeEvent<T>>                  │    │
│    └──────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
    ↓                ↓                ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   Supabase   │ │  Firebase    │ │ AWS Amplify  │
│   Plugin     │ │   Plugin     │ │   Plugin     │
│              │ │              │ │              │
│ (AVAILABLE)  │ │ (FUTURE)     │ │ (FUTURE)     │
└──────────────┘ └──────────────┘ └──────────────┘
      ↓                ↓                ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Supabase    │ │  Firebase    │ │  AWS DynamoDB│
│  PostgreSQL  │ │  Firestore   │ │               │
└──────────────┘ └──────────────┘ └──────────────┘
```

---

## 📦 Package Organization

### Core Packages

#### `quicui` (Main Package)
- **Purpose:** Database-agnostic UI framework
- **Dependencies:** flutter, flutter_bloc, objectbox, hive, etc.
- **No Supabase references**
- **Exposes:** DataSource interface contract

**File Structure:**
```
quicui/
├── lib/src/
│   ├── core/                    # Constants, exceptions, utils
│   ├── models/                  # Data models (Screen, Widget, etc.)
│   ├── rendering/               # UI rendering engine
│   ├── widgets/                 # Flutter widgets
│   ├── bloc/                    # BLoC state management
│   ├── repositories/            # Repository pattern
│   │   ├── abstract/
│   │   │   ├── data_source.dart        # NEW
│   │   │   └── realtime_source.dart    # NEW
│   │   ├── screen_repository.dart      # Updated
│   │   └── sync_repository.dart        # Updated
│   └── services/
│       ├── storage_service.dart        # Local storage
│       ├── data_source_provider.dart   # NEW
│       └── quicui_service.dart         # Updated
├── pubspec.yaml
└── README.md
```

### Plugin Packages

#### `quicui_supabase` (Supabase Backend Plugin)
- **Purpose:** Supabase implementation of DataSource
- **Dependency:** quicui, supabase_flutter
- **Provides:** SupabaseDataSource, SupabaseRealtimeSource

**File Structure:**
```
quicui_supabase/
├── lib/src/
│   ├── supabase_data_source.dart        # Implementation
│   ├── supabase_realtime_source.dart    # Real-time impl
│   ├── models/
│   │   └── supabase_config.dart
│   ├── services/
│   │   └── supabase_service.dart        # Moved from core
│   └── extensions/
│       └── quicui_supabase_init.dart    # Setup helpers
├── example/
│   ├── lib/
│   │   └── main.dart
│   └── pubspec.yaml
├── pubspec.yaml
└── README.md
```

#### `quicui_firebase` (Firebase Backend Plugin - Future)
- **Purpose:** Firebase implementation of DataSource
- **Dependency:** quicui, firebase_core, cloud_firestore
- **Provides:** FirebaseDataSource, FirebaseRealtimeSource

#### `quicui_custom` (Custom Backend Template - Future)
- **Purpose:** Template for implementing custom backends
- **Dependency:** quicui
- **Provides:** Example implementation

---

## 🔌 Plugin Contract (Interfaces)

### DataSource Interface

```dart
/// Abstract interface for backend data sources
/// 
/// All backend plugins must implement this interface
abstract class DataSource {
  
  /// ==================== Screen Operations ====================
  
  /// Fetch a single screen by ID
  Future<Screen> fetchScreen(String screenId);
  
  /// Fetch multiple screens
  /// 
  /// [limit] - Number of screens to fetch (default: 20)
  /// [offset] - Pagination offset (default: 0)
  Future<List<Screen>> fetchScreens({
    int limit = 20,
    int offset = 0,
  });
  
  /// Save/update a screen
  /// 
  /// If [screenId] exists, updates it. Otherwise, creates new.
  Future<void> saveScreen(String screenId, Screen screen);
  
  /// Delete a screen
  Future<void> deleteScreen(String screenId);
  
  /// ==================== Search & Query ====================
  
  /// Search screens by query
  Future<List<Screen>> searchScreens(String query);
  
  /// Get total screen count
  Future<int> getScreenCount();
  
  /// ==================== Sync Operations ====================
  
  /// Synchronize pending items with backend
  /// 
  /// Called when app goes back online
  /// 
  /// Returns list of conflict cases
  Future<SyncResult> syncData(List<SyncItem> pendingItems);
  
  /// Get pending items waiting to sync
  Future<List<SyncItem>> getPendingItems();
  
  /// Resolve a sync conflict
  /// 
  /// Called when local and remote versions differ
  Future<ConflictResolution> resolveConflict(ConflictCase conflict);
  
  /// ==================== Connection ====================
  
  /// Establish connection to backend
  Future<void> connect();
  
  /// Close connection
  Future<void> disconnect();
  
  /// Check if connected
  Future<bool> isConnected();
  
  /// ==================== Realtime (Optional) ====================
  
  /// Subscribe to screen changes
  /// 
  /// Returns stream of real-time events
  Stream<RealtimeEvent<Screen>> subscribeToScreen(String screenId);
  
  /// Unsubscribe from screen updates
  Future<void> unsubscribe(String screenId);
}
```

### RealtimeSource Interface

```dart
/// Abstract interface for real-time data updates
abstract class RealtimeSource {
  
  /// Subscribe to screen events
  Stream<RealtimeEvent<Screen>> onScreenChanged(String screenId);
  
  /// Subscribe to screen creation
  Stream<Screen> onScreenCreated();
  
  /// Subscribe to screen deletion
  Stream<String> onScreenDeleted();
  
  /// All events stream
  Stream<RealtimeEvent> allEvents();
}
```

### Model Classes

```dart
// Sync result after backend synchronization
class SyncResult extends Equatable {
  final int synced;              // Items successfully synced
  final int failed;              // Items that failed
  final List<SyncError> errors;  // Error details
  
  const SyncResult({
    required this.synced,
    required this.failed,
    required this.errors,
  });
}

// Real-time event from backend
class RealtimeEvent<T> extends Equatable {
  final EventType type;          // INSERT, UPDATE, DELETE
  final T data;                  // Changed data
  final DateTime timestamp;      // When change occurred
  final String? userId;          // Who made the change
  
  const RealtimeEvent({
    required this.type,
    required this.data,
    required this.timestamp,
    this.userId,
  });
}

enum EventType { insert, update, delete }
```

---

## 🚀 Plugin Implementation Guide

### Step 1: Create Package Structure

```bash
# Create new plugin package
flutter create --template=plugin quicui_firebase

# Organize directory structure
mkdir -p lib/src/{models,services,extensions}
```

### Step 2: Implement DataSource

```dart
/// firebase/lib/src/firebase_data_source.dart
import 'package:quicui/quicui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSource implements DataSource {
  final FirebaseFirestore _firestore;
  
  FirebaseDataSource(this._firestore);
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    final doc = await _firestore
        .collection('screens')
        .doc(screenId)
        .get();
    
    if (!doc.exists) {
      throw ScreenNotFoundException('Screen not found: $screenId');
    }
    
    return Screen.fromJson(doc.data()!);
  }
  
  @override
  Future<void> saveScreen(String screenId, Screen screen) async {
    await _firestore
        .collection('screens')
        .doc(screenId)
        .set(screen.toJson(), SetOptions(merge: true));
  }
  
  @override
  Future<List<Screen>> searchScreens(String query) async {
    final querySnapshot = await _firestore
        .collection('screens')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .get();
    
    return querySnapshot.docs
        .map((doc) => Screen.fromJson(doc.data()))
        .toList();
  }
  
  // ... implement other methods
}
```

### Step 3: Create Initialization Helper

```dart
/// firebase/lib/src/extensions/quicui_firebase_init.dart
import 'package:quicui/quicui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension QuicUIFirebaseInit on QuicUI {
  /// Initialize QuicUI with Firebase backend
  static Future<void> initFirebase({
    required FirebaseOptions options,
  }) async {
    // Initialize Firebase
    await Firebase.initializeApp(options: options);
    
    // Create and register data source
    final dataSource = FirebaseDataSource(FirebaseFirestore.instance);
    DataSourceProvider.register(dataSource);
    
    // Initialize QuicUI
    await QuicUI.initialize();
  }
}
```

### Step 4: Create Example App

```dart
/// firebase/example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';
import 'package:quicui_firebase/quicui_firebase.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize QuicUI with Firebase
  await QuicUI.initFirebase(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI + Firebase',
      home: const ScreenListPage(),
    );
  }
}
```

---

## 🔗 Registering a Plugin

### Method 1: Using DataSourceProvider (Recommended)

```dart
import 'package:quicui/quicui.dart';
import 'package:quicui_supabase/quicui_supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register Supabase as backend
  final dataSource = SupabaseDataSource(supabaseClient);
  DataSourceProvider.register(dataSource);
  
  // Initialize QuicUI
  await QuicUI.initialize();
  
  runApp(const MyApp());
}
```

### Method 2: Using Plugin Helper Extension

```dart
import 'package:quicui/quicui.dart';
import 'package:quicui_supabase/quicui_supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use Supabase plugin's initialization helper
  await QuicUI.initSupabase(
    url: 'https://xxx.supabase.co',
    anonKey: 'xxx',
  );
  
  runApp(const MyApp());
}
```

### Method 3: Custom Backend Implementation

```dart
import 'package:quicui/quicui.dart';

/// Your custom backend implementation
class CustomBackendDataSource implements DataSource {
  // Implement all abstract methods...
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register custom backend
  DataSourceProvider.register(CustomBackendDataSource());
  
  await QuicUI.initialize();
  
  runApp(const MyApp());
}
```

---

## 🧪 Testing Plugins

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';
import 'package:quicui_firebase/quicui_firebase.dart';

void main() {
  group('FirebaseDataSource', () {
    late FirebaseDataSource dataSource;
    late MockFirestore mockFirestore;
    
    setUp(() {
      mockFirestore = MockFirestore();
      dataSource = FirebaseDataSource(mockFirestore);
    });
    
    test('fetchScreen returns Screen', () async {
      // Arrange
      const screenId = 'test-screen';
      final expectedScreen = Screen(
        id: screenId,
        name: 'Test Screen',
        // ...
      );
      
      when(mockFirestore.collection('screens'))
          .thenReturn(mockCollection);
      // ... setup mock
      
      // Act
      final result = await dataSource.fetchScreen(screenId);
      
      // Assert
      expect(result, expectedScreen);
    });
  });
}
```

### Integration Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Firebase Integration Tests', () {
    late FirebaseDataSource dataSource;
    
    setUpAll(() async {
      // Initialize Firebase
      await Firebase.initializeApp();
      dataSource = FirebaseDataSource(FirebaseFirestore.instance);
    });
    
    testWidgets('Full sync cycle', (WidgetTester tester) async {
      // Test end-to-end sync
    });
  });
}
```

---

## 📋 Plugin Checklist

Before publishing a plugin:

- [ ] Implements all `DataSource` interface methods
- [ ] Comprehensive error handling
- [ ] Full test coverage (80%+)
- [ ] Example app included
- [ ] README with setup instructions
- [ ] API documentation
- [ ] Handles offline scenarios
- [ ] Implements conflict resolution
- [ ] Real-time updates support (if applicable)
- [ ] Security best practices
- [ ] Performance optimizations
- [ ] Published on pub.dev

---

## 🔄 Plugin Lifecycle

### 1. Discovery
User finds plugin on pub.dev or GitHub

### 2. Installation
```yaml
# pubspec.yaml
dependencies:
  quicui: ^2.0.0
  quicui_firebase: ^2.0.0
```

### 3. Initialization
```dart
await QuicUI.initFirebase(options: options);
```

### 4. Usage
```dart
// Plugin automatically provides backend communication
final screens = await repository.getScreens();
```

### 5. Updates
Plugin updates independently without affecting QuicUI core

---

## 📊 Plugin Ecosystem Roadmap

```
v2.0.0 - Core Separation + Supabase Plugin
├── quicui (core)
└── quicui_supabase (stable)

v2.1.0 - Firebase Plugin Release
├── quicui (core)
├── quicui_supabase (stable)
└── quicui_firebase (new)

v2.2.0 - AWS Amplify Plugin Release
├── quicui (core)
├── quicui_supabase (stable)
├── quicui_firebase (stable)
└── quicui_amplify (new)

v3.0.0+ - Community Plugins
├── quicui (core)
├── Official plugins (supabase, firebase, amplify)
└── Community plugins (custom backends, GraphQL, etc.)
```

---

## 🎓 Best Practices

### For Plugin Developers
1. Follow Dart/Flutter conventions
2. Comprehensive error handling
3. Offline support when possible
4. Real-time features when available
5. Security best practices
6. Thorough documentation
7. Examples for common use cases
8. Active maintenance

### For Plugin Users
1. Use stable versions
2. Check plugin documentation
3. Implement proper error handling
4. Handle offline scenarios
5. Monitor performance
6. Report issues
7. Contribute improvements

---

**Architecture Version:** 2.0.0  
**Status:** 📋 Planned for Implementation  
**Next:** Begin Phase 1 (Define Interfaces)

