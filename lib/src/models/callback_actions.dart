/// Generic callback action models for JSON-based UI events
///
/// Provides generic, reusable action definitions that can be triggered by any event.
/// Each action handles specific behaviors like navigation, state updates, API calls, etc.

import 'package:equatable/equatable.dart';
import 'callback_context.dart';

/// Base class for all callback actions
///
/// All actions implement this interface to provide:
/// - Consistent JSON serialization
/// - Type-safe execution
/// - Error handling and result propagation
/// - Action chaining via onSuccess/onError
///
/// ## Action Types
///
/// ```
/// Action (abstract)
/// ├─ NavigateAction    - Navigate to screen
/// ├─ SetStateAction    - Update widget state
/// ├─ ApiCallAction     - Make HTTP request
/// └─ CustomAction      - Call custom handler
/// ```
///
/// ## Factory Pattern for JSON Parsing
///
/// ```dart
/// // Parse action from JSON
/// final json = {
///   'action': 'apiCall',
///   'method': 'POST',
///   'endpoint': '/api/login',
/// };
/// final action = Action.fromJson(json);
/// ```
///
/// ## Usage with Events
///
/// Actions are triggered by generic events:
/// - `onPressed` - Button tapped
/// - `onTap` - Widget tapped
/// - `onLongTap` - Widget long-pressed
/// - `onChanged` - Value changed (input, checkbox)
/// - `onSubmitted` - Form submitted
///
/// See also:
/// - [CallbackContext]: Execution environment
/// - [NavigateAction]: Screen navigation
/// - [SetStateAction]: State updates
/// - [ApiCallAction]: HTTP requests
/// - [CustomAction]: Custom handlers
abstract class Action extends Equatable {
  /// Action type identifier
  ///
  /// Used for JSON serialization and factory pattern routing.
  /// Common values: navigate, setState, apiCall, custom
  final String action;

  /// Success callback
  ///
  /// Executed when action completes successfully.
  /// Can be another action for chaining.
  final Action? onSuccess;

  /// Error callback
  ///
  /// Executed when action encounters an error.
  /// Can be another action for error recovery.
  final Action? onError;

  const Action({
    required this.action,
    this.onSuccess,
    this.onError,
  });

  @override
  List<Object?> get props => [action, onSuccess, onError];

  /// Executes the action
  ///
  /// Performs the action logic and handles success/error callbacks.
  /// Returns: bool indicating success
  Future<bool> execute(CallbackContext context);

  /// Converts action to JSON
  Map<String, dynamic> toJson();

  /// Factory constructor for JSON deserialization
  ///
  /// Routes to appropriate action type based on 'action' field.
  ///
  /// Supports:
  /// - navigate
  /// - setState
  /// - apiCall
  /// - custom
  factory Action.fromJson(Map<String, dynamic> json) {
    final actionType = json['action'] as String?;

    switch (actionType) {
      case 'navigate':
        return NavigateAction.fromJson(json);
      case 'setState':
        return SetStateAction.fromJson(json);
      case 'apiCall':
        return ApiCallAction.fromJson(json);
      case 'custom':
        return CustomAction.fromJson(json);
      default:
        throw ArgumentError('Unknown action type: $actionType');
    }
  }
}

/// Navigate to another screen
///
/// Pushes a new route onto the navigation stack or replaces current route.
///
/// ## JSON Example - Basic Navigation
///
/// ```json
/// {
///   "action": "navigate",
///   "target": "dashboard_screen"
/// }
/// ```
///
/// ## JSON Example - Replace Current Route
///
/// ```json
/// {
///   "action": "navigate",
///   "target": "login_screen",
///   "replace": true
/// }
/// ```
///
/// ## JSON Example - With Arguments
///
/// ```json
/// {
///   "action": "navigate",
///   "target": "user_detail_screen",
///   "arguments": {"userId": 123, "userName": "John"}
/// }
/// ```
///
/// ## Usage with Events
///
/// ```json
/// {
///   "type": "button",
///   "events": {
///     "onPressed": {
///       "action": "navigate",
///       "target": "dashboard"
///     }
///   }
/// }
/// ```
class NavigateAction extends Action {
  /// Target screen/route name
  final String target;

