import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/services/navigation_data_manager.dart';
import 'package:quicui/src/services/callback_registry.dart';

// Integration tests for flow manager components
void main() {
  group('JSONFlowManager Integration Tests', () {
    setUp(() {
      NavigationDataManager.clearAll();
      CallbackRegistry.clearAllCallbacks();
    });

    test('NavigationDataManager and CallbackRegistry work together', () async {
      // Simulate callback that updates navigation data
      CallbackRegistry.registerCallback('loginCallback', (params) {
        NavigationDataManager.setSessionData('username', params['username']);
        NavigationDataManager.setSessionData('userId', params['userId']);
      });
      
      final data = {'username': 'john', 'userId': 123};
      await CallbackRegistry.executeCallback('loginCallback', params: data);
      
      expect(NavigationDataManager.getSessionData('username'), equals('john'));
      expect(NavigationDataManager.getSessionData('userId'), equals(123));
    });

    test('Navigation flow simulation', () {
      // Simulate multi-flow navigation
      NavigationDataManager.pushNavigation('auth', 'login');
      NavigationDataManager.pushNavigation('auth', 'signup');
      NavigationDataManager.pushNavigation('dashboard', 'home');
      
      expect(NavigationDataManager.getNavigationStack().length, equals(3));
      expect(NavigationDataManager.getCurrentNavigation()!['flowId'], equals('dashboard'));
      expect(NavigationDataManager.canGoBack(), true);
    });

    test('Callback execution with navigation data merge', () async {
      NavigationDataManager.setSessionData('username', 'john');
      
      CallbackRegistry.registerCallback('updateCallback', (params) {
        NavigationDataManager.mergeSessionData(params);
      });
      
      await CallbackRegistry.executeCallback(
        'updateCallback',
        params: {'email': 'john@example.com', 'role': 'admin'},
      );
      
      expect(NavigationDataManager.getSessionData('username'), equals('john'));
      expect(NavigationDataManager.getSessionData('email'), equals('john@example.com'));
      expect(NavigationDataManager.getSessionData('role'), equals('admin'));
    });

    test('Flow navigation with state backup and restore', () {
      NavigationDataManager.setSessionData('counter', 1);
      NavigationDataManager.pushNavigation('flow1', 'screen1');
      
      final backup = NavigationDataManager.createBackup();
      
      NavigationDataManager.clearAll();
      expect(NavigationDataManager.getSessionData('counter'), isNull);
      
      NavigationDataManager.restoreFromBackup(backup);
      expect(NavigationDataManager.getSessionData('counter'), equals(1));
    });

    test('Complex multi-flow navigation with callbacks', () async {
      // Simulate auth flow
      CallbackRegistry.registerCallback('onLogin', (params) {
        NavigationDataManager.setSessionData('username', params['username']);
        NavigationDataManager.setSessionData('token', params['token']);
      });
      
      await CallbackRegistry.executeCallback('onLogin', params: {
        'username': 'jane',
        'token': 'abc123'
      });
      
      // Navigate to dashboard flow
      NavigationDataManager.pushNavigation('dashboard', 'home');
      
      // Data should persist
      expect(NavigationDataManager.getSessionData('username'), equals('jane'));
      expect(NavigationDataManager.getNavigationStack().length, equals(1));
    });

    test('Multiple callbacks in sequence', () async {
      List<int> executionOrder = [];
      
      CallbackRegistry.registerCallback('first', () {
        executionOrder.add(1);
      });
      CallbackRegistry.registerCallback('second', () {
        executionOrder.add(2);
      });
      CallbackRegistry.registerCallback('third', () {
        executionOrder.add(3);
      });
      
      await CallbackRegistry.executeCallback('first');
      await CallbackRegistry.executeCallback('second');
      await CallbackRegistry.executeCallback('third');
      
      expect(executionOrder, equals([1, 2, 3]));
    });

    test('Navigation data isolation per flow state', () {
      // Simulate auth flow state
      NavigationDataManager.saveFlowState('auth', {
        'loginAttempts': 0,
        'locked': false
      });
      
      // Simulate dashboard flow state
      NavigationDataManager.saveFlowState('dashboard', {
        'refreshing': false,
        'filters': {}
      });
      
      final authState = NavigationDataManager.getFlowState('auth');
      final dashboardState = NavigationDataManager.getFlowState('dashboard');
      
      expect(authState!['loginAttempts'], equals(0));
      expect(dashboardState!['refreshing'], false);
    });

    test('Session data with complex nested structures', () {
      final userData = {
        'profile': {
          'name': 'John',
          'email': 'john@example.com',
          'preferences': {
            'theme': 'dark',
            'notifications': true
          }
        },
        'tags': ['vip', 'premium']
      };
      
      NavigationDataManager.mergeSessionData(userData);
      
      final retrieved = NavigationDataManager.getFullSessionData();
      expect(retrieved['profile']['preferences']['theme'], equals('dark'));
      expect(retrieved['tags'].length, equals(2));
    });

    test('Callback with async operations simulation', () async {
      final results = <String>[];
      
      CallbackRegistry.registerCallback('asyncOp', (params) async {
        results.add('started');
        await Future.delayed(Duration(milliseconds: 10));
        results.add('completed');
        return 'done';
      });
      
      await CallbackRegistry.executeCallback('asyncOp');
      
      expect(results.length, equals(2));
      expect(results[0], equals('started'));
    });

    test('Navigation stack growth and management', () {
      for (int i = 0; i < 10; i++) {
        NavigationDataManager.pushNavigation('flow$i', 'screen$i');
      }
      
      expect(NavigationDataManager.getNavigationStack().length, equals(10));
      
      NavigationDataManager.goBack(steps: 5);
      
      expect(NavigationDataManager.getNavigationStack().length, equals(5));
      expect(NavigationDataManager.getCurrentNavigation()!['flowId'], equals('flow4'));
    });

    test('Clear specific session data key', () {
      NavigationDataManager.setSessionData('key1', 'value1');
      NavigationDataManager.setSessionData('key2', 'value2');
      NavigationDataManager.setSessionData('key3', 'value3');
      
      NavigationDataManager.clearSessionDataKey('key2');
      
      expect(NavigationDataManager.getSessionData('key1'), equals('value1'));
      expect(NavigationDataManager.getSessionData('key2'), isNull);
      expect(NavigationDataManager.getSessionData('key3'), equals('value3'));
    });

    test('Manager statistics', () {
      NavigationDataManager.setSessionData('key1', 'value1');
      NavigationDataManager.setSessionData('key2', 'value2');
      NavigationDataManager.pushNavigation('flow1', 'screen1');
      NavigationDataManager.pushNavigation('flow2', 'screen2');
      
      final stats = NavigationDataManager.getStats();
      
      expect(stats['sessionDataKeys'], equals(2));
      expect(stats['navigationStackDepth'], equals(2));
      expect(stats['canGoBack'], true);
    });

    test('Callback registry statistics', () {
      CallbackRegistry.registerCallback('cb1', () {});
      CallbackRegistry.registerCallback('cb2', () {});
      CallbackRegistry.registerCallback('cb3', () {});
      
      expect(CallbackRegistry.isCallbackRegistered('cb1'), true);
      expect(CallbackRegistry.isCallbackRegistered('cb2'), true);
      expect(CallbackRegistry.isCallbackRegistered('nonexistent'), false);
      
      final names = CallbackRegistry.getRegisteredCallbackNames();
      expect(names.length, equals(3));
    });

    test('Integration: Complete flow with callbacks and navigation', () async {
      // Setup callbacks
      CallbackRegistry.registerCallback('authenticate', (params) {
        NavigationDataManager.setSessionData('user', params['username']);
        NavigationDataManager.setSessionData('authenticated', true);
      });
      
      CallbackRegistry.registerCallback('logout', () {
        NavigationDataManager.clearAllSessionData();
      });
      
      // Simulate login flow
      await CallbackRegistry.executeCallback('authenticate', params: {
        'username': 'testuser'
      });
      
      NavigationDataManager.pushNavigation('auth', 'login');
      NavigationDataManager.pushNavigation('dashboard', 'home');
      
      expect(NavigationDataManager.getSessionData('user'), equals('testuser'));
      expect(NavigationDataManager.getNavigationStack().length, equals(2));
      
      // Simulate logout
      await CallbackRegistry.executeCallback('logout');
      
      expect(NavigationDataManager.getSessionData('user'), isNull);
    });
  });
}
