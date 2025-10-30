/// Tests for callback action system
///
/// Comprehensive tests covering:
/// - Action creation and JSON parsing
/// - Action chaining with onSuccess/onError
/// - State updates
/// - Navigation
/// - API calls

import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/models/callback_actions.dart' as callback_actions;
import 'package:quicui/src/models/callback_context.dart';
import 'package:flutter/material.dart';

void main() {
  group('Action Creation & Parsing', () {
    test('Create NavigateAction directly', () {
      final action = callback_actions.NavigateAction(target: 'dashboard');
      expect(action.action, equals('navigate'));
      expect(action.target, equals('dashboard'));
      expect(action.replace, isFalse);
    });

    test('Parse NavigateAction from JSON', () {
      final json = {
        'action': 'navigate',
        'target': 'dashboard',
        'replace': true,
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action, isA<callback_actions.NavigateAction>());
      expect((action as callback_actions.NavigateAction).target, equals('dashboard'));
      expect(action.replace, isTrue);
    });

    test('Create SetStateAction directly', () {
      final action = callback_actions.SetStateAction(
        updates: {'loading': false, 'error': null},
      );
      expect(action.action, equals('setState'));
      expect(action.updates, equals({'loading': false, 'error': null}));
    });

    test('Parse SetStateAction from JSON', () {
      final json = {
        'action': 'setState',
        'updates': {'count': 5, 'message': 'Updated'},
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action, isA<callback_actions.SetStateAction>());
      expect((action as callback_actions.SetStateAction).updates['count'], equals(5));
    });

    test('Create ApiCallAction directly', () {
      final action = callback_actions.ApiCallAction(
        method: 'POST',
        endpoint: '/api/login',
        body: {'email': 'test@example.com'},
      );
      expect(action.action, equals('apiCall'));
      expect(action.method, equals('POST'));
      expect(action.endpoint, equals('/api/login'));
    });

    test('Parse ApiCallAction from JSON', () {
      final json = {
        'action': 'apiCall',
        'method': 'GET',
        'endpoint': '/api/users',
        'timeout': 30,
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action, isA<callback_actions.ApiCallAction>());
      expect((action as callback_actions.ApiCallAction).method, equals('GET'));
    });

    test('Create CustomAction directly', () {
      final action = callback_actions.CustomAction(
        handler: 'validateForm',
        parameters: {'fields': ['email', 'password']},
      );
      expect(action.action, equals('custom'));
      expect(action.handler, equals('validateForm'));
    });

    test('Parse CustomAction from JSON', () {
      final json = {
        'action': 'custom',
        'handler': 'myHandler',
        'parameters': {'key': 'value'},
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action, isA<callback_actions.CustomAction>());
      expect((action as callback_actions.CustomAction).handler, equals('myHandler'));
    });

    test('Throw error for unknown action type', () {
      final json = {
        'action': 'unknownAction',
      };
      expect(
        () => callback_actions.Action.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Action Chaining', () {
    test('NavigateAction with onSuccess', () {
      final successAction = callback_actions.SetStateAction(updates: {'done': true});
      final action = callback_actions.NavigateAction(
        target: 'dashboard',
        onSuccess: successAction,
      );
      expect(action.onSuccess, equals(successAction));
    });

    test('Parse action with nested onSuccess', () {
      final json = {
        'action': 'navigate',
        'target': 'dashboard',
        'onSuccess': {
          'action': 'setState',
          'updates': {'loggedIn': true},
        },
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action.onSuccess, isNotNull);
      expect(action.onSuccess, isA<callback_actions.SetStateAction>());
    });

    test('Parse action with nested onError', () {
      final json = {
        'action': 'apiCall',
        'method': 'POST',
        'endpoint': '/api/login',
        'onError': {
          'action': 'setState',
          'updates': {'error': 'Login failed'},
        },
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action.onError, isNotNull);
      expect(action.onError, isA<callback_actions.SetStateAction>());
    });

    test('Parse deeply nested action chain', () {
      final json = {
        'action': 'setState',
        'updates': {'loading': true},
        'onSuccess': {
          'action': 'apiCall',
          'method': 'POST',
          'endpoint': '/api/data',
          'onSuccess': {
            'action': 'navigate',
            'target': 'success',
          },
          'onError': {
            'action': 'setState',
            'updates': {'error': 'Failed'},
          },
        },
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action.onSuccess, isA<callback_actions.ApiCallAction>());
      expect(action.onSuccess!.onSuccess, isA<callback_actions.NavigateAction>());
      expect(action.onSuccess!.onError, isA<callback_actions.SetStateAction>());
    });
  });

  group('Action JSON Serialization', () {
    test('NavigateAction toJson', () {
      final action = callback_actions.NavigateAction(
        target: 'dashboard',
        replace: true,
        arguments: {'id': 123},
      );
      final json = action.toJson();
      expect(json['action'], equals('navigate'));
      expect(json['target'], equals('dashboard'));
      expect(json['replace'], isTrue);
      expect(json['arguments']['id'], equals(123));
    });

    test('SetStateAction toJson', () {
      final action = callback_actions.SetStateAction(
        updates: {'count': 5},
      );
      final json = action.toJson();
      expect(json['action'], equals('setState'));
      expect(json['updates']['count'], equals(5));
    });

    test('ApiCallAction toJson with body', () {
      final action = callback_actions.ApiCallAction(
        method: 'POST',
        endpoint: '/api/users',
        body: {'name': 'John'},
        headers: {'Authorization': 'Bearer token'},
      );
      final json = action.toJson();
      expect(json['method'], equals('POST'));
      expect(json['body']['name'], equals('John'));
      expect(json['headers']['Authorization'], equals('Bearer token'));
    });

    test('CustomAction toJson with parameters', () {
      final action = callback_actions.CustomAction(
        handler: 'myHandler',
        parameters: {'key': 'value'},
      );
      final json = action.toJson();
      expect(json['handler'], equals('myHandler'));
      expect(json['parameters']['key'], equals('value'));
    });

    test('Round-trip: JSON -> Action -> JSON', () {
      final originalJson = {
        'action': 'navigate',
        'target': 'profile',
        'replace': false,
        'arguments': {'userId': 42},
      };
      final action = callback_actions.Action.fromJson(originalJson);
      final jsonAgain = action.toJson();
      expect(jsonAgain, equals(originalJson));
    });

    test('Round-trip: Chained action', () {
      final originalJson = {
        'action': 'setState',
        'updates': {'loading': true},
        'onSuccess': {
          'action': 'apiCall',
          'method': 'GET',
          'endpoint': '/api/data',
        },
      };
      final action = callback_actions.Action.fromJson(originalJson);
      final jsonAgain = action.toJson();
      expect(jsonAgain, equals(originalJson));
    });
  });

  group('CallbackContext', () {
    test('Create context with all callbacks', () {
      // Create a dummy build context
      final widget = Builder(
        builder: (context) {
          final callbackContext = CallbackContext(
            buildContext: context,
            onStateUpdate: (updates) {},
            onNavigate: (route) async => true,
            onError: (error) {},
            onSuccess: (message) {},
          );
          expect(callbackContext.buildContext, equals(context));
          expect(callbackContext.onStateUpdate, isNotNull);
          expect(callbackContext.onNavigate, isNotNull);
          return SizedBox.shrink();
        },
      );
      expect(widget, isNotNull);
    });

    test('CallbackContext copyWith', () {
      final widget = Builder(
        builder: (context) {
          final context1 = CallbackContext(
            buildContext: context,
            userData: {'name': 'John'},
          );
          final context2 = context1.copyWith(
            userData: {'name': 'Jane'},
          );
          expect(context2.userData?['name'], equals('Jane'));
          expect(context1.userData?['name'], equals('John'));
          return SizedBox.shrink();
        },
      );
      expect(widget, isNotNull);
    });
  });

  group('Real-world Scenarios', () {
    test('Login flow action chain', () {
      final json = {
        'action': 'setState',
        'updates': {'loading': true, 'error': null},
        'onSuccess': {
          'action': 'apiCall',
          'method': 'POST',
          'endpoint': '/api/auth/login',
          'body': {'email': 'test@example.com', 'password': 'password'},
          'onSuccess': {
            'action': 'setState',
            'updates': {'loading': false, 'loggedIn': true},
            'onSuccess': {
              'action': 'navigate',
              'target': 'dashboard',
              'replace': true,
            },
          },
          'onError': {
            'action': 'setState',
            'updates': {'loading': false, 'error': 'Login failed'},
          },
        },
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action, isA<callback_actions.SetStateAction>());
      expect(action.onSuccess, isA<callback_actions.ApiCallAction>());
      expect(action.onSuccess!.onSuccess, isA<callback_actions.SetStateAction>());
      expect(action.onSuccess!.onSuccess!.onSuccess, isA<callback_actions.NavigateAction>());
      expect(action.onSuccess!.onError, isA<callback_actions.SetStateAction>());
    });

    test('Form submission with validation', () {
      final json = {
        'action': 'custom',
        'handler': 'validateForm',
        'parameters': {
          'requiredFields': ['email', 'password'],
        },
        'onSuccess': {
          'action': 'apiCall',
          'method': 'POST',
          'endpoint': '/api/auth/register',
          'body': {'email': 'new@example.com', 'password': 'secure'},
          'onSuccess': {
            'action': 'navigate',
            'target': 'verification',
          },
        },
        'onError': {
          'action': 'setState',
          'updates': {'validationError': 'Please fill all fields'},
        },
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action, isA<callback_actions.CustomAction>());
      expect((action as callback_actions.CustomAction).handler, equals('validateForm'));
      expect(action.onSuccess, isA<callback_actions.ApiCallAction>());
      expect(action.onError, isA<callback_actions.SetStateAction>());
    });

    test('Multi-step flow: fetch, update state, navigate', () {
      final json = {
        'action': 'apiCall',
        'method': 'GET',
        'endpoint': '/api/user/profile',
        'onSuccess': {
          'action': 'setState',
          'updates': {'userData': 'response.data', 'lastUpdated': 'now'},
          'onSuccess': {
            'action': 'navigate',
            'target': 'profile_detail',
            'arguments': {'userId': 'userData.id'},
          },
        },
        'onError': {
          'action': 'setState',
          'updates': {'error': 'Failed to load profile'},
        },
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action, isA<callback_actions.ApiCallAction>());
      expect(action.onSuccess, isA<callback_actions.SetStateAction>());
      expect(action.onSuccess!.onSuccess, isA<callback_actions.NavigateAction>());
    });
  });

  group('Edge Cases', () {
    test('Empty updates in SetStateAction', () {
      final action = callback_actions.SetStateAction(updates: {});
      expect(action.updates, isEmpty);
    });

    test('Null body in ApiCallAction', () {
      final action = callback_actions.ApiCallAction(
        method: 'GET',
        endpoint: '/api/data',
      );
      expect(action.body, isNull);
    });

    test('NavigateAction without arguments', () {
      final action = callback_actions.NavigateAction(target: 'home');
      expect(action.arguments, isNull);
    });

    test('CustomAction without parameters', () {
      final action = callback_actions.CustomAction(handler: 'myHandler');
      expect(action.parameters, isNull);
    });

    test('Parse action with extra fields', () {
      final json = {
        'action': 'navigate',
        'target': 'dashboard',
        'extra': 'ignored',
        'other': 123,
      };
      final action = callback_actions.Action.fromJson(json);
      expect(action, isA<callback_actions.NavigateAction>());
      expect((action as callback_actions.NavigateAction).target, equals('dashboard'));
    });
  });
}
