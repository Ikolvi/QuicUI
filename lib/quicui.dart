/// # QuicUI - Server-Driven UI Framework for Flutter
///
/// A production-ready framework for defining and rendering UIs from JSON.
/// **Fully optional cloud integration** - works standalone with local data, or connects to any backend via plugins.
///
/// ## Overview
///
/// QuicUI enables developers to create Flutter applications using JSON-based UI definitions.
/// The framework handles:
///
/// - **JSON-Driven UI:** Define UIs in JSON, render natively in Flutter
/// - **Standalone Usage:** Works without any backend - perfect for local/static UIs
/// - **Optional Cloud:** Integrate with Supabase, Firebase, or custom backends via plugins
/// - **Real-Time Sync:** Live UI updates with your chosen backend (optional)
/// - **Offline-First:** Full offline support with automatic synchronization when online
/// - **70+ Widgets:** Extensive widget library with Material Design support
/// - **Type Safety:** Full Dart null-safety and type checking
/// - **Testing:** 267/267 comprehensive tests ensuring reliability
///
/// ## Backend: Fully Optional
///
/// QuicUI works in multiple scenarios:
///
/// ### Standalone (No Backend Required)
/// ```dart
/// // Works offline with local JSON data
/// final jsonData = {'type': 'text', 'properties': {'text': 'Hello'}};
/// final screen = Screen.fromJson(jsonData);
/// final widget = UIRenderer.render(screen);
/// ```
///
/// ### With Backend Plugin (Optional)
/// ```dart
/// // Use Supabase, Firebase, or custom backend
/// final dataSource = SupabaseDataSource(...);
/// await QuicUIService().initializeWithDataSource(dataSource);
/// final screenData = await QuicUIService().fetchScreen('home');
/// ```
///
/// See [QuicUIService] for plugin-based initialization.
///
/// ## Quick Start
///
/// ### Minimal Setup (No Backend)
/// ```dart
/// import 'package:quicui/quicui.dart';
///
/// void main() {
///   runApp(QuicUIApp(home: MyLocalScreen()));
/// }
/// ```
///
/// ### With Backend Plugin (Optional)
/// ```dart
/// import 'package:quicui/quicui.dart';
/// import 'package:quicui_supabase/quicui_supabase.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final dataSource = SupabaseDataSource(...);
///   await QuicUIService().initializeWithDataSource(dataSource);
///   runApp(MyApp());
/// }
/// ```
///
/// ## Core Concepts
///
/// ### Screen & WidgetData
/// - [Screen]: Top-level definition of a UI screen (works with local JSON)
/// - [WidgetData]: Individual widget configuration with properties and actions
///
/// ### State Management
/// - [ScreenBloc]: BLoC for managing screen state and user interactions
/// - [ScreenRepository]: Repository pattern for data access (optional if no backend)
///
/// ### Data Sources (Optional)
/// - [DataSource]: Plugin interface for backend integration
/// - [DataSourceProvider]: Service locator for registered backends
/// - Built-in: Local-only data (no DataSource needed)
/// - Plugins: Supabase, Firebase, REST API, custom
///
/// ### Rendering
/// - [UIRenderer]: Main rendering engine for converting JSON to Flutter widgets
/// - [WidgetFactory]: Factory pattern for creating Flutter widgets
/// - [WidgetBuilder]: Helper for building complex widgets
///
/// ### Services
/// - [QuicUIService]: Main service - use for backend initialization (optional)
/// - [StorageService]: Local storage and caching (optional)
///
/// ## Examples
///
/// ### Local Screen Rendering (No Backend)
/// ```dart
/// final jsonData = {
///   'id': 'home_screen',
///   'name': 'Home',
///   'widgets': [...],
/// };
/// final screen = Screen.fromJson(jsonData);
/// final renderer = UIRenderer();
/// final widget = renderer.renderScreen(screen);
/// ```
///
/// ### With Backend Plugin (Optional)
/// ```dart
/// // Initialize with Supabase plugin
/// final dataSource = SupabaseDataSource(...);
/// await QuicUIService().initializeWithDataSource(dataSource);
/// 
/// // Fetch dynamic UI from backend
/// final screenData = await QuicUIService().fetchScreen('home');
/// final renderer = UIRenderer();
/// final widget = renderer.renderScreen(screenData);
/// ```
///
/// ### Offline Support
/// The framework automatically:
/// - Works with local data without any backend
/// - Caches screens when backend is available
/// - Serves cached screens when offline
/// - Syncs with backend when connection is restored
///
/// ## Architecture
///
/// ### Standalone Mode (No Backend)
/// ```
/// JSON Data (local)
///    ↓
/// ┌──────────────────┐
/// │   Screen Model   │
/// └──────┬───────────┘
///        ↓
/// ┌──────────────────┐
/// │   UIRenderer     │ (convert to widgets)
/// └──────┬───────────┘
///        ↓
///     Flutter UI
/// ```
///
/// ### With Backend Plugin (Optional)
/// ```
/// ┌─────────────────────┐
/// │   Flutter UI Layer  │
/// └──────────┬──────────┘
///            │
/// ┌──────────▼──────────┐
/// │   UIRenderer        │
/// └──────────┬──────────┘
///            │
/// ┌──────────▼──────────┐
/// │  QuicUIService      │ (optional, for backend)
/// │  + BLoC Layer       │
/// └──────────┬──────────┘
///            │
/// ┌──────────▼──────────┐
/// │  DataSourceProvider │ (optional)
/// │  (backend registry) │
/// └──────────┬──────────┘
///            │
/// ┌──────────┴──────────┐
/// │                     │
/// ▼                     ▼
/// Supabase         Firebase (future)
/// (plugin)         or custom backend
/// ```
///
/// ## Testing
///
/// QuicUI includes 267 tests covering:
/// - Unit tests for all components
/// - Integration tests for workflows
/// - Example app tests demonstrating patterns
/// - Standalone (no backend) scenarios
/// - Plugin-based initialization scenarios
///
/// ## Documentation
///
/// - **API Reference:** See individual class documentation below
/// - **Examples:** See `examples/` directory for complete example applications
/// - **Best Practices:** See package documentation
///
/// ## Performance
///
/// QuicUI is optimized for:
/// - Fast initial load times
/// - Smooth animations and transitions
/// - Minimal memory usage
/// - Efficient offline caching
///
/// ## Contributing
///
/// See GitHub repository for contribution guidelines.
///
/// ## License
///
/// MIT License - See LICENSE file for details.

