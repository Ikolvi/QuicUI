# DataSource API Reference

Complete reference documentation for all DataSource interface methods, parameters, return types, and exception handling.

## Table of Contents

- [Screen Management](#screen-management)
- [User Management](#user-management)
- [Component Management](#component-management)
- [Real-Time Subscriptions](#real-time-subscriptions)
- [Mutations](#mutations)
- [Offline Sync](#offline-sync)
- [Exception Hierarchy](#exception-hierarchy)
- [Data Models](#data-models)

---

## Screen Management

### fetchScreen(String screenId)

Fetches a single screen by ID.

**Signature:**
```dart
Future<Screen> fetchScreen(String screenId)
```

**Parameters:**
- `screenId` (String, required): Unique identifier of the screen to fetch

**Returns:**
- `Future<Screen>`: A Screen object containing all screen data

**Throws:**
- `ScreenNotFoundException`: When screen with given ID doesn't exist
- `DataSourceException`: For other backend errors
- `NetworkException`: On connectivity issues

**Example:**
```dart
try {
  final screen = await dataSource.fetchScreen('home-screen');
  print('Screen name: ${screen.name}');
  print('Widgets count: ${screen.widgets.length}');
} on ScreenNotFoundException {
  print('Screen not found');
} on DataSourceException catch (e) {
  print('Error fetching screen: ${e.message}');
}
```

**Implementation Notes:**
- Method should validate that `screenId` is not empty
- Should return complete Screen object with all nested data
- Consider caching for performance
- Should handle 404 responses as ScreenNotFoundException

---

### fetchScreensByTag(String tag)

Fetches all screens matching a specific tag.

**Signature:**
```dart
Future<List<Screen>> fetchScreensByTag(String tag)
```

**Parameters:**
- `tag` (String, required): Tag to filter screens by (e.g., "onboarding", "dashboard")

**Returns:**
- `Future<List<Screen>>`: List of Screen objects matching the tag (may be empty)

**Throws:**
- `DataSourceException`: For backend errors
- `NetworkException`: On connectivity issues

**Example:**
```dart
try {
  final screens = await dataSource.fetchScreensByTag('onboarding');
  print('Found ${screens.length} onboarding screens');
  
  for (final screen in screens) {
    print('  - ${screen.name}');
  }
} on DataSourceException catch (e) {
  print('Error fetching screens: ${e.message}');
}
```

**Implementation Notes:**
- Should return empty list if no screens match tag
- Consider pagination for large result sets
- Tag matching should be case-insensitive
- Should be efficient for frequently-used tags

---

## User Management

### fetchUser(String userId)

Fetches a single user by ID.

**Signature:**
```dart
Future<User> fetchUser(String userId)
```

**Parameters:**
- `userId` (String, required): Unique identifier of the user to fetch

**Returns:**
- `Future<User>`: A User object containing all user data

**Throws:**
- `UserNotFoundException`: When user with given ID doesn't exist
- `DataSourceException`: For other backend errors
- `NetworkException`: On connectivity issues

**Example:**
```dart
try {
  final user = await dataSource.fetchUser('user-123');
  print('Username: ${user.username}');
  print('Email: ${user.email}');
} on UserNotFoundException {
  print('User not found');
} on DataSourceException catch (e) {
  print('Error fetching user: ${e.message}');
}
```

**Implementation Notes:**
- Should validate that `userId` is not empty
- Consider caching user data
- May need to handle permission checks
- Should not expose sensitive data (passwords, tokens, etc.)

---

### fetchUsers()

Fetches all users in the system.

**Signature:**
```dart
Future<List<User>> fetchUsers()
```

**Parameters:**
- None

**Returns:**
- `Future<List<User>>`: List of all User objects

**Throws:**
- `DataSourceException`: For backend errors
- `NetworkException`: On connectivity issues
- `PermissionException`: If current user lacks permission

**Example:**
```dart
try {
  final users = await dataSource.fetchUsers();
  print('Found ${users.length} users');
  
  for (final user in users) {
    print('  - ${user.username} (${user.email})');
  }
} on PermissionException {
  print('Not authorized to fetch users');
} on DataSourceException catch (e) {
  print('Error fetching users: ${e.message}');
}
```

**Implementation Notes:**
- May require admin permissions
- Consider pagination for large result sets
- Should be efficient and cacheable
- May need to filter results based on permissions

---

## Component Management

### fetchComponent(String componentId)

Fetches a single component by ID.

**Signature:**
```dart
Future<Component> fetchComponent(String componentId)
```

**Parameters:**
- `componentId` (String, required): Unique identifier of the component to fetch

**Returns:**
- `Future<Component>`: A Component object containing all component data

**Throws:**
- `ComponentNotFoundException`: When component with given ID doesn't exist
- `DataSourceException`: For other backend errors
- `NetworkException`: On connectivity issues

**Example:**
```dart
try {
  final component = await dataSource.fetchComponent('button-primary');
  print('Component: ${component.name}');
  print('Type: ${component.type}');
} on ComponentNotFoundException {
  print('Component not found');
} on DataSourceException catch (e) {
  print('Error fetching component: ${e.message}');
}
```

**Implementation Notes:**
- Components are building blocks for screens
- Should be cached for performance
- May have nested component definitions
- Consider lazy-loading component definitions

---

### fetchComponents()

Fetches all components in the system.

**Signature:**
```dart
Future<List<Component>> fetchComponents()
```

**Parameters:**
- None

**Returns:**
- `Future<List<Component>>`: List of all Component objects

**Throws:**
- `DataSourceException`: For backend errors
- `NetworkException`: On connectivity issues

**Example:**
```dart
try {
  final components = await dataSource.fetchComponents();
  print('Found ${components.length} components');
  
  // Index components by ID for quick lookup
  final componentMap = {
    for (final c in components) c.id: c
  };
} on DataSourceException catch (e) {
  print('Error fetching components: ${e.message}');
}
```

**Implementation Notes:**
- Should cache aggressively - components change rarely
- Consider versioning for component updates
- May need to return only public/published components
- Should be efficient for initial app load

---

## Real-Time Subscriptions

### subscribeToScreen(String screenId)

Subscribes to real-time changes for a specific screen.

**Signature:**
```dart
Stream<Screen> subscribeToScreen(String screenId)
```

**Parameters:**
- `screenId` (String, required): ID of the screen to subscribe to

**Returns:**
- `Stream<Screen>`: Stream that emits Screen objects when data changes

**Throws:**
- `ScreenNotFoundException`: If screen doesn't exist (may emit as error in stream)
- `DataSourceException`: For backend errors (emitted to stream)

**Example:**
```dart
final screenStream = dataSource.subscribeToScreen('home-screen');

streamSubscription = screenStream.listen(
  (updatedScreen) {
    // React to screen changes
    print('Screen updated: ${updatedScreen.lastModified}');
    // Update UI/BLoC
  },
  onError: (error) {
    print('Stream error: $error');
  },
  onDone: () {
    print('Stream closed');
  },
);

// Don't forget to cancel when done
await streamSubscription.cancel();
```

**Implementation Notes:**
- Should establish real-time connection (WebSocket, listener, etc.)
- First emission should be current screen state
- Should handle connection interruptions
- Should clean up resources on cancel
- Consider implementing backoff for reconnection

---

### subscribeToUser(String userId)

Subscribes to real-time changes for a specific user.

**Signature:**
```dart
Stream<User> subscribeToUser(String userId)
```

**Parameters:**
- `userId` (String, required): ID of the user to subscribe to

**Returns:**
- `Stream<User>`: Stream that emits User objects when data changes

**Throws:**
- `UserNotFoundException`: If user doesn't exist (may emit as error)
- `DataSourceException`: For backend errors (emitted to stream)
- `PermissionException`: If not authorized to subscribe (may emit as error)

**Example:**
```dart
final userStream = dataSource.subscribeToUser('current-user-id');

final subscription = userStream.listen(
  (updatedUser) {
    print('User profile updated');
    // Update profile UI
  },
  onError: (error) => print('Error: $error'),
);

// Clean up
userSubscription.cancel();
```

**Implementation Notes:**
- Often used for current user monitoring
- Should handle permission-based access
- First emission should be current user state
- Should secure subscription (only user can subscribe to own data)

---

### subscribeToComponent(String componentId)

Subscribes to real-time changes for a specific component.

**Signature:**
```dart
Stream<Component> subscribeToComponent(String componentId)
```

**Parameters:**
- `componentId` (String, required): ID of the component to subscribe to

**Returns:**
- `Stream<Component>`: Stream that emits Component objects when data changes

**Throws:**
- `ComponentNotFoundException`: If component doesn't exist (may emit as error)
- `DataSourceException`: For backend errors (emitted to stream)

**Example:**
```dart
final componentStream = dataSource.subscribeToComponent('button-primary');

final subscription = componentStream.listen(
  (updatedComponent) {
    print('Component design changed');
    // Hot-reload component in running app
  },
  onError: (error) => print('Error: $error'),
);

// Clean up
subscription.cancel();
```

**Implementation Notes:**
- Useful for live design system updates
- Components change less frequently than screens
- May want to batch multiple component changes
- Consider caching latest state for new subscribers

---

## Mutations

### updateScreen(String screenId, Map<String, dynamic> data)

Updates screen data on the backend.

**Signature:**
```dart
Future<Screen> updateScreen(String screenId, Map<String, dynamic> data)
```

**Parameters:**
- `screenId` (String, required): ID of the screen to update
- `data` (Map<String, dynamic>, required): Fields to update
  - Supported keys depend on backend (typically: name, description, widgets, config, etc.)

**Returns:**
- `Future<Screen>`: Updated Screen object from backend

**Throws:**
- `ScreenNotFoundException`: If screen doesn't exist
- `ValidationException`: If data is invalid
- `DataSourceException`: For other backend errors
- `NetworkException`: On connectivity issues
- `SyncException`: If offline - data is queued

**Example:**
```dart
try {
  final updated = await dataSource.updateScreen('home-screen', {
    'name': 'New Home Screen Name',
    'description': 'Updated description',
  });
  
  print('Updated: ${updated.lastModified}');
} on ValidationException catch (e) {
  print('Invalid data: ${e.message}');
} on SyncException {
  print('Offline - changes queued for sync');
}
```

**Implementation Notes:**
- Should validate data before sending
- Should return updated Screen from backend
- May need to handle partial updates
- Should queue changes if offline
- Should broadcast update via subscriptions
- Consider optimistic UI updates

---

### updateUser(String userId, Map<String, dynamic> data)

Updates user data on the backend.

**Signature:**
```dart
Future<User> updateUser(String userId, Map<String, dynamic> data)
```

**Parameters:**
- `userId` (String, required): ID of the user to update
- `data` (Map<String, dynamic>, required): Fields to update
  - Supported keys: username, email, preferences, profile, etc.

**Returns:**
- `Future<User>`: Updated User object from backend

**Throws:**
- `UserNotFoundException`: If user doesn't exist
- `ValidationException`: If data is invalid
- `PermissionException`: If not authorized to update
- `DataSourceException`: For other backend errors
- `SyncException`: If offline - data is queued

**Example:**
```dart
try {
  final updated = await dataSource.updateUser('user-123', {
    'email': 'newemail@example.com',
    'preferences': {
      'theme': 'dark',
      'language': 'es',
    },
  });
  
  print('User updated: ${updated.email}');
} on PermissionException {
  print('Cannot update other user data');
} on SyncException {
  print('Changes queued for sync');
}
```

**Implementation Notes:**
- May have permission restrictions (can only update own data)
- Should validate data format
- Sensitive data (password) should require special handling
- Should broadcast update via subscriptions
- Should queue changes if offline

---

### updateComponent(String componentId, Map<String, dynamic> data)

Updates component data on the backend.

**Signature:**
```dart
Future<Component> updateComponent(String componentId, Map<String, dynamic> data)
```

**Parameters:**
- `componentId` (String, required): ID of the component to update
- `data` (Map<String, dynamic>, required): Fields to update
  - Supported keys: name, type, properties, styles, etc.

**Returns:**
- `Future<Component>`: Updated Component object from backend

**Throws:**
- `ComponentNotFoundException`: If component doesn't exist
- `ValidationException`: If data is invalid
- `PermissionException`: If not authorized to update
- `DataSourceException`: For other backend errors
- `SyncException`: If offline - data is queued

**Example:**
```dart
try {
  final updated = await dataSource.updateComponent('button-primary', {
    'properties': {
      'borderRadius': 8,
      'fontSize': 14,
    },
  });
  
  print('Component updated');
} on ValidationException catch (e) {
  print('Invalid component data: ${e.message}');
}
```

**Implementation Notes:**
- Usually requires admin/designer permissions
- Should validate component structure
- Changes should be reflected in running apps via subscriptions
- Should version components for backward compatibility
- Should queue changes if offline

---

## Offline Sync

### syncOfflineChanges()

Syncs any changes made while offline with the backend.

**Signature:**
```dart
Future<void> syncOfflineChanges()
```

**Parameters:**
- None

**Returns:**
- `Future<void>`: Completes when sync is done

**Throws:**
- `SyncException`: If sync fails (with details about which changes failed)
- `DataSourceException`: For backend errors
- `NetworkException`: If still no connectivity

**Example:**
```dart
try {
  // App was offline, made some changes
  await dataSource.updateScreen('screen-1', {'name': 'New Name'});
  
  // Later, when connectivity returns
  await dataSource.syncOfflineChanges();
  print('✓ All changes synced');
  
} on SyncException catch (e) {
  print('Sync failed: ${e.message}');
  print('Failed items: ${e.failedItems}');
}
```

**Implementation Notes:**
- Should process queued changes in order
- Should handle conflicts (user edits vs. remote changes)
- Should provide detailed failure information
- Should retry failed items or provide UI for resolution
- Should emit progress/completion events
- Should clear queue on successful sync

---

### getOfflineQueue()

Retrieves the queue of changes waiting to be synced.

**Signature:**
```dart
Future<List<Map<String, dynamic>>> getOfflineQueue()
```

**Parameters:**
- None

**Returns:**
- `Future<List<Map<String, dynamic>>>`: List of queued changes
  - Each item has: `operation`, `entityId`, `data`, `timestamp`, `status`

**Throws:**
- `DataSourceException`: For backend errors

**Example:**
```dart
try {
  final queue = await dataSource.getOfflineQueue();
  
  print('Pending changes: ${queue.length}');
  for (final item in queue) {
    print('  - ${item['operation']} on ${item['entityId']}');
    print('    Status: ${item['status']}');
  }
  
  // Show UI indicator if there are pending changes
  if (queue.isNotEmpty) {
    showSyncingIndicator();
  }
  
} on DataSourceException catch (e) {
  print('Error fetching queue: ${e.message}');
}
```

**Implementation Notes:**
- Useful for showing sync status to user
- Should include timestamp for each queued item
- Should show operation type (create, update, delete)
- Should show retry attempts
- Can be used to implement retry UI

---

## Exception Hierarchy

All exceptions inherit from `DataSourceException`:

```
DataSourceException (base class)
├── ScreenNotFoundException
├── UserNotFoundException
├── ComponentNotFoundException
├── NetworkException
├── ValidationException
├── PermissionException
├── SyncException
└── [Backend-specific exceptions]
```

### DataSourceException

Base class for all DataSource exceptions.

**Properties:**
- `message`: Human-readable error description
- `code`: Machine-readable error code
- `originalException`: Original exception from backend

**Example:**
```dart
try {
  await dataSource.fetchScreen('screen-1');
} on DataSourceException catch (e) {
  print('Error: ${e.message}');
  print('Code: ${e.code}');
  if (e.originalException != null) {
    print('Original: ${e.originalException}');
  }
}
```

### ScreenNotFoundException

Thrown when screen is not found.

```dart
on ScreenNotFoundException catch (e) {
  print('Screen not found: ${e.message}');
  // Show "Screen not found" UI
}
```

### UserNotFoundException

Thrown when user is not found.

```dart
on UserNotFoundException catch (e) {
  print('User not found: ${e.message}');
}
```

### ComponentNotFoundException

Thrown when component is not found.

```dart
on ComponentNotFoundException catch (e) {
  print('Component not found: ${e.message}');
}
```

### NetworkException

Thrown on network/connectivity issues.

```dart
on NetworkException catch (e) {
  print('Network error: ${e.message}');
  print('Retrying or queuing for offline...');
}
```

### ValidationException

Thrown when data validation fails.

```dart
on ValidationException catch (e) {
  print('Validation error: ${e.message}');
  // Show validation errors to user
}
```

### PermissionException

Thrown when user lacks permission.

```dart
on PermissionException catch (e) {
  print('Permission denied: ${e.message}');
  // Show "access denied" UI
}
```

### SyncException

Thrown when offline sync fails.

```dart
on SyncException catch (e) {
  print('Sync error: ${e.message}');
  // May have e.failedItems for partial failure
}
```

---

## Data Models

### Screen

Represents a UI screen/page in the design system.

**Properties:**
```dart
class Screen {
  final String id;
  final String name;
  final String? description;
  final List<WidgetData> widgets;
  final ScreenConfig? config;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime lastModified;
  final String version;
  final Map<String, dynamic>? metadata;
}
```

### User

Represents an application user.

**Properties:**
```dart
class User {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final Map<String, dynamic>? preferences;
  final List<String>? roles;
  final DateTime createdAt;
  final DateTime lastModified;
}
```

### Component

Represents a reusable UI component.

**Properties:**
```dart
class Component {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> properties;
  final Map<String, dynamic>? styles;
  final List<Component>? children;
  final String version;
  final DateTime createdAt;
  final DateTime lastModified;
}
```

---

## Best Practices

1. **Always Handle Exceptions**
   ```dart
   try {
     await dataSource.fetchScreen(id);
   } on ScreenNotFoundException {
     // Handle not found
   } on NetworkException {
     // Handle offline
   } catch (e) {
     // Handle unexpected
   }
   ```

2. **Clean Up Subscriptions**
   ```dart
   late StreamSubscription subscription;
   
   @override
   void initState() {
     subscription = dataSource.subscribeToScreen(id).listen(...);
   }
   
   @override
   void dispose() {
     subscription.cancel();
     super.dispose();
   }
   ```

3. **Use Immutable Data Models**
   - All returned objects should be immutable
   - Use `const` constructors where possible

4. **Implement Caching**
   - Cache frequently accessed screens/components
   - Invalidate cache on updates
   - Use time-based or change-based invalidation

5. **Handle Offline Gracefully**
   - Queue mutations when offline
   - Show sync status to user
   - Implement conflict resolution

6. **Validate Input**
   - Check for empty IDs
   - Validate data structure before mutations
   - Provide clear validation error messages

---

## See Also

- [Plugin Architecture Overview](PLUGIN_ARCHITECTURE.md)
- [Migration Guide](MIGRATION_GUIDE.md)
- [Backend Integration Guide](BACKEND_INTEGRATION.md)
