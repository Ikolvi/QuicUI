# QuicUI Error Handling and Validation System

A comprehensive error handling and JSON validation system for QuicUI that provides robust error recovery, detailed debugging information, and build-time validation.

## Overview

This system provides multi-layered error handling that ensures your QuicUI applications are resilient and debuggable:

1. **Build-time Validation**: Catch JSON errors before deployment
2. **Runtime Error Handling**: Graceful error recovery during app execution  
3. **Comprehensive Logging**: Detailed error information for debugging
4. **User-Friendly Fallbacks**: Appropriate error displays for users

## Features

### ✅ JSON Schema Validation
- Widget type validation
- Required field checking
- Property type validation
- Nested structure validation

### ✅ Runtime Error Recovery
- Graceful widget fallbacks
- Detailed error context
- Performance-optimized error reporting
- Debug vs production error displays

### ✅ Build-time Analysis
- Cross-file dependency validation
- Performance issue detection
- Security vulnerability scanning
- Accessibility compliance checking

### ✅ Development Tools
- CLI validation tool
- Watch mode for real-time feedback
- IDE integration support
- Comprehensive error reporting

## Quick Start

### Runtime Error Handling

The error handling system is automatically integrated into `UIRenderer`. No additional setup required:

```dart
// Error handling is automatic
final widget = UIRenderer.render(jsonData);

// Errors are caught and logged automatically
// Fallback widgets are displayed to users
// Detailed debug information is available in logs
```

### Build-time Validation

Use the CLI tool to validate your JSON configurations:

```bash
# Validate entire project
dart run quicui:validate

# Validate specific file
dart run quicui:validate --file assets/screens/login.json

# Watch mode for development
dart run quicui:validate --watch

# Generate detailed report
dart run quicui:validate --output report.json
```

### Programmatic Validation

```dart
import 'package:quicui/quicui.dart';

// Validate JSON content
final validator = BuildTimeValidator();
final result = await validator.validateJson(jsonString);

if (!result.isValid) {
  for (final issue in result.issues) {
    print('${issue.severity}: ${issue.message}');
  }
}

// Validate entire project
final report = await validator.validateProject('/path/to/project');
print(report.generateSummary());
```

## Error Categories

### 1. JSON Syntax Errors
- Invalid JSON structure
- Missing brackets/quotes
- Trailing commas

**Example:**
```json
{
  "type": "Text",
  "properties": {
    "text": "Hello World"  // Missing comma
    "fontSize": 16
  }
}
```

**Detection:** Build-time and runtime
**Impact:** Critical - prevents parsing

### 2. Schema Validation Errors
- Missing required fields
- Invalid property types
- Unknown widget types

**Example:**
```json
{
  "type": "Text",
  // Missing required "text" property
  "properties": {
    "fontSize": "large"  // Invalid type (should be number)
  }
}
```

**Detection:** Build-time and runtime
**Impact:** Major - affects functionality

### 3. Widget Rendering Errors
- Property parsing failures
- Layout constraint violations
- Resource loading failures

**Example:**
```json
{
  "type": "Row",
  "properties": {
    "mainAxisSize": "max"  // Can cause unbounded constraints in ScrollView
  },
  "children": [
    // Large number of children
  ]
}
```

**Detection:** Runtime
**Impact:** Major - visual issues

### 4. Dependency Errors
- Missing image assets
- Invalid navigation targets
- Broken references

**Example:**
```json
{
  "type": "Image",
  "properties": {
    "src": "assets/missing_image.png"  // File doesn't exist
  }
}
```

**Detection:** Build-time
**Impact:** Major - broken functionality

## Error Handling Strategies

### Debug Mode
In debug mode, detailed error information is displayed:

```dart
// Detailed error widget with:
// - Error type and message
// - JSON context
// - Stack trace
// - Debugging hints
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.red[50],
    border: Border.all(color: Colors.red),
  ),
  child: Column(
    children: [
      Icon(Icons.error_outline),
      Text('Widget Rendering Error'),
      Text('Text widget requires "text" property'),
      Text('JSON: {"type": "Text", "properties": {}}'),
    ],
  ),
)
```

### Production Mode
In production, user-friendly error displays are shown:

```dart
// Minimal error indication
Container(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      Icon(Icons.info_outline, color: Colors.grey),
      Text('Content temporarily unavailable'),
    ],
  ),
)
```

### Fallback Strategies

1. **Property Fallbacks**: Use default values for missing properties
2. **Widget Fallbacks**: Replace complex widgets with simpler versions
3. **Content Fallbacks**: Show placeholder content when data is invalid
4. **Layout Fallbacks**: Use basic layouts when complex ones fail

## Validation Rules

### Required Fields by Widget Type

#### Text Widget
```json
{
  "type": "Text",
  "properties": {
    "text": "Required - string content"  // Required
  }
}
```

#### Button Widgets
```json
{
  "type": "ElevatedButton", 
  "properties": {
    "text": "Required - button label"  // Required
  },
  "events": {
    "onPressed": {  // Recommended
      "action": "navigate",
      "screen": "target_screen"
    }
  }
}
```

#### Layout Widgets
```json
{
  "type": "Column",
  "children": []  // Required - array of child widgets
}
```

### Performance Rules

1. **Maximum Children**: Warn if > 50 children in layout widgets
2. **Nesting Depth**: Warn if nesting > 10 levels deep
3. **Image Sizes**: Check for oversized images
4. **Memory Usage**: Detect potential memory leaks

### Accessibility Rules

1. **Semantic Labels**: Interactive widgets should have labels
2. **Color Contrast**: Ensure sufficient contrast ratios
3. **Touch Targets**: Minimum 48dp touch targets
4. **Navigation**: Proper focus management

