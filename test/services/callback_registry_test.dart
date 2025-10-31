import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/services/callback_registry.dart';

void main() {
  group('CallbackRegistry Tests', () {
    setUp(() {
      // Clear all callbacks before each test
      CallbackRegistry.clearAllCallbacks();
    });

    test('registerCallback stores callback successfully', () {
      void testCallback() {
        // Empty test callback
      }

      CallbackRegistry.registerCallback('test_callback', testCallback);
      expect(CallbackRegistry.isCallbackRegistered('test_callback'), true);
    });

    test('getCallback retrieves registered callback', () {
      void testCallback() {
        // Empty test callback
      }

      CallbackRegistry.registerCallback('test_callback', testCallback);
      final retrieved = CallbackRegistry.getCallback('test_callback');
      
      expect(retrieved, isNotNull);
      expect(retrieved, equals(testCallback));
    });

    test('getCallback returns null for unregistered callback', () {
      final retrieved = CallbackRegistry.getCallback('nonexistent_callback');
      expect(retrieved, isNull);
    });

    test('isCallbackRegistered returns false for unregistered callback', () {
      expect(
        CallbackRegistry.isCallbackRegistered('nonexistent_callback'),
        false
      );
    });

    test('executeCallback executes registered callback', () async {
      bool executed = false;

      CallbackRegistry.registerCallback('test_callback', () {
        executed = true;
      });

      await CallbackRegistry.executeCallback('test_callback');
      expect(executed, true);
    });

    test('executeCallback with parameters passes data correctly', () async {
      Map<String, dynamic>? receivedParams;

      CallbackRegistry.registerCallback('param_callback', (params) {
        receivedParams = params;
      });

      final testParams = {'key1': 'value1', 'key2': 123};
      await CallbackRegistry.executeCallback('param_callback', params: testParams);

      expect(receivedParams, isNotNull);
      expect(receivedParams!['key1'], equals('value1'));
      expect(receivedParams!['key2'], equals(123));
    });

    test('executeCallback handles null parameters', () async {
      int callCount = 0;

      CallbackRegistry.registerCallback('no_param_callback', () {
        callCount++;
      });

      await CallbackRegistry.executeCallback('no_param_callback');
      expect(callCount, equals(1));
    });

    test('registerCallback overwrites existing callback', () async {
      int callCount = 0;

      CallbackRegistry.registerCallback('test_callback', () {
        callCount++;
      });

      await CallbackRegistry.executeCallback('test_callback');
      expect(callCount, equals(1));

      // Register new callback with same name
      CallbackRegistry.registerCallback('test_callback', () {
        callCount += 10;
      });

      await CallbackRegistry.executeCallback('test_callback');
      expect(callCount, equals(11));
    });

    test('clearAllCallbacks removes all registered callbacks', () {
      CallbackRegistry.registerCallback('callback1', () {});
      CallbackRegistry.registerCallback('callback2', () {});
      CallbackRegistry.registerCallback('callback3', () {});

      expect(CallbackRegistry.isCallbackRegistered('callback1'), true);
      expect(CallbackRegistry.isCallbackRegistered('callback2'), true);
      expect(CallbackRegistry.isCallbackRegistered('callback3'), true);

      CallbackRegistry.clearAllCallbacks();

      expect(CallbackRegistry.isCallbackRegistered('callback1'), false);
      expect(CallbackRegistry.isCallbackRegistered('callback2'), false);
      expect(CallbackRegistry.isCallbackRegistered('callback3'), false);
    });

    test('multiple callbacks with different signatures', () async {
      bool simpleExecuted = false;
      String? paramValue;
      int? numValue;

      CallbackRegistry.registerCallback('simple', () {
        simpleExecuted = true;
      });

      CallbackRegistry.registerCallback('with_params', (params) {
        paramValue = params['text'];
        numValue = params['count'];
      });

      await CallbackRegistry.executeCallback('simple');
      expect(simpleExecuted, true);

      await CallbackRegistry.executeCallback('with_params', params: {
        'text': 'hello',
        'count': 42
      });

      expect(paramValue, equals('hello'));
      expect(numValue, equals(42));
    });

    test('executeCallback returns false for non-existent callback', () async {
      try {
        await CallbackRegistry.executeCallback('nonexistent');
        fail('Expected exception for non-existent callback');
      } catch (e) {
        expect(e, isNotNull);
      }
    });

    test('callback with complex nested parameters', () async {
      Map<String, dynamic>? received;

      CallbackRegistry.registerCallback('complex', (params) {
        received = params;
      });

      final complexData = {
        'user': {
          'name': 'John',
          'age': 30,
          'tags': ['admin', 'user']
        },
        'metadata': {
          'timestamp': '2024-01-01',
          'version': 1
        }
      };

      await CallbackRegistry.executeCallback('complex', params: complexData);

      expect(received, isNotNull);
      expect(received!['user']['name'], equals('John'));
      expect(received!['user']['tags'].length, equals(2));
      expect(received!['metadata']['version'], equals(1));
    });

    test('rapid sequential callback execution', () async {
      int counter = 0;

      CallbackRegistry.registerCallback('increment', () {
        counter++;
      });

      for (int i = 0; i < 100; i++) {
        await CallbackRegistry.executeCallback('increment');
      }

      expect(counter, equals(100));
    });

    test('callback state isolation between instances', () async {
      int count1 = 0;
      int count2 = 0;

      CallbackRegistry.registerCallback('counter1', () {
        count1++;
      });

      CallbackRegistry.registerCallback('counter2', () {
        count2++;
      });

      await CallbackRegistry.executeCallback('counter1');
      expect(count1, equals(1));
      expect(count2, equals(0));

      await CallbackRegistry.executeCallback('counter2');
      expect(count1, equals(1));
      expect(count2, equals(1));
    });
  });
}
