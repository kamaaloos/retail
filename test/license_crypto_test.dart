import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/licensing/license_crypto.dart';
import 'package:retail_manager/licensing/license_document.dart';

void main() {
  group('LicenseDocument', () {
    test('expiry detection', () {
      const doc = LicenseDocument(
        version: 1,
        customer: 'Acme',
        issued: '2026-01-01',
        expires: '2026-08-01',
      );
      expect(doc.isExpiredOn(DateTime(2026, 8, 1)), isFalse);
      expect(doc.isExpiredOn(DateTime(2026, 8, 2)), isTrue);
    });

    test('perpetual never expires', () {
      const doc = LicenseDocument(
        version: 1,
        customer: 'Acme',
        issued: '2026-01-01',
      );
      expect(doc.isExpiredOn(DateTime(2099, 1, 1)), isFalse);
    });
  });

  group('LicenseCrypto', () {
    test('sign and verify round-trip', () async {
      final keys = await LicenseCrypto.generateKeyPair();
      final seed = base64Decode(keys.privateSeedB64);
      final pub = LicenseCrypto.publicKeyFromBase64(keys.publicB64);
      final doc = LicenseDocument(
        version: 1,
        customer: 'Test Shop',
        issued: '2026-08-24',
        expires: '2027-08-24',
        machineId: 'abc',
      );
      final lic = await LicenseCrypto.signPayload(
        doc,
        privateSeedBytes: seed,
        requireAppPublicKeyMatch: false,
      );
      final verified = await LicenseCrypto.verifyFileBytes(
        utf8.encode(lic),
        publicKey: pub,
      );
      expect(verified.customer, 'Test Shop');
      expect(verified.machineId, 'abc');
    });

    test('Node server signature verifies with app public key', () async {
      // Requires tool/licensing/secrets/private_seed.b64 matching license_public_key.dart
      final result = await Process.run(
        'node',
        ['tool/licensing/server/verify-sign.js'],
        workingDirectory: Directory.current.path,
      );
      if (result.exitCode != 0) {
        // Skip when seed missing (CI without secrets)
        expect(result.stderr.toString(), contains('MAYLESOFT_LICENSE_SEED'));
        return;
      }
      final verified = await LicenseCrypto.verifyFileBytes(
        utf8.encode(result.stdout as String),
      );
      expect(verified.customer, 'SignCheck');
      expect(verified.machineId, 'test-machine-id-001');
    }, skip: false);

    test('tampered payload fails verify', () async {
      final keys = await LicenseCrypto.generateKeyPair();
      final seed = base64Decode(keys.privateSeedB64);
      final pub = LicenseCrypto.publicKeyFromBase64(keys.publicB64);
      final doc = const LicenseDocument(
        version: 1,
        customer: 'Test Shop',
        issued: '2026-08-24',
      );
      final lic = await LicenseCrypto.signPayload(
        doc,
        privateSeedBytes: seed,
        requireAppPublicKeyMatch: false,
      );
      final map = jsonDecode(lic) as Map<String, dynamic>;
      (map['payload'] as Map<String, dynamic>)['customer'] = 'Hacker';
      expect(
        () => LicenseCrypto.verifyFileBytes(utf8.encode(jsonEncode(map)), publicKey: pub),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
