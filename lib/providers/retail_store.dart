import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../data/repositories/product_repository.dart';
import '../data/repositories/purchase_repository.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/staff.dart';

/// Offline app state for Shop X POS.
class RetailStore extends ChangeNotifier {
  RetailStore({
    ProductRepository? products,
    SaleRepository? sales,
    PurchaseRepository? purchases,
    StaffRepository? staff,
  })  : _products = products ?? ProductRepository(),
        _sales = sales ?? SaleRepository(),
        _purchases = purchases ?? PurchaseRepository(),
        _staff = staff ?? StaffRepository();

  final ProductRepository _products;
  final SaleRepository _sales;
  final PurchaseRepository _purchases;
  final StaffRepository _staff;

  List<Product> productList = [];
  List<Category> categories = [];
  List<Sale> recentSales = [];
  List<Sale> filteredSales = [];
  List<Purchase> purchaseList = [];
  List<Employee> employees = [];
  List<Shift> shiftHistory = [];
  List<StockMovement> stockHistory = [];
  List<Product> lowStockProducts = [];
  DashboardStats stats = const DashboardStats();
  ReportStats reportStats = const ReportStats();
  Shift? activeShift;
  ShiftSummary? activeShiftSummary;
  Employee? currentEmployee;
  final List<CartItem> cart = [];

  bool loading = true;
  String? error;
  String currencySymbol = '\$';
  String currencyCode = 'USD';
  String storeName = 'Shop X';
  String phone = '';
  String email = '';
  String address = '';
  String receiptHeader = '';
  String receiptFooter = '';
  String taxName = 'Sales Tax';
  double taxRate = 10;
  String taxType = 'exclusive';
  String language = 'en_US';
  bool darkMode = true;
  String systemName = 'Shop X';
  String appVersion = '1.0.0';
  String receiptPrefix = 'R';

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _loadSettings();
      await _reloadAll();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    final rows = await _products.getSettings();
    String get(String key, [String fallback = '']) => rows[key] ?? fallback;