library;

// Core exports
export 'src/core/quicui.dart';
export 'src/core/constants.dart';
export 'src/core/exceptions.dart';
export 'src/core/typedefs.dart';

// Models and Serialization
export 'src/models/screen.dart';
export 'src/models/widget_data.dart';
export 'src/models/theme_config.dart';

// BLoC Layer - State Management
export 'src/bloc/screen/screen_bloc.dart';

// Repository Layer
export 'src/repositories/screen_repository.dart';
export 'src/repositories/sync_repository.dart';
export 'src/repositories/data_source_provider.dart';

// Repository Abstractions (v2.0.0 Plugin Architecture)
export 'src/repositories/abstract/data_source.dart';
export 'src/repositories/abstract/realtime_source.dart';
export 'src/repositories/abstract/sync_models.dart';
export 'src/repositories/abstract/exceptions.dart';

// Data Sources
export 'src/data/datasources/remote_data_source.dart';
export 'src/data/datasources/local_data_source.dart';

// UI Rendering
export 'src/rendering/ui_renderer.dart';
export 'src/rendering/widget_builder.dart';
export 'src/rendering/widget_factory.dart';

// Widgets
export 'src/widgets/quicui_app.dart';
export 'src/widgets/screen_view.dart';

// Services
export 'src/services/quicui_service.dart';
export 'src/services/storage_service.dart';

// Utilities
export 'src/utils/logger_util.dart';
export 'src/utils/validators.dart';
export 'src/utils/extensions.dart';
