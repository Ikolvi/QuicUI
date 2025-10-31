# Form System Developer Guide

## QuicUI Framework - Phase 4 API Reference

**Last Updated**: Phase 4  
**Framework**: QuicUI Flutter  
**Status**: Complete

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Core Concepts](#core-concepts)
3. [API Reference](#api-reference)
4. [Validators](#validators)
5. [Advanced Patterns](#advanced-patterns)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

### 1. Create a Simple Form

```dart
// Define fields
final emailField = FormFieldConfig(
  id: 'email',
  fieldType: FieldType.email,
  label: 'Email Address',
  placeholder: 'your@email.com',
  isRequired: true,
  validators: ['required', 'email'],
);

final passwordField = FormFieldConfig(
  id: 'password',
  fieldType: FieldType.password,
  label: 'Password',
  isRequired: true,
  validators: ['required', 'length'],
  metadata: {'minLength': 8},
);

// Create form configuration
final config = FormBuilderConfig(
  formId: 'login',
  title: 'Login Form',
  fields: [emailField, passwordField],
);

// Build controller
final controller = FormBuilder.buildController(config);
```

### 2. Handle Form Input

```dart
// Listen for changes
controller.addListener(() {
  if (controller.isDirty) {
    print('Form has unsaved changes');
  }
});

// Update values
controller.setFieldValue('email', 'user@example.com');
controller.setFieldValue('password', 'securePassword123');

// Get values
final values = controller.values;
print('Email: ${values['email']}');
print('Password: ${values['password']}');
```

### 3. Validate and Submit

```dart
// Validate before submission
final isValid = await controller.validateAll();

if (isValid) {
  final success = await controller.submit(
    onSubmit: (values) async {
      // Make API call
      return await api.post('/login', values);
    },
  );
  
  if (success) {
    print('Login successful');
  } else {
    print('Login failed: ${controller.lastError}');
  }
} else {
  print('Form has errors');
  print(controller.errors);
}
```

---

## Core Concepts

### FormFieldConfig

Configuration object for a single form field.

```dart
FormFieldConfig(
  id: 'email',                           // Unique field ID
  fieldType: FieldType.email,            // Field type
  label: 'Email Address',                // Display label
  placeholder: 'your@email.com',         // Placeholder text
  helperText: 'We\'ll never share',      // Help text
  initialValue: '',                      // Initial value
  isRequired: true,                      // Required indicator
  isDisabled: false,                     // Disabled state
  isVisible: true,                       // Visibility
  validators: ['required', 'email'],     // Validator names
  
  // Size constraints
  minLength: 1,
  maxLength: 100,
  minValue: 0,
  maxValue: 999,
  
  // Keyboard configuration
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
  
  // Options for select/radio/checkbox
  options: [
    FormFieldOption(value: '1', label: 'Option 1'),
    FormFieldOption(value: '2', label: 'Option 2'),
  ],
  
  // Visibility condition
  visibilityCondition: (formValues) => formValues['type'] == 'email',
  
  // Custom properties
  metadata: {
    'pattern': r'^[a-z]+$',
    'customProp': 'value',
  },
  
  // Validation messages
  validationMessages: {
    'required': 'This field is required',
    'email': 'Please enter a valid email',
  },
)
```

### FieldType

Enum of supported field types:

```dart
enum FieldType {
  text,           // Simple text input
  email,          // Email field with email keyboard
  password,       // Password field (masked input)
  phone,          // Phone number field
  number,         // Integer input
  decimal,        // Decimal number input
  date,           // Date picker
  time,           // Time picker
  datetime,       // Date and time picker
  checkbox,       // Checkbox input
  radio,          // Radio button
  select,         // Dropdown select
  multiselect,    // Multi-select dropdown
  textarea,       // Multi-line text area
  slider,         // Slider input
  toggle,         // Toggle switch
  file,           // File upload
  custom,         // Custom field type
}
```

### FormController

Main form management class extending ChangeNotifier.

```dart
// Create controller
final controller = FormBuilder.buildController(config);

// Access state
bool isDirty = controller.isDirty;
bool isValid = controller.isValid;
bool isSubmitting = controller.isSubmitting;
Map<String, dynamic> values = controller.values;
Map<String, String> errors = controller.errors;
List<String> visibleFields = controller.visibleFieldIds;

// Field operations
controller.registerField(fieldConfig, validators: []);
controller.unregisterField('fieldId');
controller.setFieldValue('fieldId', 'value');
dynamic value = controller.getFieldValue('fieldId');
controller.setFieldValues({'field1': 'val1', 'field2': 'val2'});
controller.setFieldError('fieldId', 'Error message');
String? error = controller.getFieldError('fieldId');

// Validation
Future<bool> valid = controller.validateField('fieldId');
Future<bool> allValid = controller.validateAll();
controller.clearFieldError('fieldId');
controller.clearAllErrors();

// Form operations
Future<bool> success = controller.submit(onSubmit: submitFn);
controller.reset();
controller.markTouched('fieldId');
controller.setFieldVisible('fieldId', true);
FormSummary summary = controller.getFormSummary();
```

### ValidationResult

Result object from validators:

```dart
ValidationResult result = validator.validate(value);

// Check result
bool isValid = result.isValid;
String? message = result.errorMessage;
Map<String, dynamic> details = result.details;

// Create results
ValidationResult.success()                           // Valid
ValidationResult.failure('Error message')           // Invalid
ValidationResult.success(details: {'key': 'val'})  // With details
```

---

## API Reference

### FormBuilder (Static Factory)

```dart
// Create from JSON
FormBuilderConfig config = FormBuilder.fromJson({
  'formId': 'myForm',
  'title': 'My Form',
  'fields': [/* field configs */],
});

// Build controller from config
FormController controller = FormBuilder.buildController(config);
```

### Validators

#### RequiredValidator

Checks that field has a value.

```dart
final validator = RequiredValidator();
final result = validator.validate(''); // Invalid
final result = validator.validate('value'); // Valid
```

#### EmailValidator

Validates email format using RFC standard.

```dart
final validator = EmailValidator();
final result = validator.validate('user@example.com'); // Valid
final result = validator.validate('invalid'); // Invalid
```

#### LengthValidator

Validates string length.

```dart
final validator = LengthValidator(min: 3, max: 10);
final result = validator.validate('hello'); // Valid
final result = validator.validate('a'); // Invalid (too short)
```

#### PatternValidator

Validates against regex pattern.

```dart
final validator = PatternValidator(r'^[A-Z]\w*');
final result = validator.validate('Hello'); // Valid
final result = validator.validate('hello'); // Invalid
```

#### NumericValidator

Validates numeric range.

```dart
final validator = NumericValidator(min: 0, max: 100);
final result = validator.validate('50'); // Valid
final result = validator.validate('150'); // Invalid
```

#### PhoneValidator

Validates phone number format.

```dart
final validator = PhoneValidator();
final result = validator.validate('+1-555-0123'); // Valid
final result = validator.validate('abc'); // Invalid
```

#### UrlValidator

Validates URL format.

```dart
final validator = UrlValidator();
final result = validator.validate('https://example.com'); // Valid
final result = validator.validate('not-a-url'); // Invalid
```

#### MatchValidator

Validates field matches another field.

```dart
final validator = MatchValidator('password', 'passwordConfirm');
// Use with form values context
```

#### EnumValidator

Validates value is in allowed list.

```dart
final validator = EnumValidator(['admin', 'user', 'guest']);
final result = validator.validate('admin'); // Valid
final result = validator.validate('superuser'); // Invalid
```

#### GreaterThanValidator

Validates numeric greater than.

```dart
final validator = GreaterThanValidator(18);
final result = validator.validate('25'); // Valid
final result = validator.validate('17'); // Invalid
```

#### LessThanValidator

Validates numeric less than.

```dart
final validator = LessThanValidator(100);
final result = validator.validate('50'); // Valid
final result = validator.validate('150'); // Invalid
```

#### CustomValidator

Creates custom validation logic.

```dart
final validator = CustomValidator(
  validationFn: (value, fieldName, {params}) {
    if (value.contains('forbidden')) {
      return ValidationResult.failure('Contains forbidden word');
    }
    return ValidationResult.success();
  },
  errorMessageFn: (fieldName, {params}) => 'Invalid value',
  name: 'NoForbiddenWords',
);
```

---

## Advanced Patterns

### Conditional Validation

Validate only when condition is met:

```dart
final conditionalValidator = ConditionalValidator(
  validator: EmailValidator(),
  shouldValidate: (value) {
    return value != null && value.toString().isNotEmpty;
  },
);

controller.registerField(config, validators: [conditionalValidator]);
```

### Validator Chains (AND)

All validators must pass:

```dart
final chain = ValidatorChain([
  RequiredValidator(),
  EmailValidator(),
  LengthValidator(max: 100),
]);

controller.registerField(config, validators: [chain]);
```

### OR Validation

At least one validator must pass:

```dart
final orValidator = OrValidator([
  EmailValidator(),
  PhoneValidator(),
]);

controller.registerField(config, validators: [orValidator]);
```

### AND Composition

All validators must pass (explicit):

```dart
final andValidator = AndValidator([
  RequiredValidator(),
  PatternValidator(r'^[A-Z]'),
]);
```

### NOT Composition

Inverts validation result:

```dart
final notValidator = NotValidator(PatternValidator(r'\d'));

controller.registerField(config, validators: [notValidator]);
```

### Async Validation

For server-side validation:

```dart
class UniqueEmailValidator extends AsyncValidator {
  @override
  Future<ValidationResult> validate(dynamic value, {Map? params}) async {
    try {
      final response = await http.get(
        Uri.parse('/api/check-email?email=$value'),
      );
      if (response.statusCode == 200) {
        return ValidationResult.success();
      }
      return ValidationResult.failure('Email already registered');
    } catch (e) {
      return ValidationResult.failure('Could not validate email');
    }
  }
}

controller.registerField(config, validators: [UniqueEmailValidator()]);
```

### Form Sections

Group related fields:

```dart
final contactSection = FormSection(
  id: 'contact',
  title: 'Contact Information',
  description: 'How should we contact you?',
  isCollapsible: true,
  fields: [
    FormFieldConfig(
      id: 'email',
      fieldType: FieldType.email,
      label: 'Email',
    ),
    FormFieldConfig(
      id: 'phone',
      fieldType: FieldType.phone,
      label: 'Phone',
    ),
  ],
);

final config = FormBuilderConfig(
  formId: 'signup',
  sections: [contactSection],
);
```

### Dynamic Form Creation

Create forms programmatically:

```dart
// Simple form with field names
final form = DynamicFormBuilder.simpleForm(
  'quickForm',
  ['firstName', 'lastName', 'email'],
  title: 'Quick Registration',
);

// From sections
final config = DynamicFormBuilder.fromSections(
  'fullForm',
  [section1, section2, section3],
);

// Merge multiple forms
final merged = DynamicFormBuilder.mergeForms(
  'combined',
  [form1, form2, form3],
);

// Filter fields
final filtered = DynamicFormBuilder.filterForm(
  originalForm,
  (field) => field.isVisible && !field.isRequired,
);

// Clone with modifications
final cloned = DynamicFormBuilder.cloneForm(
  original,
  'clonedForm',
  fieldOverrides: {
    'email': emailFieldModified,
  },
);
```

### JSON-based Forms

Define forms in JSON:

```dart
const formJson = {
  'formId': 'registration',
  'title': 'User Registration',
  'fields': [
    {
      'id': 'firstName',
      'fieldType': 'text',
      'label': 'First Name',
      'isRequired': true,
      'validators': ['required', 'length'],
      'metadata': {'minLength': 2, 'maxLength': 50},
    },
    {
      'id': 'email',
      'fieldType': 'email',
      'label': 'Email',
      'isRequired': true,
      'validators': ['required', 'email'],
    },
    {
      'id': 'password',
      'fieldType': 'password',
      'label': 'Password',
      'isRequired': true,
      'validators': ['required', 'length'],
      'metadata': {'minLength': 8},
    },
    {
      'id': 'confirmPassword',
      'fieldType': 'password',
      'label': 'Confirm Password',
      'isRequired': true,
      'validators': ['required', 'match'],
      'metadata': {'matchField': 'password'},
    },
  ],
  'submission': {
    'endpoint': '/api/register',
    'method': 'POST',
  },
};

final config = FormBuilder.fromJson(formJson);
final controller = FormBuilder.buildController(config);
```

---

## Best Practices

### 1. Always Validate Before Submission

```dart
// ✅ Good
final isValid = await controller.validateAll();
if (isValid) {
  await controller.submit(onSubmit: submitFn);
}

// ❌ Bad
await controller.submit(onSubmit: submitFn);
```

### 2. Use Validator Chains for Multiple Validations

```dart
// ✅ Good
final validators = ValidatorChain([
  RequiredValidator(),
  EmailValidator(),
  LengthValidator(max: 100),
]);

// ❌ Bad (separate validators might conflict)
controller.registerField(config, validators: [
  RequiredValidator(),
  EmailValidator(),
  LengthValidator(max: 100),
]);
```

### 3. Provide User-Friendly Error Messages

```dart
// ✅ Good
final config = FormFieldConfig(
  id: 'email',
  fieldType: FieldType.email,
  label: 'Email Address',
  validationMessages: {
    'required': 'Email is required',
    'email': 'Please enter a valid email address',
  },
);

// ❌ Bad (generic messages)
final config = FormFieldConfig(
  id: 'email',
  fieldType: FieldType.email,
  label: 'Email Address',
);
```

### 4. Use Conditional Visibility

```dart
// ✅ Good - Show billing address only if different
final billingAddressField = FormFieldConfig(
  id: 'billingAddress',
  fieldType: FieldType.text,
  label: 'Billing Address',
  visibilityCondition: (formValues) => 
    formValues['differentBillingAddress'] == true,
);

// ❌ Bad (always shows, user confusion)
final billingAddressField = FormFieldConfig(
  id: 'billingAddress',
  fieldType: FieldType.text,
  label: 'Billing Address',
);
```

### 5. Handle Loading States

```dart
// ✅ Good
if (controller.isSubmitting) {
  print('Form is being submitted...');
}

// Use with UI
controller.addListener(() {
  setState(() {
    isLoading = controller.isSubmitting;
  });
});

// ❌ Bad (no feedback to user)
await controller.submit(onSubmit: submitFn);
```

### 6. Reset Form After Success

```dart
// ✅ Good
final success = await controller.submit(onSubmit: submitFn);
if (success) {
  controller.reset();
  showSnackBar('Form submitted successfully');
}

// ❌ Bad (form still shows old values)
final success = await controller.submit(onSubmit: submitFn);
if (success) {
  showSnackBar('Form submitted successfully');
}
```

### 7. Use Sections for Complex Forms

```dart
// ✅ Good - Logical grouping
final sections = [
  FormSection(
    id: 'personal',
    title: 'Personal Information',
    fields: [/* personal fields */],
  ),
  FormSection(
    id: 'billing',
    title: 'Billing Information',
    fields: [/* billing fields */],
  ),
];

// ❌ Bad (all fields in one list, confusing)
final fields = [
  // personal fields mixed with billing fields
];
```

---

## Troubleshooting

### Form Not Validating

**Problem**: `validateAll()` returns true even with invalid data

**Solution**: 
1. Ensure validators are registered: `registerField(config, validators: [...])`
2. Check validator configuration matches field type
3. Verify validator logic with simple test case

```dart
// Test validator directly
final validator = EmailValidator();
final result = validator.validate('invalid@');
print(result.isValid); // Should be false
```

### Field Errors Not Showing

**Problem**: Validation fails but `getFieldError()` returns null

**Solution**:
1. Call `validateField()` or `validateAll()` before checking errors
2. Ensure field exists with `controller.values.containsKey(fieldId)`

```dart
// ✅ Correct sequence
await controller.validateField('email');
String? error = controller.getFieldError('email');
```

### Form Not Submitting

**Problem**: `submit()` doesn't execute callback

**Solution**:
1. Check `validateAll()` passes before submit
2. Ensure `onSubmit` callback is provided
3. Verify async operation in callback completes

```dart
// ✅ Proper submit
final isValid = await controller.validateAll();
if (isValid) {
  final success = await controller.submit(
    onSubmit: (values) async {
      return await Future.value(true); // Must return bool
    },
  );
}
```

### Memory Leaks

**Problem**: Controllers not releasing memory

**Solution**: Always dispose of controller when done

```dart
// ✅ Dispose properly
@override
void dispose() {
  controller.dispose();
  super.dispose();
}

// Use in StatefulWidget
late FormController _controller;

@override
void initState() {
  super.initState();
  _controller = FormBuilder.buildController(config);
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### Custom Validator Not Working

**Problem**: Custom validator never called

**Solution**: Ensure validator name is registered in factory

```dart
// ✅ Working custom validator
final customValidator = CustomValidator(
  validationFn: (value, fieldName, {params}) {
    // Logic here
    return ValidationResult.success();
  },
  name: 'customValidation',
);

controller.registerField(config, validators: [customValidator]);
```

---

## Summary

The QuicUI Form System provides:
- ✅ Complete form configuration system
- ✅ 12+ built-in validators
- ✅ Extensible validation framework
- ✅ Full state management
- ✅ JSON serialization
- ✅ Production-ready implementation

For more information, see `PHASE_4_COMPLETE.md` for architecture overview.

---

*Last Updated: Phase 4*  
*Framework: QuicUI Flutter*  
*Status: Complete*
