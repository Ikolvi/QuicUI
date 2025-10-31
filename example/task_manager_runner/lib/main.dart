import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load flow configuration
  final configJson = await rootBundle.loadString('assets/flow_config.json');
  final config = jsonDecode(configJson) as Map<String, dynamic>;

  runApp(
    QuicUIMultiFlowApp(
      initialFlowId: config['initialFlow'] ?? 'auth',
      flowConfigs: Map<String, String>.from(config['flows'] ?? {}),
      globalCallbacks: config['globalCallbacks'] ?? {},
    ),
  );
}

class QuicUIMultiFlowApp extends StatefulWidget {
  final String initialFlowId;
  final Map<String, String> flowConfigs; // {flowId: jsonPath}
  final Map<String, dynamic> globalCallbacks;

  const QuicUIMultiFlowApp({
    required this.initialFlowId,
    required this.flowConfigs,
    this.globalCallbacks = const {},
    super.key,
  });

  @override
  State<QuicUIMultiFlowApp> createState() => _QuicUIMultiFlowAppState();
}

class _QuicUIMultiFlowAppState extends State<QuicUIMultiFlowApp> {
  late JSONFlowManager _flowManager;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFlowManager();
  }

  Future<void> _initializeFlowManager() async {
    try {
      _flowManager = JSONFlowManager();

      // Register global callbacks
      widget.globalCallbacks.forEach((name, callback) {
        if (callback is Function) {
          CallbackRegistry.registerCallback(name, callback);
        }
      });

      // Initialize with initial flow
      await _flowManager.initializeApp(
        widget.initialFlowId,
        widget.flowConfigs[widget.initialFlowId]!,
        additionalFlowConfigs: widget.flowConfigs,
      );

      // Register flow navigation callback
      _flowManager.onScreenChange((screenId, data) {
        setState(() {});
      });

      // Preload other flows for faster navigation
      final otherFlows = widget.flowConfigs.keys
          .where((id) => id != widget.initialFlowId)
          .toList();
      if (otherFlows.isNotEmpty) {
        await _flowManager.preloadFlows(otherFlows);
      }

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      LoggerUtil.error('Failed to initialize flow manager', e, StackTrace.current);
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Initialization Error:', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_error!),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }

    try {
      final currentFlowId = _flowManager.getCurrentFlowId();
      final currentScreenId = _flowManager.getCurrentScreenId();
      final navigationData = _flowManager.getNavigationData();

      return FutureBuilder<Map<String, dynamic>>(
        future: _flowManager.getFlow(currentFlowId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading: $currentFlowId',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final flowData = snapshot.data!;
          final screens = (flowData['screens'] as Map<String, dynamic>?) ?? {};
          final screenConfig = screens[currentScreenId] as Map<String, dynamic>?;

          if (screenConfig == null) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text('Screen not found: $currentScreenId'),
                      const SizedBox(height: 8),
                      Text('Flow: $currentFlowId'),
                      const SizedBox(height: 16),
                      if (_flowManager.canGoBack())
                        ElevatedButton(
                          onPressed: () {
                            _flowManager.goBack().then((_) {
                              setState(() {});
                            });
                          },
                          child: const Text('Go Back'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Inject navigation callbacks into screen config
          final enhancedConfig = Map<String, dynamic>.from(screenConfig);
          enhancedConfig['onNavigateTo'] = (String screenId, {Map<String, dynamic>? data}) {
            _flowManager.navigateToScreen(screenId, data: data);
            setState(() {});
          };
          enhancedConfig['onFlowNavigate'] =
              (String flowId, String screenId, Map<String, dynamic>? data) {
            _flowManager.navigateToFlow(flowId, screenId, data: data).then((_) {
              setState(() {});
            });
          };
          enhancedConfig['onExecuteCallback'] =
              (String callbackName, Map<String, dynamic>? params) async {
            try {
              await _flowManager.executeCallback(callbackName, params: params);
            } catch (e) {
              LoggerUtil.error('Error executing callback: $callbackName', e, StackTrace.current);
            }
          };
          enhancedConfig['onUpdateNavigationData'] =
              (Map<String, dynamic> data, bool merge) {
            if (merge) {
              _flowManager.updateNavigationData(data);
            } else {
              NavigationDataManager.clearAllSessionData();
              _flowManager.updateNavigationData(data);
            }
            setState(() {});
          };
          enhancedConfig['onGoBack'] = (int steps, bool clearData) {
            _flowManager.goBack(steps: steps, clearData: clearData).then((_) {
              setState(() {});
            });
          };
          enhancedConfig['navigationData'] = navigationData;

          return MaterialApp(
            title: flowData['properties']?['title'] ?? 'QuicUI App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true),
            home: UIRenderer.render(enhancedConfig, context: context),
          );
        },
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error rendering screen', e, stackTrace);
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Rendering Error'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(e.toString()),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
