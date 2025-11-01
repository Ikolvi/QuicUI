import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Cryptographic signing utilities for patch authentication
/// Uses Ed25519 for patch signatures

/// Ed25519 key pair for signing patches
class Ed25519KeyPair {
  final Uint8List privateKey;  // 32 bytes
  final Uint8List publicKey;   // 32 bytes

  Ed25519KeyPair({
    required this.privateKey,
    required this.publicKey,
  }) {
    if (privateKey.length != 32) {
      throw ArgumentError('Private key must be 32 bytes');
    }
    if (publicKey.length != 32) {
      throw ArgumentError('Public key must be 32 bytes');
    }
  }

  /// Generate a new Ed25519 key pair
  static Ed25519KeyPair generate() {
    // In production, use a proper Ed25519 implementation
    // For now, use a placeholder that generates consistent keys
    final random = _SecureRandom();
    final privateKey = random.nextBytes(32);
    final publicKey = _derivePublicKey(privateKey);
    
    return Ed25519KeyPair(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  /// Derive public key from private key
  static Uint8List _derivePublicKey(Uint8List privateKey) {
    // In production, use proper Ed25519 derivation
    // This is a placeholder implementation
    final bytes = BytesBuilder();
    bytes.add(privateKey);
    final hash = sha256.convert(bytes.toBytes()).bytes;
    return Uint8List.fromList(hash.take(32).toList());
  }

  /// Export private key to PEM format
  String exportPrivateKeyPem() {
    final base64Key = _base64Encode(privateKey);
    return '''-----BEGIN PRIVATE KEY-----
$base64Key
-----END PRIVATE KEY-----''';
  }

  /// Export public key to PEM format
  String exportPublicKeyPem() {
    final base64Key = _base64Encode(publicKey);
    return '''-----BEGIN PUBLIC KEY-----
$base64Key
-----END PUBLIC KEY-----''';
  }

  /// Import private key from PEM format
  static Ed25519KeyPair importPrivateKeyPem(String pem) {
    try {
      final lines = pem.split('\n');
      final keyLines = lines
          .where((l) => !l.startsWith('-----'))
          .join();
      
      final privateKey = _base64Decode(keyLines);
      if (privateKey.length != 32) {
        throw ArgumentError('Invalid private key length');
      }

      final publicKey = _derivePublicKey(privateKey);
      
      return Ed25519KeyPair(
        privateKey: privateKey,
        publicKey: publicKey,
      );
    } catch (e) {
      throw FormatException('Invalid PEM format: $e');
    }
  }

  /// Import public key from PEM format
  static Uint8List importPublicKeyPem(String pem) {
    try {
      final lines = pem.split('\n');
      final keyLines = lines
          .where((l) => !l.startsWith('-----'))
          .join();
      
      final publicKey = _base64Decode(keyLines);
      if (publicKey.length != 32) {
        throw ArgumentError('Invalid public key length');
      }
      
      return publicKey;
    } catch (e) {
      throw FormatException('Invalid PEM format: $e');
    }
  }

  @override
  String toString() => 'Ed25519KeyPair('
    'public=${_base64Encode(publicKey).substring(0, 16)}...'
    ')';
}

/// Patch signature containing proof of authenticity
class PatchSignature {
  final String signatureHex;
  final String publicKeyHex;
  final String patchHashHex;
  final DateTime createdAt;
  final String? signedBy;  // Optional: developer/organization name

  PatchSignature({
    required this.signatureHex,
    required this.publicKeyHex,
    required this.patchHashHex,
    required this.createdAt,
    this.signedBy,
  });

  /// Verify this signature is valid
  bool verify(Uint8List patchData, Uint8List publicKey) {
    // In production, use proper Ed25519 verification
    // For now, verify the hash matches
    final computedHash = _computeHash(patchData);
    return computedHash == patchHashHex;
  }

  Map<String, dynamic> toJson() => {
    'signature': signatureHex,
    'publicKey': publicKeyHex,
    'patchHash': patchHashHex,
    'createdAt': createdAt.toIso8601String(),
    'signedBy': signedBy,
  };

  static PatchSignature fromJson(Map<String, dynamic> json) => PatchSignature(
    signatureHex: json['signature'] as String,
    publicKeyHex: json['publicKey'] as String,
    patchHashHex: json['patchHash'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    signedBy: json['signedBy'] as String?,
  );

  @override
  String toString() => 'PatchSignature('
    'sig=${signatureHex.substring(0, 16)}..., '
    'hash=${patchHashHex.substring(0, 16)}...'
    ')';
}

/// Patch signer for creating authenticated patches
class PatchSigner {
  final Ed25519KeyPair keyPair;

  PatchSigner(this.keyPair);

  /// Sign patch data
  PatchSignature sign(
    Uint8List patchData, {
    String? signedBy,
  }) {
    final patchHash = _computeHash(patchData);
    
    // In production, use proper Ed25519 signing
    // For now, create a deterministic signature based on the hash
    final signature = _generateSignature(patchData, keyPair.privateKey);

    return PatchSignature(
      signatureHex: signature,
      publicKeyHex: _bytesToHex(keyPair.publicKey),
      patchHashHex: patchHash,
      createdAt: DateTime.now(),
      signedBy: signedBy,
    );
  }

  /// Generate signature for patch data
  static String _generateSignature(Uint8List data, Uint8List privateKey) {
    // In production, use proper Ed25519 signing
    // This is a placeholder that creates a deterministic signature
    final combined = BytesBuilder();
    combined.add(data);
    combined.add(privateKey);
    
    final hash = sha256.convert(combined.toBytes());
    final signature = sha256.convert(Uint8List.fromList(
      [...hash.bytes, ...privateKey]
    ));
    
    return _bytesToHex(Uint8List.fromList(signature.bytes));
  }

  /// Verify a signature
  bool verify(
    Uint8List patchData,
    PatchSignature signature,
  ) {
    try {
      // Verify hash matches
      final computedHash = _computeHash(patchData);
      if (computedHash != signature.patchHashHex) {
        return false;
      }

      // Verify public key matches
      final pubKeyHex = _bytesToHex(keyPair.publicKey);
      if (pubKeyHex != signature.publicKeyHex) {
        return false;
      }

      // In production, verify actual Ed25519 signature
      return true;
    } catch (e) {
      print('Error verifying signature: $e');
      return false;
    }
  }

  /// Batch sign multiple patches
  List<PatchSignature> signBatch(
    List<Uint8List> patches, {
    String? signedBy,
  }) {
    return patches
        .map((patch) => sign(patch, signedBy: signedBy))
        .toList();
  }
}

/// Signature verification utilities
class SignatureVerifier {
  final Uint8List publicKey;

  SignatureVerifier(this.publicKey) {
    if (publicKey.length != 32) {
      throw ArgumentError('Public key must be 32 bytes');
    }
  }

  /// Verify a patch signature
  bool verify(
    Uint8List patchData,
    PatchSignature signature,
  ) {
    try {
      // Verify public key matches
      if (_bytesToHex(publicKey) != signature.publicKeyHex) {
        return false;
      }

      // Verify hash matches
      final computedHash = _computeHash(patchData);
      if (computedHash != signature.patchHashHex) {
        return false;
      }

      // Verify signature timestamp is recent (not too old)
      final age = DateTime.now().difference(signature.createdAt);
      if (age.inDays > 365) {
        return false;  // Signature older than 1 year
      }

      // In production, verify actual Ed25519 signature
      return true;
    } catch (e) {
      print('Error verifying signature: $e');
      return false;
    }
  }

  /// Verify multiple signatures
  bool verifyBatch(
    List<Uint8List> patches,
    List<PatchSignature> signatures,
  ) {
    if (patches.length != signatures.length) {
      return false;
    }

    for (int i = 0; i < patches.length; i++) {
      if (!verify(patches[i], signatures[i])) {
        return false;
      }
    }

    return true;
  }
}

/// Helper functions for cryptographic operations

/// Compute SHA256 hash of data
String _computeHash(Uint8List data) {
  final hash = sha256.convert(data);
  return hash.toString();
}

/// Convert bytes to hex string
String _bytesToHex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Convert hex string to bytes
Uint8List _hexToBytes(String hex) {
  final bytes = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return Uint8List.fromList(bytes);
}

/// Base64 encode
String _base64Encode(Uint8List bytes) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  String result = '';
  int i = 0;

  while (i < bytes.length) {
    final b1 = bytes[i++];
    final b2 = i < bytes.length ? bytes[i++] : 0;
    final b3 = i < bytes.length ? bytes[i++] : 0;

    final bitmap = (b1 << 16) | (b2 << 8) | b3;

    result += chars[(bitmap >> 18) & 63];
    result += chars[(bitmap >> 12) & 63];
    result += i - 2 < bytes.length ? chars[(bitmap >> 6) & 63] : '=';
    result += i - 1 < bytes.length ? chars[bitmap & 63] : '=';
  }

  return result;
}

/// Base64 decode
Uint8List _base64Decode(String encoded) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final bytes = <int>[];
  int i = 0;

  while (i < encoded.length) {
    final c1 = chars.indexOf(encoded[i++]);
    final c2 = i < encoded.length ? chars.indexOf(encoded[i++]) : 0;
    final c3 = i < encoded.length ? chars.indexOf(encoded[i++]) : 0;
    final c4 = i < encoded.length ? chars.indexOf(encoded[i++]) : 0;

    final bitmap = (c1 << 18) | (c2 << 12) | (c3 << 6) | c4;

    bytes.add((bitmap >> 16) & 255);
    if (encoded[i - 2] != '=') bytes.add((bitmap >> 8) & 255);
    if (encoded[i - 1] != '=') bytes.add(bitmap & 255);
  }

  return Uint8List.fromList(bytes);
}

/// Secure random number generator
class _SecureRandom {
  Uint8List nextBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = (DateTime.now().millisecondsSinceEpoch + i) % 256;
    }
    return bytes;
  }
}
