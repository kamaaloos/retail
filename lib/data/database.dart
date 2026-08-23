import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Offline SQLite database for the desktop POS.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('Database not initialized. Call AppDatabase.instance.init() first.');
    }
    return database;
  }

  Future<void> init() async {
    if (_db != null) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final supportDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(supportDir.path, 'retail_manager'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final dbPath = p.join(dbDir.path, 'retail.db');

    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 4,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _applySchema(db);
          await _seedDefaults(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _migrateToV2(db);
          }
          if (oldVersion < 3) {
            await _migrateToV3(db);
          }
          if (oldVersion < 4) {
            await _migrateToV4(db);
          }
        },
      ),
    );
  }

  Future<void> _applySchema(Database db) async {
    final schema = await rootBundle.loadString('assets/sql/schema.sql');
    final statements = schema
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('--'));

    for (final statement in statements) {
      if (statement.toUpperCase().startsWith('PRAGMA')) continue;
      await db.execute(statement);
    }
  }

  Future<void> _migrateToV2(Database db) async {
    Future<void> addColumn(String table, String column, String typeSql) async {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final exists = info.any((row) => row['name'] == column);
      if (!exists) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $typeSql');
      }
    }

    await addColumn('products', 'unit', "TEXT NOT NULL DEFAULT 'pcs'");
    await addColumn('products', 'color', "TEXT NOT NULL DEFAULT '#3B82F6'");
    await addColumn('categories', 'color', "TEXT NOT NULL DEFAULT '#3B82F6'");
    await addColumn('stock_movements', 'employee_id', 'INTEGER');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_employee ON sales(employee_id)');
  }

  Future<void> _migrateToV3(Database db) async {
    Future<void> ensureSetting(String key, String value) async {
      final existing = await db.query('settings', where: 'key = ?', whereArgs: [key]);
      if (existing.isEmpty) {
        await db.insert('settings', {'key': key, 'value': value});
      }
    }

    await ensureSetting('tax_name', 'Sales Tax');
    await ensureSetting('tax_type', 'exclusive');
    await ensureSetting('phone', '');
    await ensureSetting('email', '');
    await ensureSetting('address', '');
    await ensureSetting('receipt_header', '');
    await ensureSetting('receipt_footer', '');
    await ensureSetting('language', 'en_US');
    await ensureSetting('dark_mode', '1');
    await ensureSetting('system_name', 'Shop X');
    await ensureSetting('app_version', '1.0.0');
  }

  Future<void> _migrateToV4(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(products)');
    final exists = info.any((row) => row['name'] == 'image_path');
    if (!exists) {
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
    }
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('employees', {
      'name': 'Admin',
      'username': 'admin',
      'role': 'owner',
      'active': 1,
    });

    await db.insert('settings', {'key': 'currency', 'value': 'USD'});
    await db.insert('settings', {'key': 'currency_symbol', 'value': '\$'});
    await db.insert('settings', {'key': 'store_name', 'value': 'Shop X'});
    await db.insert('settings', {'key': 'default_tax_rate', 'value': '10'});
    await db.insert('settings', {'key': 'tax_name', 'value': 'Sales Tax'});
    await db.insert('settings', {'key': 'tax_type', 'value': 'exclusive'});
    await db.insert('settings', {'key': 'receipt_prefix', 'value': 'R'});
    await db.insert('settings', {'key': 'phone', 'value': ''});
    await db.insert('settings', {'key': 'email', 'value': ''});
    await db.insert('settings', {'key': 'address', 'value': ''});
    await db.insert('settings', {'key': 'receipt_header', 'value': ''});
    await db.insert('settings', {'key': 'receipt_footer', 'value': ''});
    await db.insert('settings', {'key': 'language', 'value': 'en_US'});
    await db.insert('settings', {'key': 'dark_mode', 'value': '1'});
    await db.insert('settings', {'key': 'system_name', 'value': 'Shop X'});
    await db.insert('settings', {'key': 'app_version', 'value': '1.0.0'});

    await db.insert('categories', {'name': 'General', 'color': '#3B82F6'});
    await db.insert('categories', {'name': 'Food', 'color': '#F59E0B'});
    await db.insert('categories', {'name': 'Drinks', 'color': '#22C55E'});

    await db.insert('products', {
      'sku': 'DEMO-001',
      'barcode': '1000001',
      'name': 'Sample Product',
      'category_id': 1,
      'unit': 'pcs',
      'color': '#3B82F6',
      'cost_price': 5.00,
      'selling_price': 9.99,
      'tax_rate': 0,
      'reorder_level': 5,
      'active': 1,
    });

    await db.insert('stock_movements', {
      'product_id': 1,
      'movement_type': 'adjustment',
      'quantity': 20,
      'reference_type': 'seed',
      'notes': 'Initial stock',
      'employee_id': 1,
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
