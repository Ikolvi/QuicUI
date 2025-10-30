# QuicUI API Key Management & Integration Guide

**How to provide API keys to apps and manage authentication**

---

## 📋 Overview

Each QuicUI app needs to be authenticated to use the QuicUI framework. This document covers:

- **API Key Generation** - Creating keys for apps
- **Key Types** - Different key purposes
- **Key Distribution** - How to securely share keys
- **Key Management** - Managing and rotating keys
- **Web Dashboard Integration** - Managing keys via web UI

---

## 🔑 Key Types

### 1. **App API Key** (For Supabase Backend Access)

Used by Flutter apps to:
- Register device
- Fetch UI screens
- Sync state
- Submit forms
- Subscribe to real-time updates

**Format:** UUID (auto-generated)  
**Scope:** Per app  
**Rotation:** Annual recommended  

### 2. **AI Agent Key** (For AI Integration)

Used by AI agents to:
- Generate UI from prompts
- Publish screens to devices
- Read app state
- Log actions
- Manage app config

**Format:** UUID (auto-generated)  
**Scope:** Per app  
**Rotation:** On compromise  

### 3. **Web Dashboard Key** (For Admin Access)

Used by web dashboard to:
- Manage apps
- Edit screens
- Monitor devices
- View analytics
- Manage keys

**Format:** Session-based (via Supabase Auth)  
**Scope:** Per user  
**Rotation:** Session timeout  

---

## 🚀 API Key Flow

```
┌──────────────────────────────────────────────────────┐
│         Web Dashboard (Admin)                        │
│  - Register new app                                 │
│  - Generate API keys                                │
│  - Display keys to admin                            │
└──────────────────────────────────────────────────────┘
              ▼ (Display QR code or copy)
┌──────────────────────────────────────────────────────┐
│         Admin/Developer                             │
│  - Receives API keys securely                       │
│  - Embeds in app config or env vars                │
│  - Keeps keys secret                               │
└──────────────────────────────────────────────────────┘
              ▼ (Via app installation)
┌──────────────────────────────────────────────────────┐
│         Flutter App                                 │
│  - Loads API key from config/env                   │
│  - Uses key for all Supabase requests             │
│  - Never exposes key in logs                       │
│  - Stores key securely (Keychain/Keystore)        │
└──────────────────────────────────────────────────────┘
```

---

## 🔐 API Key Security

### Best Practices

✅ **DO:**
- Store keys in secure storage (Keychain on iOS, Keystore on Android)
- Use environment variables for sensitive configs
- Rotate keys regularly (quarterly recommended)
- Use different keys for dev/staging/production
- Monitor key usage via dashboard
- Revoke compromised keys immediately

❌ **DON'T:**
- Commit API keys to version control
- Log API keys to console
- Share keys via unencrypted channels
- Use same key across environments
- Expose keys in app source code
- Store keys in SharedPreferences/UserDefaults

---

## 📱 Flutter App Integration

### Step 1: Configure App Keys

```dart
// lib/config/api_config.dart

class ApiConfig {
  // Main Supabase configuration
  static const String supabaseUrl = 'https://tzxaqatozdxgwhjphbrs.supabase.co';
  
  // App-specific API key (from web dashboard)
  // Store this securely or read from environment
  static const String appApiKey = 'your_app_api_key_here';
  
  // AI Agent key (if AI features enabled)
  static const String aiAgentKey = 'your_ai_agent_key_here';
  
  // Supabase Anon key (public, safe to expose)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6eGFxYXRvemR4Z3doanBoYnJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NDM1MDQsImV4cCI6MjA3NzMxOTUwNH0.ipdp9RP6ZDNgZR06yPb5YTaANOzvTE-1WrS-22ss7cU';
}
```

### Step 2: Secure Key Storage

```dart
// lib/services/secure_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  /// Save app API key securely
  static Future<void> saveAppApiKey(String key) async {
    await _storage.write(
      key: 'quicui_app_api_key',
      value: key,
    );
  }
  
  /// Retrieve app API key
  static Future<String?> getAppApiKey() async {
    return await _storage.read(key: 'quicui_app_api_key');
  }
  
  /// Save AI agent key
  static Future<void> saveAiAgentKey(String key) async {
    await _storage.write(
      key: 'quicui_ai_agent_key',
      value: key,
    );
  }
  
  /// Retrieve AI agent key
  static Future<String?> getAiAgentKey() async {
    return await _storage.read(key: 'quicui_ai_agent_key');
  }
  
  /// Delete all keys (on logout)
  static Future<void> deleteAllKeys() async {
    await _storage.delete(key: 'quicui_app_api_key');
    await _storage.delete(key: 'quicui_ai_agent_key');
  }
}
```

