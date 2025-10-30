/// QuicUI - AI-Friendly Server-Driven UI Framework for Flutter
///
/// A production-ready framework for defining and rendering UIs from JSON,
/// with real-time synchronization, offline-first architecture, and BLoC-based state management.

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
