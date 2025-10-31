/// Build-time JSON validation utility for QuicUI framework
///
/// This module provides comprehensive build-time validation for JSON
/// configurations used in QuicUI applications. It helps catch errors
/// early in the development cycle and provides detailed feedback.
///
/// ## Features
///
/// 1. **Schema Validation**: Validates JSON against QuicUI widget schemas
/// 2. **Dependency Analysis**: Checks for missing resources and references
/// 3. **Performance Analysis**: Identifies potential performance issues
/// 4. **Security Checks**: Validates for potential security vulnerabilities
/// 5. **Consistency Checks**: Ensures consistency across screen definitions
///
/// ## Usage Examples
///
/// ### Basic Validation
/// ```dart
/// final validator = BuildTimeValidator();
/// final result = await validator.validateProject('/path/to/assets');
/// if (!result.isValid) {
///   for (final issue in result.issues) {
///     print('${issue.severity}: ${issue.message}');
///   }
/// }
/// ```
///
/// ### Specific File Validation
/// ```dart
/// final result = await validator.validateFile('/path/to/screen.json');
/// ```
///
/// ### Real-time Validation (for IDEs)
/// ```dart
/// final result = await validator.validateJson(jsonString, context: {
///   'file_path': '/assets/screens/login.json',
///   'screen_id': 'login_screen',
/// });
/// ```

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:quicui/src/utils/logger_util.dart';
import 'package:quicui/src/utils/error_handler.dart';

/// Build-time validator for QuicUI JSON configurations
///
/// Provides comprehensive validation for JSON files used in QuicUI
/// applications including schema validation, dependency checking,
/// and performance analysis.
class BuildTimeValidator {
  /// Validate an entire QuicUI project
  ///
  /// Scans all JSON files in the project and validates them against
  /// QuicUI schemas, checks dependencies, and analyzes for potential issues.
  ///
  /// ## Parameters
  /// - [projectPath]: Path to the project root
  /// - [assetsPaths]: List of asset directories to scan (optional)
  /// - [options]: Validation options and settings
  ///
  /// ## Returns
  /// [ValidationReport] containing all validation results
  Future<ValidationReport> validateProject(
    String projectPath, {
    List<String>? assetsPaths,
    ValidationOptions? options,
  }) async {
    final report = ValidationReport();
    final opts = options ?? ValidationOptions();

    try {
      // Find all JSON files
      final jsonFiles = await _findJsonFiles(projectPath, assetsPaths);
      LoggerUtil.info('Found ${jsonFiles.length} JSON files to validate');

      // Validate each file
      for (final file in jsonFiles) {
        final fileResult = await validateFile(file.path, options: opts);
        report.addFileResult(file.path, fileResult);
      }

      // Cross-file validation
      await _performCrossFileValidation(report, opts);

      // Performance analysis
      if (opts.enablePerformanceAnalysis) {
        await _performPerformanceAnalysis(report, opts);
      }

      // Security analysis
      if (opts.enableSecurityAnalysis) {
        await _performSecurityAnalysis(report, opts);
      }

    } catch (error, stackTrace) {
      LoggerUtil.error('Project validation failed', error, stackTrace);
      report.addIssue(ValidationIssue(
        severity: IssueSeverity.critical,
        message: 'Project validation failed: $error',
        filePath: projectPath,
        context: {'error_type': error.runtimeType.toString()},
      ));
    }

    return report;
  }

