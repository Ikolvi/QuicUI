/// Phase 2 Widget JSON Schemas
/// 
/// Defines JSON structure and properties for Phase 2 input widgets
/// These schemas ensure proper validation and type safety

class Phase2WidgetSchemas {
  /// TextFormField schema
  static const Map<String, dynamic> textFormFieldSchema = {
    'title': 'TextFormField',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'hintText': {'type': 'string', 'required': false},
      'helperText': {'type': 'string', 'required': false},
      'errorText': {'type': 'string', 'required': false},
      'inputType': {
        'type': 'enum',
        'default': 'text',
        'values': ['text', 'email', 'phone', 'number', 'url', 'multiline', 'decimal']
      },
      'isRequired': {'type': 'boolean', 'default': false},
      'prefixIcon': {'type': 'string'},
      'suffixIcon': {'type': 'string'},
      'maxLines': {'type': 'number', 'default': 1},
      'minLines': {'type': 'number', 'default': 1},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onChanged', 'onSubmitted', 'onSaved'],
  };

  /// TextArea schema
  static const Map<String, dynamic> textAreaSchema = {
    'title': 'TextArea',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'hintText': {'type': 'string', 'required': false},
      'minLines': {'type': 'number', 'default': 5},
      'maxLines': {'type': 'number', 'default': 10},
      'backgroundColor': {'type': 'color'},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onChanged', 'onSubmitted'],
  };

  /// NumberInput schema
  static const Map<String, dynamic> numberInputSchema = {
    'title': 'NumberInput',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'initialValue': {'type': 'number', 'default': 0},
      'minValue': {'type': 'number', 'default': 0},
      'maxValue': {'type': 'number', 'default': 100},
      'step': {'type': 'number', 'default': 1},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onChanged'],
  };

  /// DatePicker schema
  static const Map<String, dynamic> datePickerSchema = {
    'title': 'DatePicker',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'initialDate': {'type': 'date', 'required': false},
      'firstDate': {'type': 'date', 'required': false},
      'lastDate': {'type': 'date', 'required': false},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onDateSelected'],
  };

  /// TimePicker schema
  static const Map<String, dynamic> timePickerSchema = {
    'title': 'TimePicker',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'initialTime': {'type': 'time', 'required': false},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onTimeSelected'],
  };

  /// ColorPicker schema
  static const Map<String, dynamic> colorPickerSchema = {
    'title': 'ColorPicker',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'initialColor': {'type': 'color', 'default': '#2196F3'},
      'showHex': {'type': 'boolean', 'default': true},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onColorChanged'],
  };

  /// DropdownButtonForm schema
  static const Map<String, dynamic> dropdownButtonFormSchema = {
    'title': 'DropdownButtonForm',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'items': {'type': 'array', 'items': {'type': 'string'}, 'required': true},
      'selectedValue': {'type': 'string', 'required': false},
      'isRequired': {'type': 'boolean', 'default': false},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onChanged'],
  };

  /// MultiSelect schema
  static const Map<String, dynamic> multiSelectSchema = {
    'title': 'MultiSelect',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'items': {'type': 'array', 'items': {'type': 'string'}, 'required': true},
      'selectedValues': {'type': 'array', 'items': {'type': 'string'}},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onSelectionChanged'],
  };

  /// SearchBox schema
  static const Map<String, dynamic> searchBoxSchema = {
    'title': 'SearchBox',
    'type': 'widget',
    'properties': {
      'hintText': {'type': 'string', 'default': 'Search...'},
      'suggestions': {'type': 'array', 'items': {'type': 'string'}},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onSearch', 'onSuggestionSelected'],
  };

  /// FileUpload schema
  static const Map<String, dynamic> fileUploadSchema = {
    'title': 'FileUpload',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'acceptedTypes': {'type': 'array', 'items': {'type': 'string'}, 'default': ['*']},
      'maxFileSize': {'type': 'number', 'default': 10},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onFileSelected', 'onUploadProgress', 'onUploadComplete'],
  };

  /// Rating schema
  static const Map<String, dynamic> ratingSchema = {
    'title': 'Rating',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'required': true},
      'initialRating': {'type': 'number', 'default': 0},
      'maxRating': {'type': 'number', 'default': 5},
      'size': {'type': 'number', 'default': 24},
      'color': {'type': 'color', 'default': '#FFC107'},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onRatingChanged'],
  };

  /// OtpInput schema
  static const Map<String, dynamic> otpInputSchema = {
    'title': 'OtpInput',
    'type': 'widget',
    'properties': {
      'length': {'type': 'number', 'default': 6},
      'spacing': {'type': 'number', 'default': 8},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onCompleted', 'onChanged'],
  };

  /// Get all Phase 2 widget schemas
  static Map<String, Map<String, dynamic>> getAllSchemas() {
    return {
      'TextFormField': textFormFieldSchema,
      'TextArea': textAreaSchema,
      'NumberInput': numberInputSchema,
      'DatePicker': datePickerSchema,
      'TimePicker': timePickerSchema,
      'ColorPicker': colorPickerSchema,
      'DropdownButtonForm': dropdownButtonFormSchema,
      'MultiSelect': multiSelectSchema,
      'SearchBox': searchBoxSchema,
      'FileUpload': fileUploadSchema,
      'Rating': ratingSchema,
      'OtpInput': otpInputSchema,
    };
  }

  /// Validate widget properties against schema
  static ({bool isValid, List<String> errors}) validateProperties(
    String widgetType,
    Map<String, dynamic> properties,
  ) {
    final schemas = getAllSchemas();
    final schema = schemas[widgetType];

    if (schema == null) {
      return (isValid: false, errors: ['Widget type "$widgetType" not found in Phase 2 schemas']);
    }

    final errors = <String>[];
    final schemaProps = schema['properties'] as Map<String, dynamic>? ?? {};

    for (final entry in schemaProps.entries) {
      final key = entry.key;
      final propSchema = entry.value;
      final propDef = propSchema as Map<String, dynamic>;
      final isRequired = propDef['required'] as bool? ?? false;
      final value = properties[key];

      if (isRequired && (value == null)) {
        errors.add('Required property "$key" is missing');
      }
    }

    return (isValid: errors.isEmpty, errors: errors);
  }
}
