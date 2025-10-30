/// # QuicUI - Server-Driven UI Framework for Flutter
///
/// A production-ready framework for defining and rendering UIs from JSON,
/// with real-time synchronization via **Supabase**, offline-first architecture, and BLoC-based state management.
///
/// ## Overview
///
/// QuicUI enables developers to create Flutter applications using JSON-based UI definitions.
/// The framework handles:
///
/// - **Server-Driven UI:** Define UIs on Supabase server, render on the client
/// - **Cloud Integration:** Dynamic UI changes from Supabase without app updates
/// - **Offline-First:** Full offline support with automatic synchronization
/// - **Real-Time Updates:** Live UI updates through Supabase real-time subscriptions
/// - **70+ Widgets:** Extensive widget library with Material Design support
/// - **Type Safety:** Full Dart null-safety and type checking
/// - **Testing:** 228+ comprehensive tests ensuring reliability
///
/// ## Cloud Backend: Supabase Only
///
/// QuicUI exclusively uses **Supabase** for cloud operations:
/// - **Dynamic UI Configuration:** Fetch screen definitions from Supabase
/// - **Real-Time Sync:** Subscribe to UI changes in real-time
/// - **User Authentication:** Built-in Supabase auth integration
/// - **Data Persistence:** Store and sync user data with PostgreSQL
///
/// No other API keys or services required - **Supabase is the only cloud backend**.
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
/// - [RemoteDataSource]: Fetches screen definitions from Supabase
/// - [LocalDataSource]: Provides offline access to cached screens
///
/// ### Rendering
/// - [UIRenderer]: Main rendering engine for converting JSON to Flutter widgets
/// - [WidgetFactory]: Factory pattern for creating Flutter widgets
/// - [WidgetBuilder]: Helper for building complex widgets
///
/// ### Services
/// - [QuicUIService]: Main service for initializing framework with Supabase
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
///   supabaseAnonKey: 'your-supabase-key',
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
/// ### Cloud Integration
/// The framework integrates seamlessly with Supabase to:
/// - Fetch dynamic UI configurations from cloud
/// - Subscribe to real-time UI updates
/// - Authenticate users securely
/// - Sync data between device and cloud
///
/// ### Offline Support
/// The framework automatically:
/// - Caches screens locally when online
/// - Serves cached screens when offline
/// - Queues user interactions while offline
/// - Syncs with Supabase when connection is restored
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
export 'src/services/supabase_service.dart';
export 'src/services/storage_service.dart';

// Utilities
export 'src/utils/logger_util.dart';
export 'src/utils/validators.dart';
export 'src/utils/extensions.dart';
