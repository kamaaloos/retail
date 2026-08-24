class Employee {
  final int? id;
  final String name;
  final String? username;
  final String role;
  final bool active;
  final String? createdAt;

  const Employee({
    this.id,
    required this.name,
    this.username,
    this.role = 'cashier',
    this.active = true,
    this.createdAt,
  });

  factory Employee.fromMap(Map<String, Object?> map) {
    return Employee(
      id: map['id'] as int?,
      name: map['name'] as String,
      username: map['username'] as String?,
      role: map['role'] as String? ?? 'cashier',
      active: (map['active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'username': username,
      'role': role,
      'active': active ? 1 : 0,
    };
  }
}

const staffRoles = ['owner', 'admin', 'manager', 'cashier'];

class Shift {
  final int? id;
  final int employeeId;
  final String? employeeName;
  final String? openedAt;
  final String? closedAt;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? difference;
  final String status;

  const Shift({
    this.id,
    required this.employeeId,
    this.employeeName,
    this.openedAt,
    this.closedAt,
    this.openingCash = 0,
    this.closingCash,
    this.expectedCash,
    this.difference,
    this.status = 'open',
  });

  factory Shift.fromMap(Map<String, Object?> map) {
    return Shift(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      employeeName: map['employee_name'] as String?,
      openedAt: map['opened_at'] as String?,
      closedAt: map['closed_at'] as String?,
      openingCash: (map['opening_cash'] as num?)?.toDouble() ?? 0,
      closingCash: (map['closing_cash'] as num?)?.toDouble(),
      expectedCash: (map['expected_cash'] as num?)?.toDouble(),
      difference: (map['difference'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'open',
    );
  }
}

class CashMovement {
  final int? id;
  final int shiftId;
  final String movementType;
  final double amount;
  final String? note;
  final String? createdAt;

  const CashMovement({
    this.id,
    required this.shiftId,
    required this.movementType,
    required this.amount,
    this.note,
    this.createdAt,
  });

  factory CashMovement.fromMap(Map<String, Object?> map) {
    return CashMovement(
      id: map['id'] as int?,
      shiftId: map['shift_id'] as int,
      movementType: map['movement_type'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}

class ShiftSummary {
  final Shift shift;
  final double cashSales;
  final double cardSales;
  final double otherSales;
  final double totalSales;
  final int saleCount;
  final double refunds;
  final double cashIn;
  final double cashOut;
  final double expectedCash;
  final List<CashMovement> movements;

  const ShiftSummary({
    required this.shift,
    this.cashSales = 0,
    this.cardSales = 0,
    this.otherSales = 0,
    this.totalSales = 0,
    this.saleCount = 0,
    this.refunds = 0,
    this.cashIn = 0,
    this.cashOut = 0,
    this.expectedCash = 0,
    this.movements = const [],
  });
}

class StockMovement {
  final int? id;
  final int productId;
  final String? productName;
  final String movementType;
  final double quantity;
  final String? referenceType;
  final int? referenceId;
  final double? unitCost;
  final String? notes;
  final int? employeeId;
  final String? employeeName;
  final String? createdAt;

  const StockMovement({
    this.id,
    required this.productId,
    this.productName,
    required this.movementType,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    this.unitCost,
    this.notes,
    this.employeeId,
    this.employeeName,
    this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, Object?> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String?,
      movementType: map['movement_type'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as int?,
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      employeeId: map['employee_id'] as int?,
      employeeName: map['employee_name'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}
