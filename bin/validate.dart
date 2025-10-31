#!/usr/bin/env dart

/// QuicUI JSON Validation CLI Tool
///
/// Command-line tool for validating QuicUI JSON configurations.
/// Provides comprehensive validation including schema checking,
/// dependency validation, and performance analysis.
///
/// ## Usage Examples
///
/// ### Validate entire project
/// ```bash
/// dart run quicui:validate
/// ```
///
/// ### Validate specific file
/// ```bash
/// dart run quicui:validate --file assets/screens/login.json
/// ```
///
/// ### Validate with options
/// ```bash
/// dart run quicui:validate --strict --no-performance --output report.json
/// ```
///
/// ### Watch mode for development
/// ```bash
/// dart run quicui:validate --watch
/// ```

import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:quicui/src/utils/build_time_validator.dart';

/// Main entry point for the validation CLI
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Project root directory to validate',
      defaultsTo: '.',
    )
    ..addOption(
      'file',
      abbr: 'f',
      help: 'Specific file to validate',
    )
    ..addOption(
      'assets',
      abbr: 'a',
      help: 'Assets directory paths (comma-separated)',
      defaultsTo: 'assets,lib/assets,assets/screens',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output report file (JSON format)',
    )
    ..addFlag(
      'strict',
      abbr: 's',
      help: 'Enable strict validation mode',
      defaultsTo: false,
    )
    ..addFlag(
      'performance',
      help: 'Enable performance analysis',
      defaultsTo: true,
    )
    ..addFlag(
      'security',
      help: 'Enable security analysis',
      defaultsTo: true,
    )
    ..addFlag(
      'accessibility',
      help: 'Enable accessibility checks',
      defaultsTo: true,
    )
    ..addFlag(
      'watch',
      abbr: 'w',
      help: 'Watch mode - monitor files for changes',
      defaultsTo: false,
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
      defaultsTo: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      defaultsTo: false,
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _showHelp(parser);
      exit(0);
    }

    final validator = QuicUIValidator();
    await validator.run(results);

  } catch (e) {
    print('Error: $e');
    print('');
    _showHelp(parser);
    exit(1);
  }
}

/// Show help information
void _showHelp(ArgParser parser) {
  print('QuicUI JSON Validation Tool');
  print('===========================');
  print('');
  print('Validates QuicUI JSON configurations for syntax, schema compliance,');
  print('dependencies, performance, and security issues.');
  print('');
  print('Usage: dart run quicui:validate [options]');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Examples:');
  print('  dart run quicui:validate                    # Validate current project');
  print('  dart run quicui:validate --file screen.json # Validate specific file');
  print('  dart run quicui:validate --strict          # Strict validation');
  print('  dart run quicui:validate --watch           # Watch for changes');
  print('  dart run quicui:validate -o report.json    # Generate JSON report');
}

/// Main validator class
class QuicUIValidator {
  /// Run the validation process
  Future<void> run(ArgResults args) async {
    final options = ValidationOptions(
      enablePerformanceAnalysis: args['performance'] as bool,
      enableSecurityAnalysis: args['security'] as bool,
      enableAccessibilityChecks: args['accessibility'] as bool,
      strictMode: args['strict'] as bool,
    );

    if (args['watch'] as bool) {
      await _runWatchMode(args, options);
    } else if (args['file'] != null) {
      await _validateSingleFile(args['file'] as String, args, options);
    } else {
      await _validateProject(args, options);
    }
  }

  /// Validate entire project
  Future<void> _validateProject(ArgResults args, ValidationOptions options) async {
    final projectPath = args['project'] as String;
    final assetsPaths = (args['assets'] as String).split(',');
    
    print('🔍 Validating QuicUI project: $projectPath');
    print('📁 Assets paths: ${assetsPaths.join(', ')}');
    print('');

    final validator = BuildTimeValidator();
    final report = await validator.validateProject(
      projectPath,
      assetsPaths: assetsPaths,
      options: options,
    );

    await _outputResults(report, args);
    _exitWithCode(report);
  }

  /// Validate single file
  Future<void> _validateSingleFile(
    String filePath,
    ArgResults args,
    ValidationOptions options,
  ) async {
    print('🔍 Validating file: $filePath');
    print('');

    if (!await File(filePath).exists()) {
      print('❌ Error: File not found: $filePath');
      exit(1);
    }

    final validator = BuildTimeValidator();
    final result = await validator.validateFile(filePath, options: options);

    await _outputFileResults(result, args);
    _exitWithFileCode(result);
  }

