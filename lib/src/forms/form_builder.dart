/// Form Builder for QuicUI
/// Creates forms from JSON configuration

import 'field_types.dart';
import 'form_controller.dart';
import 'validators/base_validator.dart';
import 'validators/built_in_validators.dart';

// ===== FORM BUILDER =====

/// Builder for creating forms from JSON configuration
class FormBuilder {
  /// Builds a form configuration from JSON
  static FormBuilderConfig fromJson(Map<String, dynamic> json) {
    return FormBuilderConfig.fromJson(json);
  }

  /// Builds a form controller from configuration
  static FormController buildController(FormBuilderConfig config) {
    final controller = FormController(formId: config.formId);

    // Register fields with validators
    for (final fieldConfig in config.fields) {
      final validators = _buildValidators(fieldConfig);
      controller.registerField(fieldConfig, validators: validators);
    }

    return controller;
  }

  /// Builds validators for a field
  static List<BaseValidator> _buildValidators(FormFieldConfig config) {
    final validators = <BaseValidator>[];

    // Add required validator if field is required
    if (config.isRequired) {
      validators.add(RequiredValidator());
    }

    // Add validators from configuration
    if (config.validators != null) {
      for (final validatorName in config.validators!) {
        final validator = _buildValidator(validatorName, config);
        if (validator != null) {
          validators.add(validator);
        }
      }
    }

    return validators;
  }

  /// Builds a single validator by name
  static BaseValidator? _buildValidator(
    String validatorName,
    FormFieldConfig config,
  ) {
    switch (validatorName.toLowerCase()) {
      case 'required':
        return RequiredValidator();

      case 'email':
        return EmailValidator();

      case 'url':
        return UrlValidator();

      case 'phone':
        return PhoneValidator();

      case 'pattern':
        final pattern = config.metadata?['pattern'] as String?;
        if (pattern != null) {
          return PatternValidator.fromString(pattern);
        }
        return null;

      case 'numeric':
        return NumericValidator(
          minValue: config.minValue,
          maxValue: config.maxValue,
        );

      case 'length':
        return LengthValidator(
          minLength: config.metadata?['minLength'] as int?,
          maxLength: config.maxLength,
        );

      case 'enum':
        final values = config.options?.map((o) => o.value).toList();
        if (values != null) {
          return EnumValidator(values);
        }
        return null;

      case 'match':
        final fieldToMatch = config.metadata?['matchField'] as String?;
        if (fieldToMatch != null) {
          return MatchValidator(fieldToMatch);
        }
        return null;

      case 'greaterthan':
        final minValue = config.metadata?['minValue'] as num?;
        if (minValue != null) {
          return GreaterThanValidator(minValue);
        }
        return null;

      case 'lessthan':
        final maxValue = config.metadata?['maxValue'] as num?;
        if (maxValue != null) {
          return LessThanValidator(maxValue);
        }
        return null;

      default:
        return null;
    }
  }
}

// ===== FORM BUILDER CONFIG =====

/// Configuration for building a form
class FormBuilderConfig {
  /// Form identifier
  final String formId;

  /// Form title
  final String? title;

  /// Form description
  final String? description;

  /// Form fields
  final List<FormFieldConfig> fields;

  /// Form sections (optional grouping)
  final List<FormSection>? sections;

  /// Form submission settings
  final FormSubmissionSettings? submissionSettings;

  /// Whether to show validation errors inline
  final bool showInlineErrors;

  /// Whether to disable form on submission
  final bool disableOnSubmit;

  /// Custom metadata
  final Map<String, dynamic>? metadata;