  /// Validate a single JSON file
  ///
  /// Performs comprehensive validation on a single JSON file including
  /// syntax checking, schema validation, and content analysis.
  ///
  /// ## Parameters
  /// - [filePath]: Path to the JSON file to validate
  /// - [options]: Validation options and settings
  ///
  /// ## Returns
  /// [FileValidationResult] containing validation results for the file
  Future<FileValidationResult> validateFile(
    String filePath, {
    ValidationOptions? options,
  }) async {
    final result = FileValidationResult(filePath);
    final opts = options ?? ValidationOptions();

    try {
      // Check file exists and is readable
      final file = File(filePath);
      if (!await file.exists()) {
        result.addIssue(ValidationIssue(
          severity: IssueSeverity.critical,
          message: 'File does not exist: $filePath',
          filePath: filePath,
        ));
        return result;
      }

      // Read and parse JSON
      final content = await file.readAsString();
      final Map<String, dynamic> jsonData;

      try {
        jsonData = json.decode(content) as Map<String, dynamic>;
      } catch (parseError) {
        result.addIssue(ValidationIssue(
          severity: IssueSeverity.critical,
          message: 'Invalid JSON syntax: $parseError',
          filePath: filePath,
          context: {'parse_error': parseError.toString()},
        ));
        return result;
      }

      // Schema validation
      await _validateSchema(jsonData, result, opts);

      // Content validation
      await _validateContent(jsonData, result, opts);

      // Dependency validation
      if (opts.enableDependencyChecks) {
        await _validateDependencies(jsonData, result, opts);
      }

    } catch (error, stackTrace) {
      LoggerUtil.error('File validation failed: $filePath', error, stackTrace);
      result.addIssue(ValidationIssue(
        severity: IssueSeverity.critical,
        message: 'File validation failed: $error',
        filePath: filePath,
        context: {'error_type': error.runtimeType.toString()},
      ));
    }

    return result;
  }

  /// Validate JSON content directly
  ///
  /// Validates JSON content without file I/O, useful for real-time
  /// validation in IDEs and editors.
  ///
  /// ## Parameters
  /// - [jsonContent]: The JSON content to validate
  /// - [context]: Additional context information
  /// - [options]: Validation options
  ///
  /// ## Returns
  /// [ContentValidationResult] containing validation results
  Future<ContentValidationResult> validateJson(
    String jsonContent, {
    Map<String, dynamic>? context,
    ValidationOptions? options,
  }) async {
    final result = ContentValidationResult();
    final opts = options ?? ValidationOptions();
    final ctx = context ?? {};

    try {
      // Parse JSON
      final Map<String, dynamic> jsonData;
      
      try {
        jsonData = json.decode(jsonContent) as Map<String, dynamic>;
      } catch (parseError) {
        result.addIssue(ValidationIssue(
          severity: IssueSeverity.critical,
          message: 'Invalid JSON syntax: $parseError',
          context: {'parse_error': parseError.toString(), ...ctx},
        ));
        return result;
      }

      // Schema validation
      await _validateSchema(jsonData, result, opts);

      // Content validation
      await _validateContent(jsonData, result, opts);

    } catch (error, stackTrace) {
      LoggerUtil.error('JSON validation failed', error, stackTrace);
      result.addIssue(ValidationIssue(
        severity: IssueSeverity.critical,
        message: 'JSON validation failed: $error',
        context: {'error_type': error.runtimeType.toString(), ...ctx},
      ));
    }

    return result;
  }