  /// Run in watch mode
  Future<void> _runWatchMode(ArgResults args, ValidationOptions options) async {
    final projectPath = args['project'] as String;
    final assetsPaths = (args['assets'] as String).split(',');

    print('👀 Watching QuicUI project for changes: $projectPath');
    print('📁 Assets paths: ${assetsPaths.join(', ')}');
    print('Press Ctrl+C to stop');
    print('');

    final watcher = ProjectWatcher(projectPath, assetsPaths, options);
    await watcher.start();
  }

  /// Output validation results
  Future<void> _outputResults(ValidationReport report, ArgResults args) async {
    final verbose = args['verbose'] as bool;
    final outputFile = args['output'] as String?;

    // Console output
    _printValidationSummary(report);
    
    if (verbose || !report.isValid) {
      print('');
      _printDetailedResults(report);
    }

    // JSON output
    if (outputFile != null) {
      await _writeJsonReport(report, outputFile);
      print('📄 Report written to: $outputFile');
    }
  }

  /// Output single file results
  Future<void> _outputFileResults(FileValidationResult result, ArgResults args) async {
    final verbose = args['verbose'] as bool;
    final outputFile = args['output'] as String?;

    // Console output
    _printFileValidationSummary(result);
    
    if (verbose || !result.isValid) {
      print('');
      _printFileDetailedResults(result);
    }

    // JSON output
    if (outputFile != null) {
      await _writeFileJsonReport(result, outputFile);
      print('📄 Report written to: $outputFile');
    }
  }

  /// Print validation summary
  void _printValidationSummary(ValidationReport report) {
    if (report.isValid) {
      print('✅ Validation passed!');
    } else {
      print('❌ Validation failed!');
    }

    print('');
    print('📊 Summary:');
    print('   Files validated: ${report.fileResults.length}');
    print('   Total issues: ${report.issues.length}');
    
    for (final severity in IssueSeverity.values) {
      final count = report.getIssuesBySeverity(severity).length;
      if (count > 0) {
        final icon = _getSeverityIcon(severity);
        print('   $icon ${severity.name}: $count');
      }
    }
  }

  /// Print file validation summary
  void _printFileValidationSummary(FileValidationResult result) {
    if (result.isValid) {
      print('✅ File validation passed!');
    } else {
      print('❌ File validation failed!');
    }

    print('');
    print('📊 Summary:');
    print('   File: ${result.filePath}');
    print('   Total issues: ${result.issues.length}');
    
    for (final severity in IssueSeverity.values) {
      final count = result.getIssuesBySeverity(severity).length;
      if (count > 0) {
        final icon = _getSeverityIcon(severity);
        print('   $icon ${severity.name}: $count');
      }
    }
  }

  /// Print detailed results
  void _printDetailedResults(ValidationReport report) {
    print('🔍 Detailed Issues:');
    print('==================');
    
    for (final file in report.fileResults.keys) {
      final fileResult = report.fileResults[file]!;
      if (fileResult.issues.isNotEmpty) {
        print('');
        print('📁 ${path.relative(file)}:');
        
        for (final issue in fileResult.issues) {
          final icon = _getSeverityIcon(issue.severity);
          print('   $icon ${issue.message}');
          
          if (issue.context.isNotEmpty) {
            for (final entry in issue.context.entries) {
              print('      • ${entry.key}: ${entry.value}');
            }
          }
        }
      }
    }
  }

  /// Print detailed file results
  void _printFileDetailedResults(FileValidationResult result) {
    if (result.issues.isEmpty) return;

    print('🔍 Detailed Issues:');
    print('==================');
    
    for (final issue in result.issues) {
      final icon = _getSeverityIcon(issue.severity);
      print('$icon ${issue.message}');
      
      if (issue.context.isNotEmpty) {
        for (final entry in issue.context.entries) {
          print('   • ${entry.key}: ${entry.value}');
        }
      }
      print('');
    }
  }

  /// Get severity icon
  String _getSeverityIcon(IssueSeverity severity) {
    return switch (severity) {
      IssueSeverity.critical => '🚨',
      IssueSeverity.major => '⚠️',
      IssueSeverity.minor => '💡',
      IssueSeverity.warning => '⚡',
    };
  }