### Security Rules

1. **External URLs**: Validate external resource URLs
2. **Data Exposure**: Check for sensitive data in JSON
3. **Input Validation**: Ensure proper input sanitization

## CLI Tool Usage

### Basic Commands

```bash
# Validate current directory
dart run quicui:validate

# Validate with all checks
dart run quicui:validate --strict --performance --security --accessibility

# Validate specific file
dart run quicui:validate --file assets/screens/home.json

# Generate JSON report
dart run quicui:validate --output validation_report.json

# Watch mode for development
dart run quicui:validate --watch --verbose
```

### Exit Codes

- `0`: Validation passed
- `1`: Major errors found  
- `2`: Critical errors found

### Output Formats

#### Console Output
```
🔍 Validating QuicUI project: .
📁 Assets paths: assets, lib/assets

✅ Validation passed!

📊 Summary:
   Files validated: 12
   Total issues: 3
   ⚡ warning: 2
   💡 minor: 1
```

#### JSON Report
```json
{
  "summary": {
    "is_valid": true,
    "total_files": 12,
    "total_issues": 3,
    "issues_by_severity": {
      "critical": 0,
      "major": 0,
      "minor": 1,
      "warning": 2
    }
  },
  "files": {
    "assets/screens/home.json": {
      "is_valid": true,
      "issues": []
    }
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## IDE Integration

### VS Code Extension (Future)
- Real-time validation
- Inline error highlighting
- Quick fixes and suggestions
- Schema completion

### Configuration
```json
{
  "quicui.validation.enabled": true,
  "quicui.validation.strictMode": false,
  "quicui.validation.autoFix": true
}
```

## Best Practices

### 1. Validate Early and Often
```bash
# Add to your build pipeline
dart run quicui:validate || exit 1
```

### 2. Use Watch Mode During Development
```bash
# Terminal 1: Development server
flutter run

# Terminal 2: JSON validation
dart run quicui:validate --watch
```

### 3. Implement Proper Error Boundaries
```dart
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  
  const ErrorBoundary({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return ErrorHandler.wrapWidget(
      child,
      onError: (error, context) {
        // Custom error handling
        return CustomErrorWidget(error: error);
      },
    );
  }
}
```

### 4. Log Errors for Analytics
```dart
ErrorHandler.onError = (error, context) {
  // Send to crash analytics
  FirebaseCrashlytics.instance.recordError(error, null);
  
  // Log for debugging
  LoggerUtil.error('Widget error', error);
};
```

### 5. Provide User Feedback
```dart
// Show user-friendly messages
if (!validationResult.isValid) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Some content could not be loaded'),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () => _retryLoading(),
      ),
    ),
  );
}
```

## Advanced Configuration

### Custom Validation Rules
```dart
class CustomValidator extends BuildTimeValidator {
  @override
  Future<void> validateCustomRules(
    Map<String, dynamic> jsonData,
    ValidationResultBase result,
  ) async {
    // Add your custom validation logic
    if (jsonData['type'] == 'CustomWidget') {
      // Validate custom widget requirements
    }
  }
}
```

### Error Recovery Strategies
```dart
ErrorHandler.addRecoveryStrategy('NetworkError', (error, context) async {
  // Retry network operations
  await Future.delayed(Duration(seconds: 1));
  return await _retryNetworkCall();
});
```

### Performance Monitoring
```dart
ErrorHandler.onPerformanceIssue = (issue) {
  // Track performance issues
  Analytics.track('performance_issue', {
    'type': issue.type,
    'severity': issue.severity,
    'widget_count': issue.widgetCount,
  });
};
```

## Troubleshooting

### Common Issues

1. **Import Errors**
```dart
// Ensure proper imports
import 'package:quicui/quicui.dart';
```

2. **Path Issues**
```bash
# Use absolute paths for CLI
dart run quicui:validate --project /full/path/to/project
```

3. **Permission Issues**
```bash
# Ensure read permissions for assets
chmod -R 755 assets/
```

4. **Memory Issues with Large Projects**
```bash
# Limit validation scope
dart run quicui:validate --assets assets/screens --no-performance
```

### Debug Mode

Enable verbose logging for troubleshooting:

```dart
LoggerUtil.setLevel(LogLevel.debug);
ErrorHandler.enableVerboseLogging = true;
```

### Performance Impact

The error handling system is designed to have minimal performance impact:

- **Build-time validation**: Zero runtime impact
- **Runtime validation**: ~1-2ms overhead per widget
- **Error recovery**: Only activated during errors
- **Debug information**: Compiled out in release builds

## Migration Guide

### From Basic Error Handling

If you were using basic try-catch blocks:

```dart
// Before
try {
  final widget = UIRenderer.render(json);
  return widget;
} catch (e) {
  return Text('Error: $e');
}

// After - automatic error handling
final widget = UIRenderer.render(json);
return widget; // Errors handled automatically
```

### From Custom Validation

If you had custom validation logic:

```dart
// Before
bool validateJson(Map<String, dynamic> json) {
  return json.containsKey('type') && json.containsKey('properties');
}

// After - comprehensive validation
final result = await JsonValidator.validateWidgetJson(json);
return result.isValid;
```

## Contributing

To contribute to the error handling system:

1. **Add validation rules** in `JsonValidator`
2. **Implement error recovery** in `ErrorHandler`
3. **Extend CLI features** in `bin/validate.dart`
4. **Add tests** for new functionality

## Support

For questions and issues:

- GitHub Issues: Report bugs and feature requests
- Documentation: See inline code documentation
- Examples: Check `example/` directory for usage patterns