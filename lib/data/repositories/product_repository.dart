import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/staff.dart';

class ProductRepository {
  Database get _db => AppDatabase.instance.db;

  static const _stockSelect = '''
    SELECT
      p.*,
      c.name AS category_name,
      COALESCE((
        SELECT SUM(sm.quantity)
        FROM stock_movements sm
        WHERE sm.product_id = p.id
      ), 0) AS stock_on_hand
    FROM products p
    LEFT JOIN categories c ON c.id = p.category_id
  ''';

  Future<List<Product>> getAll({bool activeOnly = false, int? categoryId}) async {
    final filters = <String>[];
    final args = <Object?>[];
    if (activeOnly) filters.add('p.active = 1');
    if (categoryId != null) {
      filters.add('p.category_id = ?');
      args.add(categoryId);
    }
    final where = filters.isEmpty ? '' : 'WHERE ${filters.join(' AND ')}';
    final rows = await _db.rawQuery('''
      $_stockSelect
      $where
      ORDER BY p.name COLLATE NOCASE
    ''', args);
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getById(int id) async {
    final rows = await _db.rawQuery('$_stockSelect WHERE p.id = ?', [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<Product?> findByBarcodeOrSku(String query) async {
    final rows = await _db.rawQuery('''
      $_stockSelect
      WHERE p.active = 1 AND (p.barcode = ? OR p.sku = ?)
      LIMIT 1
    ''', [query, query]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<Product>> search(String query, {int? categoryId}) async {
    final like = '%$query%';
    final args = <Object?>[like, like, like];
    var categoryFilter = '';
    if (categoryId != null) {
      categoryFilter = 'AND p.category_id = ?';
      args.add(categoryId);
    }
    final rows = await _db.rawQuery('''
      $_stockSelect
      WHERE p.active = 1 AND (
        p.name LIKE ? OR p.sku LIKE ? OR IFNULL(p.barcode, '') LIKE ?
      )
      $categoryFilter
      ORDER BY p.name COLLATE NOCASE
      LIMIT 80
    ''', args);
    return rows.map(Product.fromMap).toList();
  }

  Future<int> insert(Product product) => _db.insert('products', product.toMap());

  Future<int> update(Product product) {
    return _db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> delete(int id) {
    return _db.update('products', {'active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Category>> getCategories() async {
    final rows = await _db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM products p WHERE p.category_id = c.id AND p.active = 1) AS product_count
      FROM categories c
      ORDER BY c.name COLLATE NOCASE
    ''');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category category) => _db.insert('categories', category.toMap());

  Future<int> updateCategory(Category category) {
    return _db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int id) => _db.delete('categories', where: 'id = ?', whereArgs: [id]);

  Future<int> lowStockCount() async {
    final rows = await _db.rawQuery('''
      SELECT COUNT(*) AS c FROM (
        SELECT
          p.reorder_level,
          COALESCE((SELECT SUM(sm.quantity) FROM stock_movements sm WHERE sm.product_id = p.id), 0) AS stock_on_hand
        FROM products p
        WHERE p.active = 1
      ) t
      WHERE t.stock_on_hand <= t.reorder_level
    ''');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<List<Product>> lowStockProducts() async {
    final all = await getAll(activeOnly: true);
    return all.where((p) => p.isLowStock).toList();
  }

  Future<void> adjustStock({
    required int productId,
    required double quantityDelta,
    required String reason,
    int? employeeId,
  }) async {
    await _db.insert('stock_movements', {
      'product_id': productId,
      'movement_type': 'adjustment',
      'quantity': quantityDelta,
      'reference_type': 'adjustment',
      'notes': reason,
      'employee_id': employeeId ?? 1,
    });
  }

  Future<List<StockMovement>> stockHistory({int limit = 100}) async {
    final rows = await _db.rawQuery('''
      SELECT sm.*, p.name AS product_name, e.name AS employee_name
      FROM stock_movements sm
      LEFT JOIN products p ON p.id = sm.product_id
      LEFT JOIN employees e ON e.id = sm.employee_id
      ORDER BY sm.created_at DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(StockMovement.fromMap).toList();
  }

  Future<Map<String, String>> getSettings() async {
    final rows = await _db.query('settings');
    return {
      for (final row in rows)
        if (row['key'] != null) row['key'] as String: (row['value'] as String?) ?? '',
    };
  }

  Future<void> saveSettings(Map<String, String> values) async {
    final batch = _db.batch();
    for (final entry in values.entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
