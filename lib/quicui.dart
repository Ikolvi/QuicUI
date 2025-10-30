/// # QuicUI - AI-Friendly Server-Driven UI Framework for Flutter
///
/// A production-ready framework for defining and rendering UIs from JSON,
/// with real-time synchronization, offline-first architecture, and BLoC-based state management.
///
/// ## Overview
///
/// QuicUI enables developers to create Flutter applications using JSON-based UI definitions,
/// similar to web frameworks but optimized for mobile. The framework handles:
///
/// - **Server-Driven UI:** Define UIs on the server, render on the client
/// - **Offline-First:** Full offline support with automatic synchronization
/// - **Real-Time Updates:** Live UI updates through BLoC state management
/// - **70+ Widgets:** Extensive widget library with Material Design support
/// - **Type Safety:** Full Dart null-safety and type checking
/// - **Testing:** 228+ comprehensive tests ensuring reliability
///
/// ## Quick Start
///
/// ```dart
/// import 'package:quicui/quicui.dart';
///
/// void main() {
///   runApp(const QuicUIApp());
/// }
/// ```
///
/// ## Core Concepts
///
/// ### Screen & WidgetData
/// - [Screen]: Top-level definition of a UI screen
/// - [WidgetData]: Individual widget configuration with properties and actions
///
/// ### State Management
/// - [ScreenBloc]: BLoC for managing screen state and user interactions
/// - [ScreenRepository]: Repository pattern for data access
///
/// ### Data Sources
/// - [RemoteDataSource]: Fetches screen definitions from server (Supabase)
/// - [LocalDataSource]: Provides offline access to cached screens
///
/// ### Rendering
/// - [UIRenderer]: Main rendering engine for converting JSON to Flutter widgets
/// - [WidgetFactory]: Factory pattern for creating Flutter widgets
/// - [WidgetBuilder]: Helper for building complex widgets
///
/// ### Services
/// - [QuicUIService]: Main service for initializing and managing the framework
/// - [SupabaseService]: Integration with Supabase backend
/// - [StorageService]: Local storage and caching
///
/// ## Examples
///
/// ### Basic Setup
/// ```dart
/// final quicUIService = QuicUIService();
/// await quicUIService.initialize(
///   supabaseUrl: 'your-supabase-url',
///   supabaseKey: 'your-supabase-key',
/// );
/// ```
///
/// ### Rendering a Screen
/// ```dart
/// final screenData = {
///   'id': 'home_screen',
///   'name': 'Home',
///   'widgets': [...],
///   'state': {...},
/// };
/// final screen = Screen.fromJson(screenData);
/// final renderer = UIRenderer();
/// final widget = renderer.renderScreen(screen);
/// ```
///
/// ### Offline Support
/// The framework automatically:
/// - Caches screens locally when online
/// - Serves cached screens when offline
/// - Queues user interactions while offline
/// - Syncs when connection is restored
///
/// ## Architecture
///
/// ```
/// ┌─────────────────────┐
/// │   Flutter UI Layer  │
/// └──────────┬──────────┘
///            │
/// ┌──────────▼──────────┐
/// │   BLoC Layer        │ (State Management)
/// │   (ScreenBloc)      │
/// └──────────┬──────────┘
///            │
/// ┌──────────▼──────────┐
/// │  Repository Layer   │ (Data Access)
/// │ (ScreenRepository)  │
/// └──────────┬──────────┘
///            │
/// ┌──────────┴──────────┐
/// │                     │
/// ▼                     ▼
/// RemoteDataSource  LocalDataSource
/// (Supabase)        (SharedPrefs/SQLite)
/// ```
///
/// ## Testing
///
/// QuicUI includes 228 tests covering:
/// - Unit tests for all components (86 tests)
/// - Integration tests for workflows (38 tests)
/// - Example app tests demonstrating patterns (101 tests)
/// - Original framework tests (3 tests)
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
export 'src/services/supabase_service.dart';
export 'src/services/storage_service.dart';

// Utilities
export 'src/utils/logger_util.dart';
export 'src/utils/validators.dart';
export 'src/utils/extensions.dart';