  /// Write JSON report
  Future<void> _writeJsonReport(ValidationReport report, String outputFile) async {
    final reportData = {
      'summary': {
        'is_valid': report.isValid,
        'total_files': report.fileResults.length,
        'total_issues': report.issues.length,
        'issues_by_severity': {
          for (final severity in IssueSeverity.values)
            severity.name: report.getIssuesBySeverity(severity).length,
        },
      },
      'files': {
        for (final file in report.fileResults.keys)
          file: {
            'is_valid': report.fileResults[file]!.isValid,
            'issues': report.fileResults[file]!.issues.map((issue) => {
              'severity': issue.severity.name,
              'message': issue.message,
              'context': issue.context,
            }).toList(),
          },
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    final file = File(outputFile);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(reportData),
    );
  }

  /// Write file JSON report
  Future<void> _writeFileJsonReport(FileValidationResult result, String outputFile) async {
    final reportData = {
      'file_path': result.filePath,
      'is_valid': result.isValid,
      'issues': result.issues.map((issue) => {
        'severity': issue.severity.name,
        'message': issue.message,
        'context': issue.context,
      }).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    final file = File(outputFile);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(reportData),
    );
  }

  /// Exit with appropriate code
  void _exitWithCode(ValidationReport report) {
    if (report.isValid) {
      exit(0);
    } else {
      final criticalCount = report.getIssuesBySeverity(IssueSeverity.critical).length;
      final majorCount = report.getIssuesBySeverity(IssueSeverity.major).length;
      
      if (criticalCount > 0) {
        exit(2); // Critical errors
      } else if (majorCount > 0) {
        exit(1); // Major errors
      } else {
        exit(0); // Only minor/warnings
      }
    }
  }

  /// Exit with appropriate code for single file
  void _exitWithFileCode(FileValidationResult result) {
    if (result.isValid) {
      exit(0);
    } else {
      final criticalCount = result.getIssuesBySeverity(IssueSeverity.critical).length;
      final majorCount = result.getIssuesBySeverity(IssueSeverity.major).length;
      
      if (criticalCount > 0) {
        exit(2); // Critical errors
      } else if (majorCount > 0) {
        exit(1); // Major errors
      } else {
        exit(0); // Only minor/warnings
      }
    }
  }
}

/// File system watcher for development mode
class ProjectWatcher {
  final String projectPath;
  final List<String> assetsPaths;
  final ValidationOptions options;
  final BuildTimeValidator validator;

  ProjectWatcher(this.projectPath, this.assetsPaths, this.options)
      : validator = BuildTimeValidator();

  /// Start watching for file changes
  Future<void> start() async {
    // Initial validation
    await _validateAndReport();

    // Set up watchers for each assets directory
    for (final assetsPath in assetsPaths) {
      final fullPath = path.join(projectPath, assetsPath);
      final directory = Directory(fullPath);

      if (await directory.exists()) {
        directory.watch(recursive: true).listen((event) {
          if (event.path.endsWith('.json')) {
            _handleFileChange(event);
          }
        });
      }
    }

    // Keep the process alive
    await Future<void>.delayed(const Duration(days: 365));
  }

  /// Handle file system events
  void _handleFileChange(FileSystemEvent event) {
    print('📝 File changed: ${path.relative(event.path)}');
    _validateFileAndReport(event.path);
  }

  /// Validate entire project and report
  Future<void> _validateAndReport() async {
    final report = await validator.validateProject(
      projectPath,
      assetsPaths: assetsPaths,
      options: options,
    );

    print('🔄 Validation complete at ${DateTime.now()}');
    
    if (report.isValid) {
      print('✅ All files valid');
    } else {
      print('❌ Issues found: ${report.issues.length}');
      
      // Show only critical and major issues in watch mode
      final criticalIssues = report.issues.where((i) => 
        i.severity == IssueSeverity.critical || 
        i.severity == IssueSeverity.major
      ).toList();

      for (final issue in criticalIssues.take(5)) { // Limit output
        final icon = issue.severity == IssueSeverity.critical ? '🚨' : '⚠️';
        final file = issue.filePath != null ? path.relative(issue.filePath!) : '';
        print('   $icon $file: ${issue.message}');
      }

      if (criticalIssues.length > 5) {
        print('   ... and ${criticalIssues.length - 5} more issues');
      }
    }
    print('');
  }

  /// Validate single file and report
  Future<void> _validateFileAndReport(String filePath) async {
    try {
      final result = await validator.validateFile(filePath, options: options);
      
      if (result.isValid) {
        print('✅ ${path.relative(filePath)} - OK');
      } else {
        print('❌ ${path.relative(filePath)} - ${result.issues.length} issues');
        
        for (final issue in result.issues.take(3)) {
          final icon = issue.severity == IssueSeverity.critical ? '🚨' : '⚠️';
          print('   $icon ${issue.message}');
        }
        
        if (result.issues.length > 3) {
          print('   ... and ${result.issues.length - 3} more issues');
        }
      }
    } catch (e) {
      print('💥 ${path.relative(filePath)} - Validation error: $e');
    }
    print('');
  }
}