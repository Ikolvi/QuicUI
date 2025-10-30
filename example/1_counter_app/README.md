# Counter App Example

## Overview
A simple counter application that demonstrates:
- **State Management**: Using QuicUI state binding to manage counter state
- **Event Handling**: Responding to button taps
- **Widget Hierarchy**: Scaffold, AppBar, FloatingActionButton layout
- **Text Rendering**: Displaying dynamic text with styling

## Features
✅ Increment counter on button tap  
✅ Display counter value with styling  
✅ Responsive layout with Center widget  
✅ Material Design AppBar and FAB  

## JSON Structure

### Root Level
```json
{
  "version": "1.0",
  "metadata": {...},
  "theme": {...},
  "screens": [...]
}
```

### Screen Definition
- **id**: Unique screen identifier
- **widgets**: Array of widget tree

### Widget Configuration
- **id**: Unique widget identifier
- **type**: Widget type (Scaffold, AppBar, Center, Column, Text, etc.)
- **slot**: Placement in parent (appBar, body, floatingActionButton)
- **properties**: Widget-specific properties
- **children**: Child widgets
- **stateBinding**: Variable binding for dynamic content
- **actions**: Event handlers

## Key Concepts

### State Binding
```json
"stateBinding": {
  "variable": "counter",
  "defaultValue": "0"
}
```
Binds widget text to a state variable that updates when changed.

### Actions
```json
"actions": [
  {
    "type": "setState",
    "variable": "counter",
    "operation": "increment"
  }
]
```
Defines what happens when user interacts with widget.

## Testing
This app is tested with:
- Widget rendering tests
- State update tests
- Action execution tests
- Property parsing tests

See `test/examples/counter_app_test.dart` for implementation.

## Running the Example
```bash
# Via QuicUI framework
quicui build counter_app.json

# Or directly with Flutter
flutter run --dart-define=QUICUI_CONFIG=counter_app.json
```

## Next Steps
- Explore the JSON structure
- Modify the counter increment operation
- Add a decrement button
- Style the UI with different colors