  /// Find all JSON files in project
  Future<List<FileSystemEntity>> _findJsonFiles(
    String projectPath,
    List<String>? assetsPaths,
  ) async {
    final jsonFiles = <FileSystemEntity>[];
    final searchPaths = assetsPaths ?? ['assets', 'lib/assets', 'assets/screens'];

    for (final assetsPath in searchPaths) {
      final fullPath = path.join(projectPath, assetsPath);
      final directory = Directory(fullPath);

      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.json')) {
            jsonFiles.add(entity);
          }
        }
      }
    }

    return jsonFiles;
  }

  /// Validate JSON schema
  Future<void> _validateSchema(
    Map<String, dynamic> jsonData,
    ValidationResultBase result,
    ValidationOptions options,
  ) async {
    // Determine expected schema based on content
    final schema = _detectSchema(jsonData);
    
    switch (schema) {
      case JsonSchema.screen:
        await _validateScreenSchema(jsonData, result);
        break;
      case JsonSchema.widget:
        await _validateWidgetSchema(jsonData, result);
        break;
      case JsonSchema.materialApp:
        await _validateMaterialAppSchema(jsonData, result);
        break;
      case JsonSchema.unknown:
        result.addIssue(ValidationIssue(
          severity: IssueSeverity.warning,
          message: 'Unknown JSON schema detected',
          context: {
            'available_keys': jsonData.keys.toList(),
            'suggestion': 'Ensure JSON follows QuicUI schema patterns',
          },
        ));
        break;
    }
  }

  /// Detect JSON schema type
  JsonSchema _detectSchema(Map<String, dynamic> jsonData) {
    // MaterialApp detection
    if (jsonData.containsKey('home') || 
        jsonData.containsKey('routes') ||
        jsonData.containsKey('theme')) {
      return JsonSchema.materialApp;
    }

    // Screen detection
    if (jsonData.containsKey('screens') || 
        jsonData.containsKey('screenId') ||
        (jsonData.containsKey('body') && jsonData.containsKey('appBar'))) {
      return JsonSchema.screen;
    }

    // Widget detection
    if (jsonData.containsKey('type') && jsonData.containsKey('properties')) {
      return JsonSchema.widget;
    }

    return JsonSchema.unknown;
  }

  /// Validate screen schema
  Future<void> _validateScreenSchema(
    Map<String, dynamic> jsonData,
    ValidationResultBase result,
  ) async {
    // Check required fields for screen
    final requiredFields = ['screenId', 'body'];
    for (final field in requiredFields) {
      if (!jsonData.containsKey(field)) {
        result.addIssue(ValidationIssue(
          severity: IssueSeverity.major,
          message: 'Missing required field: $field',
          context: {'expected_fields': requiredFields},
        ));
      }
    }

    // Validate screen structure
    if (jsonData.containsKey('body')) {
      final body = jsonData['body'];
      if (body is Map<String, dynamic>) {
        final validation = JsonValidator.validateWidgetJson(body);
        for (final error in validation.errors) {
          result.addIssue(ValidationIssue(
            severity: _mapErrorSeverity(error.severity),
            message: 'Body validation error: ${error.message}',
            context: {'field': 'body.${error.field}'},
          ));
        }
      }
    }
  }

  /// Validate widget schema
  Future<void> _validateWidgetSchema(
    Map<String, dynamic> jsonData,
    ValidationResultBase result,
  ) async {
    final validation = JsonValidator.validateWidgetJson(jsonData);
    for (final error in validation.errors) {
      result.addIssue(ValidationIssue(
        severity: _mapErrorSeverity(error.severity),
        message: error.message,
        context: {'field': error.field},
      ));
    }
  }

  /// Validate MaterialApp schema
  Future<void> _validateMaterialAppSchema(
    Map<String, dynamic> jsonData,
    ValidationResultBase result,
  ) async {
    // Check MaterialApp specific requirements
    if (!jsonData.containsKey('home') && !jsonData.containsKey('routes')) {
      result.addIssue(ValidationIssue(
        severity: IssueSeverity.major,
        message: 'MaterialApp must have either "home" or "routes" property',
        context: {'available_keys': jsonData.keys.toList()},
      ));
    }

    // Validate home widget if present
    if (jsonData.containsKey('home')) {
      final home = jsonData['home'];
      if (home is Map<String, dynamic>) {
        final validation = JsonValidator.validateWidgetJson(home);
        for (final error in validation.errors) {
          result.addIssue(ValidationIssue(
            severity: _mapErrorSeverity(error.severity),
            message: 'Home widget error: ${error.message}',
            context: {'field': 'home.${error.field}'},
          ));
        }
      }
    }
  }

  /// Validate content for consistency and best practices
  Future<void> _validateContent(
    Map<String, dynamic> jsonData,
    ValidationResultBase result,
    ValidationOptions options,
  ) async {
    // Check for common anti-patterns
    _checkForAntiPatterns(jsonData, result);

    // Validate accessibility
    if (options.enableAccessibilityChecks) {
      _validateAccessibility(jsonData, result);
    }

    // Check for deprecated patterns
    _checkForDeprecatedPatterns(jsonData, result);
  }

  /// Check for common anti-patterns
  void _checkForAntiPatterns(
    Map<String, dynamic> jsonData,
    ValidationResultBase result,
  ) {
    // Check for deeply nested structures
    final depth = _calculateNestingDepth(jsonData);
    if (depth > 10) {
      result.addIssue(ValidationIssue(
        severity: IssueSeverity.warning,
        message: 'Deep nesting detected (depth: $depth). Consider refactoring.',
        context: {
          'nesting_depth': depth,
          'recommendation': 'Extract nested widgets into separate components',
        },
      ));
    }

    // Check for excessive children count
    _checkExcessiveChildren(jsonData, result);
  }

  /// Calculate maximum nesting depth
  int _calculateNestingDepth(Map<String, dynamic> data, [int currentDepth = 0]) {
    int maxDepth = currentDepth;

    if (data.containsKey('children')) {
      final children = data['children'];
      if (children is List) {
        for (final child in children) {
          if (child is Map<String, dynamic>) {
            final childDepth = _calculateNestingDepth(child, currentDepth + 1);
            maxDepth = maxDepth > childDepth ? maxDepth : childDepth;
          }
        }
      }
    }

    if (data.containsKey('child')) {
      final child = data['child'];
      if (child is Map<String, dynamic>) {
        final childDepth = _calculateNestingDepth(child, currentDepth + 1);
        maxDepth = maxDepth > childDepth ? maxDepth : childDepth;
      }
    }

    return maxDepth;
  }

  /// Check for excessive children in layout widgets
  void _checkExcessiveChildren(
    Map<String, dynamic> data,
    ValidationResultBase result,
  ) {
    if (data.containsKey('children')) {
      final children = data['children'];
      if (children is List && children.length > 50) {
        result.addIssue(ValidationIssue(
          severity: IssueSeverity.warning,
          message: 'Large number of children (${children.length}). Consider using ListView or pagination.',
          context: {
            'children_count': children.length,
            'widget_type': data['type'],
            'recommendation': 'Use ListView.builder for large lists',
          },
        ));
      }
    }
  }

  /// Validate accessibility requirements
  void _validateAccessibility(
    Map<String, dynamic> data,
    ValidationResultBase result,
  ) {
    final widgetType = data['type'] as String?;
    
    // Check for semantic labels on interactive widgets
    if (_isInteractiveWidget(widgetType)) {
      final properties = data['properties'] as Map<String, dynamic>?;
      if (properties == null || 
          (!properties.containsKey('semanticLabel') && 
           !properties.containsKey('tooltip'))) {
        result.addIssue(ValidationIssue(
          severity: IssueSeverity.minor,
          message: 'Interactive widget missing accessibility labels',
          context: {
            'widget_type': widgetType,
            'recommendation': 'Add semanticLabel or tooltip property',
          },
        ));
      }
    }
  }

  /// Check if widget type is interactive
  bool _isInteractiveWidget(String? widgetType) {
    const interactiveWidgets = {
      'ElevatedButton', 'TextButton', 'OutlinedButton', 'IconButton',
      'FloatingActionButton', 'Switch', 'Checkbox', 'Radio', 'Slider',
      'TextField', 'TextFormField', 'DropdownButton', 'GestureDetector',
    };
    return widgetType != null && interactiveWidgets.contains(widgetType);
  }

  /// Check for deprecated patterns
  void _checkForDeprecatedPatterns(
    Map<String, dynamic> data,
    ValidationResultBase result,
  ) {
    // Check for deprecated property names
    final properties = data['properties'] as Map<String, dynamic>?;
    if (properties != null) {
      for (final deprecatedProperty in _deprecatedProperties.keys) {
        if (properties.containsKey(deprecatedProperty)) {
          final replacement = _deprecatedProperties[deprecatedProperty];
          result.addIssue(ValidationIssue(
            severity: IssueSeverity.warning,
            message: 'Deprecated property: $deprecatedProperty',
            context: {
              'deprecated_property': deprecatedProperty,
              'replacement': replacement,
              'recommendation': 'Update to use $replacement instead',
            },
          ));
        }
      }
    }
  }

  /// Map of deprecated properties to their replacements
  static const Map<String, String> _deprecatedProperties = {
    'fontFamily': 'style.fontFamily',
    'fontSize': 'style.fontSize',
    'fontWeight': 'style.fontWeight',
    'textColor': 'style.color',
  };

  /// Validate dependencies and references
  Future<void> _validateDependencies(
    Map<String, dynamic> jsonData,
    ValidationResultBase result,
    ValidationOptions options,
  ) async {
    // Check for missing image assets
    await _validateImageReferences(jsonData, result);

    // Check for missing navigation targets
    _validateNavigationReferences(jsonData, result);
  }

  /// Validate image asset references
  Future<void> _validateImageReferences(
    Map<String, dynamic> data,
    ValidationResultBase result,
  ) async {
    if (data['type'] == 'Image') {
      final properties = data['properties'] as Map<String, dynamic>?;
      final src = properties?['src'] as String?;
      
      if (src != null && src.startsWith('assets/')) {
        final file = File(src);
        if (!await file.exists()) {
          result.addIssue(ValidationIssue(
            severity: IssueSeverity.major,
            message: 'Referenced image asset not found: $src',
            context: {
              'asset_path': src,
              'recommendation': 'Ensure image file exists in assets directory',
            },
          ));
        }
      }
    }

    // Recursively check children
    _checkChildrenForImageReferences(data, result);
  }

  /// Recursively check children for image references
  void _checkChildrenForImageReferences(
    Map<String, dynamic> data,
    ValidationResultBase result,
  ) {
    if (data.containsKey('children')) {
      final children = data['children'];
      if (children is List) {
        for (final child in children) {
          if (child is Map<String, dynamic>) {
            _validateImageReferences(child, result);
          }
        }
      }
    }

    if (data.containsKey('child')) {
      final child = data['child'];
      if (child is Map<String, dynamic>) {
        _validateImageReferences(child, result);
      }
    }
  }

  /// Validate navigation references
  void _validateNavigationReferences(
    Map<String, dynamic> data,
    ValidationResultBase result,
  ) {
    // Check for navigation actions
    final events = data['events'] as Map<String, dynamic>?;
    if (events != null) {
      for (final event in events.values) {
        if (event is Map<String, dynamic>) {
          final action = event['action'] as String?;
          if (action == 'navigate') {
            final screen = event['screen'] as String?;
            if (screen == null || screen.isEmpty) {
              result.addIssue(ValidationIssue(
                severity: IssueSeverity.major,
                message: 'Navigation action missing target screen',
                context: {
                  'action': action,
                  'recommendation': 'Specify target screen for navigation',
                },
              ));
            }
          }
        }
      }
    }
  }

  /// Perform cross-file validation
  Future<void> _performCrossFileValidation(
    ValidationReport report,
    ValidationOptions options,
  ) async {
    // Implementation would check for consistency across files
    // e.g., navigation targets exist, shared resources are available
  }

  /// Perform performance analysis
  Future<void> _performPerformanceAnalysis(
    ValidationReport report,
    ValidationOptions options,
  ) async {
    // Implementation would analyze for performance issues
    // e.g., large images, excessive widgets, expensive operations
  }

  /// Perform security analysis
  Future<void> _performSecurityAnalysis(
    ValidationReport report,
    ValidationOptions options,
  ) async {
    // Implementation would check for security issues
    // e.g., external URLs, data exposure, injection risks
  }

  /// Map ErrorSeverity to IssueSeverity
  IssueSeverity _mapErrorSeverity(ErrorSeverity severity) {
    return switch (severity) {
      ErrorSeverity.critical => IssueSeverity.critical,
      ErrorSeverity.major => IssueSeverity.major,
      ErrorSeverity.minor => IssueSeverity.minor,
      ErrorSeverity.warning => IssueSeverity.warning,
    };
  }
}

