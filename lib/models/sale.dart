class Sale {
  final int? id;
  final String receiptNumber;
  final int? customerId;
  final int? employeeId;
  final String? employeeName;
  final String? soldAt;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String status;

  const Sale({
    this.id,
    required this.receiptNumber,
    this.customerId,
    this.employeeId,
    this.employeeName,
    this.soldAt,
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.total = 0,
    this.status = 'completed',
  });

  factory Sale.fromMap(Map<String, Object?> map) {
    return Sale(
      id: map['id'] as int?,
      receiptNumber: map['receipt_number'] as String,
      customerId: map['customer_id'] as int?,
      employeeId: map['employee_id'] as int?,
      employeeName: map['employee_name'] as String?,
      soldAt: map['sold_at'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'completed',
    );
  }
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double unitCost;
  final double discount;
  final double tax;
  final double lineTotal;
  /// Qty already returned for this product on this sale.
  final double refundedQuantity;

  const SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    this.unit = 'pcs',
    required this.quantity,
    required this.unitPrice,
    this.unitCost = 0,
    this.discount = 0,
    this.tax = 0,
    required this.lineTotal,
    this.refundedQuantity = 0,
  });

  double get remainingQuantity {
    final left = quantity - refundedQuantity;
    return left > 0 ? left : 0;
  }

  factory SaleItem.fromMap(Map<String, Object?> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String? ?? 'Product',
      unit: map['unit'] as String? ?? 'pcs',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      lineTotal: (map['line_total'] as num?)?.toDouble() ?? 0,
      refundedQuantity: (map['refunded_qty'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SaleDetail {
  final Sale sale;
  final List<SaleItem> items;
  final List<PaymentInfo> payments;

  const SaleDetail({
    required this.sale,
    required this.items,
    this.payments = const [],
  });
}

class PaymentInfo {
  final String method;
  final double amount;
  final String? paidAt;

  const PaymentInfo({
    required this.method,
    required this.amount,
    this.paidAt,
  });

  factory PaymentInfo.fromMap(Map<String, Object?> map) {
    return PaymentInfo(
      method: map['method'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paidAt: map['paid_at'] as String?,
    );
  }
}

class Purchase {
  final int? id;
  final int? supplierId;
  final String? supplierName;
  final String? invoiceNumber;
  final String? purchaseDate;
  final double subtotal;
  final double tax;
  final double total;
  final String? notes;

  const Purchase({
    this.id,
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.purchaseDate,
    this.subtotal = 0,
    this.tax = 0,
    this.total = 0,
    this.notes,
  });

  factory Purchase.fromMap(Map<String, Object?> map) {
    return Purchase(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int?,
      supplierName: map['supplier_name'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      purchaseDate: map['purchase_date'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }
}

class DashboardStats {
  final double todaySales;
  final int todayTransactions;
  final double todayGrossProfit;
  final int lowStockCount;

  const DashboardStats({
    this.todaySales = 0,
    this.todayTransactions = 0,
    this.todayGrossProfit = 0,
    this.lowStockCount = 0,
  });
}

class ReportStats {
  final double totalRevenue;
  final double estimatedProfit;
  final int numberOfSales;
  final double averageSale;
  final List<TopProduct> topProducts;
  final List<PaymentBreakdown> payments;
  final List<DailySalesPoint> dailyTrend;

  const ReportStats({
    this.totalRevenue = 0,
    this.estimatedProfit = 0,
    this.numberOfSales = 0,
    this.averageSale = 0,
    this.topProducts = const [],
    this.payments = const [],
    this.dailyTrend = const [],
  });
}

class DailySalesPoint {
  final DateTime date;
  final double revenue;
  final int transactions;

  const DailySalesPoint({
    required this.date,
    this.revenue = 0,
    this.transactions = 0,
  });
}

class TopProduct {
  final String name;
  final double quantity;

  const TopProduct({required this.name, required this.quantity});
}

class PaymentBreakdown {
  final String method;
  final double amount;

  const PaymentBreakdown({required this.method, required this.amount});
}
