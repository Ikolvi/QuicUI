/// Form Controller for QuicUI
/// Manages form state, fields, and validation

import 'package:flutter/material.dart';
import 'field_types.dart';
import 'validators/base_validator.dart';

// ===== FIELD STATE =====

/// Represents the state of a single form field
class FieldState {
  /// Field configuration
  final FormFieldConfig config;

  /// Current field value
  dynamic value;

  /// Field error message (null if valid)
  String? errorMessage;

  /// Whether field has been touched
  bool touched;

  /// Whether field is validating
  bool validating;

  /// Whether validation passed
  bool isValid;

  /// Creates a field state
  FieldState({
    required this.config,
    this.value,
    this.errorMessage,
    this.touched = false,
    this.validating = false,
    this.isValid = true,
  });

  /// Resets field state
  void reset() {
    value = config.initialValue;
    errorMessage = null;
    touched = false;
    validating = false;
    isValid = true;
  }

  /// Marks field as touched
  void touch() {
    touched = true;
  }
}

// ===== FORM STATE =====

/// Enum for form submission state
enum FormSubmissionState {
  idle,
  validating,
  submitting,
  success,
  failure,
}

/// Enum for form dirty state
enum FormDirtyState {
  clean,
  dirty,
  resetting,
}

// ===== FORM CONTROLLER =====

/// Controller for managing form state and validation
class FormController with ChangeNotifier {
  /// Form identifier
  final String formId;

  /// Field states by field ID
  final Map<String, FieldState> _fields = {};

  /// Validators by field ID
  final Map<String, List<BaseValidator>> _validators = {};

  /// Form submission state
  FormSubmissionState _submissionState = FormSubmissionState.idle;

  /// Form dirty state
  FormDirtyState _dirtyState = FormDirtyState.clean;

  /// Last error
  String? _lastError;

  /// Submission data
  Map<String, dynamic>? _submissionData;

  /// Creates a form controller
  FormController({required this.formId});

  // ===== GETTERS =====

  /// Get all field states
  Map<String, FieldState> get fields => _fields;

  /// Get submission state
  FormSubmissionState get submissionState => _submissionState;

  /// Get dirty state
  FormDirtyState get dirtyState => _dirtyState;

  /// Get last error message
  String? get lastError => _lastError;

  /// Get submission data
  Map<String, dynamic>? get submissionData => _submissionData;

  /// Check if form is dirty
  bool get isDirty => _dirtyState == FormDirtyState.dirty;

  /// Check if form is valid
  bool get isValid {
    return _fields.values.every((field) => field.isValid);
  }

  /// Check if form is submitting
  bool get isSubmitting => _submissionState == FormSubmissionState.submitting;

  /// Check if form submission succeeded
  bool get submissionSucceeded =>
      _submissionState == FormSubmissionState.success;

  /// Check if form submission failed
  bool get submissionFailed => _submissionState == FormSubmissionState.failure;

  /// Get form values
  Map<String, dynamic> get values {
    return _fields.map((id, field) => MapEntry(id, field.value));
  }

  /// Get form errors
  Map<String, String> get errors {
    final errorMap = <String, String>{};
    _fields.forEach((id, field) {
      if (field.errorMessage != null) {
        errorMap[id] = field.errorMessage!;
      }
    });
    return errorMap;
  }

  // ===== FIELD REGISTRATION =====

  /// Register a field
  void registerField(
    FormFieldConfig config, {
    List<BaseValidator>? validators,
  }) {
    _fields[config.id] = FieldState(
      config: config,
      value: config.initialValue,
    );
    if (validators != null && validators.isNotEmpty) {
      _validators[config.id] = validators;
    }
  }

  /// Unregister a field
  void unregisterField(String fieldId) {
    _fields.remove(fieldId);
    _validators.remove(fieldId);
  }

  /// Register multiple fields
  void registerFields(
    List<FormFieldConfig> configs, {
    Map<String, List<BaseValidator>>? validatorsMap,
  }) {
    for (final config in configs) {
      registerField(
        config,
        validators: validatorsMap?[config.id],
      );
    }
  }

  // ===== FIELD VALUE MANAGEMENT =====

  /// Set field value
  void setFieldValue(String fieldId, dynamic value) {
    if (!_fields.containsKey(fieldId)) return;

    _fields[fieldId]!.value = value;
    _dirtyState = FormDirtyState.dirty;
    notifyListeners();
  }

  /// Get field value
  dynamic getFieldValue(String fieldId) {
    return _fields[fieldId]?.value;
  }

  /// Set multiple field values
  void setFieldValues(Map<String, dynamic> values) {
    values.forEach((id, value) {
      if (_fields.containsKey(id)) {
        _fields[id]!.value = value;
      }
    });
    _dirtyState = FormDirtyState.dirty;
    notifyListeners();
  }

  /// Touch a field
  void touchField(String fieldId) {
    if (_fields.containsKey(fieldId)) {
      _fields[fieldId]!.touch();
      notifyListeners();
    }
  }

  /// Get field state
  FieldState? getFieldState(String fieldId) {
    return _fields[fieldId];
  }

