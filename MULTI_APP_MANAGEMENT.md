# Multi-App Management & App Registration Guide

## 🏢 Multi-App Architecture

QuicUI supports managing **multiple applications** from a single backend, each with:

- Independent configuration
- Separate device registrations
- Isolated state & data
- AI agent management
- Real-time sync chains

---

## 📱 App Registration Flow

```
┌─────────────────────────────────────────┐
│     Flutter App First Launch            │
├─────────────────────────────────────────┤
│ 1. Get/Generate Device ID              │
│ 2. Get App Bundle ID                   │
│ 3. Check if App registered in Supabase │
│ 4. If not, register new app            │
│ 5. Save App ID locally                 │
│ 6. Register device with app            │
│ 7. Download initial UI screens         │
│ 8. Subscribe to real-time updates      │
└─────────────────────────────────────────┘
```

---

## 🔧 Implementation

### Step 1: Create App Registration Manager

```dart
// lib/src/services/app_manager.dart

class AppManager {
  static const String _appIdKey = 'quicui_app_id';
  static const String _bundleIdKey = 'quicui_bundle_id';
  static late String _currentAppId;
  static late String _currentBundleId;
  
  static final _supabase = Supabase.instance.client;
  
  /// Initialize app (call in main.dart)
  static Future<void> initialize({
    required String appName,
    required String bundleId,
    required String packageName,
    String? aiAgentKey,
  }) async {
    try {
      _currentBundleId = bundleId;
      
      // Check if already registered
      final prefs = await SharedPreferences.getInstance();
      var appId = prefs.getString(_appIdKey);
      
      if (appId == null) {
        // Register or get existing app
        appId = await _registerApp(
          appName: appName,
          bundleId: bundleId,
          packageName: packageName,
          aiAgentKey: aiAgentKey,
        );
        
        // Save locally
        await prefs.setString(_appIdKey, appId);
      }
      
      _currentAppId = appId;
      
      // Register this device with the app
      await _registerDevice(appId, bundleId);
      
      logger.i('App initialized: $appId');
    } catch (e) {
      logger.e('App initialization failed', e);
      rethrow;
    }
  }
  
  /// Register app on Supabase
  static Future<String> _registerApp({
    required String appName,
    required String bundleId,
    required String packageName,
    String? aiAgentKey,
  }) async {
    try {
      // Check if app already exists
      final existing = await _supabase
          .from('apps')
          .select('id')
          .eq('bundle_id', bundleId)
          .maybeSingle();
      
      if (existing != null) {
        return existing['id'] as String;
      }
      
      // Create new app registration
      final response = await _supabase.from('apps').insert({
        'name': appName,
        'bundle_id': bundleId,
        'package_name': packageName,
        'ai_agent_key': aiAgentKey ?? 'quicui_${const Uuid().v4()}',
        'api_key': const Uuid().v4().toString(),
        'status': 'active',
        'metadata': {
          'created_at': DateTime.now().toIso8601String(),
          'initial_version': '1.0.0',
        },
      }).select().single();
      
      return response['id'] as String;
    } catch (e) {
      logger.e('App registration failed', e);
      rethrow;
    }
  }
  
  /// Register device with app
  static Future<void> _registerDevice(
    String appId,
    String bundleId,
  ) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Check if device already registered
      final existing = await _supabase
          .from('registered_devices')
          .select('id')
          .eq('app_id', appId)
          .eq('device_id', deviceId)
          .maybeSingle();
      
      if (existing != null) {
        // Update existing registration
        await _supabase
            .from('registered_devices')
            .update({
              'is_online': true,
              'app_version': packageInfo.version,
              'last_sync_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Create new device registration
        await _supabase.from('registered_devices').insert({
          'app_id': appId,
          'device_id': deviceId,
          'device_name': deviceInfo['name'],
          'device_os': deviceInfo['os'],
          'app_version': packageInfo.version,
          'is_online': true,
          'last_sync_at': DateTime.now().toIso8601String(),
        });
      }
      
      logger.i('Device registered: $deviceId');
    } catch (e) {
      logger.e('Device registration failed', e);
    }
  }
  
  /// Get current app ID
  static String get currentAppId => _currentAppId;
  
  /// Get current bundle ID
  static String get currentBundleId => _currentBundleId;
  
  /// Get device info
  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return {
        'os': 'Android',
        'name': '${info.manufacturer} ${info.model}',
      };
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return {
        'os': 'iOS',
        'name': info.model ?? 'iPhone',
      };
    } else if (Platform.isWeb) {
      return {
        'os': 'Web',
        'name': 'Web Browser',
      };
    }
    
    return {
      'os': Platform.operatingSystem,
      'name': 'Unknown Device',
    };
  }
  
  /// Mark device offline (call in app lifecycle)
  static Future<void> markOffline() async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();
      await _supabase
          .from('registered_devices')
          .update({'is_online': false})
          .eq('app_id', _currentAppId)
          .eq('device_id', deviceId);
    } catch (e) {
      logger.e('Failed to mark device offline', e);
    }
  }
  
  /// Get app config from cloud
  static Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final response = await _supabase
          .from('apps')
          .select('*')
          .eq('id', _currentAppId)
          .single();
      
      return response as Map<String, dynamic>;
    } catch (e) {
      logger.e('Failed to get app config', e);
      rethrow;
    }
  }
}
```