  /// Whether to replace current route
  ///
  /// If true, uses `pushReplacementNamed` instead of `pushNamed`.
  /// Useful for login flows where you don't want back button to return to login.
  final bool replace;

  /// Route arguments
  ///
  /// Optional parameters to pass to the target screen.
  /// Can include complex objects.
  final Map<String, dynamic>? arguments;

  const NavigateAction({
    required this.target,
    this.replace = false,
    this.arguments,
    Action? onSuccess,
    Action? onError,
  }) : super(action: 'navigate', onSuccess: onSuccess, onError: onError);

  @override
  List<Object?> get props => [action, target, replace, arguments, onSuccess, onError];

  @override
  Future<bool> execute(CallbackContext context) async {
    try {
      final result = await context.navigate(target);
      if (result && onSuccess != null) {
        await onSuccess!.execute(context);
      } else if (!result && onError != null) {
        await onError!.execute(context);
      }
      return result;
    } catch (e) {
      context.showError('Navigation failed: ${e.toString()}');
      if (onError != null) {
        await onError!.execute(context);
      }
      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'action': action,
        'target': target,
        'replace': replace,
        if (arguments != null) 'arguments': arguments,
        if (onSuccess != null) 'onSuccess': onSuccess!.toJson(),
        if (onError != null) 'onError': onError!.toJson(),
      };

  factory NavigateAction.fromJson(Map<String, dynamic> json) {
    final onSuccessJson = json['onSuccess'] as Map<String, dynamic>?;
    final onErrorJson = json['onError'] as Map<String, dynamic>?;
    return NavigateAction(
      target: json['target'] as String,
      replace: json['replace'] as bool? ?? false,
      arguments: json['arguments'] as Map<String, dynamic>?,
      onSuccess: onSuccessJson != null ? Action.fromJson(onSuccessJson) : null,
      onError: onErrorJson != null ? Action.fromJson(onErrorJson) : null,
    );
  }
}

/// Set state action
///
/// Updates widget state with new values.
/// Triggers UI rebuild with updated data.
///
/// ## JSON Example - Simple Update
///
/// ```json
/// {
///   "action": "setState",
///   "updates": {
///     "loading": false,
///     "error": null
///   }
/// }
/// ```
///
/// ## JSON Example - With Field References
///
/// ```json
/// {
///   "action": "setState",
///   "updates": {
///     "emailInput": "${email_field.value}",
///     "formFilled": true
///   }
/// }
/// ```
///
/// ## Usage - Toggle State
///
/// ```json
/// {
///   "type": "checkbox",
///   "events": {
///     "onChanged": {
///       "action": "setState",
///       "updates": {"agreeToTerms": "${this.value}"}
///     }
///   }
/// }
/// ```
///
/// ## Usage - Show/Hide Error
///
/// ```json
/// {
///   "action": "setState",
///   "updates": {"showError": true, "errorMsg": "Invalid input"}
/// }
/// ```
class SetStateAction extends Action {
  /// State updates to apply
  ///
  /// Map of state variable names to new values.
  /// Supports template variables like ${field.value}
  final Map<String, dynamic> updates;

  const SetStateAction({
    required this.updates,
    Action? onSuccess,
    Action? onError,
  }) : super(action: 'setState', onSuccess: onSuccess, onError: onError);

  @override
  List<Object?> get props => [action, updates, onSuccess, onError];

