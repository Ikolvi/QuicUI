/// Phase 2 Widget Examples
/// 
/// This file contains JSON examples for all Phase 2 input widgets.
/// Each widget example shows the required and optional properties.

class Phase2Examples {
  /// TextFormField Example - Standard form text input
  static const Map<String, dynamic> textFormFieldExample = {
    'type': 'TextFormField',
    'properties': {
      'label': 'Username',
      'hintText': 'Enter your username',
      'helperText': 'Your unique username',
      'inputType': 'text',
      'isRequired': true,
      'maxLines': 1,
    }
  };

  /// TextFormField with validation example
  static const Map<String, dynamic> textFormFieldValidationExample = {
    'type': 'TextFormField',
    'properties': {
      'label': 'Email',
      'hintText': 'your.email@example.com',
      'inputType': 'email',
      'isRequired': true,
      'backgroundColor': '#F5F5F5',
      'borderRadius': 8,
    }
  };

  /// TextArea Example - Multi-line text input
  static const Map<String, dynamic> textAreaExample = {
    'type': 'TextArea',
    'properties': {
      'label': 'Comments',
      'hintText': 'Enter your feedback...',
      'minLines': 3,
      'maxLines': 6,
      'backgroundColor': '#FFFFFF',
    }
  };

  /// TextArea with long text example
  static const Map<String, dynamic> textAreaLongExample = {
    'type': 'TextArea',
    'properties': {
      'label': 'Description',
      'minLines': 4,
      'maxLines': 10,
      'backgroundColor': '#F9F9F9',
    }
  };

  /// NumberInput Example - Numeric field with spinner
  static const Map<String, dynamic> numberInputExample = {
    'type': 'NumberInput',
    'properties': {
      'label': 'Quantity',
      'initialValue': 1,
      'size': 'medium',
    }
  };

  /// NumberInput with constraints example
  static const Map<String, dynamic> numberInputRangeExample = {
    'type': 'NumberInput',
    'properties': {
      'label': 'Rating (1-5)',
      'initialValue': 3,
      'size': 'small',
    }
  };

  /// DatePicker Example - Date selection
  static const Map<String, dynamic> datePickerExample = {
    'type': 'DatePicker',
    'properties': {
      'label': 'Birth Date',
      'hintText': 'Select your date of birth',
      'showClear': true,
    }
  };

  /// DatePicker with future dates example
  static const Map<String, dynamic> datePickerFutureExample = {
    'type': 'DatePicker',
    'properties': {
      'label': 'Appointment Date',
      'hintText': 'Select appointment date',
      'showClear': true,
    }
  };

  /// TimePicker Example - Time selection
  static const Map<String, dynamic> timePickerExample = {
    'type': 'TimePicker',
    'properties': {
      'label': 'Meeting Time',
      'hintText': 'Select meeting time',
      'showClear': true,
    }
  };

  /// TimePicker with format example
  static const Map<String, dynamic> timePickerFormatExample = {
    'type': 'TimePicker',
    'properties': {
      'label': 'Alarm Time',
      'hintText': 'Set alarm time',
    }
  };

  /// ColorPicker Example - Color selection with hex
  static const Map<String, dynamic> colorPickerExample = {
    'type': 'ColorPicker',
    'properties': {
      'label': 'Theme Color',
      'initialColor': '#2196F3',
      'showHex': true,
    }
  };

  /// ColorPicker with preset colors example
  static const Map<String, dynamic> colorPickerPresetExample = {
    'type': 'ColorPicker',
    'properties': {
      'label': 'Background Color',
      'initialColor': '#FFFFFF',
      'showHex': true,
    }
  };

  /// DropdownButtonForm Example - Dropdown selection
  static const Map<String, dynamic> dropdownButtonFormExample = {
    'type': 'DropdownButtonForm',
    'properties': {
      'label': 'Country',
      'items': [
        {'label': 'United States', 'value': 'US'},
        {'label': 'Canada', 'value': 'CA'},
        {'label': 'United Kingdom', 'value': 'UK'},
      ],
      'selectedValue': 'US',
      'isRequired': true,
    }
  };