### Step 2: Device ID Service

```dart
// lib/src/services/device_id_service.dart

class DeviceIdService {
  static const String _deviceIdKey = 'quicui_device_id';
  
  /// Get or create unique device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }
  
  /// Reset device ID (for testing)
  static Future<void> resetDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }
  
  /// Export device info for debugging
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    final deviceInfo = DeviceInfoPlugin();
    
    String os = Platform.operatingSystem;
    String osVersion = '';
    String model = '';
    
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      osVersion = info.version.release;
      model = info.model;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      osVersion = info.systemVersion;
      model = info.model ?? 'Unknown';
    }
    
    return {
      'deviceId': deviceId,
      'os': os,
      'osVersion': osVersion,
      'model': model,
    };
  }
}
```

### Step 3: App Lifecycle Management

```dart
// lib/src/core/app_lifecycle.dart

class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  
  factory AppLifecycleManager() {
    return _instance;
  }
  
  AppLifecycleManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
  
  Future<void> _onAppResumed() async {
    logger.i('App resumed - marking device online');
    
    try {
      // Mark device as online
      final appId = AppManager.currentAppId;
      final deviceId = await DeviceIdService.getDeviceId();
      
      await Supabase.instance.client
          .from('registered_devices')
          .update({
            'is_online': true,
            'last_sync_at': DateTime.now().toIso8601String(),
          })
          .eq('app_id', appId)
          .eq('device_id', deviceId);
      
      // Sync any offline changes
      await SyncManager.instance.syncOfflineChanges();
    } catch (e) {
      logger.e('Failed to resume app', e);
    }
  }
  
  Future<void> _onAppPaused() async {
    logger.i('App paused - marking device offline');
    
    try {
      // Mark device as offline
      await AppManager.markOffline();
    } catch (e) {
      logger.e('Failed to pause app', e);
    }
  }
  
  Future<void> _onAppDetached() async {
    logger.i('App detached');
    WidgetsBinding.instance.removeObserver(this);
  }
}
```

### Step 4: Main App Setup

```dart
// lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://tzxaqatozdxgwhjphbrs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6eGFxYXRvemR4Z3doanBoYnJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NDM1MDQsImV4cCI6MjA3NzMxOTUwNH0.ipdp9RP6ZDNgZR06yPb5YTaANOzvTE-1WrS-22ss7cU',
  );
  
  // Initialize ObjectBox for local caching
  await ObjectBoxProvider.initialize();
  
  // Register app on first launch
  await AppManager.initialize(
    appName: 'My QuicUI App',
    bundleId: 'com.example.myapp',
    packageName: 'com.example.myapp',
    aiAgentKey: 'my_ai_agent_key', // Optional
  );
  
  // Initialize app lifecycle
  AppLifecycleManager();
  
  // Initialize sync
  await SyncManager.instance.initialize(
    appId: AppManager.currentAppId,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? screenData;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  Future<void> _loadScreen() async {
    try {
      // Load screen from cache or cloud
      final appId = AppManager.currentAppId;
      
      // Try to get from cache first
      screenData = await ObjectBoxProvider.getScreen('home');
      
      // If not in cache, fetch from cloud
      if (screenData == null) {
        screenData = await ScreenService.fetchScreen(
          appId: appId,
          screenId: 'home',
        );
      }
      
      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('QuicUI')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      );
    }

    return QuicUIScreen(jsonData: screenData!);
  }
}
```

