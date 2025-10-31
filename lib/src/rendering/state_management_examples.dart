// Phase 7 Examples - State Management UI Patterns
// Demonstrates practical implementations of 16 state management widgets
// Pure JSON configuration format (no method calls)

class Phase7Examples {
  /// LoadingStateWidget Examples
  static final loadingStateExamples = [
    {
      'name': 'Small Loading Spinner',
      'type': 'LoadingStateWidget',
      'properties': {
        'size': 40,
        'color': '#2196F3',
        'message': null
      }
    },
    {
      'name': 'Large Loading with Text',
      'type': 'LoadingStateWidget',
      'properties': {
        'size': 60,
        'color': '#2196F3',
        'message': 'Loading data...'
      }
    },
    {
      'name': 'Loading with Custom Message',
      'type': 'LoadingStateWidget',
      'properties': {
        'size': 50,
        'color': '#FF9800',
        'message': 'Syncing...'
      }
    },
  ];

  /// ErrorStateWidget Examples
  static final errorStateExamples = [
    {
      'name': 'Network Error',
      'type': 'ErrorStateWidget',
      'properties': {
        'title': 'Network Error',
        'message': 'Failed to connect to server',
        'icon': 'error_outline',
        'hasRetry': true
      }
    },
    {
      'name': 'Timeout Error',
      'type': 'ErrorStateWidget',
      'properties': {
        'title': 'Request Timeout',
        'message': 'The operation took too long',
        'icon': 'schedule',
        'hasRetry': true
      }
    },
    {
      'name': 'Permission Error',
      'type': 'ErrorStateWidget',
      'properties': {
        'title': 'Permission Denied',
        'message': 'You don\'t have access to this resource',
        'icon': 'lock',
        'hasRetry': false
      }
    },
  ];

  /// EmptyStateWidget Examples
  static final emptyStateExamples = [
    {
      'name': 'Empty Inbox',
      'type': 'EmptyStateWidget',
      'properties': {
        'title': 'No Messages',
        'message': 'You don\'t have any messages yet',
        'icon': 'inbox',
        'actionLabel': 'Compose'
      }
    },
    {
      'name': 'Empty Shopping Cart',
      'type': 'EmptyStateWidget',
      'properties': {
        'title': 'Cart is Empty',
        'message': 'Start shopping to add items to your cart',
        'icon': 'shopping_cart',
        'actionLabel': 'Browse Items'
      }
    },
    {
      'name': 'No Search Results',
      'type': 'EmptyStateWidget',
      'properties': {
        'title': 'No Results Found',
        'message': 'Try different search terms',
        'icon': 'search',
        'actionLabel': 'Clear Search'
      }
    },
  ];

  /// SkeletonLoader Examples
  static final skeletonLoaderExamples = [
    {
      'name': 'List Skeleton',
      'type': 'SkeletonLoader',
      'properties': {
        'itemCount': 3,
        'height': 16,
        'borderRadius': 8
      }
    },
    {
      'name': 'Card Skeleton',
      'type': 'SkeletonLoader',
      'properties': {
        'itemCount': 5,
        'height': 24,
        'borderRadius': 4
      }
    },
    {
      'name': 'Heavy Load Skeleton',
      'type': 'SkeletonLoader',
      'properties': {
        'itemCount': 8,
        'height': 12,
        'borderRadius': 6
      }
    },
  ];

  /// SuccessStateWidget Examples
  static final successStateExamples = [
    {
      'name': 'Basic Success',
      'type': 'SuccessStateWidget',
      'properties': {
        'title': 'Success',
        'message': 'Operation completed successfully',
        'duration': 3000
      }
    },
    {
      'name': 'Purchase Success',
      'type': 'SuccessStateWidget',
      'properties': {
        'title': 'Purchase Complete',
        'message': 'Your order has been placed successfully',
        'duration': 4000
      }
    },
    {
      'name': 'Upload Success',
      'type': 'SuccessStateWidget',
      'properties': {
        'title': 'Upload Complete',
        'message': 'Your file has been uploaded',
        'duration': 3000
      }
    },
  ];

