import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProductImageStore {
  static Future<Directory> _dir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'retail_manager', 'product_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies [sourcePath] into app storage and returns the new absolute path.
  static Future<String> saveFromPath(String sourcePath, {String? productKey}) async {
    final dir = await _dir();
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final name = '${productKey ?? DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = p.join(dir.path, name);
    await File(sourcePath).copy(dest);
    return dest;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class StoreLogoStore {
  static Future<Directory> _dir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'retail_manager', 'store_assets'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> _clearExisting() async {
    final dir = await _dir();
    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }

  static Future<String> saveFromPath(String sourcePath) async {
    final ext = p.extension(sourcePath).isEmpty ? '.png' : p.extension(sourcePath).toLowerCase();
    await _clearExisting();
    final dir = await _dir();
    final dest = p.join(dir.path, 'store_logo$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await _clearExisting();
  }
}
