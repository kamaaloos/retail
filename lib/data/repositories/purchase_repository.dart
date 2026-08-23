import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database.dart';
import '../../models/sale.dart';

class PurchaseLine {
  final int productId;
  final double quantity;
  final double unitCost;

  const PurchaseLine({
    required this.productId,
    required this.quantity,
    required this.unitCost,
  });

  double get lineTotal => quantity * unitCost;
}

class PurchaseRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<Purchase>> getAll({int limit = 100}) async {
    final rows = await _db.rawQuery('''
      SELECT p.*, s.name AS supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON s.id = p.supplier_id
      ORDER BY p.purchase_date DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(Purchase.fromMap).toList();
  }

  Future<int> receiveStock({
    required List<PurchaseLine> lines,
    int? supplierId,
    String? invoiceNumber,
    String? notes,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('No purchase lines');
    }

    return _db.transaction((txn) async {
      double subtotal = 0;
      for (final line in lines) {
        subtotal += line.lineTotal;
      }

      final purchaseId = await txn.insert('purchases', {
        'supplier_id': supplierId,
        'invoice_number': invoiceNumber,
        'subtotal': subtotal,
        'tax': 0,
        'total': subtotal,
        'notes': notes,
      });

      for (final line in lines) {
        await txn.insert('purchase_items', {
          'purchase_id': purchaseId,
          'product_id': line.productId,
          'quantity': line.quantity,
          'unit_cost': line.unitCost,
          'line_total': line.lineTotal,
        });

        await txn.insert('stock_movements', {
          'product_id': line.productId,
          'movement_type': 'purchase',
          'quantity': line.quantity,
          'reference_type': 'purchase',
          'reference_id': purchaseId,
          'unit_cost': line.unitCost,
        });

        await txn.update(
          'products',
          {
            'cost_price': line.unitCost,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [line.productId],
        );
      }

      return purchaseId;
    });
  }
}
