# Phase 2: Input & Form Widgets

**Status:** ✅ Complete  
**Widgets:** 12 input/form widgets  
**Lines of Code:** 1,200+  
**Date Completed:** 2024

## Overview

Phase 2 expands QuicUI with **12 comprehensive input and form widgets**, bringing the total widget count from 70+ to 82+. These widgets provide a complete foundation for building interactive forms, surveys, filters, and data entry interfaces.

### Phase 2 Widgets

| # | Widget | Purpose | Status |
|---|--------|---------|--------|
| 1 | **TextFormField** | Enhanced form text input with validation | ✅ Enhanced |
| 2 | **TextArea** | Multi-line text input | ✅ New |
| 3 | **NumberInput** | Numeric input with increment/decrement spinner | ✅ New |
| 4 | **DatePicker** | Date selection with calendar UI | ✅ New |
| 5 | **TimePicker** | Time selection with time picker UI | ✅ New |
| 6 | **ColorPicker** | Color selection with hex code display | ✅ New |
| 7 | **DropdownButtonForm** | Dropdown with form integration | ✅ New |
| 8 | **MultiSelect** | Multiple selection with checkboxes | ✅ New |
| 9 | **SearchBox** | Search input with suggestions/autocomplete | ✅ New |
| 10 | **FileUpload** | Drag-drop file upload with preview | ✅ New |
| 11 | **Rating** | Star rating widget (1-5 or custom) | ✅ New |
| 12 | **OtpInput** | OTP/PIN entry with multiple fields | ✅ New |

---

## Widget Details

### 1. TextFormField (Enhanced)

Enhanced form text input with validation support and customizable styling.

**Properties:**
```json
{
  "type": "TextFormField",
  "properties": {
    "label": "string (required)",
    "hintText": "string",
    "helperText": "string",
    "initialValue": "string",
    "inputType": "text|email|password|number|phone|url",
    "isRequired": "boolean (default: false)",
    "maxLines": "number (default: 1)",
    "backgroundColor": "string (hex color)",
    "borderRadius": "number",
    "borderColor": "string (hex color)",
    "textColor": "string (hex color)",
    "fontSize": "number"
  }
}
```

**Example:**
```json
{
  "type": "TextFormField",
  "properties": {
    "label": "Email",
    "hintText": "your.email@example.com",
    "inputType": "email",
    "isRequired": true,
    "backgroundColor": "#F5F5F5",
    "borderRadius": 8
  }
}
```

**Use Cases:**
- Login forms
- Registration forms
- Contact forms
- Search inputs

---

### 2. TextArea

Multi-line text input for longer text content with configurable line counts.

**Properties:**
```json
{
  "type": "TextArea",
  "properties": {
    "label": "string (required)",
    "hintText": "string",
    "initialValue": "string",
    "minLines": "number (default: 3)",
    "maxLines": "number (default: 6)",
    "backgroundColor": "string (hex color)",
    "borderRadius": "number",
    "textColor": "string (hex color)",
    "fontSize": "number"
  }
}
```

**Example:**
```json
{
  "type": "TextArea",
  "properties": {
    "label": "Comments",
    "hintText": "Enter your feedback...",
    "minLines": 3,
    "maxLines": 8,
    "backgroundColor": "#F9F9F9"
  }
}
```

**Use Cases:**
- Comments/feedback forms
- Description fields
- Message composition
- Testimonials

---

### 3. NumberInput

Numeric input with increment/decrement spinner controls.

**Properties:**
```json
{
  "type": "NumberInput",
  "properties": {
    "label": "string (required)",
    "initialValue": "number (default: 0)",
    "size": "small|medium|large",
    "backgroundColor": "string (hex color)",
    "accentColor": "string (hex color)"
  }
}
```

**Example:**
```json
{
  "type": "NumberInput",
  "properties": {
    "label": "Quantity",
    "initialValue": 1,
    "size": "medium"
  }
}
```

**Use Cases:**
- Shopping cart quantities
- Age input
- Rating selections
- Order amounts

---

### 4. DatePicker

Date selection with calendar UI.

**Properties:**
```json
{
  "type": "DatePicker",
  "properties": {
    "label": "string (required)",
    "hintText": "string",
    "initialDate": "string (yyyy-MM-dd)",
    "showClear": "boolean (default: true)",
    "backgroundColor": "string (hex color)"
  }
}
```

**Example:**
```json
{
  "type": "DatePicker",
  "properties": {
    "label": "Birth Date",
    "hintText": "Select your date of birth",
    "showClear": true
  }
}
```

**Use Cases:**
- Birth date selection
- Appointment scheduling
- Event date selection
- Date range filters

---

### 5. TimePicker

Time selection with time picker UI.

**Properties:**
```json
{
  "type": "TimePicker",
  "properties": {
    "label": "string (required)",
    "hintText": "string",
    "initialTime": "string (HH:mm)",
    "showClear": "boolean (default: true)",
    "backgroundColor": "string (hex color)"
  }
}
```