  /// Creates a form builder configuration
  FormBuilderConfig({
    required this.formId,
    this.title,
    this.description,
    required this.fields,
    this.sections,
    this.submissionSettings,
    this.showInlineErrors = true,
    this.disableOnSubmit = true,
    this.metadata,
  });

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'formId': formId,
      'title': title,
      'description': description,
      'fields': fields.map((f) => f.toJson()).toList(),
      'sections': sections?.map((s) => s.toJson()).toList(),
      'submissionSettings': submissionSettings?.toJson(),
      'showInlineErrors': showInlineErrors,
      'disableOnSubmit': disableOnSubmit,
      'metadata': metadata,
    };
  }

  /// Creates from JSON
  factory FormBuilderConfig.fromJson(Map<String, dynamic> json) {
    return FormBuilderConfig(
      formId: json['formId'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      fields: (json['fields'] as List)
          .map((f) => FormFieldConfig.fromJson(f as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List?)
          ?.map((s) => FormSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      submissionSettings: json['submissionSettings'] != null
          ? FormSubmissionSettings.fromJson(
              json['submissionSettings'] as Map<String, dynamic>)
          : null,
      showInlineErrors: json['showInlineErrors'] as bool? ?? true,
      disableOnSubmit: json['disableOnSubmit'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

// ===== FORM SUBMISSION SETTINGS =====

/// Settings for form submission
class FormSubmissionSettings {
  /// API endpoint for submission
  final String? endpoint;

  /// HTTP method (GET, POST, PUT, DELETE, PATCH)
  final String method;

  /// Whether to include CSRF token
  final bool includeCsrfToken;

  /// Success message
  final String? successMessage;

  /// Error message
  final String? errorMessage;

  /// Redirect URL after successful submission
  final String? redirectUrl;

  /// Whether to clear form after successful submission
  final bool clearOnSuccess;

  /// Callback URLs for webhooks
  final Map<String, String>? webhooks;

  /// Creates submission settings
  FormSubmissionSettings({
    this.endpoint,
    this.method = 'POST',
    this.includeCsrfToken = true,
    this.successMessage,
    this.errorMessage,
    this.redirectUrl,
    this.clearOnSuccess = false,
    this.webhooks,
  });

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'method': method,
      'includeCsrfToken': includeCsrfToken,
      'successMessage': successMessage,
      'errorMessage': errorMessage,
      'redirectUrl': redirectUrl,
      'clearOnSuccess': clearOnSuccess,
      'webhooks': webhooks,
    };
  }

  /// Creates from JSON
  factory FormSubmissionSettings.fromJson(Map<String, dynamic> json) {
    return FormSubmissionSettings(
      endpoint: json['endpoint'] as String?,
      method: json['method'] as String? ?? 'POST',
      includeCsrfToken: json['includeCsrfToken'] as bool? ?? true,
      successMessage: json['successMessage'] as String?,
      errorMessage: json['errorMessage'] as String?,
      redirectUrl: json['redirectUrl'] as String?,
      clearOnSuccess: json['clearOnSuccess'] as bool? ?? false,
      webhooks: (json['webhooks'] as Map?)?.cast<String, String>(),
    );
  }
}

// ===== DYNAMIC FORM BUILDER =====

/// Builder for creating forms dynamically at runtime
class DynamicFormBuilder {
  /// Creates a form from sections
  static FormBuilderConfig fromSections(
    String formId,
    List<FormSection> sections, {
    String? title,
    String? description,
    FormSubmissionSettings? submissionSettings,
  }) {
    // Flatten sections into fields
    final fields = <FormFieldConfig>[];
    for (final section in sections) {
      fields.addAll(section.fields);
    }

    return FormBuilderConfig(
      formId: formId,
      title: title,
      description: description,
      fields: fields,
      sections: sections,
      submissionSettings: submissionSettings,
    );
  }

  /// Creates a simple form with text fields
  static FormBuilderConfig simpleForm(
    String formId,
    List<String> fieldNames, {
    String? title,
  }) {
    final fields = fieldNames.asMap().entries.map((entry) {
      return FormFieldConfig(
        id: entry.value,
        fieldType: FieldType.text,
        label: entry.value.replaceAll('_', ' ').toUpperCase(),
        isRequired: true,
      );
    }).toList();

    return FormBuilderConfig(
      formId: formId,
      title: title,
      fields: fields,
    );
  }

  /// Merges multiple forms
  static FormBuilderConfig mergeForms(
    String mergedFormId,
    List<FormBuilderConfig> forms, {
    String? title,
  }) {
    final allFields = <FormFieldConfig>[];
    for (final form in forms) {
      allFields.addAll(form.fields);
    }

    return FormBuilderConfig(
      formId: mergedFormId,
      title: title,
      fields: allFields,
    );
  }

  /// Filters form fields by predicate
  static FormBuilderConfig filterForm(
    FormBuilderConfig originalForm,
    bool Function(FormFieldConfig) predicate, {
    String? newFormId,
  }) {
    return FormBuilderConfig(
      formId: newFormId ?? originalForm.formId,
      title: originalForm.title,
      description: originalForm.description,
      fields: originalForm.fields.where(predicate).toList(),
      sections: originalForm.sections,
      submissionSettings: originalForm.submissionSettings,
      showInlineErrors: originalForm.showInlineErrors,
      disableOnSubmit: originalForm.disableOnSubmit,
      metadata: originalForm.metadata,
    );
  }

  /// Clones a form with modifications
  static FormBuilderConfig cloneForm(
    FormBuilderConfig originalForm,
    String newFormId, {
    Map<String, FormFieldConfig>? fieldOverrides,
  }) {
    fieldOverrides ??= {};
    final clonedFields = originalForm.fields.map((field) {
      return fieldOverrides![field.id] ?? field;
    }).toList();

    return FormBuilderConfig(
      formId: newFormId,
      title: originalForm.title,
      description: originalForm.description,
      fields: clonedFields,
      sections: originalForm.sections,
      submissionSettings: originalForm.submissionSettings,
      showInlineErrors: originalForm.showInlineErrors,
      disableOnSubmit: originalForm.disableOnSubmit,
      metadata: originalForm.metadata,
    );
  }
}