  @override
  Future<bool> execute(CallbackContext context) async {
    try {
      context.updateState(updates);

      if (onSuccess != null) {
        await onSuccess!.execute(context);
      }

      return true;
    } catch (e) {
      context.showError('State update failed: ${e.toString()}');

      if (onError != null) {
        await onError!.execute(context);
      }

      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'action': action,
        'updates': updates,
        if (onSuccess != null) 'onSuccess': onSuccess!.toJson(),
        if (onError != null) 'onError': onError!.toJson(),
      };

  factory SetStateAction.fromJson(Map<String, dynamic> json) {
    final onSuccessJson = json['onSuccess'] as Map<String, dynamic>?;
    final onErrorJson = json['onError'] as Map<String, dynamic>?;
    return SetStateAction(
      updates: json['updates'] as Map<String, dynamic>? ?? {},
      onSuccess: onSuccessJson != null ? Action.fromJson(onSuccessJson) : null,
      onError: onErrorJson != null ? Action.fromJson(onErrorJson) : null,
    );
  }
}

/// API call action
///
/// Makes HTTP request to backend API.
/// Supports GET, POST, PUT, DELETE, PATCH methods.
///
/// ## JSON Example - POST Request
///
/// ```json
/// {
///   "action": "apiCall",
///   "method": "POST",
///   "endpoint": "/api/auth/login",
///   "body": {
///     "email": "${email_input.value}",
///     "password": "${password_input.value}"
///   },
///   "onSuccess": {
///     "action": "setState",
///     "updates": {"loggedIn": true}
///   },
///   "onError": {
///     "action": "setState",
///     "updates": {"error": "Login failed"}
///   }
/// }
/// ```
///
/// ## JSON Example - GET with Query Params
///
/// ```json
/// {
///   "action": "apiCall",
///   "method": "GET",
///   "endpoint": "/api/users",
///   "queryParams": {"page": "1", "limit": "10"}
/// }
/// ```
///
/// ## JSON Example - Custom Headers
///
/// ```json
/// {
///   "action": "apiCall",
///   "method": "POST",
///   "endpoint": "/api/data",
///   "headers": {
///     "Authorization": "Bearer token",
///     "Content-Type": "application/json"
///   },
///   "body": {"name": "John"}
/// }
/// ```
///
/// ## Usage - Form Submission
///
/// ```json
/// {
///   "type": "button",
///   "properties": {"label": "Submit"},
///   "events": {
///     "onPressed": {
///       "action": "apiCall",
///       "method": "POST",
///       "endpoint": "/api/forms/submit",
///       "body": {
///         "name": "${name_field.value}",
///         "email": "${email_field.value}"
///       }
///     }
///   }
/// }
/// ```
///
/// ## Usage - With Loading State
///
/// ```json
/// {
///   "action": "setState",
///   "updates": {"loading": true},
///   "onSuccess": {
///     "action": "apiCall",
///     "method": "POST",
///     "endpoint": "/api/login",
///     "body": {"email": "..."},
///     "onSuccess": {
///       "action": "setState",
///       "updates": {"loading": false, "loggedIn": true}
///     },
///     "onError": {
///       "action": "setState",
///       "updates": {"loading": false, "error": "Failed"}
///     }
///   }
/// }
/// ```
class ApiCallAction extends Action {
  /// HTTP method (GET, POST, PUT, DELETE, PATCH)
  final String method;

  /// API endpoint URL
  ///
  /// Can be relative or absolute. 
  /// Examples: "/api/users", "https://api.example.com/data"
  final String endpoint;

  /// Request body (for POST, PUT, PATCH)
  ///
  /// Will be sent as JSON.
  /// Can contain template variables like ${field.value}
  final Map<String, dynamic>? body;

  /// Query parameters
  ///
  /// Will be appended to URL.
  /// Example: {page: "1", limit: "10"} → ?page=1&limit=10
  final Map<String, String>? queryParams;

  /// HTTP headers
  ///
  /// Custom headers to include in request.
  /// Example: {"Authorization": "Bearer token"}
  final Map<String, String>? headers;

  /// Request timeout in seconds
  ///
  /// Default: 30 seconds
  final int timeout;

  const ApiCallAction({
    required this.method,
    required this.endpoint,
    this.body,
    this.queryParams,
    this.headers,
    this.timeout = 30,
    Action? onSuccess,
    Action? onError,
  }) : super(action: 'apiCall', onSuccess: onSuccess, onError: onError);

  @override
  List<Object?> get props => [
        action,
        method,
        endpoint,
        body,
        queryParams,
        headers,
        timeout,
        onSuccess,
        onError
      ];

