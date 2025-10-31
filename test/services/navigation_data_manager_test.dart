import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/services/navigation_data_manager.dart';

void main() {
  group('NavigationDataManager Tests', () {
    setUp(() {
      // Clear all data before each test
      NavigationDataManager.clearAll();
    });

    test('setSessionData stores data correctly', () {
      NavigationDataManager.setSessionData('username', 'john');
      NavigationDataManager.setSessionData('token', 'abc123');

      final retrieved = NavigationDataManager.getSessionData('username');
      expect(retrieved, equals('john'));
    });

    test('getSessionData returns null for non-existent key', () {
      NavigationDataManager.setSessionData('name', 'test');
      final result = NavigationDataManager.getSessionData('nonexistent');
      expect(result, isNull);
    });

    test('getFullSessionData returns all data', () {
      NavigationDataManager.setSessionData('username', 'john');
      NavigationDataManager.setSessionData('email', 'john@example.com');
      NavigationDataManager.setSessionData('role', 'admin');

      final allData = NavigationDataManager.getFullSessionData();
      expect(allData, isNotNull);
      expect(allData['username'], equals('john'));
      expect(allData['email'], equals('john@example.com'));
      expect(allData['role'], equals('admin'));
    });

    test('mergeSessionData combines data correctly', () {
      NavigationDataManager.setSessionData('username', 'john');
      NavigationDataManager.mergeSessionData({'email': 'john@example.com'});

      final merged = NavigationDataManager.getFullSessionData();
      expect(merged['username'], equals('john'));
      expect(merged['email'], equals('john@example.com'));
    });

    test('mergeSessionData overwrites existing keys', () {
      NavigationDataManager.setSessionData('username', 'john');
      NavigationDataManager.setSessionData('status', 'online');
      NavigationDataManager.mergeSessionData({'username': 'jane'});

      final merged = NavigationDataManager.getFullSessionData();
      expect(merged['username'], equals('jane'));
      expect(merged['status'], equals('online'));
    });

    test('pushNavigation adds to navigation stack', () {
      expect(NavigationDataManager.getNavigationStack().length, equals(0));

      NavigationDataManager.pushNavigation('flow1', 'screen1');
      expect(NavigationDataManager.getNavigationStack().length, equals(1));

      NavigationDataManager.pushNavigation('flow1', 'screen2');
      expect(NavigationDataManager.getNavigationStack().length, equals(2));
    });

    test('popNavigation removes from stack', () {
      NavigationDataManager.pushNavigation('flow1', 'screen1');
      NavigationDataManager.pushNavigation('flow1', 'screen2');
      expect(NavigationDataManager.getNavigationStack().length, equals(2));

      NavigationDataManager.popNavigation();
      expect(NavigationDataManager.getNavigationStack().length, equals(1));
    });

    test('canGoBack returns correct value', () {
      expect(NavigationDataManager.canGoBack(), false);

      NavigationDataManager.pushNavigation('flow1', 'screen1');
      expect(NavigationDataManager.canGoBack(), false);

      NavigationDataManager.pushNavigation('flow1', 'screen2');
      expect(NavigationDataManager.canGoBack(), true);
    });

    test('getCurrentNavigation returns latest entry', () {
      NavigationDataManager.pushNavigation('flow1', 'screen1');
      NavigationDataManager.pushNavigation('flow2', 'screen2');

      final current = NavigationDataManager.getCurrentNavigation();
      expect(current, isNotNull);
      if (current != null) {
        expect(current['flowId'], equals('flow2'));
        expect(current['screenId'], equals('screen2'));
      }
    });

    test('goBack navigates back in history', () {
      NavigationDataManager.pushNavigation('flow1', 'screen1');
      NavigationDataManager.pushNavigation('flow2', 'screen2');
      NavigationDataManager.pushNavigation('flow3', 'screen3');

      expect(NavigationDataManager.getNavigationStack().length, equals(3));

      NavigationDataManager.goBack(steps: 1);
      expect(NavigationDataManager.getNavigationStack().length, equals(2));

      final current = NavigationDataManager.getCurrentNavigation();
      expect(current!['flowId'], equals('flow2'));
    });

    test('goBack with multiple steps', () {
      NavigationDataManager.pushNavigation('flow1', 'screen1');
      NavigationDataManager.pushNavigation('flow2', 'screen2');
      NavigationDataManager.pushNavigation('flow3', 'screen3');
      NavigationDataManager.pushNavigation('flow4', 'screen4');

      expect(NavigationDataManager.getNavigationStack().length, equals(4));

      NavigationDataManager.goBack(steps: 2);
      expect(NavigationDataManager.getNavigationStack().length, equals(2));

      final current = NavigationDataManager.getCurrentNavigation();
      expect(current!['flowId'], equals('flow2'));
    });

    test('clearAllSessionData removes session data', () {
      NavigationDataManager.setSessionData('key', 'value');
      NavigationDataManager.pushNavigation('flow1', 'screen1');

      NavigationDataManager.clearAllSessionData();

      expect(NavigationDataManager.getFullSessionData(), isEmpty);
      // Navigation stack should still exist
      expect(NavigationDataManager.getNavigationStack().length, equals(1));
    });

    test('clearFlowHistory removes flow history', () {
      NavigationDataManager.saveFlowState('flow1', {'data': 'value1'});
      NavigationDataManager.saveFlowState('flow2', {'data': 'value2'});

      NavigationDataManager.clearFlowHistory();

      expect(NavigationDataManager.getFlowState('flow1'), isNull);
      expect(NavigationDataManager.getFlowState('flow2'), isNull);
    });

    test('session data persists across navigation', () {
      NavigationDataManager.setSessionData('username', 'john');
      NavigationDataManager.setSessionData('userId', 123);

      NavigationDataManager.pushNavigation('flow1', 'screen1');
      NavigationDataManager.pushNavigation('flow2', 'screen2');
      NavigationDataManager.pushNavigation('flow3', 'screen3');

      expect(NavigationDataManager.getSessionData('username'), equals('john'));
      expect(NavigationDataManager.getSessionData('userId'), equals(123));
    });

    test('saveFlowState and getFlowState', () {
      final state = {
        'screenData': {'id': 1, 'name': 'test'},
        'formValues': {'field1': 'value1'}
      };

      NavigationDataManager.saveFlowState('dashboard', state);
      final retrieved = NavigationDataManager.getFlowState('dashboard');

      expect(retrieved, isNotNull);
      if (retrieved != null) {
        expect(retrieved['screenData']['name'], equals('test'));
        expect(retrieved['formValues']['field1'], equals('value1'));
      }
    });

    test('getNavigationStack returns accurate list', () {
      expect(NavigationDataManager.getNavigationStack().length, equals(0));

      for (int i = 1; i <= 10; i++) {
        NavigationDataManager.pushNavigation('flow', 'screen$i');
        expect(NavigationDataManager.getNavigationStack().length, equals(i));
      }
    });

    test('navigation stack maintains order', () {
      final flows = ['auth', 'dashboard', 'profile', 'settings'];

      for (final flow in flows) {
        NavigationDataManager.pushNavigation(flow, 'screen');
      }

      final stack = NavigationDataManager.getNavigationStack();
      expect(stack.isNotEmpty, true);
      expect(stack.first['flowId'], equals('auth'));
      expect(stack.last['flowId'], equals('settings'));
    });

    test('createBackup and restoreFromBackup', () {
      NavigationDataManager.setSessionData('counter', 1);
      NavigationDataManager.pushNavigation('flow1', 'screen1');

      final backup = NavigationDataManager.createBackup();
      expect(backup, isNotNull);

      NavigationDataManager.setSessionData('counter', 2);
      NavigationDataManager.pushNavigation('flow2', 'screen2');

      NavigationDataManager.restoreFromBackup(backup);

      expect(NavigationDataManager.getSessionData('counter'), equals(1));
    });

    test('mergeSessionData with empty data', () {
      NavigationDataManager.setSessionData('key1', 'value1');
      NavigationDataManager.mergeSessionData({});

      expect(NavigationDataManager.getSessionData('key1'), equals('value1'));
    });

    test('navigation with same flow different screens', () {
      NavigationDataManager.pushNavigation('dashboard', 'home');
      NavigationDataManager.pushNavigation('dashboard', 'profile');
      NavigationDataManager.pushNavigation('dashboard', 'settings');

      expect(NavigationDataManager.getNavigationStack().length, equals(3));

      final current = NavigationDataManager.getCurrentNavigation();
      expect(current, isNotNull);
      if (current != null) {
        expect(current['screenId'], equals('settings'));
        expect(current['flowId'], equals('dashboard'));
      }
    });

    test('clearSessionDataKey removes specific key only', () {
      NavigationDataManager.setSessionData('key1', 'value1');
      NavigationDataManager.setSessionData('key2', 'value2');
      NavigationDataManager.setSessionData('key3', 'value3');

      NavigationDataManager.clearSessionDataKey('key2');

      expect(NavigationDataManager.getSessionData('key1'), equals('value1'));
      expect(NavigationDataManager.getSessionData('key2'), isNull);
      expect(NavigationDataManager.getSessionData('key3'), equals('value3'));
    });

    test('getStats returns correct statistics', () {
      NavigationDataManager.setSessionData('key1', 'value1');
      NavigationDataManager.setSessionData('key2', 'value2');
      NavigationDataManager.pushNavigation('flow1', 'screen1');
      NavigationDataManager.pushNavigation('flow2', 'screen2');

      final stats = NavigationDataManager.getStats();

      expect(stats['sessionDataKeys'], equals(2));
      expect(stats['navigationStackDepth'], equals(2));
      expect(stats['canGoBack'], true);
    });

    test('clearFlowHistory with specific flowId', () {
      NavigationDataManager.saveFlowState('flow1', {'data': 'value1'});
      NavigationDataManager.saveFlowState('flow2', {'data': 'value2'});

      NavigationDataManager.clearFlowHistory(flowId: 'flow1');

      expect(NavigationDataManager.getFlowState('flow1'), isNull);
      expect(NavigationDataManager.getFlowState('flow2'), isNotNull);
    });
  });
}
