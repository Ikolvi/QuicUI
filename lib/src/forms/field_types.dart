/// Form Field Types and Configurations for QuicUI
/// Defines all supported field types and their properties

import 'package:flutter/material.dart';

// ===== FIELD TYPE ENUM =====

/// Enum for all supported form field types
enum FieldType {
  text,
  email,
  password,
  phone,
  number,
  decimal,
  date,
  time,
  datetime,
  checkbox,
  radio,
  select,
  multiselect,
  textarea,
  slider,
  toggle,
  file,
  custom,
}

/// Extension to get field type name
extension FieldTypeExtension on FieldType {
  String get name {
    switch (this) {
      case FieldType.text:
        return 'text';
      case FieldType.email:
        return 'email';
      case FieldType.password:
        return 'password';
      case FieldType.phone:
        return 'phone';
      case FieldType.number:
        return 'number';
      case FieldType.decimal:
        return 'decimal';
      case FieldType.date:
        return 'date';
      case FieldType.time:
        return 'time';
      case FieldType.datetime:
        return 'datetime';
      case FieldType.checkbox:
        return 'checkbox';
      case FieldType.radio:
        return 'radio';
      case FieldType.select:
        return 'select';
      case FieldType.multiselect:
        return 'multiselect';
      case FieldType.textarea:
        return 'textarea';
      case FieldType.slider:
        return 'slider';
      case FieldType.toggle:
        return 'toggle';
      case FieldType.file:
        return 'file';
      case FieldType.custom:
        return 'custom';
    }
  }

  static FieldType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'email':
        return FieldType.email;
      case 'password':
        return FieldType.password;
      case 'phone':
        return FieldType.phone;
      case 'number':
        return FieldType.number;
      case 'decimal':
        return FieldType.decimal;
      case 'date':
        return FieldType.date;
      case 'time':
        return FieldType.time;
      case 'datetime':
        return FieldType.datetime;
      case 'checkbox':
        return FieldType.checkbox;
      case 'radio':
        return FieldType.radio;
      case 'select':
        return FieldType.select;
      case 'multiselect':
        return FieldType.multiselect;
      case 'textarea':
        return FieldType.textarea;
      case 'slider':
        return FieldType.slider;
      case 'toggle':
        return FieldType.toggle;
      case 'file':
        return FieldType.file;
      case 'custom':
        return FieldType.custom;
      case 'text':
      default:
        return FieldType.text;
    }
  }
}

// ===== FORM FIELD CONFIGURATION =====

/// Configuration for a form field
class FormFieldConfig {
  /// Unique identifier for the field
  final String id;

  /// Field type (text, email, password, etc.)
  final FieldType fieldType;

  /// Display label
  final String label;

  /// Field placeholder text
  final String? placeholder;

  /// Helper text
  final String? helperText;

  /// Whether field is required
  final bool isRequired;

  /// Initial value
  final dynamic initialValue;

  /// Whether field is disabled
  final bool isDisabled;

  /// Input hint text
  final String? hint;

  /// Maximum length for text fields
  final int? maxLength;

  /// Minimum value for numeric fields
  final num? minValue;

  /// Maximum value for numeric fields
  final num? maxValue;

  /// Options for select/radio/checkbox fields
  final List<FormFieldOption>? options;

  /// Validation rules
  final List<String>? validators;

  /// Custom validation messages
  final Map<String, String>? validationMessages;

  /// Whether to display error inline
  final bool showInlineError;

  /// Whether field is visible
  final bool isVisible;

  /// Conditional visibility based on other field values
  final Map<String, dynamic>? visibilityCondition;

  /// Input keyboard type
  final TextInputType? keyboardType;

  /// Input action on submit
  final TextInputAction? textInputAction;

  /// Whether to obscure text (for passwords)
  final bool obscureText;

  /// Number of lines for textarea
  final int? maxLines;

  /// Minimum lines for textarea
  final int? minLines;

  /// Custom metadata
  final Map<String, dynamic>? metadata;

  /// Creates a form field configuration
  FormFieldConfig({
    required this.id,
    required this.fieldType,
    required this.label,
    this.placeholder,
    this.helperText,
    this.isRequired = false,
    this.initialValue,
    this.isDisabled = false,
    this.hint,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.options,
    this.validators,
    this.validationMessages,
    this.showInlineError = true,
    this.isVisible = true,
    this.visibilityCondition,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines,
    this.minLines,
    this.metadata,
  });