  /// DropdownButtonForm with many options example
  static const Map<String, dynamic> dropdownButtonFormLargeExample = {
    'type': 'DropdownButtonForm',
    'properties': {
      'label': 'Product Category',
      'items': [
        {'label': 'Electronics', 'value': 'electronics'},
        {'label': 'Clothing', 'value': 'clothing'},
        {'label': 'Books', 'value': 'books'},
        {'label': 'Home & Garden', 'value': 'home'},
      ],
      'hintText': 'Select a category',
    }
  };

  /// MultiSelect Example - Multiple selection checkboxes
  static const Map<String, dynamic> multiSelectExample = {
    'type': 'MultiSelect',
    'properties': {
      'label': 'Interests',
      'items': [
        {'label': 'Sports', 'value': 'sports'},
        {'label': 'Music', 'value': 'music'},
        {'label': 'Reading', 'value': 'reading'},
        {'label': 'Cooking', 'value': 'cooking'},
      ],
      'selectedValues': ['sports', 'music'],
    }
  };

  /// MultiSelect with many options example
  static const Map<String, dynamic> multiSelectManyExample = {
    'type': 'MultiSelect',
    'properties': {
      'label': 'Languages',
      'items': [
        {'label': 'English', 'value': 'en'},
        {'label': 'Spanish', 'value': 'es'},
        {'label': 'French', 'value': 'fr'},
        {'label': 'German', 'value': 'de'},
        {'label': 'Chinese', 'value': 'zh'},
      ],
    }
  };

  /// SearchBox Example - Search with suggestions
  static const Map<String, dynamic> searchBoxExample = {
    'type': 'SearchBox',
    'properties': {
      'label': 'Search',
      'hintText': 'Type to search...',
      'suggestions': [
        'Apple',
        'Banana',
        'Cherry',
        'Date',
        'Elderberry',
      ],
    }
  };

  /// SearchBox with autocomplete example
  static const Map<String, dynamic> searchBoxAutocompleteExample = {
    'type': 'SearchBox',
    'properties': {
      'hintText': 'Search products...',
      'suggestions': [
        'Laptop Computer',
        'Laptop Bag',
        'Laptop Stand',
      ],
    }
  };

  /// FileUpload Example - Drag-drop file upload
  static const Map<String, dynamic> fileUploadExample = {
    'type': 'FileUpload',
    'properties': {
      'label': 'Upload Profile Picture',
      'acceptedTypes': ['image/jpeg', 'image/png'],
      'maxFileSize': 5242880, // 5MB in bytes
      'showFileList': true,
    }
  };

  /// FileUpload with multiple files example
  static const Map<String, dynamic> fileUploadMultipleExample = {
    'type': 'FileUpload',
    'properties': {
      'label': 'Upload Documents',
      'acceptedTypes': ['application/pdf'],
      'maxFileSize': 10485760, // 10MB
      'showFileList': true,
    }
  };

  /// Rating Example - Star rating widget
  static const Map<String, dynamic> ratingExample = {
    'type': 'Rating',
    'properties': {
      'initialRating': 4,
      'maxRating': 5,
      'size': 'medium',
      'color': '#FFC107',
    }
  };

  /// Rating with custom size example
  static const Map<String, dynamic> ratingLargeExample = {
    'type': 'Rating',
    'properties': {
      'initialRating': 3,
      'maxRating': 5,
      'size': 'large',
      'color': '#E91E63',
    }
  };

  /// OtpInput Example - OTP/PIN entry
  static const Map<String, dynamic> otpInputExample = {
    'type': 'OtpInput',
    'properties': {
      'length': 4,
      'keyboardType': 'number',
      'hideCharacters': false,
    }
  };

  /// OtpInput with hidden characters example
  static const Map<String, dynamic> otpInputHiddenExample = {
    'type': 'OtpInput',
    'properties': {
      'length': 6,
      'keyboardType': 'number',
      'hideCharacters': true,
    }
  };

