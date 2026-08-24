import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database.dart';
import '../../models/customer.dart';

class CustomerRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<Customer>> getAll({String? query}) async {
    if (query == null || query.trim().isEmpty) {
      final rows = await _db.query('customers', orderBy: 'name COLLATE NOCASE');
      return rows.map(Customer.fromMap).toList();
    }
    final like = '%${query.trim()}%';
    final rows = await _db.query(
      'customers',
      where: 'name LIKE ? OR IFNULL(phone, \'\') LIKE ? OR IFNULL(email, \'\') LIKE ?',
      whereArgs: [like, like, like],
      orderBy: 'name COLLATE NOCASE',
      limit: 80,
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(int id) async {
    final rows = await _db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<int> insert(Customer customer) => _db.insert('customers', customer.toMap());

  Future<int> update(Customer customer) {
    return _db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> delete(int id) => _db.delete('customers', where: 'id = ?', whereArgs: [id]);
}