  // ===== VALIDATION =====

  /// Validate a single field
  Future<bool> validateField(String fieldId) async {
    if (!_fields.containsKey(fieldId)) return false;

    final field = _fields[fieldId]!;
    final validators = _validators[fieldId];

    if (validators == null || validators.isEmpty) {
      field.isValid = true;
      field.errorMessage = null;
      notifyListeners();
      return true;
    }

    field.validating = true;
    notifyListeners();

    // Run validators
    for (final validator in validators) {
      final result = validator.validate(
        field.value,
        field.config.label,
      );
      if (!result.isValid) {
        field.isValid = false;
        field.errorMessage = result.errorMessage;
        field.validating = false;
        notifyListeners();
        return false;
      }
    }

    field.isValid = true;
    field.errorMessage = null;
    field.validating = false;
    notifyListeners();
    return true;
  }

  /// Validate all fields
  Future<bool> validateAll() async {
    _submissionState = FormSubmissionState.validating;
    notifyListeners();

    bool allValid = true;
    for (final fieldId in _fields.keys) {
      final valid = await validateField(fieldId);
      if (!valid) allValid = false;
    }

    _submissionState = FormSubmissionState.idle;
    notifyListeners();
    return allValid;
  }

  /// Get field error
  String? getFieldError(String fieldId) {
    return _fields[fieldId]?.errorMessage;
  }

  /// Set field error manually
  void setFieldError(String fieldId, String? error) {
    if (!_fields.containsKey(fieldId)) return;

    _fields[fieldId]!.errorMessage = error;
    _fields[fieldId]!.isValid = error == null;
    notifyListeners();
  }

  /// Clear field errors
  void clearErrors() {
    for (final field in _fields.values) {
      field.errorMessage = null;
      field.isValid = true;
    }
    notifyListeners();
  }

  // ===== FORM SUBMISSION =====

  /// Submit form
  /// Returns true if validation passed and submission succeeded
  Future<bool> submit({
    required Future<bool> Function(Map<String, dynamic>) onSubmit,
  }) async {
    // Validate form
    final valid = await validateAll();
    if (!valid) {
      _submissionState = FormSubmissionState.failure;
      _lastError = 'Form validation failed';
      notifyListeners();
      return false;
    }

    _submissionState = FormSubmissionState.submitting;
    notifyListeners();

    try {
      final success = await onSubmit(values);
      if (success) {
        _submissionState = FormSubmissionState.success;
        _submissionData = values;
        _lastError = null;
      } else {
        _submissionState = FormSubmissionState.failure;
        _lastError = 'Submission failed';
      }
    } catch (e) {
      _submissionState = FormSubmissionState.failure;
      _lastError = e.toString();
    }

    notifyListeners();
    return _submissionState == FormSubmissionState.success;
  }

  /// Reset submission state
  void resetSubmissionState() {
    _submissionState = FormSubmissionState.idle;
    _lastError = null;
    _submissionData = null;
    notifyListeners();
  }

  // ===== FORM RESET =====

  /// Reset form to initial state
  void reset() {
    _dirtyState = FormDirtyState.resetting;
    for (final field in _fields.values) {
      field.reset();
    }
    _dirtyState = FormDirtyState.clean;
    resetSubmissionState();
    notifyListeners();
  }

  /// Reset specific field
  void resetField(String fieldId) {
    if (_fields.containsKey(fieldId)) {
      _fields[fieldId]!.reset();
      notifyListeners();
    }
  }

  /// Reset multiple fields
  void resetFields(List<String> fieldIds) {
    for (final id in fieldIds) {
      resetField(id);
    }
  }

  // ===== FIELD VISIBILITY =====

  /// Check if field should be visible
  bool isFieldVisible(String fieldId) {
    if (!_fields.containsKey(fieldId)) return false;

    final field = _fields[fieldId]!;
    if (!field.config.isVisible) return false;

    // Check visibility condition
    final condition = field.config.visibilityCondition;
    if (condition == null) return true;

    // Simple condition evaluation
    // Can be extended for more complex logic
    final dependentFieldId = condition['dependsOn'] as String?;
    if (dependentFieldId == null) return true;

    final dependentValue = getFieldValue(dependentFieldId);
    final expectedValue = condition['value'];

    return dependentValue == expectedValue;
  }

  /// Get visible fields
  List<String> get visibleFieldIds {
    return _fields.keys.where((id) => isFieldVisible(id)).toList();
  }

  // ===== UTILITIES =====

  /// Clear all data
  void clear() {
    _fields.clear();
    _validators.clear();
    reset();
  }

  /// Get form summary
  Map<String, dynamic> getSummary() {
    return {
      'formId': formId,
      'totalFields': _fields.length,
      'validFields': _fields.values.where((f) => f.isValid).length,
      'invalidFields': _fields.values.where((f) => !f.isValid).length,
      'touchedFields':
          _fields.values.where((f) => f.touched).length,
      'isDirty': isDirty,
      'isValid': isValid,
      'submissionState': _submissionState.toString(),
    };
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