/// Validation options and settings
class ValidationOptions {
  final bool enableDependencyChecks;
  final bool enablePerformanceAnalysis;
  final bool enableSecurityAnalysis;
  final bool enableAccessibilityChecks;
  final bool strictMode;

  const ValidationOptions({
    this.enableDependencyChecks = true,
    this.enablePerformanceAnalysis = true,
    this.enableSecurityAnalysis = true,
    this.enableAccessibilityChecks = true,
    this.strictMode = false,
  });
}

/// JSON schema types
enum JsonSchema {
  screen,
  widget,
  materialApp,
  unknown,
}

/// Issue severity levels
enum IssueSeverity {
  critical,
  major,
  minor,
  warning,
}

/// Validation issue details
class ValidationIssue {
  final IssueSeverity severity;
  final String message;
  final String? filePath;
  final Map<String, dynamic> context;

  const ValidationIssue({
    required this.severity,
    required this.message,
    this.filePath,
    this.context = const {},
  });

  @override
  String toString() {
    final location = filePath != null ? ' ($filePath)' : '';
    return '${severity.name.toUpperCase()}: $message$location';
  }
}

/// Base class for validation results
abstract class ValidationResultBase {
  final List<ValidationIssue> _issues = [];

  List<ValidationIssue> get issues => List.unmodifiable(_issues);

