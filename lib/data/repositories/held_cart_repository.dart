import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database.dart';
import '../../models/cart_item.dart';
import '../../models/held_cart.dart';
import 'product_repository.dart';

class HeldCartRepository {
  Database get _db => AppDatabase.instance.db;
  final ProductRepository _products = ProductRepository();

  Future<List<HeldCart>> listAll() async {
    final headers = await _db.query('held_carts', orderBy: 'held_at DESC');
    final result = <HeldCart>[];
    for (final h in headers) {
      final id = h['id'] as int;
      final itemRows = await _db.query(
        'held_cart_items',
        where: 'held_cart_id = ?',
        whereArgs: [id],
      );
      final items = <CartItem>[];
      for (final row in itemRows) {
        final productId = row['product_id'] as int;
        final product = await _products.getById(productId);
        if (product == null || !product.active) continue;
        items.add(
          CartItem(
            product: product,
            quantity: (row['quantity'] as num).toDouble(),
            discount: (row['discount'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
      if (items.isEmpty) {
        await delete(id.toString());
        continue;
      }
      result.add(
        HeldCart(
          id: id.toString(),
          label: h['label'] as String? ?? 'Hold',
          items: items,
          heldAt: DateTime.tryParse(h['held_at'] as String? ?? '') ?? DateTime.now(),
          employeeId: h['employee_id'] as int?,
        ),
      );
    }
    return result;
  }

  Future<HeldCart> insert({
    required String label,
    required List<CartItem> items,
    int? employeeId,
  }) async {
    return _db.transaction((txn) async {
      final heldAt = DateTime.now().toIso8601String();
      final id = await txn.insert('held_carts', {
        'label': label,
        'employee_id': employeeId,
        'held_at': heldAt,
      });
      for (final item in items) {
        final productId = item.product.id;
        if (productId == null) continue;
        await txn.insert('held_cart_items', {
          'held_cart_id': id,
          'product_id': productId,
          'quantity': item.quantity,
          'discount': item.discount,
        });
      }
      return HeldCart(
        id: id.toString(),
        label: label,
        items: items.map((e) => e.copy()).toList(),
        heldAt: DateTime.parse(heldAt),
        employeeId: employeeId,
      );
    });
  }

  Future<void> delete(String id) async {
    final dbId = int.tryParse(id);
    if (dbId == null) return;
    await _db.delete('held_carts', where: 'id = ?', whereArgs: [dbId]);
  }
}
