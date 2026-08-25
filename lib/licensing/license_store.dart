import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'license_crypto.dart';
import 'license_document.dart';

abstract final class LicenseStore {
  static const trialDays = 14;
  static const licenseFileName = 'license.maylesoft.lic';
  static const stateFileName = 'license_state.json';

  static Future<Directory> _dir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'retail_manager'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> licenseFile() async {
    final dir = await _dir();
    return File(p.join(dir.path, licenseFileName));
  }

  static Future<File> _stateFile() async {
    final dir = await _dir();
    return File(p.join(dir.path, stateFileName));
  }

  static Future<DateTime> ensureTrialStarted({DateTime? now}) async {
    final when = now ?? DateTime.now();
    final file = await _stateFile();
    if (await file.exists()) {
      try {
        final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final raw = map['trialStartedAt'] as String?;
        final parsed = raw == null ? null : DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      } catch (_) {}
    }
    final started = DateTime(when.year, when.month, when.day);
    await file.writeAsString(
      jsonEncode({'trialStartedAt': started.toIso8601String()}),
      flush: true,
    );
    return started;
  }

  static Future<LicenseDocument?> loadInstalledLicense() async {
    final file = await licenseFile();
    if (!await file.exists()) return null;
    return LicenseCrypto.verifyFileBytes(await file.readAsBytes());
  }

  static Future<void> installLicenseBytes(List<int> bytes) async {
    // Verify before writing so we never store junk.
    await LicenseCrypto.verifyFileBytes(bytes);
    final file = await licenseFile();
    await file.writeAsBytes(bytes, flush: true);
  }

  static Future<void> clearLicense() async {
    final file = await licenseFile();
    if (await file.exists()) await file.delete();
  }
}
