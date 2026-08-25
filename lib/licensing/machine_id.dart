import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stable per-install machine id (not hardware-locked across wipe unless rebound).
abstract final class MachineId {
  static const _fileName = 'machine.id';

  static Future<Directory> _dir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'retail_manager'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _file() async {
    final dir = await _dir();
    return File(p.join(dir.path, _fileName));
  }

  static Future<String> getOrCreate() async {
    final file = await _file();
    if (await file.exists()) {
      final existing = (await file.readAsString()).trim();
      if (existing.isNotEmpty) return existing;
    }
    final id = _generate();
    await file.writeAsString(id, flush: true);
    return id;
  }

  static String _generate() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(24, (_) => rnd.nextInt(256));
    final host = Platform.localHostname;
    final material = utf8.encode('$host|${base64Encode(bytes)}');
    return sha256.convert(material).toString().substring(0, 32);
  }
}