**Example:**
```json
{
  "type": "TimePicker",
  "properties": {
    "label": "Meeting Time",
    "hintText": "Select meeting time",
    "showClear": true
  }
}
```

**Use Cases:**
- Appointment time selection
- Schedule creation
- Alarm settings
- Business hours configuration

---

### 6. ColorPicker

Color selection with hex code display and validation.

**Properties:**
```json
{
  "type": "ColorPicker",
  "properties": {
    "label": "string (required)",
    "initialColor": "string (hex color, default: #FFFFFF)",
    "showHex": "boolean (default: true)",
    "backgroundColor": "string (hex color)"
  }
}
```

**Example:**
```json
{
  "type": "ColorPicker",
  "properties": {
    "label": "Theme Color",
    "initialColor": "#2196F3",
    "showHex": true
  }
}
```

**Use Cases:**
- Theme color selection
- Brand color configuration
- Design customization
- Background color selection

---

### 7. DropdownButtonForm

Dropdown selection with form integration.

**Properties:**
```json
{
  "type": "DropdownButtonForm",
  "properties": {
    "label": "string (required)",
    "items": [
      {"label": "string", "value": "string"},
      {"label": "string", "value": "string"}
    ],
    "selectedValue": "string",
    "hintText": "string",
    "isRequired": "boolean (default: false)",
    "backgroundColor": "string (hex color)"
  }
}
```

**Example:**
```json
{
  "type": "DropdownButtonForm",
  "properties": {
    "label": "Country",
    "items": [
      {"label": "United States", "value": "US"},
      {"label": "Canada", "value": "CA"},
      {"label": "United Kingdom", "value": "UK"}
    ],
    "selectedValue": "US",
    "isRequired": true
  }
}
```

**Use Cases:**
- Country/state selection
- Category selection
- Status selection
- Language preference

---

### 8. MultiSelect

Multiple selection with checkboxes.

**Properties:**
```json
{
  "type": "MultiSelect",
  "properties": {
    "label": "string (required)",
    "items": [
      {"label": "string", "value": "string"},
      {"label": "string", "value": "string"}
    ],
    "selectedValues": ["string"],
    "backgroundColor": "string (hex color)",
    "accentColor": "string (hex color)"
  }
}
```

**Example:**
```json
{
  "type": "MultiSelect",
  "properties": {
    "label": "Interests",
    "items": [
      {"label": "Sports", "value": "sports"},
      {"label": "Music", "value": "music"},
      {"label": "Reading", "value": "reading"}
    ],
    "selectedValues": ["sports", "music"]
  }
}
```

**Use Cases:**
- Skill/interest selection
- Permission settings
- Feature selection
- Tag assignment

---

### 9. SearchBox

Search input with suggestions and autocomplete.

**Properties:**
```json
{
  "type": "SearchBox",
  "properties": {
    "label": "string",
    "hintText": "string",
    "suggestions": ["string"],
    "backgroundColor": "string (hex color)",
    "accentColor": "string (hex color)"
  }
}
```

**Example:**
```json
{
  "type": "SearchBox",
  "properties": {
    "hintText": "Search products...",
    "suggestions": [
      "Laptop",
      "Laptop Bag",
      "Laptop Stand"
    ]
  }
}
```

**Use Cases:**
- Product search
- User search
- Document search
- Global search interface

---

### 10. FileUpload

Drag-drop file upload with preview and validation.

**Properties:**
```json
{
  "type": "FileUpload",
  "properties": {
    "label": "string (required)",
    "acceptedTypes": ["string (MIME type)"],
    "maxFileSize": "number (bytes)",
    "showFileList": "boolean (default: true)",
    "multiple": "boolean (default: false)"
  }
}
```

**Example:**
```json
{
  "type": "FileUpload",
  "properties": {
    "label": "Upload Profile Picture",
    "acceptedTypes": ["image/jpeg", "image/png"],
    "maxFileSize": 5242880,
    "showFileList": true
  }
}
```

**Use Cases:**
- Profile picture upload
- Document upload
- Resume upload
- Media gallery upload

---

### 11. Rating

Star rating widget with customizable rating levels.

**Properties:**
```json
{
  "type": "Rating",
  "properties": {
    "initialRating": "number (default: 0)",
    "maxRating": "number (default: 5)",
    "size": "small|medium|large",
    "color": "string (hex color)",
    "backgroundColor": "string (hex color)"
  }
}
```

**Example:**
```json
{
  "type": "Rating",
  "properties": {
    "initialRating": 4,
    "maxRating": 5,
    "size": "medium",
    "color": "#FFC107"
  }
}
```

**Use Cases:**
- Product ratings
- Service satisfaction
- Review submission
- Quality feedback

---

### 12. OtpInput

OTP/PIN entry with multiple input fields.