  // ============ COMPLEX EXAMPLES ============

  /// Complete Registration Form Example
  static const Map<String, dynamic> registrationFormExample = {
    'type': 'Column',
    'properties': {
      'spacing': 16,
      'padding': 20,
    },
    'children': [
      {
        'type': 'TextFormField',
        'properties': {
          'label': 'Full Name',
          'hintText': 'John Doe',
          'isRequired': true,
        }
      },
      {
        'type': 'TextFormField',
        'properties': {
          'label': 'Email',
          'hintText': 'john@example.com',
          'inputType': 'email',
          'isRequired': true,
        }
      },
      {
        'type': 'TextFormField',
        'properties': {
          'label': 'Password',
          'hintText': 'Enter password',
          'inputType': 'password',
          'isRequired': true,
        }
      },
      {
        'type': 'DatePicker',
        'properties': {
          'label': 'Date of Birth',
          'hintText': 'Select your DOB',
          'isRequired': true,
        }
      },
      {
        'type': 'DropdownButtonForm',
        'properties': {
          'label': 'Country',
          'items': [
            {'label': 'United States', 'value': 'US'},
            {'label': 'Canada', 'value': 'CA'},
            {'label': 'UK', 'value': 'UK'},
          ],
          'isRequired': true,
        }
      },
      {
        'type': 'MultiSelect',
        'properties': {
          'label': 'Interests',
          'items': [
            {'label': 'Sports', 'value': 'sports'},
            {'label': 'Music', 'value': 'music'},
            {'label': 'Reading', 'value': 'reading'},
          ],
        }
      },
      {
        'type': 'TextArea',
        'properties': {
          'label': 'Bio',
          'hintText': 'Tell us about yourself...',
          'minLines': 3,
          'maxLines': 5,
        }
      },
      {
        'type': 'Button',
        'properties': {
          'label': 'Register',
          'width': double.infinity,
        }
      }
    ]
  };

  /// Survey Form Example
  static const Map<String, dynamic> surveyFormExample = {
    'type': 'Column',
    'properties': {
      'spacing': 20,
      'padding': 16,
    },
    'children': [
      {
        'type': 'Text',
        'properties': {
          'text': 'Customer Satisfaction Survey',
          'fontSize': 20,
          'fontWeight': 'bold',
        }
      },
      {
        'type': 'Rating',
        'properties': {
          'label': 'How would you rate our service?',
          'maxRating': 5,
        }
      },
      {
        'type': 'MultiSelect',
        'properties': {
          'label': 'What did you like most?',
          'items': [
            {'label': 'Quality', 'value': 'quality'},
            {'label': 'Price', 'value': 'price'},
            {'label': 'Customer Service', 'value': 'service'},
            {'label': 'Delivery Speed', 'value': 'speed'},
          ],
        }
      },
      {
        'type': 'TextArea',
        'properties': {
          'label': 'Any additional comments?',
          'minLines': 3,
          'maxLines': 6,
        }
      },
      {
        'type': 'Button',
        'properties': {
          'label': 'Submit Survey',
        }
      }
    ]
  };

  /// E-commerce Product Filter Example
  static const Map<String, dynamic> productFilterExample = {
    'type': 'Column',
    'properties': {
      'spacing': 16,
      'padding': 12,
    },
    'children': [
      {
        'type': 'SearchBox',
        'properties': {
          'hintText': 'Search products...',
          'suggestions': [
            'Laptop',
            'Laptop Bag',
            'Laptop Stand',
          ],
        }
      },
      {
        'type': 'DropdownButtonForm',
        'properties': {
          'label': 'Category',
          'items': [
            {'label': 'Electronics', 'value': 'electronics'},
            {'label': 'Clothing', 'value': 'clothing'},
          ],
        }
      },
      {
        'type': 'NumberInput',
        'properties': {
          'label': 'Price Range: Min',
          'initialValue': 0,
        }
      },
      {
        'type': 'NumberInput',
        'properties': {
          'label': 'Price Range: Max',
          'initialValue': 1000,
        }
      },
      {
        'type': 'MultiSelect',
        'properties': {
          'label': 'Brands',
          'items': [
            {'label': 'Apple', 'value': 'apple'},
            {'label': 'Dell', 'value': 'dell'},
            {'label': 'HP', 'value': 'hp'},
          ],
        }
      },
      {
        'type': 'Button',
        'properties': {
          'label': 'Apply Filters',
        }
      }
    ]
  };