  /// Creates a copy with modified properties
  FormFieldConfig copyWith({
    String? id,
    FieldType? fieldType,
    String? label,
    String? placeholder,
    String? helperText,
    bool? isRequired,
    dynamic initialValue,
    bool? isDisabled,
    String? hint,
    int? maxLength,
    num? minValue,
    num? maxValue,
    List<FormFieldOption>? options,
    List<String>? validators,
    Map<String, String>? validationMessages,
    bool? showInlineError,
    bool? isVisible,
    Map<String, dynamic>? visibilityCondition,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool? obscureText,
    int? maxLines,
    int? minLines,
    Map<String, dynamic>? metadata,
  }) {
    return FormFieldConfig(
      id: id ?? this.id,
      fieldType: fieldType ?? this.fieldType,
      label: label ?? this.label,
      placeholder: placeholder ?? this.placeholder,
      helperText: helperText ?? this.helperText,
      isRequired: isRequired ?? this.isRequired,
      initialValue: initialValue ?? this.initialValue,
      isDisabled: isDisabled ?? this.isDisabled,
      hint: hint ?? this.hint,
      maxLength: maxLength ?? this.maxLength,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      options: options ?? this.options,
      validators: validators ?? this.validators,
      validationMessages: validationMessages ?? this.validationMessages,
      showInlineError: showInlineError ?? this.showInlineError,
      isVisible: isVisible ?? this.isVisible,
      visibilityCondition: visibilityCondition ?? this.visibilityCondition,
      keyboardType: keyboardType ?? this.keyboardType,
      textInputAction: textInputAction ?? this.textInputAction,
      obscureText: obscureText ?? this.obscureText,
      maxLines: maxLines ?? this.maxLines,
      minLines: minLines ?? this.minLines,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts configuration to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fieldType': fieldType.name,
      'label': label,
      'placeholder': placeholder,
      'helperText': helperText,
      'isRequired': isRequired,
      'initialValue': initialValue,
      'isDisabled': isDisabled,
      'hint': hint,
      'maxLength': maxLength,
      'minValue': minValue,
      'maxValue': maxValue,
      'options': options?.map((o) => o.toJson()).toList(),
      'validators': validators,
      'validationMessages': validationMessages,
      'showInlineError': showInlineError,
      'isVisible': isVisible,
      'visibilityCondition': visibilityCondition,
      'obscureText': obscureText,
      'maxLines': maxLines,
      'minLines': minLines,
      'metadata': metadata,
    };
  }

  /// Creates configuration from JSON
  factory FormFieldConfig.fromJson(Map<String, dynamic> json) {
    return FormFieldConfig(
      id: json['id'] as String,
      fieldType: FieldTypeExtension.fromString(json['fieldType'] as String?),
      label: json['label'] as String,
      placeholder: json['placeholder'] as String?,
      helperText: json['helperText'] as String?,
      isRequired: json['isRequired'] as bool? ?? false,
      initialValue: json['initialValue'],
      isDisabled: json['isDisabled'] as bool? ?? false,
      hint: json['hint'] as String?,
      maxLength: json['maxLength'] as int?,
      minValue: (json['minValue'] as num?),
      maxValue: (json['maxValue'] as num?),
      options: (json['options'] as List?)
          ?.map((o) => FormFieldOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      validators: (json['validators'] as List?)?.cast<String>(),
      validationMessages:
          (json['validationMessages'] as Map?)?.cast<String, String>(),
      showInlineError: json['showInlineError'] as bool? ?? true,
      isVisible: json['isVisible'] as bool? ?? true,
      visibilityCondition: (json['visibilityCondition'] as Map?)?.cast<String, dynamic>(),
      keyboardType: _getKeyboardType(json['keyboardType'] as String?),
      textInputAction: _getTextInputAction(json['textInputAction'] as String?),
      obscureText: json['obscureText'] as bool? ?? false,
      maxLines: json['maxLines'] as int?,
      minLines: json['minLines'] as int?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }

  /// Parse keyboard type from string
  static TextInputType? _getKeyboardType(String? type) {
    switch (type) {
      case 'number':
        return TextInputType.number;
      case 'phone':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      case 'url':
        return TextInputType.url;
      case 'multiline':
        return TextInputType.multiline;
      default:
        return null;
    }
  }

  /// Parse text input action from string
  static TextInputAction? _getTextInputAction(String? action) {
    switch (action) {
      case 'done':
        return TextInputAction.done;
      case 'go':
        return TextInputAction.go;
      case 'next':
        return TextInputAction.next;
      case 'search':
        return TextInputAction.search;
      case 'send':
        return TextInputAction.send;
      default:
        return null;
    }
  }
}

// ===== FORM FIELD OPTION =====

/// Option for select/radio/checkbox fields
class FormFieldOption {
  /// Option value
  final dynamic value;

  /// Display label
  final String label;

  /// Whether option is disabled
  final bool isDisabled;

  /// Optional metadata
  final Map<String, dynamic>? metadata;

  /// Creates a form field option
  FormFieldOption({
    required this.value,
    required this.label,
    this.isDisabled = false,
    this.metadata,
  });

  /// Converts option to JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'isDisabled': isDisabled,
      'metadata': metadata,
    };
  }

  /// Creates option from JSON
  factory FormFieldOption.fromJson(Map<String, dynamic> json) {
    return FormFieldOption(
      value: json['value'],
      label: json['label'] as String,
      isDisabled: json['isDisabled'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

// ===== FORM SECTION =====

/// Groups related fields together
class FormSection {
  /// Section identifier
  final String id;

  /// Section title
  final String? title;

  /// Section description
  final String? description;

  /// Fields in this section
  final List<FormFieldConfig> fields;

  /// Whether section is collapsible
  final bool isCollapsible;

  /// Whether section is initially collapsed
  final bool isCollapsed;

  /// Creates a form section
  FormSection({
    required this.id,
    this.title,
    this.description,
    required this.fields,
    this.isCollapsible = false,
    this.isCollapsed = false,
  });

  /// Converts section to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fields': fields.map((f) => f.toJson()).toList(),
      'isCollapsible': isCollapsible,
      'isCollapsed': isCollapsed,
    };
  }

  /// Creates section from JSON
  factory FormSection.fromJson(Map<String, dynamic> json) {
    return FormSection(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      fields: (json['fields'] as List)
          .map((f) => FormFieldConfig.fromJson(f as Map<String, dynamic>))
          .toList(),
      isCollapsible: json['isCollapsible'] as bool? ?? false,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
    );
  }
}