**Properties:**
```json
{
  "type": "OtpInput",
  "properties": {
    "length": "number (default: 4)",
    "keyboardType": "number|text (default: number)",
    "hideCharacters": "boolean (default: false)"
  }
}
```

**Example:**
```json
{
  "type": "OtpInput",
  "properties": {
    "length": 6,
    "keyboardType": "number",
    "hideCharacters": false
  }
}
```

**Use Cases:**
- Two-factor authentication
- Email verification
- Phone verification
- PIN entry

---

## JSON Schema System

All Phase 2 widgets include comprehensive JSON schemas with property validation:

```dart
// Get all schemas
final schemas = Phase2Schemas.getAllSchemas();

// Validate widget properties
final validation = Phase2Schemas.validateProperties(
  'DatePicker',
  properties
);

if (validation['isValid']) {
  // Properties are valid
} else {
  final errors = validation['errors'];
  // Handle validation errors
}
```

---

## Usage Examples

### Simple Form

```json
{
  "type": "Column",
  "properties": {"spacing": 16},
  "children": [
    {
      "type": "TextFormField",
      "properties": {
        "label": "Name",
        "hintText": "Enter your name"
      }
    },
    {
      "type": "TextFormField",
      "properties": {
        "label": "Email",
        "inputType": "email"
      }
    },
    {
      "type": "Button",
      "properties": {"label": "Submit"}
    }
  ]
}
```

### Product Filter

```json
{
  "type": "Column",
  "properties": {"spacing": 12, "padding": 16},
  "children": [
    {
      "type": "SearchBox",
      "properties": {
        "hintText": "Search products..."
      }
    },
    {
      "type": "DropdownButtonForm",
      "properties": {
        "label": "Category",
        "items": [
          {"label": "Electronics", "value": "electronics"},
          {"label": "Clothing", "value": "clothing"}
        ]
      }
    },
    {
      "type": "MultiSelect",
      "properties": {
        "label": "Brands",
        "items": [
          {"label": "Apple", "value": "apple"},
          {"label": "Dell", "value": "dell"}
        ]
      }
    }
  ]
}
```

### OTP Verification

```json
{
  "type": "Column",
  "properties": {
    "spacing": 20,
    "padding": 24
  },
  "children": [
    {
      "type": "Text",
      "properties": {
        "text": "Enter Verification Code",
        "fontSize": 18
      }
    },
    {
      "type": "OtpInput",
      "properties": {
        "length": 6,
        "keyboardType": "number"
      }
    },
    {
      "type": "Button",
      "properties": {"label": "Verify"}
    }
  ]
}
```

---

## Integration with UIRenderer

All Phase 2 widgets integrate seamlessly with UIRenderer:

```dart
final widget = UIRenderer.render({
  'type': 'DatePicker',
  'properties': {
    'label': 'Birth Date',
    'hintText': 'Select your date of birth'
  }
}, context);
```

---

## Schema Validation

Each widget includes comprehensive schema definition:

```dart
const textAreaSchema = {
  'type': 'TextArea',
  'properties': {
    'label': {
      'type': 'string',
      'required': true,
      'description': 'Label text for the text area'
    },
    'minLines': {
      'type': 'number',
      'default': 3,
      'description': 'Minimum number of lines'
    },
    'maxLines': {
      'type': 'number',
      'default': 6,
      'description': 'Maximum number of lines'
    },
    // ... more properties
  }
};
```

---

## Performance Considerations

- **Lazy Loading:** File uploads lazy-load previews
- **Text Caching:** Input fields cache formatted text
- **Color Parsing:** Color values are parsed and cached
- **Suggestion Debouncing:** SearchBox debounces suggestions

---

## Accessibility

All Phase 2 widgets include:
- ✅ Semantic labels
- ✅ Keyboard navigation support
- ✅ Screen reader compatibility
- ✅ Proper focus management
- ✅ WCAG 2.1 AA compliance

---

## Best Practices

1. **Use appropriate input types** for TextFormField
2. **Set maxFileSize** appropriately for FileUpload
3. **Provide helpful hints and helpers** for better UX
4. **Validate properties** before rendering
5. **Use MultiSelect** instead of multiple DropdownButtonForm
6. **Provide suggestions** in SearchBox for autocomplete

---

## Files

- **phase2_widgets.dart** - Widget implementations (500+ lines)
- **phase2_schemas.dart** - Schema definitions (350+ lines)
- **phase2_examples.dart** - Usage examples (300+ lines)

---

## Statistics

| Metric | Value |
|--------|-------|
| Total Widgets | 12 |
| New Widgets | 11 |
| Enhanced Widgets | 1 (TextFormField) |
| Total Code Lines | 1,200+ |
| Schema Definitions | 12 |
| Example Scenarios | 30+ |
| Input Types Supported | 8 |
| Validation Rules | 40+ |

---

## Next Phase

**Phase 3:** Layout & Advanced Widgets (13+ widgets)
- CustomScrollView
- SliverList, SliverGrid
- Flow, Wrap
- And more...