  /// OTP Verification Example
  static const Map<String, dynamic> otpVerificationExample = {
    'type': 'Column',
    'properties': {
      'spacing': 20,
      'padding': 24,
      'crossAxisAlignment': 'center',
    },
    'children': [
      {
        'type': 'Text',
        'properties': {
          'text': 'Enter Verification Code',
          'fontSize': 18,
          'fontWeight': 'bold',
        }
      },
      {
        'type': 'Text',
        'properties': {
          'text': 'We sent a 6-digit code to your email',
          'fontSize': 14,
          'color': '#666666',
        }
      },
      {
        'type': 'OtpInput',
        'properties': {
          'length': 6,
          'keyboardType': 'number',
        }
      },
      {
        'type': 'Button',
        'properties': {
          'label': 'Verify',
        }
      }
    ]
  };

  /// Profile Settings Example
  static const Map<String, dynamic> profileSettingsExample = {
    'type': 'Column',
    'properties': {
      'spacing': 16,
      'padding': 16,
    },
    'children': [
      {
        'type': 'TextFormField',
        'properties': {
          'label': 'Username',
          'initialValue': 'johndoe',
        }
      },
      {
        'type': 'TextFormField',
        'properties': {
          'label': 'Email',
          'initialValue': 'john@example.com',
          'inputType': 'email',
        }
      },
      {
        'type': 'FileUpload',
        'properties': {
          'label': 'Profile Picture',
          'acceptedTypes': ['image/jpeg', 'image/png'],
        }
      },
      {
        'type': 'ColorPicker',
        'properties': {
          'label': 'Theme Color',
          'initialColor': '#2196F3',
        }
      },
      {
        'type': 'TextArea',
        'properties': {
          'label': 'Bio',
          'minLines': 3,
          'maxLines': 5,
        }
      },
      {
        'type': 'Button',
        'properties': {
          'label': 'Save Changes',
        }
      }
    ]
  };

  /// Get all examples as a map
  static Map<String, Map<String, dynamic>> getAllExamples() => {
    'textFormField': textFormFieldExample,
    'textFormFieldValidation': textFormFieldValidationExample,
    'textArea': textAreaExample,
    'textAreaLong': textAreaLongExample,
    'numberInput': numberInputExample,
    'numberInputRange': numberInputRangeExample,
    'datePicker': datePickerExample,
    'datePickerFuture': datePickerFutureExample,
    'timePicker': timePickerExample,
    'timePickerFormat': timePickerFormatExample,
    'colorPicker': colorPickerExample,
    'colorPickerPreset': colorPickerPresetExample,
    'dropdownButtonForm': dropdownButtonFormExample,
    'dropdownButtonFormLarge': dropdownButtonFormLargeExample,
    'multiSelect': multiSelectExample,
    'multiSelectMany': multiSelectManyExample,
    'searchBox': searchBoxExample,
    'searchBoxAutocomplete': searchBoxAutocompleteExample,
    'fileUpload': fileUploadExample,
    'fileUploadMultiple': fileUploadMultipleExample,
    'rating': ratingExample,
    'ratingLarge': ratingLargeExample,
    'otpInput': otpInputExample,
    'otpInputHidden': otpInputHiddenExample,
    'registrationForm': registrationFormExample,
    'surveyForm': surveyFormExample,
    'productFilter': productFilterExample,
    'otpVerification': otpVerificationExample,
    'profileSettings': profileSettingsExample,
  };
}
