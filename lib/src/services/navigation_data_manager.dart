import '../utils/logger_util.dart';

/// Manages navigation data across flows and screens
/// Tracks session data, flow history, and state persistence
class NavigationDataManager {
  static final Map<String, dynamic> _sessionData = {};
  static final Map<String, Map<String, dynamic>> _flowHistory = {};
  static final List<Map<String, String>> _navigationStack = [];

  /// Set session data value
  static void setSessionData(String key, dynamic value) {
    LoggerUtil.info('NavigationDataManager: Setting session data: $key');
    _sessionData[key] = value;
  }

  /// Get session data value
  static dynamic getSessionData(String key) {
    if (!_sessionData.containsKey(key)) {
      LoggerUtil.warning('NavigationDataManager: Session data not found: $key');
      return null;
    }
    return _sessionData[key];
  }

  /// Merge new session data
  static void mergeSessionData(Map<String, dynamic> data) {
    LoggerUtil.info('NavigationDataManager: Merging session data with ${data.length} keys');
    _sessionData.addAll(data);
  }

  /// Get full session data (returns copy)
  static Map<String, dynamic> getFullSessionData() {
    return Map<String, dynamic>.from(_sessionData);
  }

  /// Save flow state
  static void saveFlowState(String flowId, Map<String, dynamic> state) {
    LoggerUtil.info('NavigationDataManager: Saving state for flow: $flowId');
    _flowHistory[flowId] = Map<String, dynamic>.from(state);
  }

  /// Get flow state
  static Map<String, dynamic>? getFlowState(String flowId) {
    if (_flowHistory.containsKey(flowId)) {
      return Map<String, dynamic>.from(_flowHistory[flowId]!);
    }
    LoggerUtil.warning('NavigationDataManager: Flow state not found: $flowId');
    return null;
  }

  /// Clear flow history
  static void clearFlowHistory({String? flowId}) {
    if (flowId != null) {
      LoggerUtil.info('NavigationDataManager: Clearing history for flow: $flowId');
      _flowHistory.remove(flowId);
    } else {
      LoggerUtil.info('NavigationDataManager: Clearing all flow history');
      _flowHistory.clear();
    }
  }

  /// Push navigation to stack
  static void pushNavigation(String flowId, String screenId) {
    LoggerUtil.info(
      'NavigationDataManager: Pushing navigation: $flowId → $screenId',
    );
    _navigationStack.add({
      'flowId': flowId,
      'screenId': screenId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Pop navigation from stack (go back)
  static Map<String, String>? popNavigation() {
    if (_navigationStack.isEmpty) {
      LoggerUtil.warning('NavigationDataManager: Navigation stack is empty');
      return null;
    }
    final popped = _navigationStack.removeLast();
    LoggerUtil.info(
      'NavigationDataManager: Popped navigation: ${popped['flowId']} → ${popped['screenId']}',
    );
    return popped;
  }

  /// Get current navigation (peek, don't pop)
  static Map<String, String>? getCurrentNavigation() {
    if (_navigationStack.isEmpty) {
      return null;
    }
    return Map<String, String>.from(_navigationStack.last);
  }

  /// Get navigation stack
  static List<Map<String, String>> getNavigationStack() {
    return List<Map<String, String>>.from(_navigationStack);
  }

  /// Can go back
  static bool canGoBack() {
    return _navigationStack.length > 1;
  }

  /// Go back N steps
  static List<Map<String, String>?> goBack({int steps = 1}) {
    LoggerUtil.info('NavigationDataManager: Going back $steps steps');
    final popped = <Map<String, String>?>[];
    for (int i = 0; i < steps && _navigationStack.isNotEmpty; i++) {
      popped.add(popNavigation());
    }
    return popped;
  }

  /// Clear specific session data key
  static void clearSessionDataKey(String key) {
    LoggerUtil.info('NavigationDataManager: Clearing session data key: $key');
    _sessionData.remove(key);
  }

  /// Clear all session data
  static void clearAllSessionData() {
    LoggerUtil.info('NavigationDataManager: Clearing all session data');
    _sessionData.clear();
  }

  /// Clear everything
  static void clearAll() {
    LoggerUtil.info('NavigationDataManager: Clearing all data');
    _sessionData.clear();
    _flowHistory.clear();
    _navigationStack.clear();
  }

  /// Get statistics
  static Map<String, dynamic> getStats() {
    return {
      'sessionDataKeys': _sessionData.length,
      'flowHistoryCount': _flowHistory.length,
      'navigationStackDepth': _navigationStack.length,
      'canGoBack': canGoBack(),
      'navigationStack': _navigationStack,
    };
  }

  /// Restore from backup (for state persistence)
  static void restoreFromBackup(Map<String, dynamic> backup) {
    if (backup.containsKey('sessionData')) {
      _sessionData.clear();
      _sessionData.addAll(backup['sessionData'] as Map<String, dynamic>);
    }
    if (backup.containsKey('flowHistory')) {
      _flowHistory.clear();
      (backup['flowHistory'] as Map<String, dynamic>).forEach((key, value) {
        _flowHistory[key] = Map<String, dynamic>.from(value);
      });
    }
    LoggerUtil.info('NavigationDataManager: Restored from backup');
  }

  /// Create backup for state persistence
  static Map<String, dynamic> createBackup() {
    return {
      'sessionData': Map<String, dynamic>.from(_sessionData),
      'flowHistory': _flowHistory
          .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
