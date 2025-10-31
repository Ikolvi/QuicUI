/// Base Validator Classes for QuicUI Form System
/// Provides foundation for all form field validation

// ===== VALIDATION RESULT =====

/// Result of a validation operation
class ValidationResult {
  /// Whether validation passed
  final bool isValid;

  /// Error message if validation failed
  final String? errorMessage;

  /// Additional error details/metadata
  final Map<String, dynamic>? details;

  /// Creates a validation result
  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.details,
  });

  /// Creates a successful validation result
  factory ValidationResult.success() {
    return ValidationResult(isValid: true);
  }

  /// Creates a failed validation result with error message
  factory ValidationResult.failure(
    String errorMessage, {
    Map<String, dynamic>? details,
  }) {
    return ValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      details: details,
    );
  }

  /// Converts result to JSON
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'errorMessage': errorMessage,
      'details': details,
    };
  }

  @override
  String toString() {
    if (isValid) return 'ValidationResult(valid)';
    return 'ValidationResult(invalid: $errorMessage)';
  }
}

// ===== BASE VALIDATOR =====

/// Abstract base class for form field validators
abstract class BaseValidator {
  /// Display name for the validator
  String get name;

  /// Validates a value
  ///
  /// [value] - The value to validate
  /// [fieldName] - The name of the field being validated
  /// [params] - Additional validation parameters
  ///
  /// Returns [ValidationResult] indicating validity
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  });

  /// Builds error message for validation failure
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  });
}

// ===== VALIDATOR CHAIN =====

/// Combines multiple validators into a single validator
class ValidatorChain extends BaseValidator {
  /// List of validators to execute
  final List<BaseValidator> validators;

  /// Creates a validator chain
  ValidatorChain(this.validators);

  @override
  String get name => 'ValidatorChain';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    // Run all validators and return first failure
    for (final validator in validators) {
      final result = validator.validate(value, fieldName, params: params);
      if (!result.isValid) {
        return result;
      }
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return 'Validation failed';
  }
}

// ===== CONDITIONAL VALIDATOR =====

/// Validator that runs conditionally based on a predicate
class ConditionalValidator extends BaseValidator {
  /// The actual validator to use
  final BaseValidator validator;

  /// Predicate function to determine if validation should run
  final bool Function(dynamic value) shouldValidate;

  /// Creates a conditional validator
  ConditionalValidator({
    required this.validator,
    required this.shouldValidate,
  });

  @override
  String get name => 'ConditionalValidator(${validator.name})';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    // Only validate if predicate returns true
    if (!shouldValidate(value)) {
      return ValidationResult.success();
    }
    return validator.validate(value, fieldName, params: params);
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return validator.buildErrorMessage(fieldName, params: params);
  }
}

// ===== ASYNC VALIDATOR =====

/// Base class for async validators
abstract class AsyncValidator {
  /// Display name for the validator
  String get name;

  /// Validates a value asynchronously
  ///
  /// [value] - The value to validate
  /// [fieldName] - The name of the field being validated
  /// [params] - Additional validation parameters
  ///
  /// Returns [ValidationResult] in a Future
  Future<ValidationResult> validateAsync(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  });

  /// Builds error message for validation failure
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  });
}

// ===== VALIDATION CONTEXT =====

/// Context for validation operations
class ValidationContext {
  /// All form field values
  final Map<String, dynamic> formValues;

  /// Current field being validated
  final String fieldName;

  /// Current field value
  final dynamic fieldValue;

  /// Validation parameters
  final Map<String, dynamic>? params;

  /// Creates a validation context
  ValidationContext({
    required this.formValues,
    required this.fieldName,
    required this.fieldValue,
    this.params,
  });

  /// Get another field's value
  dynamic getFieldValue(String fieldName) {
    return formValues[fieldName];
  }

  /// Check if another field has a value
  bool hasFieldValue(String fieldName) {
    return formValues.containsKey(fieldName) && formValues[fieldName] != null;
  }
}

// ===== CUSTOM VALIDATOR BUILDER =====

/// Utility for creating custom validators
class CustomValidator extends BaseValidator {
  /// Validation function
  final ValidationResult Function(dynamic value, String fieldName,
      {Map<String, dynamic>? params}) validationFn;

  /// Error message builder function
  final String Function(String fieldName, {Map<String, dynamic>? params})
      errorMessageFn;

  /// Custom validator name
  final String _name;

  /// Creates a custom validator
  CustomValidator({
    required this.validationFn,
    required this.errorMessageFn,
    String? name,
  }) : _name = name ?? 'CustomValidator';

  @override
  String get name => _name;

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return validationFn(value, fieldName, params: params);
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return errorMessageFn(fieldName, params: params);
  }
}

// ===== COMPOSITE VALIDATORS =====

/// OR composition - passes if any validator passes
class OrValidator extends BaseValidator {
  /// List of validators
  final List<BaseValidator> validators;

  /// Creates an OR validator
  OrValidator(this.validators);

  @override
  String get name => 'OrValidator';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    for (final validator in validators) {
      final result = validator.validate(value, fieldName, params: params);
      if (result.isValid) {
        return result;
      }
    }
    return ValidationResult.failure(
      'None of the validators passed',
    );
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return 'Field does not meet any of the validation criteria';
  }
}

/// AND composition - passes only if all validators pass
class AndValidator extends BaseValidator {
  /// List of validators
  final List<BaseValidator> validators;

  /// Creates an AND validator
  AndValidator(this.validators);

  @override
  String get name => 'AndValidator';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    for (final validator in validators) {
      final result = validator.validate(value, fieldName, params: params);
      if (!result.isValid) {
        return result;
      }
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return 'Field does not meet all validation criteria';
  }
}

/// NOT composition - inverts validator result
class NotValidator extends BaseValidator {
  /// The validator to invert
  final BaseValidator validator;

  /// Creates a NOT validator
  NotValidator(this.validator);

  @override
  String get name => 'NotValidator(${validator.name})';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    final result = validator.validate(value, fieldName, params: params);
    if (result.isValid) {
      return ValidationResult.failure(
        'Value should not match this pattern',
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return 'Field value is invalid';
  }
}
