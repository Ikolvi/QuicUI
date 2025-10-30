/// Callback execution context
///
/// Provides context information for action execution, including:
/// - Access to widget data
/// - State management
/// - Navigation capability
/// - API communication
/// - Error handling

import 'package:flutter/material.dart';

/// Execution context for callback actions
///
/// Contains all necessary information for actions to execute properly:
/// - Navigation context (BuildContext)
/// - State manager reference
/// - User data and session info
/// - Form data and field values
/// - Error and success handlers
///
/// ## Usage Example
///
/// ```dart
/// final context = CallbackContext(
///   buildContext: context,
///   onNavigate: (screen) => Navigator.pushNamed(context, screen),
///   onError: (error) => ScaffoldMessenger.of(context).showSnackBar(...),
///   getFieldValue: (fieldId) => formState.getValue(fieldId),
/// );
///
/// // Execute action with context
/// await action.execute(context);
/// ```
class CallbackContext {
  /// Flutter BuildContext for navigation and UI operations
  final BuildContext buildContext;

  /// Callback for state updates (e.g., setState)
  ///
  /// Called when actions need to update widget state.
  /// Parameters: Map<String, dynamic> with state updates
  final Function(Map<String, dynamic> updates)? onStateUpdate;

  /// Callback for navigation
  ///
  /// Called when action requests navigation.
  /// Parameters: String route name
  /// Returns: Future<bool> indicating success
  final Future<bool> Function(String route)? onNavigate;

  /// Callback for error handling
  ///
  /// Called when action encounters an error.
  /// Parameters: String error message
  final Function(String error)? onError;

  /// Callback for success messages
  ///
  /// Called when action completes successfully.
  /// Parameters: String success message
  final Function(String message)? onSuccess;

  /// Function to get field value from form
  ///
  /// Used by login and form submission actions.
  /// Parameters: String field ID
  /// Returns: dynamic field value
  final dynamic Function(String fieldId)? getFieldValue;

  /// Function to set field value in form
  ///
  /// Used by actions that update form fields.
  /// Parameters: String field ID, dynamic value
  final Function(String fieldId, dynamic value)? setFieldValue;

  /// HTTP client for API calls
  ///
  /// Can be injected for testing or custom configuration.
  final dynamic httpClient;

  /// Current user data
  ///
  /// Contains authenticated user information.
  /// Can be null if user is not authenticated.
  final Map<String, dynamic>? userData;

  /// Session token for API authentication
  ///
  /// Automatically included in API requests.
  final String? sessionToken;

  /// Custom metadata and configuration
  ///
  /// Used to pass additional context-specific data.
  final Map<String, dynamic>? metadata;

  /// Creates callback context
  ///
  /// All parameters are optional except buildContext.
  const CallbackContext({
    required this.buildContext,
    this.onStateUpdate,
    this.onNavigate,
    this.onError,
    this.onSuccess,
    this.getFieldValue,
    this.setFieldValue,
    this.httpClient,
    this.userData,
    this.sessionToken,
    this.metadata,
  });

  /// Creates a copy with modified fields
  CallbackContext copyWith({
    BuildContext? buildContext,
    Function(Map<String, dynamic> updates)? onStateUpdate,
    Future<bool> Function(String route)? onNavigate,
    Function(String error)? onError,
    Function(String message)? onSuccess,
    dynamic Function(String fieldId)? getFieldValue,
    Function(String fieldId, dynamic value)? setFieldValue,
    dynamic httpClient,
    Map<String, dynamic>? userData,
    String? sessionToken,
    Map<String, dynamic>? metadata,
  }) {
    return CallbackContext(
      buildContext: buildContext ?? this.buildContext,
      onStateUpdate: onStateUpdate ?? this.onStateUpdate,
      onNavigate: onNavigate ?? this.onNavigate,
      onError: onError ?? this.onError,
      onSuccess: onSuccess ?? this.onSuccess,
      getFieldValue: getFieldValue ?? this.getFieldValue,
      setFieldValue: setFieldValue ?? this.setFieldValue,
      httpClient: httpClient ?? this.httpClient,
      userData: userData ?? this.userData,
      sessionToken: sessionToken ?? this.sessionToken,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper to show error message
  void showError(String message) {
    onError?.call(message);
  }

  /// Helper to show success message
  void showSuccess(String message) {
    onSuccess?.call(message);
  }

  /// Helper to navigate
  Future<bool> navigate(String route) async {
    if (onNavigate != null) {
      return await onNavigate!(route);
    }
    return false;
  }

  /// Helper to update state
  void updateState(Map<String, dynamic> updates) {
    onStateUpdate?.call(updates);
  }

  /// Helper to get field value
  dynamic getField(String fieldId) {
    return getFieldValue?.call(fieldId);
  }

  /// Helper to set field value
  void setField(String fieldId, dynamic value) {
    setFieldValue?.call(fieldId, value);
  }
}
