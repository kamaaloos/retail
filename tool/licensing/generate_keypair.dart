import 'dart:io';

import 'package:retail_manager/licensing/license_crypto.dart';

/// Generates Ed25519 keypair for MayleSoft licenses.
///
/// Writes:
/// - tool/licensing/secrets/private_seed.b64  (gitignored)
/// - updates lib/licensing/license_public_key.dart
Future<void> main() async {
  final root = Directory.current;
  final secrets = Directory('${root.path}/tool/licensing/secrets');
  if (!secrets.existsSync()) {
    secrets.createSync(recursive: true);
  }

  final keys = await LicenseCrypto.generateKeyPair();
  final privateFile = File('${secrets.path}/private_seed.b64');
  privateFile.writeAsStringSync('${keys.privateSeedB64}\n');

  final pubFile = File('${root.path}/lib/licensing/license_public_key.dart');
  pubFile.writeAsStringSync('''
/// Ed25519 public key embedded in the app (safe to ship).
///
/// Private seed lives only in `tool/licensing/secrets/` (gitignored).
/// Regenerate with: `dart run tool/licensing/generate_keypair.dart`
abstract final class LicensePublicKey {
  static const String ed25519PublicKeyBase64 =
      '${keys.publicB64}';
}
''');

  stdout.writeln('Wrote ${privateFile.path}');
  stdout.writeln('Updated ${pubFile.path}');
  stdout.writeln('Public key: ${keys.publicB64}');
  stdout.writeln('');
  stdout.writeln('Keep private_seed.b64 secret. Never commit it.');
}
