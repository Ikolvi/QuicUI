/// Security Configuration Verification Script
/// 
/// Validates that the application is properly configured for production deployment
/// Usage: dart run bin/verify_security_config.dart
/// 
/// Exit codes:
/// 0 - All checks passed
/// 1 - Critical checks failed
/// 2 - Warnings detected (non-blocking)

import 'dart:io';
import '../lib/src/security_config.dart';

void main(List<String> arguments) {
  print('\n🔐 QuicUI Security Configuration Verification\n');
  print('=' * 60);

  int criticalIssues = 0;
  int warnings = 0;

  // Check environment variable set
  print('\n📋 Checking environment setup...\n');
  
  final environment = Platform.environment['QUICUI_ENVIRONMENT'] ?? 'not-set';
  if (environment == 'not-set') {
    print('❌ CRITICAL: QUICUI_ENVIRONMENT not set');
    criticalIssues++;
  } else {
    print('✅ QUICUI_ENVIRONMENT = $environment');
  }

  // Try to load security config
  print('\n🔒 Loading security configuration...\n');
  
  late SecurityConfig config;
  try {
    config = SecurityConfig.fromEnvironment();
    print('✅ Configuration loaded successfully');
  } catch (e) {
    print('❌ CRITICAL: Configuration loading failed');
    print('   Error: $e');
    criticalIssues++;
    
    // Print recommendations
    print('\n💡 Recommendations:');
    print('   1. Set QUICUI_ENVIRONMENT (development, staging, or production)');
    print('   2. Set QUICUI_ALLOWED_ORIGINS (comma-separated list)');
    if (environment == 'production') {
      print('   3. Set QUICUI_TLS_CERT_PATH and QUICUI_TLS_KEY_PATH');
    }
    
    exit(1);
  }

  // Validate HTTPS configuration
  print('\n🔐 Validating HTTPS/TLS...\n');
  
  if (config.enforceHttps) {
    print('✅ HTTPS enforcement: ENABLED');
    
    // Check certificate files
    if (config.tlsCertPath != null) {
      if (File(config.tlsCertPath!).existsSync()) {
        print('✅ TLS certificate found: ${config.tlsCertPath}');
      } else {
        print('❌ CRITICAL: TLS certificate not found: ${config.tlsCertPath}');
        criticalIssues++;
      }
    } else {
      print('❌ CRITICAL: TLS certificate path not configured');
      criticalIssues++;
    }
    
    if (config.tlsKeyPath != null) {
      if (File(config.tlsKeyPath!).existsSync()) {
        print('✅ TLS private key found: ${config.tlsKeyPath}');
      } else {
        print('❌ CRITICAL: TLS private key not found: ${config.tlsKeyPath}');
        criticalIssues++;
      }
    } else {
      print('❌ CRITICAL: TLS key path not configured');
      criticalIssues++;
    }
    
    // Check HSTS configuration
    if (config.hstsMaxAge.isNotEmpty) {
      final maxAge = int.tryParse(config.hstsMaxAge);
      if (maxAge != null && maxAge > 0) {
        print('✅ HSTS enabled (max-age=${config.hstsMaxAge}s)');
      } else {
        print('⚠️ WARNING: HSTS max-age invalid: ${config.hstsMaxAge}');
        warnings++;
      }
    }
  } else {
    print('ℹ️ HTTPS enforcement: DISABLED (development mode)');
  }

  // Validate CORS configuration
  print('\n🌐 Validating CORS...\n');
  
  if (config.allowedOrigins.isEmpty) {
    print('❌ CRITICAL: No CORS origins configured');
    criticalIssues++;
  } else {
    print('✅ CORS origins configured (${config.allowedOrigins.length}):');
    for (final origin in config.allowedOrigins) {
      if (origin == '*') {
        if (config.debugMode) {
          print('   ⚠️ WILDCARD origin in development mode: $origin');
        } else {
          print('   ❌ CRITICAL: Wildcard origin not allowed in production: $origin');
          criticalIssues++;
        }
      } else {
        print('   ✅ $origin');
      }
    }
  }

  // Validate allowed methods
  if (config.allowedMethods.isEmpty) {
    print('❌ CRITICAL: No CORS methods configured');
    criticalIssues++;
  } else {
    print('✅ CORS methods: ${config.allowedMethods.join(", ")}');
  }

  // Validate allowed headers
  if (config.allowedHeaders.isEmpty) {
    print('❌ CRITICAL: No CORS headers configured');
    criticalIssues++;
  } else {
    print('✅ CORS headers: ${config.allowedHeaders.join(", ")}');
  }

  // Validate security headers
  print('\n🛡️ Validating Security Headers...\n');
  
  if (config.xContentTypeOptions.isNotEmpty) {
    print('✅ X-Content-Type-Options: ${config.xContentTypeOptions}');
  } else {
    print('❌ CRITICAL: X-Content-Type-Options not configured');
    criticalIssues++;
  }

  if (config.xFrameOptions.isNotEmpty) {
    print('✅ X-Frame-Options: ${config.xFrameOptions}');
  } else {
    print('❌ CRITICAL: X-Frame-Options not configured');
    criticalIssues++;
  }

  if (config.contentSecurityPolicy.isNotEmpty) {
    print('✅ Content-Security-Policy: ${config.contentSecurityPolicy}');
  } else {
    print('⚠️ WARNING: Content-Security-Policy not configured');
    warnings++;
  }

  if (config.referrerPolicy.isNotEmpty) {
    print('✅ Referrer-Policy: ${config.referrerPolicy}');
  } else {
    print('❌ CRITICAL: Referrer-Policy not configured');
    criticalIssues++;
  }

  // Validate application configuration
  print('\n⚙️ Validating Application Settings...\n');
  
  print('✅ Max request size: ${(config.maxRequestSize / 1024 / 1024).toStringAsFixed(1)}MB');
  print('✅ Request timeout: ${config.requestTimeout.inSeconds}s');
  print('✅ Debug mode: ${config.debugMode ? "ENABLED" : "DISABLED"}');

  if (config.debugMode && !config.debugMode) {
    print('⚠️ WARNING: Debug mode enabled in non-development environment');
    warnings++;
  }

  // Credentials warning
  if (config.allowCredentials && !config.debugMode) {
    print('⚠️ WARNING: CORS credentials allowed in production environment');
    warnings++;
  }

  // Database configuration check
  print('\n🗄️ Checking Database Configuration...\n');
  
  final dbHost = Platform.environment['DATABASE_HOST'];
  final dbPort = Platform.environment['DATABASE_PORT'];
  final dbName = Platform.environment['DATABASE_NAME'];
  final dbUser = Platform.environment['DATABASE_USER'];
  
  if (dbHost?.isNotEmpty ?? false) {
    print('✅ DATABASE_HOST: $dbHost');
  } else {
    print('⚠️ WARNING: DATABASE_HOST not configured');
    warnings++;
  }
  
  if (dbPort?.isNotEmpty ?? false) {
    print('✅ DATABASE_PORT: $dbPort');
  } else {
    print('⚠️ WARNING: DATABASE_PORT not configured');
    warnings++;
  }

  if (dbName?.isNotEmpty ?? false) {
    print('✅ DATABASE_NAME: $dbName');
  } else {
    print('⚠️ WARNING: DATABASE_NAME not configured');
    warnings++;
  }

  if (dbUser?.isNotEmpty ?? false) {
    print('✅ DATABASE_USER: $dbUser');
  } else {
    print('⚠️ WARNING: DATABASE_USER not configured');
    warnings++;
  }

  final dbPassword = Platform.environment['DATABASE_PASSWORD'];
  if (dbPassword?.isNotEmpty ?? false) {
    print('✅ DATABASE_PASSWORD: [SET]');
  } else {
    print('❌ CRITICAL: DATABASE_PASSWORD not configured');
    criticalIssues++;
  }

  // Authentication configuration
  print('\n🔑 Checking Authentication Configuration...\n');
  
  final jwtSecret = Platform.environment['JWT_SECRET_KEY'];
  if (jwtSecret?.isNotEmpty ?? false) {
    if ((jwtSecret?.length ?? 0) >= 32) {
      print('✅ JWT_SECRET_KEY: [SET] (${jwtSecret!.length} chars)');
    } else {
      print('⚠️ WARNING: JWT_SECRET_KEY too short (${jwtSecret!.length} chars, minimum 32)');
      warnings++;
    }
  } else {
    print('❌ CRITICAL: JWT_SECRET_KEY not configured');
    criticalIssues++;
  }

  final apiKeySecret = Platform.environment['API_KEY_SECRET'];
  if (apiKeySecret?.isNotEmpty ?? false) {
    print('✅ API_KEY_SECRET: [SET]');
  } else {
    print('⚠️ WARNING: API_KEY_SECRET not configured');
    warnings++;
  }

  // Summary
  print('\n' + '=' * 60);
  print('\n📊 SUMMARY\n');

  if (criticalIssues == 0 && warnings == 0) {
    print('✅ All security checks passed!');
    print('✅ Configuration is ready for deployment');
    config.printSecurityChecklistProduction();
    exit(0);
  } else if (criticalIssues == 0) {
    print('⚠️ ${warnings} warning(s) detected (non-blocking)');
    print('✅ Critical configuration is valid');
    config.printSecurityChecklistProduction();
    exit(2); // Warnings only
  } else {
    print('❌ ${criticalIssues} critical issue(s) detected');
    print('❌ Configuration is INVALID - deployment blocked');
    print('\n💡 Fix the critical issues above before deploying');
    exit(1); // Critical failures
  }
}
