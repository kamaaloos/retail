import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database.dart';
import '../../models/cart_item.dart';
import '../../models/insufficient_stock.dart';
import '../../models/sale.dart';

class SaleRepository {
  Database get _db => AppDatabase.instance.db;

  Future<Sale> checkout({
    required List<CartItem> items,
    String paymentMethod = 'cash',
    List<({String method, double amount})>? payments,
    int? employeeId,
    int? customerId,
    double cartDiscount = 0,
    /// When set (cash/non-card nickel rounding), becomes the stored sale total.
    double? chargedTotal,
  }) async {
    if (items.isEmpty) throw ArgumentError('Cart is empty');

    return _db.transaction((txn) async {
      for (final item in items) {
        final productId = item.product.id;
        if (productId == null) {
          throw ArgumentError('Cart item is missing a product id');
        }
        final stockRows = await txn.rawQuery(
          'SELECT COALESCE(SUM(quantity), 0) AS q FROM stock_movements WHERE product_id = ?',
          [productId],
        );
        final available = (stockRows.first['q'] as num?)?.toDouble() ?? 0;
        if (item.quantity > available + 0.0001) {
          throw InsufficientStockException(
            productName: item.product.name,
            requested: item.quantity,
            available: available < 0 ? 0 : available,
          );
        }
      }

      final receiptNumber = await _nextReceiptNumber(txn);

      double subtotal = 0;
      double tax = 0;
      for (final item in items) {
        subtotal += item.lineSubtotal - item.discount;
        tax += item.taxAmount;
      }
      final rawTotal = double.parse((subtotal - cartDiscount + tax).toStringAsFixed(2));
      final total = chargedTotal != null
          ? double.parse(chargedTotal.toStringAsFixed(2))
          : rawTotal;

      final saleId = await txn.insert('sales', {
        'receipt_number': receiptNumber,
        'customer_id': customerId,
        'employee_id': employeeId ?? 1,
        'subtotal': subtotal,
        'discount': cartDiscount,
        'tax': tax,
        'total': total,
        'status': 'completed',
      });

      for (final item in items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'unit_cost': item.product.costPrice,
          'discount': item.discount,
          'tax': item.taxAmount,
          'line_total': item.lineTotal,
        });

        await txn.insert('stock_movements', {
          'product_id': item.product.id,
          'movement_type': 'sale',
          'quantity': -item.quantity,
          'reference_type': 'sale',
          'reference_id': saleId,
          'unit_cost': item.product.costPrice,
          'employee_id': employeeId ?? 1,
        });
      }

      final paymentRows = payments == null || payments.isEmpty
          ? <({String method, double amount})>[(method: paymentMethod, amount: total)]
          : payments;
      for (final p in paymentRows) {
        if (p.amount <= 0) continue;
        await txn.insert('payments', {
          'sale_id': saleId,
          'method': p.method,
          'amount': p.amount,
        });
      }

      final rows = await txn.rawQuery('''
        SELECT s.*, e.name AS employee_name
        FROM sales s
        LEFT JOIN employees e ON e.id = s.employee_id
        WHERE s.id = ?
      ''', [saleId]);
      return Sale.fromMap(rows.first);
    });
  }

  Future<String> _nextReceiptNumber(Transaction txn) async {
    final settings = await txn.query('settings', where: 'key = ?', whereArgs: ['receipt_prefix']);
    final prefix = settings.isEmpty ? 'R' : (settings.first['value'] as String? ?? 'R');
    final countRows = await txn.rawQuery('SELECT COUNT(*) AS c FROM sales');
    final count = (countRows.first['c'] as int?) ?? 0;
    return '$prefix${(count + 1).toString().padLeft(6, '0')}';
  }

  Future<List<Sale>> list({
    DateTime? from,
    DateTime? to,
    int? employeeId,
    int limit = 200,
  }) async {
    final filters = <String>['1=1'];
    final args = <Object?>[];

    if (from != null) {
      filters.add('date(s.sold_at) >= date(?)');
      args.add(_date(from));
    }
    if (to != null) {
      filters.add('date(s.sold_at) <= date(?)');
      args.add(_date(to));
    }
    if (employeeId != null) {
      filters.add('s.employee_id = ?');
      args.add(employeeId);
    }
    args.add(limit);

    final rows = await _db.rawQuery('''
      SELECT s.*, e.name AS employee_name
      FROM sales s
      LEFT JOIN employees e ON e.id = s.employee_id
      WHERE ${filters.join(' AND ')}
      ORDER BY s.sold_at DESC
      LIMIT ?
    ''', args);
    return rows.map(Sale.fromMap).toList();
  }

  Future<List<Sale>> recent({int limit = 50}) => list(limit: limit);

  Future<SaleDetail?> getDetail(int saleId) async {
    final saleRows = await _db.rawQuery('''
      SELECT s.*, e.name AS employee_name
      FROM sales s
      LEFT JOIN employees e ON e.id = s.employee_id
      WHERE s.id = ?
    ''', [saleId]);
    if (saleRows.isEmpty) return null;

    final itemRows = await _db.rawQuery('''
      SELECT si.*, p.name AS product_name, IFNULL(p.unit, 'pcs') AS unit,
        COALESCE((
          SELECT SUM(ri.quantity)
          FROM return_items ri
          JOIN returns r ON r.id = ri.return_id
          WHERE r.sale_id = si.sale_id AND ri.product_id = si.product_id
        ), 0) AS refunded_qty
      FROM sale_items si
      LEFT JOIN products p ON p.id = si.product_id
      WHERE si.sale_id = ?
    ''', [saleId]);

    final paymentRows = await _db.query('payments', where: 'sale_id = ?', whereArgs: [saleId]);

    return SaleDetail(
      sale: Sale.fromMap(saleRows.first),
      items: itemRows.map(SaleItem.fromMap).toList(),
      payments: paymentRows.map(PaymentInfo.fromMap).toList(),
    );
  }

  /// Refund selected quantities from a completed/partial sale; restocks inventory.
  Future<void> refundSale({
    required int saleId,
    required Map<int, double> productQuantities,
    required String reason,
    int? employeeId,
  }) async {
    if (productQuantities.isEmpty) throw ArgumentError('Nothing to refund');

    await _db.transaction((txn) async {
      final saleRows = await txn.query('sales', where: 'id = ?', whereArgs: [saleId]);
      if (saleRows.isEmpty) throw StateError('Sale not found');
      final status = saleRows.first['status'] as String? ?? 'completed';
      if (status == 'refunded') {
        throw StateError('Sale is already fully refunded');
      }

      final detailItems = await txn.rawQuery('''
        SELECT si.*, p.name AS product_name,
          COALESCE((
            SELECT SUM(ri.quantity)
            FROM return_items ri
            JOIN returns r ON r.id = ri.return_id
            WHERE r.sale_id = si.sale_id AND ri.product_id = si.product_id
          ), 0) AS refunded_qty
        FROM sale_items si
        LEFT JOIN products p ON p.id = si.product_id
        WHERE si.sale_id = ?
      ''', [saleId]);

      double refundTotal = 0;
      var anyRefunded = false;
      final returnId = await txn.insert('returns', {
        'sale_id': saleId,
        'employee_id': employeeId ?? 1,
        'total': 0,
        'reason': reason,
      });

      // Aggregate requested qty per product (UI may send one entry per line).
      final requested = <int, double>{};
      for (final entry in productQuantities.entries) {
        if (entry.value <= 0) continue;
        requested[entry.key] = (requested[entry.key] ?? 0) + entry.value;
      }

      for (final row in detailItems) {
        final productId = row['product_id'] as int;
        final want = requested[productId];
        if (want == null || want <= 0) continue;

        final soldQty = (row['quantity'] as num).toDouble();
        final already = (row['refunded_qty'] as num?)?.toDouble() ?? 0;
        final remaining = soldQty - already;
        if (remaining <= 0.0001) continue;

        final refundQty = want > remaining ? remaining : want;
        requested[productId] = want - refundQty;
        if (refundQty <= 0.0001) continue;

        anyRefunded = true;
        final unitPrice = (row['unit_price'] as num).toDouble();
        final lineTotal = unitPrice * refundQty;
        refundTotal += lineTotal;

        await txn.insert('return_items', {
          'return_id': returnId,
          'product_id': productId,
          'quantity': refundQty,
          'unit_price': unitPrice,
          'line_total': lineTotal,
        });

        await txn.insert('stock_movements', {
          'product_id': productId,
          'movement_type': 'return',
          'quantity': refundQty,
          'reference_type': 'return',
          'reference_id': returnId,
          'notes': reason,
          'employee_id': employeeId ?? 1,
        });
      }

      if (!anyRefunded) {
        throw StateError('No refundable quantity remaining');
      }

      await txn.update('returns', {'total': refundTotal}, where: 'id = ?', whereArgs: [returnId]);

      // Recompute remaining across all lines to set sale status.
      final afterItems = await txn.rawQuery('''
        SELECT si.quantity,
          COALESCE((
            SELECT SUM(ri.quantity)
            FROM return_items ri
            JOIN returns r ON r.id = ri.return_id
            WHERE r.sale_id = si.sale_id AND ri.product_id = si.product_id
          ), 0) AS refunded_qty
        FROM sale_items si
        WHERE si.sale_id = ?
      ''', [saleId]);
      var fullyRefunded = true;
      for (final row in afterItems) {
        final sold = (row['quantity'] as num).toDouble();
        final refunded = (row['refunded_qty'] as num?)?.toDouble() ?? 0;
        if (refunded + 0.0001 < sold) {
          fullyRefunded = false;
          break;
        }
      }
      await txn.update(
        'sales',
        {'status': fullyRefunded ? 'refunded' : 'partial_refund'},
        where: 'id = ?',
        whereArgs: [saleId],
      );
    });
  }

  Future<DashboardStats> todayStats() async {
    final start = _date(DateTime.now());
    final salesRows = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS sales_total,
        COUNT(*) AS txn_count,
        COALESCE(SUM(
          (SELECT COALESCE(SUM((si.unit_price - si.unit_cost) * si.quantity - si.discount), 0)
           FROM sale_items si WHERE si.sale_id = s.id)
        ), 0) AS gross_profit
      FROM sales s
      WHERE s.status = 'completed' AND date(s.sold_at) = date(?)
    ''', [start]);

    final low = await _db.rawQuery('''
      SELECT COUNT(*) AS c FROM (
        SELECT p.reorder_level,
          COALESCE((SELECT SUM(sm.quantity) FROM stock_movements sm WHERE sm.product_id = p.id), 0) AS stock_on_hand
        FROM products p WHERE p.active = 1
      ) t WHERE t.stock_on_hand <= t.reorder_level
    ''');

    return DashboardStats(
      todaySales: (salesRows.first['sales_total'] as num?)?.toDouble() ?? 0,
      todayTransactions: (salesRows.first['txn_count'] as int?) ?? 0,
      todayGrossProfit: (salesRows.first['gross_profit'] as num?)?.toDouble() ?? 0,
      lowStockCount: (low.first['c'] as int?) ?? 0,
    );
  }

  Future<ReportStats> reportStats({required DateTime from, required DateTime to}) async {
    final salesRows = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS revenue,
        COUNT(*) AS txn_count,
        COALESCE(SUM(
          (SELECT COALESCE(SUM((si.unit_price - si.unit_cost) * si.quantity - si.discount), 0)
           FROM sale_items si WHERE si.sale_id = s.id)
        ), 0) AS profit
      FROM sales s
      WHERE s.status = 'completed'
        AND date(s.sold_at) >= date(?)
        AND date(s.sold_at) <= date(?)
    ''', [_date(from), _date(to)]);

    final revenue = (salesRows.first['revenue'] as num?)?.toDouble() ?? 0;
    final count = (salesRows.first['txn_count'] as int?) ?? 0;
    final profit = (salesRows.first['profit'] as num?)?.toDouble() ?? 0;

    final topRows = await _db.rawQuery('''
      SELECT p.name AS name, COALESCE(SUM(si.quantity), 0) AS qty
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      JOIN products p ON p.id = si.product_id
      WHERE s.status = 'completed'
        AND date(s.sold_at) >= date(?)
        AND date(s.sold_at) <= date(?)
      GROUP BY si.product_id
      ORDER BY qty DESC
      LIMIT 10
    ''', [_date(from), _date(to)]);

    final payRows = await _db.rawQuery('''
      SELECT pay.method AS method, COALESCE(SUM(pay.amount), 0) AS amount
      FROM payments pay
      JOIN sales s ON s.id = pay.sale_id
      WHERE s.status = 'completed'
        AND date(s.sold_at) >= date(?)
        AND date(s.sold_at) <= date(?)
      GROUP BY pay.method
    ''', [_date(from), _date(to)]);

    final trendRows = await _db.rawQuery('''
      SELECT
        date(s.sold_at) AS day,
        COALESCE(SUM(s.total), 0) AS revenue,
        COUNT(*) AS txn_count
      FROM sales s
      WHERE s.status = 'completed'
        AND date(s.sold_at) >= date(?)
        AND date(s.sold_at) <= date(?)
      GROUP BY date(s.sold_at)
      ORDER BY day
    ''', [_date(from), _date(to)]);

    final trendMap = {
      for (final row in trendRows)
        row['day'] as String: DailySalesPoint(
          date: DateTime.parse(row['day'] as String),
          revenue: (row['revenue'] as num?)?.toDouble() ?? 0,
          transactions: (row['txn_count'] as int?) ?? 0,
        ),
    };
    final dailyTrend = <DailySalesPoint>[];
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!cursor.isAfter(end)) {
      final key = _date(cursor);
      dailyTrend.add(
        trendMap[key] ?? DailySalesPoint(date: cursor),
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    return ReportStats(
      totalRevenue: revenue,
      estimatedProfit: profit,
      numberOfSales: count,
      averageSale: count == 0 ? 0 : revenue / count,
      topProducts: topRows
          .map((r) => TopProduct(
                name: r['name'] as String? ?? 'Product',
                quantity: (r['qty'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
      payments: payRows
          .map((r) => PaymentBreakdown(
                method: r['method'] as String? ?? 'cash',
                amount: (r['amount'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
      dailyTrend: dailyTrend,
    );
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