---

## 🔗 Web Dashboard: Apps Management

### List All Apps

```typescript
// web/pages/apps/index.tsx

export async function getServerSideProps() {
  try {
    const { data } = await supabase
      .from('apps')
      .select('*, registered_devices(count)')
      .order('created_at', { ascending: false });
    
    return { props: { apps: data || [] } };
  } catch (error) {
    return { props: { apps: [] } };
  }
}

export default function AppsPage({ apps }) {
  const [appsList, setAppsList] = useState(apps);

  useEffect(() => {
    // Subscribe to real-time updates
    const subscription = supabase
      .from('apps')
      .on('*', payload => {
        setAppsList(prev =>
          prev.map(a => a.id === payload.new.id ? payload.new : a)
        );
      })
      .subscribe();

    return () => subscription.unsubscribe();
  }, []);

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Registered Apps</h1>
      
      <Link href="/apps/create">
        <a className="bg-blue-500 text-white px-4 py-2 rounded mb-6">
          + Register New App
        </a>
      </Link>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {appsList.map(app => (
          <div key={app.id} className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-semibold mb-2">{app.name}</h2>
            <p className="text-gray-600 text-sm mb-4">
              Bundle: {app.bundle_id}
            </p>
            <div className="flex justify-between items-center">
              <span className={`text-sm px-2 py-1 rounded ${
                app.status === 'active'
                  ? 'bg-green-100 text-green-800'
                  : 'bg-gray-100 text-gray-800'
              }`}>
                {app.status}
              </span>
              <span className="text-gray-600 text-sm">
                {app.registered_devices?.length || 0} devices
              </span>
            </div>
            <div className="mt-4 flex gap-2">
              <Link href={`/apps/${app.id}/overview`}>
                <a className="flex-1 bg-blue-100 text-blue-800 px-3 py-2 rounded text-center text-sm">
                  Open
                </a>
              </Link>
              <button
                onClick={() => deleteApp(app.id)}
                className="flex-1 bg-red-100 text-red-800 px-3 py-2 rounded text-sm"
              >
                Delete
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Create New App

```typescript
// web/pages/apps/create.tsx

