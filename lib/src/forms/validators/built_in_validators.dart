/// Built-in Form Field Validators for QuicUI
/// Provides common validation patterns: required, email, length, pattern, etc.

import 'base_validator.dart';

// ===== REQUIRED VALIDATOR =====

/// Validates that a field has a non-empty value
class RequiredValidator extends BaseValidator {
  @override
  String get name => 'Required';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return '$fieldName is required';
  }
}

// ===== EMAIL VALIDATOR =====

/// Validates email format
class EmailValidator extends BaseValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  String get name => 'Email';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null || value.toString().isEmpty) {
      return ValidationResult.success(); // Optional field
    }

    final email = value.toString().trim();
    if (!_emailRegex.hasMatch(email)) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return 'Please enter a valid email address';
  }
}

// ===== LENGTH VALIDATOR =====

/// Validates string length
class LengthValidator extends BaseValidator {
  final int? minLength;
  final int? maxLength;

  /// Creates a length validator
  ///
  /// At least one of [minLength] or [maxLength] must be specified
  LengthValidator({
    this.minLength,
    this.maxLength,
  }) : assert(minLength != null || maxLength != null,
      'At least one of minLength or maxLength must be specified');

  @override
  String get name => 'Length';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null) {
      return ValidationResult.success();
    }

    final stringValue = value.toString();
    final length = stringValue.length;

    if (minLength != null && length < minLength!) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
        details: {'length': length, 'minLength': minLength},
      );
    }

    if (maxLength != null && length > maxLength!) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
        details: {'length': length, 'maxLength': maxLength},
      );
    }

    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (minLength != null && maxLength != null) {
      return '$fieldName must be between $minLength and $maxLength characters';
    } else if (minLength != null) {
      return '$fieldName must be at least $minLength characters';
    } else {
      return '$fieldName must be at most $maxLength characters';
    }
  }
}

// ===== PATTERN VALIDATOR =====

/// Validates against a regex pattern
class PatternValidator extends BaseValidator {
  final RegExp pattern;
  final String? errorMessage;

  /// Creates a pattern validator
  PatternValidator(
    this.pattern, {
    this.errorMessage,
  });

  /// Factory constructor for string pattern
  factory PatternValidator.fromString(
    String pattern, {
    String? errorMessage,
  }) {
    return PatternValidator(
      RegExp(pattern),
      errorMessage: errorMessage,
    );
  }

  @override
  String get name => 'Pattern';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null || value.toString().isEmpty) {
      return ValidationResult.success();
    }

    if (!pattern.hasMatch(value.toString())) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return errorMessage ?? '$fieldName format is invalid';
  }
}

// ===== NUMERIC VALIDATOR =====

/// Validates numeric values
class NumericValidator extends BaseValidator {
  final num? minValue;
  final num? maxValue;

  /// Creates a numeric validator
  NumericValidator({
    this.minValue,
    this.maxValue,
  });

  @override
  String get name => 'Numeric';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null || (value is String && value.isEmpty)) {
      return ValidationResult.success();
    }

    num? numValue;
    if (value is num) {
      numValue = value;
    } else {
      try {
        numValue = num.parse(value.toString());
      } catch (e) {
        return ValidationResult.failure(
          buildErrorMessage(fieldName, params: params),
        );
      }
    }

    if (minValue != null && numValue < minValue!) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
        details: {'value': numValue, 'minValue': minValue},
      );
    }

    if (maxValue != null && numValue > maxValue!) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
        details: {'value': numValue, 'maxValue': maxValue},
      );
    }

    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (minValue != null && maxValue != null) {
      return '$fieldName must be between $minValue and $maxValue';
    } else if (minValue != null) {
      return '$fieldName must be at least $minValue';
    } else if (maxValue != null) {
      return '$fieldName must be at most $maxValue';
    } else {
      return '$fieldName must be a valid number';
    }
  }
}

// ===== URL VALIDATOR =====

/// Validates URL format
class UrlValidator extends BaseValidator {
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  @override
  String get name => 'Url';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null || value.toString().isEmpty) {
      return ValidationResult.success();
    }

    if (!_urlRegex.hasMatch(value.toString())) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return 'Please enter a valid URL';
  }
}

// ===== PHONE VALIDATOR =====

/// Validates phone number format
class PhoneValidator extends BaseValidator {
  // Simplified pattern - adjust as needed
  static final RegExp _phoneRegex = RegExp(r'^[\d\s\-\+\(\)]{7,}$');

  @override
  String get name => 'Phone';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null || value.toString().isEmpty) {
      return ValidationResult.success();
    }

    final phone = value.toString().replaceAll(' ', '');
    if (!_phoneRegex.hasMatch(phone)) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return 'Please enter a valid phone number';
  }
}

// ===== MATCH VALIDATOR =====

/// Validates that value matches another field's value
class MatchValidator extends BaseValidator {
  final String fieldToMatch;

  /// Creates a match validator
  MatchValidator(this.fieldToMatch);

  @override
  String get name => 'Match';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    final otherValue = params?['otherValue'];
    if (value != otherValue) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return '$fieldName must match $fieldToMatch';
  }
}

// ===== CUSTOM ENUM VALIDATOR =====

/// Validates value is one of allowed options
class EnumValidator extends BaseValidator {
  final List<dynamic> allowedValues;

  /// Creates an enum validator
  EnumValidator(this.allowedValues);

  @override
  String get name => 'Enum';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null) {
      return ValidationResult.success();
    }

    if (!allowedValues.contains(value)) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
        details: {'allowedValues': allowedValues},
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return '$fieldName must be one of the allowed values';
  }
}

// ===== GREATER THAN VALIDATOR =====

/// Validates value is greater than minimum
class GreaterThanValidator extends BaseValidator {
  final num minValue;

  /// Creates a greater than validator
  GreaterThanValidator(this.minValue);

  @override
  String get name => 'GreaterThan';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null) {
      return ValidationResult.success();
    }

    final numValue = num.tryParse(value.toString());
    if (numValue == null || numValue <= minValue) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return '$fieldName must be greater than $minValue';
  }
}

// ===== LESS THAN VALIDATOR =====

/// Validates value is less than maximum
class LessThanValidator extends BaseValidator {
  final num maxValue;

  /// Creates a less than validator
  LessThanValidator(this.maxValue);

  @override
  String get name => 'LessThan';

  @override
  ValidationResult validate(
    dynamic value,
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    if (value == null) {
      return ValidationResult.success();
    }

    final numValue = num.tryParse(value.toString());
    if (numValue == null || numValue >= maxValue) {
      return ValidationResult.failure(
        buildErrorMessage(fieldName, params: params),
      );
    }
    return ValidationResult.success();
  }

  @override
  String buildErrorMessage(
    String fieldName, {
    Map<String, dynamic>? params,
  }) {
    return '$fieldName must be less than $maxValue';
  }
}
