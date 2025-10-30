# Form App Example

## Overview
A user registration form demonstrating:
- **Form Inputs**: Text fields with different keyboard types
- **State Management**: Binding form fields to state variables
- **Form Submission**: Sending data to backend API
- **User Feedback**: Displaying form status
- **Layout**: SingleChildScrollView for scrollable content

## Features
✅ Text input fields with labels and hints  
✅ Multiple keyboard types (text, email, phone)  
✅ Password field with obscure text  
✅ Form validation and submission  
✅ Responsive scrollable layout  
✅ Success feedback  

## JSON Structure

### Form Fields
```json
{
  "id": "text_field_name",
  "type": "TextField",
  "properties": {
    "label": "Full Name",
    "hint": "Enter your full name",
    "keyboardType": "text",
    "maxLines": 1
  },
  "stateBinding": {
    "variable": "fullName",
    "defaultValue": ""
  }
}
```

### Form Submission
```json
"actions": [
  {
    "type": "submitForm",
    "endpoint": "/api/register",
    "method": "POST",
    "body": {
      "fullName": "{fullName}",
      "email": "{email}"
    }
  }
]
```

## Key Concepts

### TextField Properties
- **label**: Field label text
- **hint**: Placeholder text
- **keyboardType**: Input type (text, email, phone, number, etc.)
- **obscureText**: Hide input (for passwords)
- **maxLines**: Number of input lines

### State Binding
Form fields bind to state variables for:
- Capturing user input
- Validating data
- Submitting to API

### Form Actions
- **submitForm**: Send form data to endpoint
- **showSnackbar**: Display success/error messages
- **validate**: Client-side validation

## Validation Rules
```json
"validation": {
  "fullName": {
    "required": true,
    "minLength": 2
  },
  "email": {
    "required": true,
    "pattern": "email"
  },
  "phone": {
    "required": true,
    "pattern": "phone"
  },
  "password": {
    "required": true,
    "minLength": 8
  }
}
```

## Testing
This app is tested with:
- TextField rendering tests
- State binding tests
- Form submission tests
- Keyboard type tests
- Validation tests

See `test/examples/form_app_test.dart` for implementation.

## Running the Example
```bash
flutter run --dart-define=QUICUI_CONFIG=form_app.json
```

## API Integration
The form sends POST request to `/api/register` with:
```json
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "phone": "1234567890",
  "password": "secure_password"
}
```

Expected success response:
```json
{
  "success": true,
  "message": "Registration successful!",
  "userId": "12345"
}
```

## Next Steps
- Add form validation
- Implement error handling
- Add loading spinner during submission
- Persist form data locally
- Add terms & conditions checkbox