export default function CreateAppPage() {
  const [formData, setFormData] = useState({
    name: '',
    bundleId: '',
    packageName: '',
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { data } = await supabase
        .from('apps')
        .insert([
          {
            name: formData.name,
            bundle_id: formData.bundleId,
            package_name: formData.packageName,
            ai_agent_key: `agent_${Date.now()}`,
            status: 'active',
          },
        ])
        .select()
        .single();

      toast.success('App registered successfully!');
      router.push(`/apps/${data.id}/overview`);
    } catch (error) {
      toast.error('Failed to register app');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto p-8">
      <h1 className="text-3xl font-bold mb-6">Register New App</h1>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">App Name</label>
          <input
            type="text"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            className="w-full border rounded px-3 py-2"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Bundle ID</label>
          <input
            type="text"
            placeholder="com.example.myapp"
            value={formData.bundleId}
            onChange={(e) => setFormData({ ...formData, bundleId: e.target.value })}
            className="w-full border rounded px-3 py-2"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Package Name</label>
          <input
            type="text"
            placeholder="com.example.myapp"
            value={formData.packageName}
            onChange={(e) => setFormData({ ...formData, packageName: e.target.value })}
            className="w-full border rounded px-3 py-2"
            required
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 disabled:bg-gray-400"
        >
          {loading ? 'Registering...' : 'Register App'}
        </button>
      </form>
    </div>
  );
}
```

---

## 📊 App Overview Dashboard

```typescript
// web/pages/apps/[id]/overview.tsx

export default function AppOverviewPage({ app }) {
  const [stats, setStats] = useState({
    deviceCount: 0,
    screenCount: 0,
    formSubmissions: 0,
    lastSync: null,
  });

  useEffect(() => {
    loadAppStats();
    subscribeToStats();
  }, [app.id]);

  const loadAppStats = async () => {
    try {
      const [devices, screens, forms] = await Promise.all([
        supabase.from('registered_devices').select('id').eq('app_id', app.id),
        supabase.from('ui_screens').select('id').eq('app_id', app.id),
        supabase.from('form_submissions').select('id').eq('app_id', app.id),
      ]);

      setStats({
        deviceCount: devices.data?.length || 0,
        screenCount: screens.data?.length || 0,
        formSubmissions: forms.data?.length || 0,
        lastSync: new Date().toISOString(),
      });
    } catch (error) {
      console.error('Failed to load stats:', error);
    }
  };

  const subscribeToStats = () => {
    const subscription = supabase
      .from('registered_devices')
      .on('*', () => loadAppStats())
      .eq('app_id', app.id)
      .subscribe();

    return () => subscription.unsubscribe();
  };

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">{app.name}</h1>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-blue-50 p-4 rounded-lg">
          <p className="text-gray-600 text-sm">Connected Devices</p>
          <p className="text-3xl font-bold">{stats.deviceCount}</p>
        </div>
        
        <div className="bg-green-50 p-4 rounded-lg">
          <p className="text-gray-600 text-sm">Screens</p>
          <p className="text-3xl font-bold">{stats.screenCount}</p>
        </div>
        
        <div className="bg-purple-50 p-4 rounded-lg">
          <p className="text-gray-600 text-sm">Form Submissions</p>
          <p className="text-3xl font-bold">{stats.formSubmissions}</p>
        </div>
        
        <div className="bg-orange-50 p-4 rounded-lg">
          <p className="text-gray-600 text-sm">Last Sync</p>
          <p className="text-sm">{stats.lastSync ? new Date(stats.lastSync).toLocaleString() : 'Never'}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Link href={`/apps/${app.id}/screens`}>
          <a className="block bg-white p-6 rounded-lg shadow hover:shadow-lg">
            <h2 className="text-xl font-semibold mb-2">📱 UI Screens</h2>
            <p className="text-gray-600">Manage and edit UI definitions</p>
          </a>
        </Link>

        <Link href={`/apps/${app.id}/devices`}>
          <a className="block bg-white p-6 rounded-lg shadow hover:shadow-lg">
            <h2 className="text-xl font-semibold mb-2">📡 Devices</h2>
            <p className="text-gray-600">Monitor connected devices</p>
          </a>
        </Link>

        <Link href={`/apps/${app.id}/sync`}>
          <a className="block bg-white p-6 rounded-lg shadow hover:shadow-lg">
            <h2 className="text-xl font-semibold mb-2">🔄 Sync Status</h2>
            <p className="text-gray-600">Real-time sync monitoring</p>
          </a>
        </Link>

        <Link href={`/apps/${app.id}/settings`}>
          <a className="block bg-white p-6 rounded-lg shadow hover:shadow-lg">
            <h2 className="text-xl font-semibold mb-2">⚙️ Settings</h2>
            <p className="text-gray-600">App configuration</p>
          </a>
        </Link>
      </div>
    </div>
  );
}
```

---

## ✅ Deployment Checklist

- [ ] Create Supabase project and get credentials
- [ ] Run database migrations
- [ ] Setup RLS policies
- [ ] Update Flutter `main.dart` with Supabase config
- [ ] Implement `AppManager`
- [ ] Implement `DeviceIdService`
- [ ] Setup `AppLifecycleManager`
- [ ] Test app registration
- [ ] Test device registration
- [ ] Test screen fetching
- [ ] Setup Next.js web dashboard
- [ ] Deploy Flutter app
- [ ] Deploy web dashboard
- [ ] Monitor via web dashboard

---

*Last Updated: October 30, 2025*