### Step 3: Initialize with API Key

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/secure_storage.dart';
import 'config/api_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to load API key from secure storage
  String? apiKey = await SecureStorage.getAppApiKey();
  
  // Fallback to config if not found
  apiKey ??= ApiConfig.appApiKey;
  
  // Save to secure storage if loaded from config
  if (apiKey == ApiConfig.appApiKey) {
    await SecureStorage.saveAppApiKey(apiKey);
  }
  
  // Initialize Supabase with Anon key (safe to use)
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );
  
  // Initialize QuicUI with app API key
  await QuicUI.initialize(
    appApiKey: apiKey,
    enableLogging: true,
  );
  
  runApp(const MyApp());
}
```

### Step 4: Use API Key in Services

```dart
// lib/services/quicui_service.dart

import 'package:quicui/quicui.dart';
import 'secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuicUIService {
  static final _supabase = Supabase.instance.client;
  static String? _appApiKey;
  
  /// Initialize service with API key
  static Future<void> initialize(String appApiKey) async {
    _appApiKey = appApiKey;
  }
  
  /// Get current app API key
  static String? getApiKey() => _appApiKey;
  
  /// Verify API key is valid
  static Future<bool> verifyApiKey() async {
    try {
      // Make a test request with the API key
      final response = await _supabase
          .from('apps')
          .select('id')
          .limit(1);
      
      return response != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Fetch screen with auth header
  static Future<Map<String, dynamic>> fetchScreen({
    required String appId,
    required String screenId,
  }) async {
    try {
      if (_appApiKey == null) {
        throw Exception('API key not initialized');
      }
      
      // Make request with API key
      final response = await _supabase
          .from('ui_screens')
          .select()
          .eq('app_id', appId)
          .eq('screen_id', screenId)
          .eq('status', 'published')
          .single();
      
      return response['json_definition'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch screen: $e');
    }
  }
}
```

---

## 🌐 Web Dashboard: API Key Management

### Database Schema for Keys

```sql
-- API Keys table
CREATE TABLE public.api_keys (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  key_type text NOT NULL, -- 'app', 'ai_agent', 'webhook'
  key_value text NOT NULL,
  name text,
  description text,
  is_active boolean DEFAULT true,
  last_used_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_by uuid,
  expires_at timestamp with time zone,
  CONSTRAINT api_keys_key_type_check CHECK (key_type IN ('app', 'ai_agent', 'webhook'))
);

CREATE INDEX idx_api_keys_app_id ON public.api_keys(app_id);
CREATE INDEX idx_api_keys_key_type ON public.api_keys(key_type);
CREATE INDEX idx_api_keys_is_active ON public.api_keys(is_active);
```

### Keys Management Service

```dart
// quicui_web_dashboard/lib/services/api_key_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ApiKeyService {
  final supabase = Supabase.instance.client;
  
  /// Generate new API key
  Future<String> generateKey() async {
    const uuid = Uuid();
    return uuid.v4();
  }
  
  /// Create API key for app
  Future<Map<String, dynamic>> createApiKey({
    required String appId,
    required String keyType, // 'app', 'ai_agent'
    required String name,
    String? description,
    Duration? expiresIn,
  }) async {
    try {
      final keyValue = await generateKey();
      final expiresAt = expiresIn != null
          ? DateTime.now().add(expiresIn).toIso8601String()
          : null;
      
      final response = await supabase.from('api_keys').insert({
        'app_id': appId,
        'key_type': keyType,
        'key_value': keyValue,
        'name': name,
        'description': description,
        'expires_at': expiresAt,
      }).select().single();
      
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create API key: $e');
    }
  }
  
  /// Get all keys for app
  Future<List<Map<String, dynamic>>> getAppKeys(String appId) async {
    try {
      final response = await supabase
          .from('api_keys')
          .select()
          .eq('app_id', appId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch API keys: $e');
    }
  }
  
  /// Revoke API key
  Future<void> revokeKey(String keyId) async {
    try {
      await supabase
          .from('api_keys')
          .update({'is_active': false})
          .eq('id', keyId);
    } catch (e) {
      throw Exception('Failed to revoke API key: $e');
    }
  }
  
  /// Update last used timestamp
  Future<void> updateLastUsed(String keyId) async {
    try {
      await supabase
          .from('api_keys')
          .update({'last_used_at': DateTime.now().toIso8601String()})
          .eq('id', keyId);
    } catch (e) {
      // Silently fail - not critical
    }
  }
}
```

### API Keys Screen (Web Dashboard)

```dart
// quicui_web_dashboard/lib/screens/ai/api_keys_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/ai_controller.dart';
import '../../services/api_key_service.dart';

class ApiKeysScreen extends StatefulWidget {
  final String appId;
  
  const ApiKeysScreen({Key? key, required this.appId}) : super(key: key);

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  late final ApiKeyService _keyService;
  List<Map<String, dynamic>> _keys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _keyService = ApiKeyService();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    try {
      final keys = await _keyService.getAppKeys(widget.appId);
      setState(() {
        _keys = keys;
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading keys: $e')),
      );
    }
  }

  Future<void> _createKey() async {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Key Name',
                hintText: 'e.g., Production App',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _keyService.createApiKey(
                  appId: widget.appId,
                  keyType: 'app',
                  name: nameController.text,
                  expiresIn: const Duration(days: 365), // 1 year
                );
                
                Navigator.pop(context);
                await _loadKeys();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API key created')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Keys'),
        actions: [
          IconButton(
            onPressed: _loadKeys,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createKey,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _keys.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No API keys',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _createKey,
                        child: const Text('Create First Key'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _keys.length,
                  itemBuilder: (context, index) {
                    final key = _keys[index];
                    
                    return Card(
                      child: ExpansionTile(
                        title: Text(key['name'] ?? 'API Key'),
                        subtitle: Text(
                          'Created: ${DateTime.parse(key['created_at']).toString().split('.')[0]}',
                        ),
                        trailing: Chip(
                          label: Text(
                            key['is_active'] ? 'Active' : 'Revoked',
                          ),
                          backgroundColor: key['is_active']
                              ? Colors.green[100]
                              : Colors.red[100],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Key Value:'),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SelectableText(
                                          key['key_value'],
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: key['key_value']),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Copied to clipboard'),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy),
                                        tooltip: 'Copy',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (key['is_active'])
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await _keyService.revokeKey(key['id']);
                                      await _loadKeys();
                                      
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Key revoked'),
                                        ),
                                      );
                                    },
                                    child: const Text('Revoke Key'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
```

---

## 📦 Publishing QuicUI Package

The **quicui** package needs to be published to pub.dev for easy integration.

### Step 1: Prepare for Publishing

```yaml
# pubspec.yaml

name: quicui
description: QuicUI - AI-Friendly Server-Driven UI Framework for Flutter. Define UIs in JSON, update instantly without app deployment.
version: 1.0.0
repository: https://github.com/yourusername/quicui
issue_tracker: https://github.com/yourusername/quicui/issues
documentation: https://github.com/yourusername/quicui

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  supabase_flutter: ^2.11.0
  provider: ^6.4.0
  dio: ^5.7.0
  objectbox: ^4.1.1
  json_annotation: ^4.8.0
  # ... other dependencies

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.6
  json_serializable: ^6.7.0

flutter:
  # Package doesn't have any assets or fonts
```

### Step 2: Verify Package

```bash
cd quicui

# Analyze the package
flutter analyze

# Run tests
flutter test

# Check pub requirements
pub publish --dry-run
```

### Step 3: Publish to pub.dev

```bash
# Login to pub.dev (first time)
pub login

# Publish
pub publish
```

---

## 🔐 Key Rotation Strategy

### Monthly Rotation (Recommended)

1. Generate new key
2. Update app configuration
3. Test with new key
4. Revoke old key after 7 days

### Emergency Rotation

If key is compromised:
1. Immediately revoke the key
2. Generate new key
3. Redeploy apps with new key
4. Monitor for unauthorized access

---

## 📊 Key Usage Monitoring

```dart
// View key usage in web dashboard
// - Last used timestamp
// - Number of requests
// - Error rates
// - Geographic location of usage
```

---

## ✅ Integration Checklist

- [ ] Create API key system in database
- [ ] Implement key generation
- [ ] Add secure storage (app)
- [ ] Add key management (web dashboard)
- [ ] Implement key verification
- [ ] Setup key rotation
- [ ] Add usage monitoring
- [ ] Document for developers
- [ ] Create key distribution process
- [ ] Setup alerts for compromised keys

---

*Secure API Key Management for QuicUI Framework*
