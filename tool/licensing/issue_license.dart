import 'dart:convert';
import 'dart:io';

import 'package:retail_manager/licensing/license_crypto.dart';
import 'package:retail_manager/licensing/license_document.dart';

/// Issue an offline signed license.
///
/// Usage:
///   dart run tool/licensing/issue_license.dart --customer "Shop Name" [--email a@b.c]
///       [--expires 2027-12-31] [--machine <id>] [--out path.lic]
///
/// Requires tool/licensing/secrets/private_seed.b64 from generate_keypair.dart
Future<void> main(List<String> args) async {
  String? customer;
  String? email;
  String? expires;
  String? machineId;
  String? notes;
  String? outPath;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    String next() {
      if (i + 1 >= args.length) throw ArgumentError('Missing value for $a');
      return args[++i];
    }

    switch (a) {
      case '--customer':
        customer = next();
      case '--email':
        email = next();
      case '--expires':
        expires = next();
      case '--machine':
        machineId = next();
      case '--notes':
        notes = next();
      case '--out':
        outPath = next();
      case '--help':
      case '-h':
        _usage();
        return;
      default:
        stderr.writeln('Unknown arg: $a');
        _usage();
        exit(64);
    }
  }

  if (customer == null || customer.trim().isEmpty) {
    stderr.writeln('--customer is required');
    _usage();
    exit(64);
  }

  final seedFile = File('tool/licensing/secrets/private_seed.b64');
  if (!seedFile.existsSync()) {
    stderr.writeln('Missing ${seedFile.path}');
    stderr.writeln('Run: dart run tool/licensing/generate_keypair.dart');
    exit(1);
  }
  final seedB64 = seedFile.readAsStringSync().trim();
  final seed = base64Decode(seedB64);

  final today = DateTime.now();
  final issued =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final doc = LicenseDocument(
    version: 1,
    customer: customer.trim(),
    email: email?.trim(),
    issued: issued,
    expires: expires?.trim(),
    machineId: machineId?.trim(),
    notes: notes?.trim(),
  );

  final lic = await LicenseCrypto.signPayload(doc, privateSeedBytes: seed);
  final safeName = customer.trim().replaceAll(RegExp(r'[^\w\-]+'), '_');
  final path = outPath ?? 'tool/licensing/out/${safeName}_$issued.lic';
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('$lic\n');
  stdout.writeln('License written: ${file.path}');
  if (machineId != null && machineId!.isNotEmpty) {
    stdout.writeln('Bound to machine: $machineId');
  } else {
    stdout.writeln('Not machine-bound (portable).');
  }
  if (expires != null && expires!.isNotEmpty) {
    stdout.writeln('Expires: $expires');
  } else {
    stdout.writeln('Expires: never');
  }
}

void _usage() {
  stdout.writeln('''
Issue a MayleSoft retail license (.lic)

  dart run tool/licensing/issue_license.dart --customer "Acme Shop" [options]

Options:
  --customer   Shop / licensee name (required)
  --email      Contact email
  --expires    YYYY-MM-DD (omit for perpetual)
  --machine    Machine id from Activation screen (omit for portable)
  --notes      Free-text note
  --out        Output .lic path
''');
}