  /// RetryButton Examples
  static final retryButtonExamples = [
    {
      'name': 'Simple Retry',
      'type': 'RetryButton',
      'properties': {
        'label': 'Retry',
        'icon': 'refresh',
        'isLoading': false
      }
    },
    {
      'name': 'Loading Retry',
      'type': 'RetryButton',
      'properties': {
        'label': 'Retry',
        'icon': 'refresh',
        'isLoading': true
      }
    },
    {
      'name': 'Try Again Button',
      'type': 'RetryButton',
      'properties': {
        'label': 'Try Again',
        'icon': 'autorenew',
        'isLoading': false
      }
    },
  ];

  /// ProgressIndicator Examples
  static final progressIndicatorExamples = [
    {
      'name': 'Download Progress 50%',
      'type': 'ProgressIndicator',
      'properties': {
        'progress': 0.5,
        'label': 'Downloading',
        'showPercentage': true,
        'height': 8
      }
    },
    {
      'name': 'Upload Progress 75%',
      'type': 'ProgressIndicator',
      'properties': {
        'progress': 0.75,
        'label': 'Uploading',
        'showPercentage': true,
        'height': 6
      }
    },
    {
      'name': 'Installation 100%',
      'type': 'ProgressIndicator',
      'properties': {
        'progress': 1.0,
        'label': 'Installing',
        'showPercentage': true,
        'height': 8
      }
    },
  ];

  /// StatusBadge Examples
  static final statusBadgeExamples = [
    {
      'name': 'Active Status',
      'type': 'StatusBadge',
      'properties': {
        'label': 'Active',
        'type': 'active',
        'icon': 'check_circle'
      }
    },
    {
      'name': 'Pending Status',
      'type': 'StatusBadge',
      'properties': {
        'label': 'Pending',
        'type': 'pending',
        'icon': 'schedule'
      }
    },
    {
      'name': 'Error Status',
      'type': 'StatusBadge',
      'properties': {
        'label': 'Error',
        'type': 'error',
        'icon': 'error'
      }
    },
  ];

  /// StateTransitionWidget Examples
  static final stateTransitionExamples = [
    {
      'name': 'Fast Transition 200ms',
      'type': 'StateTransitionWidget',
      'properties': {
        'duration': 200
      }
    },
    {
      'name': 'Normal Transition 300ms',
      'type': 'StateTransitionWidget',
      'properties': {
        'duration': 300
      }
    },
    {
      'name': 'Slow Transition 500ms',
      'type': 'StateTransitionWidget',
      'properties': {
        'duration': 500
      }
    },
  ];

  /// DataRefreshWidget Examples
  static final dataRefreshExamples = [
    {
      'name': 'Simple Refresh',
      'type': 'DataRefreshWidget',
      'properties': {
        'label': 'Refresh Data',
        'isRefreshing': false
      }
    },
    {
      'name': 'Refreshing State',
      'type': 'DataRefreshWidget',
      'properties': {
        'label': 'Refresh Results',
        'isRefreshing': true
      }
    },
    {
      'name': 'With Timestamp',
      'type': 'DataRefreshWidget',
      'properties': {
        'label': 'Sync Database',
        'isRefreshing': false,
        'showLastRefresh': true
      }
    },
  ];

  /// OfflineIndicator Examples
  static final offlineIndicatorExamples = [
    {
      'name': 'Online Status',
      'type': 'OfflineIndicator',
      'properties': {
        'isOnline': true,
        'onlineMessage': 'Online',
        'offlineMessage': 'Offline'
      }
    },
    {
      'name': 'Offline Status',
      'type': 'OfflineIndicator',
      'properties': {
        'isOnline': false,
        'onlineMessage': 'Connected',
        'offlineMessage': 'No Connection'
      }
    },
    {
      'name': 'Custom Messages',
      'type': 'OfflineIndicator',
      'properties': {
        'isOnline': true,
        'onlineMessage': 'Cloud Sync Active',
        'offlineMessage': 'Cloud Sync Disabled'
      }
    },
  ];

  /// SyncStatusWidget Examples
  static final syncStatusExamples = [
    {
      'name': 'Not Synced',
      'type': 'SyncStatusWidget',
      'properties': {
        'isSyncing': false,
        'isSynced': false,
        'message': 'Changes not synced'
      }
    },
    {
      'name': 'Syncing',
      'type': 'SyncStatusWidget',
      'properties': {
        'isSyncing': true,
        'isSynced': false,
        'message': 'Syncing changes...'
      }
    },
    {
      'name': 'Synced',
      'type': 'SyncStatusWidget',
      'properties': {
        'isSyncing': false,
        'isSynced': true,
        'message': 'All changes synced'
      }
    },
  ];

