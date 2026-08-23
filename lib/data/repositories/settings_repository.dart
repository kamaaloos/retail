import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database.dart';
import '../../models/settings_config.dart';

class SettingsRepository {
  Database get _db => AppDatabase.instance.db;

  // --- Discounts ---

  Future<List<DiscountRule>> getDiscounts() async {
    final rows = await _db.query('discount_rules', orderBy: 'name COLLATE NOCASE');
    final rules = <DiscountRule>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final productRows = await _db.query(
        'discount_rule_products',
        where: 'discount_rule_id = ?',
        whereArgs: [id],
      );
      final productIds = productRows.map((r) => r['product_id'] as int).toList();
      rules.add(DiscountRule.fromMap(row, productIds: productIds));
    }
    return rules;
  }

  Future<int> insertDiscount(DiscountRule rule) async {
    return _db.transaction((txn) async {
      final id = await txn.insert('discount_rules', rule.toMap());
      for (final productId in rule.productIds) {
        await txn.insert('discount_rule_products', {
          'discount_rule_id': id,
          'product_id': productId,
        });
      }
      return id;
    });
  }

  Future<void> updateDiscount(DiscountRule rule) async {
    await _db.transaction((txn) async {
      await txn.update('discount_rules', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
      await txn.delete('discount_rule_products', where: 'discount_rule_id = ?', whereArgs: [rule.id]);
      for (final productId in rule.productIds) {
        await txn.insert('discount_rule_products', {
          'discount_rule_id': rule.id,
          'product_id': productId,
        });
      }
    });
  }

  Future<void> deleteDiscount(int id) async {
    await _db.delete('discount_rules', where: 'id = ?', whereArgs: [id]);
  }

  // --- Payment methods ---

  Future<List<PaymentMethodConfig>> getPaymentMethods() async {
    final rows = await _db.query('payment_methods', orderBy: 'sort_order, id');
    return rows.map(PaymentMethodConfig.fromMap).toList();
  }

  Future<int> insertPaymentMethod(PaymentMethodConfig method) =>
      _db.insert('payment_methods', method.toMap());

  Future<void> updatePaymentMethod(PaymentMethodConfig method) async {
    await _db.update('payment_methods', method.toMap(), where: 'id = ?', whereArgs: [method.id]);
  }

  Future<void> deletePaymentMethod(int id) async {
    await _db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  // --- POS devices ---

  Future<List<PosDevice>> getPosDevices() async {
    final rows = await _db.query('pos_devices', orderBy: 'name COLLATE NOCASE');
    return rows.map(PosDevice.fromMap).toList();
  }

  Future<int> insertPosDevice(PosDevice device) => _db.insert('pos_devices', device.toMap());

  Future<void> updatePosDevice(PosDevice device) async {
    await _db.update('pos_devices', device.toMap(), where: 'id = ?', whereArgs: [device.id]);
  }

  Future<void> deletePosDevice(int id) async {
    await _db.delete('pos_devices', where: 'id = ?', whereArgs: [id]);
  }

  // --- Printers ---

  Future<List<PrinterConfig>> getPrinters() async {
    final rows = await _db.query('printers', orderBy: 'is_default DESC, name COLLATE NOCASE');
    return rows.map(PrinterConfig.fromMap).toList();
  }

  Future<int> insertPrinter(PrinterConfig printer) async {
    if (printer.isDefault) {
      await _db.update('printers', {'is_default': 0});
    }
    return _db.insert('printers', printer.toMap());
  }

  Future<void> updatePrinter(PrinterConfig printer) async {
    if (printer.isDefault) {
      await _db.update('printers', {'is_default': 0});
    }
    await _db.update('printers', printer.toMap(), where: 'id = ?', whereArgs: [printer.id]);
  }

  Future<void> deletePrinter(int id) async {
    await _db.delete('printers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Network ---

  Future<Map<String, String>> getSettings() async {
    final rows = await _db.query('settings');
    return {
      for (final row in rows)
        if (row['key'] != null) row['key'] as String: (row['value'] as String?) ?? '',
    };
  }

  Future<NetworkSettings> getNetworkSettings() async {
    return NetworkSettings.fromMap(await getSettings());
  }

  Future<void> saveNetworkSettings(NetworkSettings settings) async {
    final batch = _db.batch();
    for (final entry in settings.toSettingsMap().entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Backup ---

  Future<String> exportDatabase(String destinationPath) async {
    final source = AppDatabase.instance.databasePath;
    await File(source).copy(destinationPath);
    return destinationPath;
  }

  Future<void> restoreDatabase(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Backup file not found');
    }
    await AppDatabase.instance.restoreFrom(sourcePath);
  }

  String suggestedBackupName() {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    return 'maylesoft_retail_$stamp.db';
  }

  String get databaseDirectory => p.dirname(AppDatabase.instance.databasePath);

  String get databasePath => AppDatabase.instance.databasePath;
}
