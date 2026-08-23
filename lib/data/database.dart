import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pin_auth.dart';

/// Offline SQLite database for the desktop POS.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  String? _dbPath;

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
    _dbPath = dbPath;

    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 10,
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
          if (oldVersion < 5) {
            await _migrateToV5(db);
          }
          if (oldVersion < 6) {
            await _migrateToV6(db);
          }
          if (oldVersion < 7) {
            await _migrateToV7(db);
          }
          if (oldVersion < 8) {
            await _migrateToV8(db);
          }
          if (oldVersion < 9) {
            await _migrateToV9(db);
          }
          if (oldVersion < 10) {
            await _migrateToV10(db);
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
    await ensureSetting('system_name', 'MayleSoft retail');
    await ensureSetting('app_version', '1.0.0');
  }

  Future<void> _migrateToV4(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(products)');
    final exists = info.any((row) => row['name'] == 'image_path');
    if (!exists) {
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
    }
  }

  Future<void> _migrateToV5(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(employees)');
    if (!info.any((row) => row['name'] == 'pin_hash')) {
      await db.execute('ALTER TABLE employees ADD COLUMN pin_hash TEXT');
    }

    final admins = await db.query('employees', where: 'username = ?', whereArgs: ['admin']);
    for (final row in admins) {
      final hash = row['pin_hash'] as String?;
      if (hash == null || hash.isEmpty) {
        await db.update(
          'employees',
          {'pin_hash': PinAuth.hash('1234')},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  Future<void> _migrateToV6(Database db) async {
    final rows = await db.query('settings', where: 'key = ?', whereArgs: ['system_name']);
    if (rows.isNotEmpty && rows.first['value'] == 'Shop X') {
      await db.update(
        'settings',
        {'value': 'MayleSoft retail'},
        where: 'key = ?',
        whereArgs: ['system_name'],
      );
    }
  }

  Future<void> _migrateToV7(Database db) async {
    final rows = await db.query('settings', where: 'key = ?', whereArgs: ['system_name']);
    if (rows.isEmpty) return;
    final value = rows.first['value'] as String?;
    if (value == 'Shop X' || value == 'MayleSoft Retail') {
      await db.update(
        'settings',
        {'value': 'MayleSoft retail'},
        where: 'key = ?',
        whereArgs: ['system_name'],
      );
    }
  }

  Future<void> _migrateToV8(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS discount_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        discount_type TEXT NOT NULL DEFAULT 'percent',
        value REAL NOT NULL DEFAULT 0,
        min_purchase REAL NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        label TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        device_type TEXT NOT NULL DEFAULT 'terminal',
        identifier TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS printers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        printer_type TEXT NOT NULL DEFAULT 'receipt',
        connection TEXT NOT NULL DEFAULT 'usb',
        address TEXT,
        paper_width INTEGER NOT NULL DEFAULT 80,
        is_default INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    final paymentRows = await db.rawQuery('SELECT COUNT(*) AS c FROM payment_methods');
    final paymentCount = paymentRows.first['c'] as int? ?? 0;
    if (paymentCount == 0) {
      await db.insert('payment_methods', {'code': 'cash', 'label': 'Cash', 'enabled': 1, 'sort_order': 0});
      await db.insert('payment_methods', {'code': 'card', 'label': 'Card', 'enabled': 1, 'sort_order': 1});
      await db.insert('payment_methods', {'code': 'mobile', 'label': 'Mobile', 'enabled': 1, 'sort_order': 2});
    }

    Future<void> ensureSetting(String key, String value) async {
      final existing = await db.query('settings', where: 'key = ?', whereArgs: [key]);
      if (existing.isEmpty) {
        await db.insert('settings', {'key': key, 'value': value});
      }
    }

    await ensureSetting('network_enabled', '0');
    await ensureSetting('network_server_url', '');
    await ensureSetting('network_terminal_name', '');
    await ensureSetting('network_sync_interval', '60');
  }

  Future<void> _migrateToV9(Database db) async {
    final existing = await db.query('settings', where: 'key = ?', whereArgs: ['store_logo']);
    if (existing.isEmpty) {
      await db.insert('settings', {'key': 'store_logo', 'value': ''});
    }
  }

  Future<void> _migrateToV10(Database db) async {
    Future<void> addColumn(String table, String column, String typeSql) async {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final exists = info.any((row) => row['name'] == column);
      if (!exists) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $typeSql');
      }
    }

    await addColumn('discount_rules', 'scope', "TEXT NOT NULL DEFAULT 'all'");
    await addColumn('discount_rules', 'start_date', 'TEXT');
    await addColumn('discount_rules', 'end_date', 'TEXT');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS discount_rule_products (
        discount_rule_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        PRIMARY KEY (discount_rule_id, product_id),
        FOREIGN KEY (discount_rule_id) REFERENCES discount_rules(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');
  }

  String get databasePath {
    final path = _dbPath;
    if (path == null) {
      throw StateError('Database not initialized. Call AppDatabase.instance.init() first.');
    }
    return path;
  }

  Future<void> restoreFrom(String sourcePath) async {
    final path = databasePath;
    await close();
    await File(sourcePath).copy(path);
    await init();
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('employees', {
      'name': 'Admin',
      'username': 'admin',
      'pin_hash': PinAuth.hash('1234'),
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
    await db.insert('settings', {'key': 'system_name', 'value': 'MayleSoft retail'});
    await db.insert('settings', {'key': 'app_version', 'value': '1.0.0'});
    await db.insert('settings', {'key': 'network_enabled', 'value': '0'});
    await db.insert('settings', {'key': 'network_server_url', 'value': ''});
    await db.insert('settings', {'key': 'network_terminal_name', 'value': ''});
    await db.insert('settings', {'key': 'network_sync_interval', 'value': '60'});
    await db.insert('settings', {'key': 'store_logo', 'value': ''});

    await db.insert('payment_methods', {'code': 'cash', 'label': 'Cash', 'enabled': 1, 'sort_order': 0});
    await db.insert('payment_methods', {'code': 'card', 'label': 'Card', 'enabled': 1, 'sort_order': 1});
    await db.insert('payment_methods', {'code': 'mobile', 'label': 'Mobile', 'enabled': 1, 'sort_order': 2});

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