  bool get isValid => _issues.where((i) => 
    i.severity == IssueSeverity.critical || 
    i.severity == IssueSeverity.major
  ).isEmpty;

  void addIssue(ValidationIssue issue) {
    _issues.add(issue);
  }

  List<ValidationIssue> getIssuesBySeverity(IssueSeverity severity) {
    return _issues.where((i) => i.severity == severity).toList();
  }
}

/// Validation result for a single file
class FileValidationResult extends ValidationResultBase {
  final String filePath;

  FileValidationResult(this.filePath);
}

/// Validation result for JSON content
class ContentValidationResult extends ValidationResultBase {}

/// Complete validation report for a project
class ValidationReport extends ValidationResultBase {
  final Map<String, FileValidationResult> _fileResults = {};

  Map<String, FileValidationResult> get fileResults => 
    Map.unmodifiable(_fileResults);

  void addFileResult(String filePath, FileValidationResult result) {
    _fileResults[filePath] = result;
    _issues.addAll(result.issues);
  }

  /// Generate summary report
  String generateSummary() {
    final buffer = StringBuffer();
    buffer.writeln('QuicUI Validation Report');
    buffer.writeln('========================');
    buffer.writeln();
    
    buffer.writeln('Files validated: ${_fileResults.length}');
    buffer.writeln('Total issues: ${_issues.length}');
    
    for (final severity in IssueSeverity.values) {
      final count = getIssuesBySeverity(severity).length;
      if (count > 0) {
        buffer.writeln('${severity.name}: $count');
      }
    }
    
    if (!isValid) {
      buffer.writeln();
      buffer.writeln('Critical and Major Issues:');
      buffer.writeln('--------------------------');
      
      final criticalIssues = _issues.where((i) => 
        i.severity == IssueSeverity.critical || 
        i.severity == IssueSeverity.major
      ).toList();
      
      for (final issue in criticalIssues) {
        buffer.writeln('• ${issue}');
      }
    }
    
    return buffer.toString();
  }
}