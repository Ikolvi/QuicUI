# Custom Callbacks Guide

Advanced guide to implementing and using custom named callbacks in QuicUI applications.

## Table of Contents

1. [Overview](#overview)
2. [Basic Usage](#basic-usage)
3. [Advanced Patterns](#advanced-patterns)
4. [Error Handling](#error-handling)
5. [API Integration](#api-integration)
6. [Best Practices](#best-practices)
7. [Examples](#examples)

---

## Overview

Custom callbacks allow you to:

- **Execute custom logic** triggered from JSON widgets
- **Perform validation** before navigation
- **Make API calls** and handle responses
- **Update app state** based on business logic
- **Chain operations** with conditional branching
- **Handle errors** gracefully

### Callback vs. Built-in Actions

**Built-in Actions** (in JSON):
- `navigate` - Simple screen navigation
- `navigateToFlow` - Navigate to different flow
- `updateNavigationData` - Update session data
- `goBack` - Navigate back

**Custom Callbacks** (Dart code):
- Complex validation logic
- API calls and network operations
- Database operations
- Encryption/decryption
- Conditional logic
- Multi-step workflows

---

## Basic Usage

### 1. Register a Callback

In `main.dart` before app initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register simple callback
  CallbackRegistry.registerCallback('sayHello', (params) {
    print('Hello ${params?['name']}!');
  });
  
  // Register async callback
  CallbackRegistry.registerCallback('fetchData', (params) async {
    final data = await api.getData();
    return data;
  });
  
  runApp(QuicUIMultiFlowApp(...));
}
```

### 2. Call from JSON

In your JSON screen:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Say Hello",
    "events": {
      "onPressed": {
        "action": "executeCallback",
        "callbackName": "sayHello",
        "params": {
          "name": "${fields.fullName}"
        }
      }
    }
  }
}
```

### 3. Handle Response

Callbacks can return values and trigger navigation:

```dart
CallbackRegistry.registerCallback('validateEmail', (params) async {
  final email = params?['email'];
  
  // Validation
  if (!email.contains('@')) {
    throw Exception('Invalid email format');
  }
  
  // Success - update data
  NavigationDataManager.setSessionData('email', email);
  return {'success': true, 'email': email};
});
```

---

## Advanced Patterns

### Async Callbacks with API Calls

```dart
CallbackRegistry.registerCallback('loginUser', (params) async {
  try {
    final email = params?['email'];
    final password = params?['password'];
    
    // Validate inputs
    if (email == null || password == null) {
      throw Exception('Email and password required');
    }
    
    // Show loading indicator (optional)
    // loader.show();
    
    // Make API call
    final response = await apiClient.post('/api/login', body: {
      'email': email,
      'password': password,
    });
    
    // Parse response
    final userData = response['data'];
    
    // Store session data
    NavigationDataManager.mergeSessionData({
      'userId': userData['id'],
      'token': response['token'],
      'username': userData['name'],
      'email': userData['email'],
      'loginTime': DateTime.now().toIso8601String(),
    });
    
    // Return success
    return {'success': true, 'user': userData};
  } catch (e) {
    // Log error
    LoggerUtil.error('Login failed', e, StackTrace.current);
    throw Exception('Login failed: $e');
  }
});
```

### Conditional Navigation

```dart
CallbackRegistry.registerCallback('checkUserRole', (params) async {
  final userId = params?['userId'];
  
  // Fetch user data
  final user = await apiClient.getUser(userId);
  
  // Navigate based on role
  if (user['role'] == 'admin') {
    FlowManager.navigateToFlow('admin', 'dashboard');
  } else if (user['role'] == 'moderator') {
    FlowManager.navigateToFlow('moderator', 'dashboard');
  } else {
    FlowManager.navigateToFlow('dashboard', 'home');
  }
});
```

### Chained Callbacks

```dart
CallbackRegistry.registerCallback('completeSignup', (params) async {
  // Step 1: Validate form
  if (!_isFormValid(params)) {
    throw Exception('Form validation failed');
  }
  
  // Step 2: Create user account
  final user = await apiClient.createUser({
    'name': params?['fullName'],
    'email': params?['email'],
    'password': params?['password'],
  });
  
  // Step 3: Send verification email
  await emailService.sendVerificationEmail(user['email']);
  
  // Step 4: Store in session
  NavigationDataManager.mergeSessionData({
    'newUserId': user['id'],
    'newUserEmail': user['email'],
  });
  
  // Step 5: Navigate to next step
  FlowManager.navigateToFlow('auth', 'verify_email', data: {
    'userId': user['id'],
    'email': user['email'],
  });
  
  return {'success': true};
});
```

### With Retry Logic

```dart
CallbackRegistry.registerCallback('fetchWithRetry', (params) async {
  int maxRetries = 3;
  int retryCount = 0;
  
  while (retryCount < maxRetries) {
    try {
      final data = await apiClient.getData();
      return {'success': true, 'data': data};
    } catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) {
        throw Exception('Failed after $maxRetries retries');
      }
      // Wait before retry
      await Future.delayed(Duration(seconds: 2));
    }
  }
});
```

---

## Error Handling

### Try-Catch Pattern

```dart
CallbackRegistry.registerCallback('safeOperation', (params) async {
  try {
    // Perform operation
    final result = await performOperation(params);
    return result;
  } on TimeoutException catch (e) {
    LoggerUtil.error('Timeout during operation', e);
    throw Exception('Request timed out. Please try again.');
  } on NetworkException catch (e) {
    LoggerUtil.error('Network error', e);
    throw Exception('Network error. Check your connection.');
  } catch (e) {
    LoggerUtil.error('Unexpected error', e, StackTrace.current);
    throw Exception('Something went wrong. Please try again.');
  }
});
```

### Error Handling in JSON

Callbacks should throw exceptions, which are handled by the framework:

```dart
// In JSON, handle error by showing message or navigating
CallbackRegistry.registerCallback('handleError', (params) async {
  try {
    await riskyOperation();
  } catch (e) {
    // Log error
    LoggerUtil.error('Operation failed', e);
    
    // Optionally navigate to error screen
    FlowManager.navigateToFlow('errors', 'errorDetail', data: {
      'error': e.toString(),
      'previousFlow': FlowManager.getCurrentFlowId(),
    });
    
    rethrow; // Re-throw to propagate error
  }
});
```

---

## API Integration

### REST API Calls

```dart
CallbackRegistry.registerCallback('fetchUserProfile', (params) async {
  final userId = params?['userId'];
  
  final response = await httpClient.get(
    '/api/users/$userId',
    headers: {
      'Authorization': 'Bearer ${NavigationDataManager.getSessionData('token')}',
    },
  );
  
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch profile');
  }
  
  final profile = jsonDecode(response.body)['data'];
  NavigationDataManager.setSessionData('userProfile', profile);
  
  return profile;
});
```

### GraphQL Queries

```dart
CallbackRegistry.registerCallback('graphqlQuery', (params) async {
  final query = '''
    query GetUser(\$id: ID!) {
      user(id: \$id) {
        id
        name
        email
      }
    }
  ''';
  
  final result = await graphqlClient.query(
    QueryOptions(
      document: gql(query),
      variables: {'id': params?['userId']},
    ),
  );
  
  if (result.hasException) {
    throw result.exception!;
  }
  
  return result.data;
});
```

### File Upload

```dart
CallbackRegistry.registerCallback('uploadFile', (params) async {
  final filePath = params?['filePath'];
  final file = File(filePath);
  
  final request = MultipartRequest('POST', Uri.parse('/api/upload'))
    ..files.add(await MultipartFile.fromPath('file', file.path));
  
  final response = await request.send();
  
  if (response.statusCode != 200) {
    throw Exception('File upload failed');
  }
  
  return {'success': true, 'url': response.toString()};
});
```

---

## Best Practices

### 1. Naming Conventions

```dart
// Good names
'validateEmail'
'loginUser'
'fetchUserProfile'
'uploadFile'
'syncData'

// Avoid unclear names
'doStuff'
'process'
'handle'
'callback'
```

### 2. Input Validation

```dart
CallbackRegistry.registerCallback('processPayment', (params) async {
  // Always validate inputs
  final amount = params?['amount'];
  final currency = params?['currency'];
  
  if (amount == null || amount <= 0) {
    throw Exception('Invalid amount');
  }
  
  if (currency == null || currency.isEmpty) {
    throw Exception('Currency required');
  }
  
  // Process payment...
});
```

### 3. Documentation

```dart
/// Register callbacks at app startup
void _registerCallbacks() {
  /// Authenticates user with email and password
  /// 
  /// Params:
  /// - email: User email address
  /// - password: User password
  /// 
  /// Returns: {userId, token, username}
  /// 
  /// Throws: Exception if authentication fails
  CallbackRegistry.registerCallback('authenticateUser', (params) async {
    // Implementation...
  });
}
```

### 4. Logging

```dart
CallbackRegistry.registerCallback('complexOperation', (params) async {
  LoggerUtil.info('Starting complex operation');
  LoggerUtil.debug('Params: $params');
  
  try {
    final result = await perform(params);
    LoggerUtil.info('Operation completed successfully');
    return result;
  } catch (e) {
    LoggerUtil.error('Operation failed', e, StackTrace.current);
    rethrow;
  }
});
```

### 5. Testing

```dart
// Unit test for callback
test('validateEmail throws on invalid format', () {
  expect(
    () => executeCallback('validateEmail', params: {'email': 'invalid'}),
    throwsException,
  );
});

// Integration test
testWidgets('Callback updates navigation data', (tester) async {
  await tester.pumpWidget(app);
  
  // Trigger callback
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  // Verify data updated
  final data = NavigationDataManager.getSessionData('key');
  expect(data, isNotNull);
});
```

---

## Examples

### Example 1: Login Callback

```dart
CallbackRegistry.registerCallback('loginUser', (params) async {
  final email = params?['email'];
  final password = params?['password'];
  
  if (email == null || password == null) {
    throw Exception('Email and password required');
  }
  
  try {
    final response = await apiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    
    final token = response['token'];
    final user = response['user'];
    
    // Store authentication data
    NavigationDataManager.mergeSessionData({
      'token': token,
      'userId': user['id'],
      'username': user['name'],
      'email': user['email'],
    });
    
    // Save token securely
    await secureStorage.write(key: 'auth_token', value: token);
    
    return {'success': true};
  } on TimeoutException {
    throw Exception('Request timeout - check your connection');
  } on SocketException {
    throw Exception('Network error - check your internet connection');
  }
});
```

### Example 2: Sync Callback

```dart
CallbackRegistry.registerCallback('syncUserData', (params) async {
  final userId = NavigationDataManager.getSessionData('userId');
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  try {
    // Fetch from server
    final response = await apiClient.get('/api/users/$userId');
    final userData = response['data'];
    
    // Update local cache
    await database.updateUser(userData);
    
    // Update session
    NavigationDataManager.mergeSessionData({'userData': userData});
    
    return {'success': true, 'syncedAt': DateTime.now()};
  } catch (e) {
    LoggerUtil.warning('Sync failed', e);
    // Return cached data or error
    throw Exception('Failed to sync data');
  }
});
```

### Example 3: Form Submission

```dart
CallbackRegistry.registerCallback('submitForm', (params) async {
  // Validate each field
  final name = params?['name'];
  final email = params?['email'];
  final message = params?['message'];
  
  if (name?.isEmpty ?? true) {
    throw Exception('Name is required');
  }
  if (email?.isEmpty ?? true) {
    throw Exception('Email is required');
  }
  if (!email.contains('@')) {
    throw Exception('Invalid email format');
  }
  if (message?.isEmpty ?? true) {
    throw Exception('Message is required');
  }
  
  // Submit form
  final response = await apiClient.post('/api/contact', body: {
    'name': name,
    'email': email,
    'message': message,
  });
  
  // Navigate to success screen
  FlowManager.navigateToFlow('confirmation', 'success', data: {
    'submitId': response['id'],
    'email': email,
  });
  
  return {'success': true};
});
```

---

## Troubleshooting

### Callback Not Registered

**Problem:** "Callback not registered: xyz"

**Solution:** Register callback before app launches, in `main()` before `runApp()`

### Callback Receives Null Params

**Problem:** `params` is null even though data was passed

**Solution:** Data is passed as `params` map. Access with `params?['key']`

### Navigation Not Working from Callback

**Problem:** `FlowManager.navigateToFlow()` doesn't navigate

**Solution:** Ensure `FlowManager` is initialized. Better: Return from callback and let main app handle navigation

### Async Not Awaiting

**Problem:** Callback completes before async operation finishes

**Solution:** Always `await` async calls, and declare callback as `async`

### Error Not Being Thrown

**Problem:** Exception in callback doesn't show error to user

**Solution:** Framework catches exceptions. Explicitly handle them in JSON or custom error handling

