import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'license_document.dart';
import 'license_public_key.dart';

/// Verifies / signs MayleSoft `.lic` files (Ed25519).
abstract final class LicenseCrypto {
  static final _algo = Ed25519();

  static SimplePublicKey publicKeyFromBase64(String b64) => SimplePublicKey(
        base64Decode(b64),
        type: KeyPairType.ed25519,
      );

  static SimplePublicKey get publicKey {
    final b64 = LicensePublicKey.ed25519PublicKeyBase64;
    if (b64.startsWith('REPLACE_')) {
      throw StateError('License public key not generated yet');
    }
    return publicKeyFromBase64(b64);
  }

  /// File format: `{"payload":{...},"sig":"<base64>"}`.
  static Future<LicenseDocument> verifyFileBytes(
    List<int> bytes, {
    SimplePublicKey? publicKey,
  }) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('License root must be a JSON object');
    }
    final payload = decoded['payload'];
    final sigB64 = decoded['sig'] as String?;
    if (payload is! Map<String, dynamic> || sigB64 == null || sigB64.isEmpty) {
      throw const FormatException('License missing payload or sig');
    }
    final doc = LicenseDocument.fromJson(payload);
    if (doc.customer.isEmpty || doc.issued.isEmpty) {
      throw const FormatException('License missing customer or issued date');
    }
    final key = publicKey ?? LicenseCrypto.publicKey;
    final signature = Signature(
      base64Decode(sigB64),
      publicKey: key,
    );
    final ok = await _algo.verify(
      doc.canonicalBytes(),
      signature: signature,
    );
    if (!ok) {
      throw const FormatException('License signature is invalid');
    }
    return doc;
  }

  static Future<String> signPayload(
    LicenseDocument doc, {
    required List<int> privateSeedBytes,
    bool requireAppPublicKeyMatch = true,
  }) async {
    if (privateSeedBytes.length != 32) {
      throw ArgumentError('Ed25519 seed must be 32 bytes');
    }
    final pair = await _algo.newKeyPairFromSeed(privateSeedBytes);
    final pub = await pair.extractPublicKey();
    if (requireAppPublicKeyMatch &&
        !LicensePublicKey.ed25519PublicKeyBase64.startsWith('REPLACE_') &&
        base64Encode(pub.bytes) != LicensePublicKey.ed25519PublicKeyBase64) {
      throw StateError('Private seed does not match app public key');
    }
    final signature = await _algo.sign(doc.canonicalBytes(), keyPair: pair);
    final envelope = {
      'payload': doc.toJson(),
      'sig': base64Encode(signature.bytes),
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  static Future<({String publicB64, String privateSeedB64})> generateKeyPair() async {
    final pair = await _algo.newKeyPair();
    final pub = await pair.extractPublicKey();
    final seed = await pair.extractPrivateKeyBytes();
    return (
      publicB64: base64Encode(pub.bytes),
      privateSeedB64: base64Encode(seed),
    );
  }
}
