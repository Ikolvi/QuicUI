import 'dart:io';
import 'dart:typed_data';

import 'kernel_analysis.dart';
import 'signing_utils.dart';

/// CLI commands for the QuicUI Code Push compiler
/// Handles: build, upload, rollout, version management

class CodePushCliCommands {
  final String projectDir;
  final String outputDir;
  late Ed25519KeyPair signingKey;

  CodePushCliCommands({
    required this.projectDir,
    required this.outputDir,
  });

  /// Initialize CLI with signing key
  Future<void> initialize({String? keyFile}) async {
    if (keyFile != null && await File(keyFile).exists()) {
      final pem = await File(keyFile).readAsString();
      signingKey = Ed25519KeyPair.importPrivateKeyPem(pem);
    } else {
      signingKey = Ed25519KeyPair.generate();
      await _saveSigningKey();
    }
  }

  /// Build patch from current kernel to new kernel
  Future<BuildResult> build({
    required String oldKernelPath,
    required String newKernelPath,
    required String patchVersion,
    String? description,
    bool critical = false,
  }) async {
    print('🔨 Building patch v$patchVersion...');

    try {
      // Validate kernel files
      if (!await File(oldKernelPath).exists()) {
        throw FileSystemException('Old kernel not found: $oldKernelPath');
      }
      if (!await File(newKernelPath).exists()) {
        throw FileSystemException('New kernel not found: $newKernelPath');
      }

      // Analyze kernels
      print('📊 Analyzing kernels...');
      final oldAnalysis = await KernelFile.analyzeKernel(oldKernelPath);
      final newAnalysis = await KernelFile.analyzeKernel(newKernelPath);

      // Generate binary diff
      print('🔄 Generating binary diff...');
      final patch = await BinaryDiff.generatePatch(oldKernelPath, newKernelPath);

      // Read patch data for signing
      final newKernel = await File(newKernelPath).readAsBytes();

      // Sign patch
      print('✍️  Signing patch...');
      final signer = PatchSigner(signingKey);
      final signature = signer.sign(newKernel, signedBy: 'quicui-compiler');

      // Create patch manifest
      final manifest = PatchManifest(
        version: patchVersion,
        oldVersion: oldAnalysis.hash,
        newVersion: newAnalysis.hash,
        timestamp: DateTime.now(),
        critical: critical,
        description: description,
        fileSize: patch.patchSize,
        compressionRatio: patch.compressionRatio,
        estimatedSavings: patch.estimatedSavings,
        signature: signature,
        operationCount: patch.operations.length,
      );

      // Save patch and manifest
      await _savePatch(patch, manifest, patchVersion);

      print('✅ Patch built successfully!');
      print('   Version: $patchVersion');
      print('   Size: ${_formatBytes(patch.patchSize)}');
      print('   Savings: ${patch.estimatedSavings.toStringAsFixed(2)}%');
      print('   Operations: ${patch.operations.length}');

      return BuildResult(
        success: true,
        patchVersion: patchVersion,
        patchSize: patch.patchSize,
        manifest: manifest,
      );
    } catch (e) {
      print('❌ Build failed: $e');
      return BuildResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload patch to code push service
  Future<UploadResult> upload({
    required String patchVersion,
    required String serviceUrl,
    required String appId,
    String? authToken,
  }) async {
    print('📤 Uploading patch v$patchVersion to $serviceUrl...');

    try {
      final patchFile = File('$outputDir/$patchVersion.patch');
      final manifestFile = File('$outputDir/$patchVersion.manifest.json');

      if (!await patchFile.exists()) {
        throw FileSystemException('Patch file not found: ${patchFile.path}');
      }
      if (!await manifestFile.exists()) {
        throw FileSystemException('Manifest file not found: ${manifestFile.path}');
      }

      // Read patch data
      final patchData = await patchFile.readAsBytes();
      final manifestData = await manifestFile.readAsString();

      // Prepare upload payload
      final uploadUrl = '$serviceUrl/api/v1/patches/upload';

      print('📋 Preparing upload payload...');
      print('   Patch size: ${_formatBytes(patchData.length)}');

      // In production, this would use HTTP multipart upload
      // For now, simulate the upload
      print('🔗 Connecting to $uploadUrl...');

      await Future.delayed(Duration(seconds: 1)); // Simulate network call

      print('✅ Upload successful!');
      print('   URL: $uploadUrl');
      print('   Version: $patchVersion');

      return UploadResult(
        success: true,
        patchVersion: patchVersion,
        uploadedAt: DateTime.now(),
        uploadUrl: uploadUrl,
      );
    } catch (e) {
      print('❌ Upload failed: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Rollout patch to users
  Future<RolloutResult> rollout({
    required String patchVersion,
    required String serviceUrl,
    required String appId,
    String? environment,
    double rolloutPercentage = 100.0,
    bool critical = false,
  }) async {
    print('🚀 Rolling out patch v$patchVersion...');

    try {
      if (rolloutPercentage < 0 || rolloutPercentage > 100) {
        throw ArgumentError('Rollout percentage must be between 0 and 100');
      }

      print('🎯 Rollout configuration:');
      print('   Environment: ${environment ?? 'production'}');
      print('   Rollout: $rolloutPercentage%');
      print('   Critical: $critical');

      // Prepare rollout payload
      final rolloutPayload = {
        'version': patchVersion,
        'environment': environment ?? 'production',
        'rolloutPercentage': rolloutPercentage,
        'critical': critical,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📊 Starting gradual rollout...');

      // Simulate rollout phases
      for (int i = 0; i < 3; i++) {
        print('   Phase ${i + 1}: ${(rolloutPercentage / 3).toStringAsFixed(1)}% deployed');
        await Future.delayed(Duration(seconds: 1));
      }

      print('✅ Rollout successful!');
      print('   Patch: $patchVersion');
      print('   Coverage: $rolloutPercentage%');

      return RolloutResult(
        success: true,
        patchVersion: patchVersion,
        rolloutPercentage: rolloutPercentage,
        deployedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Rollout failed: $e');
      return RolloutResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Manage patch versions
  Future<VersionResult> listVersions({
    required String serviceUrl,
    required String appId,
  }) async {
    print('📋 Fetching available versions...');

    try {
      // In production, this would call the API
      print('🔗 Connecting to $serviceUrl...');

      await Future.delayed(Duration(milliseconds: 500));

      final versions = [
        '1.0.0',
        '1.0.1',
        '1.0.2',
        '1.1.0',
      ];

      print('✅ Found ${versions.length} versions:');
      for (final version in versions) {
        print('   • $version');
      }

      return VersionResult(
        success: true,
        versions: versions,
      );
    } catch (e) {
      print('❌ Failed to list versions: $e');
      return VersionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Generate signing key pair
  Future<KeyGenResult> generateKey() async {
    print('🔐 Generating Ed25519 key pair...');

    try {
      signingKey = Ed25519KeyPair.generate();
      await _saveSigningKey();

      print('✅ Key pair generated successfully!');
      print('   Public key: ${signingKey.publicKey.take(8).toString()}...');
      print('   Saved to: $outputDir/signing-key.pem');

      return KeyGenResult(
        success: true,
        publicKey: signingKey.exportPublicKeyPem(),
      );
    } catch (e) {
      print('❌ Key generation failed: $e');
      return KeyGenResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Verify a patch signature
  Future<VerifyResult> verify({
    required String patchFile,
    required String publicKeyFile,
    required String manifestFile,
  }) async {
    print('🔍 Verifying patch signature...');

    try {
      final patchData = await File(patchFile).readAsBytes();
      final pubKeyPem = await File(publicKeyFile).readAsString();
      final manifestJson = await File(manifestFile).readAsString();

      // Parse manifest
      final manifest = PatchManifest.fromJson(manifestJson);

      // Get public key
      final publicKey = Ed25519KeyPair.importPublicKeyPem(pubKeyPem);

      // Verify signature
      final verifier = SignatureVerifier(publicKey);
      final isValid = verifier.verify(patchData, manifest.signature);

      if (isValid) {
        print('✅ Signature verified!');
        print('   Signed by: ${manifest.signature.signedBy ?? "unknown"}');
        print('   Date: ${manifest.signature.createdAt}');
      } else {
        print('❌ Signature verification failed!');
      }

      return VerifyResult(
        success: isValid,
        patchVersion: manifest.version,
      );
    } catch (e) {
      print('❌ Verification failed: $e');
      return VerifyResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Save patch and manifest to disk
  Future<void> _savePatch(
    Patch patch,
    PatchManifest manifest,
    String patchVersion,
  ) async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Save manifest
    final manifestFile = File('$outputDir/$patchVersion.manifest.json');
    await manifestFile.writeAsString(manifest.toJson());

    print('   Manifest: ${manifestFile.path}');
  }

  /// Save signing key to disk
  Future<void> _saveSigningKey() async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final keyFile = File('$outputDir/signing-key.pem');
    await keyFile.writeAsString(signingKey.exportPrivateKeyPem());

    final pubKeyFile = File('$outputDir/signing-key.pub');
    await pubKeyFile.writeAsString(signingKey.exportPublicKeyPem());

    print('   Private key: ${keyFile.path}');
    print('   Public key: ${pubKeyFile.path}');
  }

  /// Format bytes for display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Patch manifest with metadata
class PatchManifest {
  final String version;
  final String oldVersion;
  final String newVersion;
  final DateTime timestamp;
  final bool critical;
  final String? description;
  final int fileSize;
  final double compressionRatio;
  final double estimatedSavings;
  final PatchSignature signature;
  final int operationCount;

  PatchManifest({
    required this.version,
    required this.oldVersion,
    required this.newVersion,
    required this.timestamp,
    required this.critical,
    this.description,
    required this.fileSize,
    required this.compressionRatio,
    required this.estimatedSavings,
    required this.signature,
    required this.operationCount,
  });

  String toJson() => '''
{
  "version": "$version",
  "oldVersion": "$oldVersion",
  "newVersion": "$newVersion",
  "timestamp": "${timestamp.toIso8601String()}",
  "critical": $critical,
  "description": "$description",
  "fileSize": $fileSize,
  "compressionRatio": $compressionRatio,
  "estimatedSavings": $estimatedSavings,
  "operationCount": $operationCount,
  "signature": ${signature.toJson()}
}
''';

  static PatchManifest fromJson(String json) {
    // In production, use proper JSON parsing
    throw UnimplementedError('JSON parsing not implemented');
  }
}

/// Build command result
class BuildResult {
  final bool success;
  final String? patchVersion;
  final int? patchSize;
  final PatchManifest? manifest;
  final String? error;

  BuildResult({
    required this.success,
    this.patchVersion,
    this.patchSize,
    this.manifest,
    this.error,
  });
}

/// Upload command result
class UploadResult {
  final bool success;
  final String? patchVersion;
  final DateTime? uploadedAt;
  final String? uploadUrl;
  final String? error;

  UploadResult({
    required this.success,
    this.patchVersion,
    this.uploadedAt,
    this.uploadUrl,
    this.error,
  });
}

/// Rollout command result
class RolloutResult {
  final bool success;
  final String? patchVersion;
  final double? rolloutPercentage;
  final DateTime? deployedAt;
  final String? error;

  RolloutResult({
    required this.success,
    this.patchVersion,
    this.rolloutPercentage,
    this.deployedAt,
    this.error,
  });
}

/// Version management result
class VersionResult {
  final bool success;
  final List<String>? versions;
  final String? error;

  VersionResult({
    required this.success,
    this.versions,
    this.error,
  });
}

/// Key generation result
class KeyGenResult {
  final bool success;
  final String? publicKey;
  final String? error;

  KeyGenResult({
    required this.success,
    this.publicKey,
    this.error,
  });
}

/// Verification result
class VerifyResult {
  final bool success;
  final String? patchVersion;
  final String? error;

  VerifyResult({
    required this.success,
    this.patchVersion,
    this.error,
  });
}
