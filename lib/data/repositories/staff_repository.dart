import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database.dart';
import '../../models/staff.dart';

class StaffRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<Employee>> getAll({bool activeOnly = false}) async {
    final where = activeOnly ? 'WHERE active = 1' : '';
    final rows = await _db.rawQuery(
      'SELECT * FROM employees $where ORDER BY name COLLATE NOCASE',
    );
    return rows.map(Employee.fromMap).toList();
  }

  Future<int> insert(Employee employee) => _db.insert('employees', employee.toMap());

  Future<int> update(Employee employee) {
    return _db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<Shift?> currentOpenShift() async {
    final rows = await _db.rawQuery('''
      SELECT sh.*, e.name AS employee_name
      FROM shifts sh
      LEFT JOIN employees e ON e.id = sh.employee_id
      WHERE sh.status = 'open'
      ORDER BY sh.opened_at DESC
      LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    return Shift.fromMap(rows.first);
  }

  Future<int> openShift({
    required int employeeId,
    required double openingCash,
  }) async {
    final open = await currentOpenShift();
    if (open != null) throw StateError('A shift is already open');
    return _db.insert('shifts', {
      'employee_id': employeeId,
      'opening_cash': openingCash,
      'status': 'open',
    });
  }

  Future<void> addCashMovement({
    required int shiftId,
    required String type,
    required double amount,
    String? note,
  }) async {
    await _db.insert('cash_movements', {
      'shift_id': shiftId,
      'movement_type': type,
      'amount': amount,
      'note': note,
    });
  }

  Future<ShiftSummary> shiftSummary(int shiftId) async {
    final shiftRows = await _db.rawQuery('''
      SELECT sh.*, e.name AS employee_name
      FROM shifts sh
      LEFT JOIN employees e ON e.id = sh.employee_id
      WHERE sh.id = ?
    ''', [shiftId]);
    final shift = Shift.fromMap(shiftRows.first);

    final movementRows = await _db.query(
      'cash_movements',
      where: 'shift_id = ?',
      whereArgs: [shiftId],
      orderBy: 'created_at DESC',
    );
    final movements = movementRows.map(CashMovement.fromMap).toList();

    double cashIn = 0;
    double cashOut = 0;
    for (final m in movements) {
      if (m.movementType == 'in') {
        cashIn += m.amount;
      } else if (m.movementType == 'out') {
        cashOut += m.amount;
      }
    }

    final salesRows = await _db.rawQuery('''
      SELECT COALESCE(SUM(p.amount), 0) AS cash_sales
      FROM payments p
      JOIN sales s ON s.id = p.sale_id
      WHERE p.method = 'cash'
        AND s.status = 'completed'
        AND s.sold_at >= ?
        AND (? IS NULL OR s.sold_at <= ?)
    ''', [shift.openedAt, shift.closedAt, shift.closedAt]);

    final cashSales = (salesRows.first['cash_sales'] as num?)?.toDouble() ?? 0;
    final expected = shift.openingCash + cashSales + cashIn - cashOut;

    return ShiftSummary(
      shift: shift,
      cashSales: cashSales,
      cashIn: cashIn,
      cashOut: cashOut,
      expectedCash: expected,
      movements: movements,
    );
  }

  Future<void> closeShift({
    required int shiftId,
    required double closingCash,
  }) async {
    final summary = await shiftSummary(shiftId);
    await _db.update(
      'shifts',
      {
        'closed_at': DateTime.now().toIso8601String(),
        'closing_cash': closingCash,
        'expected_cash': summary.expectedCash,
        'difference': closingCash - summary.expectedCash,
        'status': 'closed',
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }

  Future<List<Shift>> shiftHistory({int limit = 50}) async {
    final rows = await _db.rawQuery('''
      SELECT sh.*, e.name AS employee_name
      FROM shifts sh
      LEFT JOIN employees e ON e.id = sh.employee_id
      ORDER BY sh.opened_at DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(Shift.fromMap).toList();
  }
}
