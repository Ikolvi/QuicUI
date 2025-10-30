/// Core constants used throughout the QuicUI framework


/// Default timeout duration for network requests
const Duration defaultRequestTimeout = Duration(seconds: 30);

/// Default timeout duration for database operations
const Duration defaultDbTimeout = Duration(seconds: 10);

/// Maximum retry attempts for failed operations
const int maxRetryAttempts = 3;

/// Retry delay base duration (exponential backoff)
const Duration retryDelayBase = Duration(milliseconds: 500);

/// Storage keys
class StorageKeys {
  static const String appConfig = 'app_config';
  static const String userSession = 'user_session';
  static const String screenCache = 'screen_cache';
  static const String syncState = 'sync_state';
  static const String lastSync = 'last_sync';
}

/// API endpoints
class ApiEndpoints {
  static const String screens = '/api/screens';
  static const String devices = '/api/devices';
  static const String sync = '/api/sync';
  static const String config = '/api/config';
}

/// Widget type constants for JSON rendering
class WidgetTypes {
  // Layout
  static const String column = 'column';
  static const String row = 'row';
  static const String container = 'container';
  static const String stack = 'stack';
  static const String gridView = 'gridview';
  static const String listView = 'listview';

  // Input
  static const String textField = 'textfield';
  static const String button = 'button';
  static const String checkbox = 'checkbox';
  static const String radio = 'radio';
  static const String datePicker = 'datepicker';

  // Display
  static const String text = 'text';
  static const String image = 'image';
  static const String icon = 'icon';
  static const String badge = 'badge';
  static const String card = 'card';
}