    storeName = get('store_name', 'Shop X');
    currencyCode = get('currency', 'USD');
    currencySymbol = get('currency_symbol', '\$');
    phone = get('phone');
    email = get('email');
    address = get('address');
    receiptHeader = get('receipt_header');
    receiptFooter = get('receipt_footer');
    taxName = get('tax_name', 'Sales Tax');
    taxRate = double.tryParse(get('default_tax_rate', '10')) ?? 10;
    taxType = get('tax_type', 'exclusive');
    language = get('language', 'en_US');
    darkMode = get('dark_mode', '1') == '1';
    systemName = get('system_name', 'Shop X');
    appVersion = get('app_version', '1.0.0');
    receiptPrefix = get('receipt_prefix', 'R');
  }

  Future<void> saveSettings({
    required String storeName,
    required String phone,
    required String email,
    required String address,
    required String receiptHeader,
    required String receiptFooter,
    required String currencyCode,
    required String currencySymbol,
    required String taxName,
    required double taxRate,
    required String taxType,
    required String language,
    required bool darkMode,
  }) async {
    final map = {
      'store_name': storeName,
      'phone': phone,
      'email': email,
      'address': address,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'currency': currencyCode,
      'currency_symbol': currencySymbol,
      'tax_name': taxName,
      'default_tax_rate': taxRate.toString(),
      'tax_type': taxType,
      'language': language,
      'dark_mode': darkMode ? '1' : '0',
    };
    await _products.saveSettings(map);
    await _loadSettings();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _products.saveSettings({'dark_mode': value ? '1' : '0'});
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    await _products.saveSettings({'language': value});
    notifyListeners();
  }

  Future<void> _reloadAll() async {
    productList = await _products.getAll();
    categories = await _products.getCategories();
    recentSales = await _sales.recent();
    filteredSales = recentSales;
    purchaseList = await _purchases.getAll();
    employees = await _staff.getAll();
    shiftHistory = await _staff.shiftHistory();
    stockHistory = await _products.stockHistory();
    lowStockProducts = await _products.lowStockProducts();
    stats = await _sales.todayStats();
    activeShift = await _staff.currentOpenShift();
    if (activeShift?.id != null) {
      activeShiftSummary = await _staff.shiftSummary(activeShift!.id!);
    } else {
      activeShiftSummary = null;
    }
    currentEmployee ??= employees.isEmpty ? null : employees.first;
    final now = DateTime.now();
    reportStats = await _sales.reportStats(
      from: DateTime(now.year, now.month, 1),
      to: now,
    );
  }

  Future<void> refreshProducts() async {
    productList = await _products.getAll();
    categories = await _products.getCategories();
    lowStockProducts = await _products.lowStockProducts();
    stats = await _sales.todayStats();
    stockHistory = await _products.stockHistory();
    notifyListeners();
  }

  // --- Catalogue ---

  Future<void> addProduct(Product product) async {
    await _products.insert(product);
    await refreshProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _products.update(product);
    await refreshProducts();
  }

  Future<void> deactivateProduct(int id) async {
    await _products.delete(id);
    await refreshProducts();
  }

  Future<Product?> findProduct(String query) => _products.findByBarcodeOrSku(query.trim());

  Future<List<Product>> searchProducts(String query, {int? categoryId}) {
    if (query.trim().isEmpty) {
      return _products.getAll(activeOnly: true, categoryId: categoryId);
    }
    return _products.search(query.trim(), categoryId: categoryId);
  }

  Future<void> addCategory(String name, {String color = '#3B82F6'}) async {
    await _products.insertCategory(Category(name: name, color: color));
    categories = await _products.getCategories();
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    await _products.updateCategory(category);
    categories = await _products.getCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    await _products.deleteCategory(id);
    categories = await _products.getCategories();
    notifyListeners();
  }

  // --- Cart / POS ---

  void addToCart(Product product, {double qty = 1}) {
    final existing = cart.where((c) => c.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += qty;
    } else {
      cart.add(CartItem(product: product, quantity: qty));
    }
    notifyListeners();
  }

  void updateCartQty(int productId, double qty) {
    if (qty <= 0) {
      cart.removeWhere((c) => c.product.id == productId);
    } else {
      for (final item in cart) {
        if (item.product.id == productId) {
          item.quantity = qty;
          break;
        }
      }
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  double get cartSubtotal =>
      cart.fold(0.0, (sum, item) => sum + item.lineSubtotal - item.discount);

  double get cartTax => cart.fold(0.0, (sum, item) => sum + item.taxAmount);

  double get cartTotal => cartSubtotal + cartTax;

  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity.ceil());

  Future<Sale> checkout({String paymentMethod = 'cash'}) async {
    final sale = await _sales.checkout(
      items: List.from(cart),
      paymentMethod: paymentMethod,
      employeeId: currentEmployee?.id ?? activeShift?.employeeId ?? 1,
    );
    clearCart();
    recentSales = await _sales.recent();
    filteredSales = recentSales;
    await refreshProducts();
    if (activeShift?.id != null) {
      activeShiftSummary = await _staff.shiftSummary(activeShift!.id!);
    }
    return sale;
  }

  // --- Sales history ---

  Future<void> filterSales({DateTime? from, DateTime? to, int? employeeId}) async {
    filteredSales = await _sales.list(from: from, to: to, employeeId: employeeId);
    notifyListeners();
  }

  Future<SaleDetail?> saleDetail(int saleId) => _sales.getDetail(saleId);

  Future<void> refundSale({
    required int saleId,
    required Map<int, double> quantities,
    required String reason,
  }) async {
    await _sales.refundSale(
      saleId: saleId,
      productQuantities: quantities,
      reason: reason,
      employeeId: currentEmployee?.id ?? 1,
    );
    recentSales = await _sales.recent();
    filteredSales = recentSales;
    await refreshProducts();
  }

  // --- Inventory ---

  Future<void> adjustStock({
    required int productId,
    required double quantityDelta,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Adjustment reason is required');
    }
    await _products.adjustStock(
      productId: productId,
      quantityDelta: quantityDelta,
      reason: reason.trim(),
      employeeId: currentEmployee?.id ?? 1,
    );
    await refreshProducts();
  }

  Future<void> receivePurchase({
    required int productId,
    required double quantity,
    required double unitCost,
    String? invoiceNumber,
  }) async {
    await _purchases.receiveStock(
      lines: [
        PurchaseLine(productId: productId, quantity: quantity, unitCost: unitCost),
      ],
      invoiceNumber: invoiceNumber,
    );
    purchaseList = await _purchases.getAll();
    await refreshProducts();
  }

  // --- Staff ---

  void setCurrentEmployee(Employee employee) {
    currentEmployee = employee;
    notifyListeners();
  }

  Future<void> addEmployee(Employee employee) async {
    await _staff.insert(employee);
    employees = await _staff.getAll();
    notifyListeners();
  }

  Future<void> updateEmployee(Employee employee) async {
    await _staff.update(employee);
    employees = await _staff.getAll();
    notifyListeners();
  }

  // --- Shifts ---

  Future<void> openShift({required double openingCash}) async {
    final employeeId = currentEmployee?.id ?? 1;
    await _staff.openShift(employeeId: employeeId, openingCash: openingCash);
    activeShift = await _staff.currentOpenShift();
    if (activeShift?.id != null) {
      activeShiftSummary = await _staff.shiftSummary(activeShift!.id!);
    }
    shiftHistory = await _staff.shiftHistory();
    notifyListeners();
  }

  Future<void> cashIn({required double amount, String? note}) async {
    final shift = activeShift;
    if (shift?.id == null) throw StateError('No open shift');
    await _staff.addCashMovement(shiftId: shift!.id!, type: 'in', amount: amount, note: note);
    activeShiftSummary = await _staff.shiftSummary(shift.id!);
    notifyListeners();
  }

  Future<void> cashOut({required double amount, String? note}) async {
    final shift = activeShift;
    if (shift?.id == null) throw StateError('No open shift');
    await _staff.addCashMovement(shiftId: shift!.id!, type: 'out', amount: amount, note: note);
    activeShiftSummary = await _staff.shiftSummary(shift.id!);
    notifyListeners();
  }

  Future<void> closeShift({required double closingCash}) async {
    final shift = activeShift;
    if (shift?.id == null) throw StateError('No open shift');
    await _staff.closeShift(shiftId: shift!.id!, closingCash: closingCash);
    activeShift = await _staff.currentOpenShift();
    activeShiftSummary = null;
    shiftHistory = await _staff.shiftHistory();
    notifyListeners();
  }

  Future<ShiftSummary> getShiftSummary(int shiftId) => _staff.shiftSummary(shiftId);

  // --- Reports ---

  Future<void> loadReport({required DateTime from, required DateTime to}) async {
    reportStats = await _sales.reportStats(from: from, to: to);
    notifyListeners();
  }
}