  /// ValidationIndicator Examples
  static final validationIndicatorExamples = [
    {
      'name': 'Valid Input',
      'type': 'ValidationIndicator',
      'properties': {
        'isValid': true,
        'successMessage': 'Email is valid'
      }
    },
    {
      'name': 'Invalid Input',
      'type': 'ValidationIndicator',
      'properties': {
        'isValid': false,
        'errorMessage': 'Email format is invalid'
      }
    },
    {
      'name': 'Password Validation',
      'type': 'ValidationIndicator',
      'properties': {
        'isValid': true,
        'successMessage': 'Password is strong'
      }
    },
  ];

  /// WarningBanner Examples
  static final warningBannerExamples = [
    {
      'name': 'Deprecation Warning',
      'type': 'WarningBanner',
      'properties': {
        'message': 'This feature will be deprecated soon',
        'icon': 'warning',
        'dismissible': true
      }
    },
    {
      'name': 'Update Available',
      'type': 'WarningBanner',
      'properties': {
        'message': 'A new version is available. Please update.',
        'icon': 'system_update',
        'dismissible': true
      }
    },
    {
      'name': 'Limited Time',
      'type': 'WarningBanner',
      'properties': {
        'message': 'This offer expires in 24 hours',
        'icon': 'schedule',
        'dismissible': false
      }
    },
  ];

  /// InfoPanel Examples
  static final infoPanelExamples = [
    {
      'name': 'Help Information',
      'type': 'InfoPanel',
      'properties': {
        'title': 'How it Works',
        'message': 'This feature automatically saves your progress',
        'actionLabel': 'Learn More'
      }
    },
    {
      'name': 'Feature Introduction',
      'type': 'InfoPanel',
      'properties': {
        'title': 'New Feature Available',
        'message': 'Try our new dark mode for better visibility',
        'actionLabel': 'Enable Now'
      }
    },
    {
      'name': 'Privacy Notice',
      'type': 'InfoPanel',
      'properties': {
        'title': 'Privacy Update',
        'message': 'We have updated our privacy policy',
        'actionLabel': 'Read Policy'
      }
    },
  ];

  /// ToastNotification Examples
  static final toastNotificationExamples = [
    {
      'name': 'Success Toast',
      'type': 'ToastNotification',
      'properties': {
        'message': 'Item saved successfully',
        'duration': 3000,
        'backgroundColor': '#4CAF50'
      }
    },
    {
      'name': 'Error Toast',
      'type': 'ToastNotification',
      'properties': {
        'message': 'Failed to save item',
        'duration': 4000,
        'backgroundColor': '#F44336'
      }
    },
    {
      'name': 'Info Toast',
      'type': 'ToastNotification',
      'properties': {
        'message': 'Please check your internet connection',
        'duration': 5000,
        'backgroundColor': '#2196F3'
      }
    },
  ];

  /// Get all examples
  static final allExamples = {
    'LoadingStateWidget': loadingStateExamples,
    'ErrorStateWidget': errorStateExamples,
    'EmptyStateWidget': emptyStateExamples,
    'SkeletonLoader': skeletonLoaderExamples,
    'SuccessStateWidget': successStateExamples,
    'RetryButton': retryButtonExamples,
    'ProgressIndicator': progressIndicatorExamples,
    'StatusBadge': statusBadgeExamples,
    'StateTransitionWidget': stateTransitionExamples,
    'DataRefreshWidget': dataRefreshExamples,
    'OfflineIndicator': offlineIndicatorExamples,
    'SyncStatusWidget': syncStatusExamples,
    'ValidationIndicator': validationIndicatorExamples,
    'WarningBanner': warningBannerExamples,
    'InfoPanel': infoPanelExamples,
    'ToastNotification': toastNotificationExamples,
  };

  /// Get example by type and index
  static Map<String, dynamic>? getExample(String type, int index) {
    final examples = allExamples[type];
    if (examples != null && index >= 0 && index < examples.length) {
      return examples[index];
    }
    return null;
  }

  /// Get all example names by type
  static List<String> getExampleNames(String type) {
    final examples = allExamples[type];
    if (examples != null) {
      return examples.map((e) => e['name'] as String).toList();
    }
    return [];
  }
}
