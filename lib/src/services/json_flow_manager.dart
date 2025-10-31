import 'json_loader.dart';
import 'callback_registry.dart';
import 'navigation_data_manager.dart';
import '../utils/logger_util.dart';

/// Manages multi-JSON flow orchestration and navigation
/// Central manager for handling flow transitions, screen rendering, and data passing
class JSONFlowManager {
  // Current flow and screen state
  String _currentFlowId = '';
  String _currentScreenId = '';
  Map<String, String> _flowConfigs = {}; // {flowId: jsonPath}

  // Cached loaded flows
  final Map<String, Map<String, dynamic>> _loadedFlows = {};

  // Navigation callbacks
  Function(String screenId, Map<String, dynamic>? data)? _onScreenChangeCallback;

  /// Initialize the flow manager with initial flow
  Future<void> initializeApp(
    String initialFlowId,
    String initialJsonPath, {
    Map<String, String>? additionalFlowConfigs,
  }) async {
    try {
      LoggerUtil.info(
        'JSONFlowManager: Initializing with flow: $initialFlowId',
      );

      _currentFlowId = initialFlowId;
      _flowConfigs = {initialFlowId: initialJsonPath};

      if (additionalFlowConfigs != null) {
        _flowConfigs.addAll(additionalFlowConfigs);
      }

      // Load initial flow
      await loadFlow(initialFlowId, initialJsonPath);

      // Get first screen from flow
      final flow = _loadedFlows[initialFlowId];
      if (flow == null || flow['screens'] == null) {
        throw Exception('No screens found in flow: $initialFlowId');
      }

      final screensMap = flow['screens'] as Map<String, dynamic>;
      _currentScreenId = screensMap.keys.first;

      // Push to navigation stack
      NavigationDataManager.pushNavigation(_currentFlowId, _currentScreenId);

      LoggerUtil.info(
        'JSONFlowManager: Initialized - Current: $_currentFlowId/$_currentScreenId',
      );
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Initialization failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Load a flow (JSON file)
  Future<Map<String, dynamic>> loadFlow(String flowId, String jsonPath) async {
    try {
      LoggerUtil.info('JSONFlowManager: Loading flow: $flowId from $jsonPath');

      // Check if already loaded
      if (_loadedFlows.containsKey(flowId)) {
        LoggerUtil.info('JSONFlowManager: Using cached flow: $flowId');
        // Set as current if not set yet
        if (!_isInitialized()) {
          _currentFlowId = flowId;
          final flow = _loadedFlows[flowId]!;
          if (flow['screens'] != null) {
            final screensMap = flow['screens'] as Map<String, dynamic>;
            _currentScreenId = screensMap.keys.first;
            NavigationDataManager.pushNavigation(_currentFlowId, _currentScreenId);
          }
        }
        return Map<String, dynamic>.from(_loadedFlows[flowId]!);
      }

      // Load from JSONLoader
      final flowJson = await JSONLoader.loadJsonFromAssets(jsonPath);
      _loadedFlows[flowId] = flowJson;

      // Set as current if this is the first load
      if (!_isInitialized()) {
        _currentFlowId = flowId;
        if (flowJson['screens'] != null) {
          final screensMap = flowJson['screens'] as Map<String, dynamic>;
          _currentScreenId = screensMap.keys.first;
          NavigationDataManager.pushNavigation(_currentFlowId, _currentScreenId);
          LoggerUtil.info(
            'JSONFlowManager: Set current flow: $_currentFlowId/$_currentScreenId',
          );
        }
      }

      LoggerUtil.info('JSONFlowManager: Flow loaded successfully: $flowId');
      return Map<String, dynamic>.from(flowJson);
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Failed to load flow: $flowId',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Get a loaded flow
  Future<Map<String, dynamic>> getFlow(String flowId) async {
    try {
      if (_loadedFlows.containsKey(flowId)) {
        return Map<String, dynamic>.from(_loadedFlows[flowId]!);
      }

      // Try to load if config exists
      if (_flowConfigs.containsKey(flowId)) {
        return await loadFlow(flowId, _flowConfigs[flowId]!);
      }

      throw Exception('Flow not found or configured: $flowId');
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Failed to get flow: $flowId',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Navigate to a screen within the current flow
  void navigateToScreen(String screenId, {Map<String, dynamic>? data}) {
    try {
      LoggerUtil.info(
        'JSONFlowManager: Navigating to screen: $screenId in flow: $_currentFlowId',
      );

      final flow = _loadedFlows[_currentFlowId];
      if (flow == null || flow['screens'] == null) {
        throw Exception('Flow not loaded: $_currentFlowId');
      }

      final screensMap = flow['screens'] as Map<String, dynamic>;
      if (!screensMap.containsKey(screenId)) {
        throw Exception('Screen not found in flow: $screenId');
      }

      _currentScreenId = screenId;
      NavigationDataManager.pushNavigation(_currentFlowId, _currentScreenId);

      if (data != null) {
        NavigationDataManager.mergeSessionData(data);
      }

      _triggerScreenChange();

      LoggerUtil.info(
        'JSONFlowManager: Screen changed to: $_currentFlowId/$_currentScreenId',
      );
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Failed to navigate to screen: $screenId',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Navigate to a different flow with optional screen and data
  Future<void> navigateToFlow(
    String targetFlowId,
    String targetScreenId, {
    Map<String, dynamic>? data,
  }) async {
    try {
      LoggerUtil.info(
        'JSONFlowManager: Navigating to flow: $targetFlowId, screen: $targetScreenId',
      );

      // Ensure flow is loaded
      await getFlow(targetFlowId);

      _currentFlowId = targetFlowId;
      _currentScreenId = targetScreenId;

      NavigationDataManager.pushNavigation(_currentFlowId, _currentScreenId);

      if (data != null) {
        NavigationDataManager.mergeSessionData(data);
      }

      _triggerScreenChange();

      LoggerUtil.info(
        'JSONFlowManager: Navigated to flow: $_currentFlowId/$_currentScreenId',
      );
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Failed to navigate to flow: $targetFlowId',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Register a callback for screen changes
  void onScreenChange(
    Function(String screenId, Map<String, dynamic>? data)? callback,
  ) {
    _onScreenChangeCallback = callback;
  }

  /// Execute a registered callback
  Future<dynamic> executeCallback(
    String callbackName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      LoggerUtil.info('JSONFlowManager: Executing callback: $callbackName');
      return await CallbackRegistry.executeCallback(
        callbackName,
        params: params,
      );
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Failed to execute callback: $callbackName',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Get current navigation data
  Map<String, dynamic> getNavigationData() {
    return NavigationDataManager.getFullSessionData();
  }

  /// Update navigation data
  void updateNavigationData(Map<String, dynamic> data) {
    NavigationDataManager.mergeSessionData(data);
  }

  /// Get current flow ID
  String getCurrentFlowId() {
    return _currentFlowId;
  }

  /// Get current screen ID
  String getCurrentScreenId() {
    return _currentScreenId;
  }

  /// Get current screen config
  Map<String, dynamic>? getCurrentScreenConfig() {
    try {
      final flow = _loadedFlows[_currentFlowId];
      if (flow == null || flow['screens'] == null) {
        return null;
      }

      final screensMap = flow['screens'] as Map<String, dynamic>;
      return screensMap[_currentScreenId] as Map<String, dynamic>?;
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Failed to get current screen config',
        e,
        StackTrace.current,
      );
      return null;
    }
  }

  /// Go back in navigation history
  Future<void> goBack({int steps = 1, bool clearData = true}) async {
    try {
      if (!canGoBack()) {
        LoggerUtil.warning('JSONFlowManager: Cannot go back - at root');
        return;
      }

      LoggerUtil.info('JSONFlowManager: Going back $steps steps');

      final popped = NavigationDataManager.goBack(steps: steps);
      if (popped.isEmpty) {
        return;
      }

      final previousNav = popped.last;
      if (previousNav != null) {
        _currentFlowId = previousNav['flowId']!;
        _currentScreenId = previousNav['screenId']!;

        if (clearData) {
          NavigationDataManager.clearAllSessionData();
        }

        _triggerScreenChange();

        LoggerUtil.info(
          'JSONFlowManager: Navigated back to: $_currentFlowId/$_currentScreenId',
        );
      }
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Failed to go back',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Can go back
  bool canGoBack() {
    return NavigationDataManager.canGoBack();
  }

  /// Register a global callback
  void registerCallback(String name, Function callback) {
    LoggerUtil.info('JSONFlowManager: Registering global callback: $name');
    CallbackRegistry.registerCallback(name, callback);
  }

  /// Register flow configurations (flowId -> jsonPath mappings)
  void registerFlowConfigs(Map<String, String> flowConfigs) {
    LoggerUtil.info('JSONFlowManager: Registering ${flowConfigs.length} flow configs');
    _flowConfigs.addAll(flowConfigs);
    LoggerUtil.info('JSONFlowManager: Registered flows: ${_flowConfigs.keys.toList()}');
  }

  /// Preload flows
  Future<void> preloadFlows(List<String> flowIds) async {
    try {
      LoggerUtil.info('JSONFlowManager: Preloading ${flowIds.length} flows');
      final futures = flowIds
          .where((id) => _flowConfigs.containsKey(id))
          .map((id) => loadFlow(id, _flowConfigs[id]!));
      await Future.wait(futures);
      LoggerUtil.info('JSONFlowManager: Preload completed');
    } catch (e) {
      LoggerUtil.error(
        'JSONFlowManager: Preload failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Get statistics
  Map<String, dynamic> getStats() {
    return {
      'currentFlow': _currentFlowId,
      'currentScreen': _currentScreenId,
      'loadedFlows': _loadedFlows.keys.toList(),
      'registeredFlows': _flowConfigs.keys.toList(),
      'navigationData': getNavigationData(),
      'navigationStack': NavigationDataManager.getNavigationStack(),
    };
  }

  /// Trigger screen change callback
  void _triggerScreenChange() {
    if (_onScreenChangeCallback != null) {
      _onScreenChangeCallback!(_currentScreenId, getNavigationData());
    }
  }

  /// Clear cache
  void clearCache({String? flowId}) {
    if (flowId != null) {
      _loadedFlows.remove(flowId);
      LoggerUtil.info('JSONFlowManager: Cleared cache for flow: $flowId');
    } else {
      _loadedFlows.clear();
      LoggerUtil.info('JSONFlowManager: Cleared all flow cache');
    }
  }

  /// Reset to initial state
  void reset() {
    LoggerUtil.info('JSONFlowManager: Resetting to initial state');
    _loadedFlows.clear();
    NavigationDataManager.clearAll();
  }

  /// Check if fields have been initialized
  bool _isInitialized() {
    return _currentFlowId.isNotEmpty && _currentScreenId.isNotEmpty;
  }
}