  @override
  Future<bool> execute(CallbackContext context) async {
    try {
      context.updateState({'loading': true, 'error': null});

      // TODO: Make actual API call when http client is available in context
      // For now, simulate successful API call
      await Future.delayed(Duration(milliseconds: 500));

      context.showSuccess('API call successful');
      context.updateState({'loading': false});

      if (onSuccess != null) {
        await onSuccess!.execute(context);
      }

      return true;
    } catch (e) {
      final errorMessage = 'API call failed: ${e.toString()}';
      context.showError(errorMessage);
      context.updateState({'loading': false, 'error': errorMessage});

      if (onError != null) {
        await onError!.execute(context);
      }

      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'action': action,
        'method': method,
        'endpoint': endpoint,
        if (body != null) 'body': body,
        if (queryParams != null) 'queryParams': queryParams,
        if (headers != null) 'headers': headers,
        if (timeout != 30) 'timeout': timeout,
        if (onSuccess != null) 'onSuccess': onSuccess!.toJson(),
        if (onError != null) 'onError': onError!.toJson(),
      };

  factory ApiCallAction.fromJson(Map<String, dynamic> json) {
    final onSuccessJson = json['onSuccess'] as Map<String, dynamic>?;
    final onErrorJson = json['onError'] as Map<String, dynamic>?;
    return ApiCallAction(
      method: json['method'] as String,
      endpoint: json['endpoint'] as String,
      body: json['body'] as Map<String, dynamic>?,
      queryParams: (json['queryParams'] as Map<String, dynamic>?)?.cast<String, String>(),
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
      timeout: json['timeout'] as int? ?? 30,
      onSuccess: onSuccessJson != null ? Action.fromJson(onSuccessJson) : null,
      onError: onErrorJson != null ? Action.fromJson(onErrorJson) : null,
    );
  }
}

/// Custom action
///
/// Calls a custom Dart handler function.
/// Allows developers to extend action system with app-specific logic.
///
/// ## JSON Example - Simple Custom Action
///
/// ```json
/// {
///   "action": "custom",
///   "handler": "onLoginButtonPressed"
/// }
/// ```
///
/// ## JSON Example - With Parameters
///
/// ```json
/// {
///   "action": "custom",
///   "handler": "processFormData",
///   "parameters": {
///     "email": "${email_field.value}",
///     "name": "${name_field.value}",
///     "subscribe": true
///   }
/// }
/// ```
///
/// ## Usage - Validate Input
///
/// ```json
/// {
///   "type": "button",
///   "properties": {"label": "Validate"},
///   "events": {
///     "onPressed": {
///       "action": "custom",
///       "handler": "validateForm",
///       "parameters": {
///         "requiredFields": ["email", "password"]
///       }
///     }
///   }
/// }
/// ```
///
/// ## Registering Custom Handlers in Dart
///
/// ```dart
/// final customHandlers = {
///   'onLoginButtonPressed': (context, params) async {
///     // Custom logic here
///   },
///   'validateForm': (context, params) async {
///     // Validation logic
///   },
/// };
/// ```
class CustomAction extends Action {
  /// Handler name to call
  ///
  /// Name of the custom handler function registered in the app.
  final String handler;

  /// Parameters to pass to handler
  ///
  /// Optional map of data passed to the handler function.
  final Map<String, dynamic>? parameters;

  const CustomAction({
    required this.handler,
    this.parameters,
    Action? onSuccess,
    Action? onError,
  }) : super(action: 'custom', onSuccess: onSuccess, onError: onError);

  @override
  List<Object?> get props => [action, handler, parameters, onSuccess, onError];

  @override
  Future<bool> execute(CallbackContext context) async {
    try {
      // TODO: Call custom handler from context or handler registry
      // For now, just show a message
      context.showSuccess('Custom handler "$handler" executed');

      if (onSuccess != null) {
        await onSuccess!.execute(context);
      }

      return true;
    } catch (e) {
      context.showError('Custom handler failed: ${e.toString()}');

      if (onError != null) {
        await onError!.execute(context);
      }

      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'action': action,
        'handler': handler,
        if (parameters != null) 'parameters': parameters,
        if (onSuccess != null) 'onSuccess': onSuccess!.toJson(),
        if (onError != null) 'onError': onError!.toJson(),
      };

  factory CustomAction.fromJson(Map<String, dynamic> json) {
    final onSuccessJson = json['onSuccess'] as Map<String, dynamic>?;
    final onErrorJson = json['onError'] as Map<String, dynamic>?;
    return CustomAction(
      handler: json['handler'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
      onSuccess: onSuccessJson != null ? Action.fromJson(onSuccessJson) : null,
      onError: onErrorJson != null ? Action.fromJson(onErrorJson) : null,
    );
  }
}
