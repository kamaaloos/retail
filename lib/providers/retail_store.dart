import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../app_info.dart';
import '../data/product_images.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/held_cart_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/purchase_repository.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../licensing/license_document.dart';
import '../licensing/license_service.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/held_cart.dart';
import '../models/insufficient_stock.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/settings_config.dart';
import '../models/staff.dart';
import '../services/license_activation_api.dart';
import '../services/receipt_printer.dart';
import '../l10n/app_strings.dart';

/// Offline app state for Shop X POS.
class RetailStore extends ChangeNotifier {
  RetailStore({
    ProductRepository? products,
    SaleRepository? sales,
    PurchaseRepository? purchases,
    StaffRepository? staff,
    SettingsRepository? settings,
    CustomerRepository? customers,
    HeldCartRepository? heldCartsRepo,
  })  : _products = products ?? ProductRepository(),
        _sales = sales ?? SaleRepository(),
        _purchases = purchases ?? PurchaseRepository(),
        _staff = staff ?? StaffRepository(),
        _settings = settings ?? SettingsRepository(),
        _customers = customers ?? CustomerRepository(),
        _heldCartsRepo = heldCartsRepo ?? HeldCartRepository();

  final ProductRepository _products;
  final SaleRepository _sales;
  final PurchaseRepository _purchases;
  final StaffRepository _staff;
  final SettingsRepository _settings;
  final CustomerRepository _customers;
  final HeldCartRepository _heldCartsRepo;

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
  Employee? loggedInEmployee;
  bool isLoggedIn = false;
  /// True after login when the PIN is still the factory default `1234`.
  bool requiresPinChange = false;
  final List<CartItem> cart = [];
  final List<HeldCart> heldCarts = [];
  List<Customer> customers = [];
  Customer? selectedCustomer;
  int _heldCartSeq = 0;

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
  String systemName = 'MayleSoft retail';
  String appVersion = '1.0.0';
  String receiptPrefix = 'R';
  String storeLogoPath = '';
  List<DiscountRule> discountRules = [];
  List<PaymentMethodConfig> paymentMethods = [];
  List<PosDevice> posDevices = [];
  List<PrinterConfig> printers = [];
  NetworkSettings networkSettings = const NetworkSettings();
  LicenseStatus licenseStatus = const LicenseStatus(kind: LicenseAccessKind.blocked);
  String? machineId;

  bool get canSell => licenseStatus.allowsUse;

  List<PaymentMethodConfig> get enabledPaymentMethods =>
      paymentMethods.where((m) => m.enabled).toList();

  String paymentLabel(String code) {
    for (final method in paymentMethods) {
      if (method.code == code) return method.label;
    }
    return code;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _loadSettings();
      await _loadConfigSettings();
      await _reloadAll();
      await refreshLicense();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLicense() async {
    licenseStatus = await LicenseService.instance.refresh();
    machineId = LicenseService.instance.machineId;
    notifyListeners();
  }

  Future<void> activateLicenseBytes(List<int> bytes) async {
    licenseStatus = await LicenseService.instance.installLicenseBytes(bytes);
    machineId = LicenseService.instance.machineId;
    if (!licenseStatus.isLicensed) {
      throw StateError(licenseStatus.message ?? 'License not accepted');
    }
    notifyListeners();
  }

  /// Online activation: posts code + this PC's Machine ID, installs returned .lic.
  Future<void> activateWithCode(String code) async {
    final mid = machineId ?? LicenseService.instance.machineId;
    if (mid == null || mid.isEmpty) {
      await refreshLicense();
    }
    final id = machineId ?? LicenseService.instance.machineId;
    if (id == null || id.isEmpty) {
      throw StateError('Machine ID is not available yet');
    }
    final bytes = await LicenseActivationApi.activate(
      code: code,
      machineId: id,
      appVersion: AppInfo.versionLabel,
    );
    await activateLicenseBytes(bytes);
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
    systemName = get('system_name', 'MayleSoft retail');
    appVersion = AppInfo.version;
    receiptPrefix = get('receipt_prefix', 'R');
    storeLogoPath = get('store_logo');
    // Keep DB setting aligned with the shipping build for receipts / about.
    await _products.saveSettings({'app_version': AppInfo.version});
  }

  Future<void> _loadConfigSettings() async {
    discountRules = await _settings.getDiscounts();
    paymentMethods = await _settings.getPaymentMethods();
    posDevices = await _settings.getPosDevices();
    printers = await _settings.getPrinters();
    networkSettings = await _settings.getNetworkSettings();
  }

  Future<void> refreshConfigSettings() async {
    await _loadConfigSettings();
    _recalculateCartDiscounts();
    notifyListeners();
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
    String? pickedStoreLogoSource,
    bool clearStoreLogo = false,
  }) async {
    var logoPath = storeLogoPath;
    if (clearStoreLogo) {
      await StoreLogoStore.deleteIfExists(logoPath);
      logoPath = '';
    } else if (pickedStoreLogoSource != null) {
      await StoreLogoStore.deleteIfExists(logoPath);
      logoPath = await StoreLogoStore.saveFromPath(pickedStoreLogoSource);
    }

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
      'store_logo': logoPath,
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
    customers = await _customers.getAll();
    heldCarts
      ..clear()
      ..addAll(await _heldCartsRepo.listAll());
    if (heldCarts.isNotEmpty) {
      final maxSeq = heldCarts
          .map((h) {
            final m = RegExp(r'#(\d+)$').firstMatch(h.label);
            return int.tryParse(m?.group(1) ?? '') ?? 0;
          })
          .fold(0, (a, b) => a > b ? a : b);
      if (maxSeq > _heldCartSeq) _heldCartSeq = maxSeq;
    }
    stats = await _sales.todayStats();
    activeShift = await _staff.currentOpenShift();
    if (activeShift?.id != null) {
      activeShiftSummary = await _staff.shiftSummary(activeShift!.id!);
    } else {
      activeShiftSummary = null;
    }
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

  void _ensureQtyFitsStock(Product product, double requestedQty) {
    final available = product.stockOnHand < 0 ? 0.0 : product.stockOnHand;
    if (requestedQty > available + 0.0001) {
      throw InsufficientStockException(
        productName: product.name,
        requested: requestedQty,
        available: available,
      );
    }
  }

  void addToCart(Product product, {double qty = 1}) {
    final existing = cart.where((c) => c.product.id == product.id).toList();
    final nextQty = (existing.isEmpty ? 0.0 : existing.first.quantity) + qty;
    _ensureQtyFitsStock(product, nextQty);
    if (existing.isNotEmpty) {
      existing.first.quantity = nextQty;
    } else {
      cart.add(CartItem(product: product, quantity: qty));
    }
    _recalculateCartDiscounts();
    notifyListeners();
  }

  void updateCartQty(int productId, double qty) {
    if (qty <= 0) {
      cart.removeWhere((c) => c.product.id == productId);
    } else {
      for (final item in cart) {
        if (item.product.id == productId) {
          _ensureQtyFitsStock(item.product, qty);
          item.quantity = qty;
          break;
        }
      }
    }
    _recalculateCartDiscounts();
    notifyListeners();
  }

  /// Live stock check. Throws [InsufficientStockException] if any line exceeds on-hand qty.
  Future<void> assertCartHasStock() async {
    for (final item in cart) {
      final id = item.product.id;
      if (id == null) continue;
      final live = await _products.getById(id);
      final available = live?.stockOnHand ?? 0;
      if (item.quantity > available + 0.0001) {
        throw InsufficientStockException(
          productName: item.product.name,
          requested: item.quantity,
          available: available < 0 ? 0 : available,
        );
      }
    }
  }

  void clearCart() {
    cart.clear();
    selectedCustomer = null;
    notifyListeners();
  }

  void selectCustomer(Customer? customer) {
    selectedCustomer = customer;
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    await _customers.insert(customer);
    customers = await _customers.getAll();
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _customers.update(customer);
    customers = await _customers.getAll();
    if (selectedCustomer?.id == customer.id) {
      selectedCustomer = customers.where((c) => c.id == customer.id).firstOrNull ?? customer;
    }
    notifyListeners();
  }

  Future<void> deleteCustomer(int id) async {
    await _customers.delete(id);
    customers = await _customers.getAll();
    if (selectedCustomer?.id == id) selectedCustomer = null;
    notifyListeners();
  }

  /// Park the current cart so another customer can be served.
  Future<HeldCart> holdCurrentCart({String? note}) async {
    if (cart.isEmpty) {
      throw StateError('Cart is empty');
    }
    _heldCartSeq += 1;
    final label = (note == null || note.trim().isEmpty)
        ? 'Hold #$_heldCartSeq'
        : note.trim();
    final held = await _heldCartsRepo.insert(
      label: label,
      items: cart.map((item) => item.copy()).toList(),
      employeeId: currentEmployee?.id ?? loggedInEmployee?.id,
    );
    heldCarts.insert(0, held);
    cart.clear();
    selectedCustomer = null;
    notifyListeners();
    return held;
  }

  /// Restore a held cart. If the current cart has items, it is parked first.
  Future<HeldCart?> resumeHeldCart(String id, {bool holdCurrentIfNeeded = true}) async {
    final index = heldCarts.indexWhere((h) => h.id == id);
    if (index < 0) return null;

    HeldCart? parkedCurrent;
    if (cart.isNotEmpty && holdCurrentIfNeeded) {
      parkedCurrent = await holdCurrentCart();
    } else {
      cart.clear();
      selectedCustomer = null;
    }

    // Re-find after possible re-insert from holdCurrentCart.
    final resumeIndex = heldCarts.indexWhere((h) => h.id == id);
    if (resumeIndex < 0) return parkedCurrent;
    final held = heldCarts.removeAt(resumeIndex);
    await _heldCartsRepo.delete(id);
    cart.addAll(held.items.map((item) => item.copy()));
    _recalculateCartDiscounts();
    notifyListeners();
    return parkedCurrent;
  }

  Future<void> discardHeldCart(String id) async {
    await _heldCartsRepo.delete(id);
    heldCarts.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  void _recalculateCartDiscounts() {
    final now = DateTime.now();
    for (final item in cart) {
      item.discount = bestLineDiscount(
        productId: item.product.id,
        lineSubtotal: item.lineSubtotal,
        rules: discountRules,
        when: now,
      );
    }
  }

  double get cartDiscountTotal => cart.fold(0.0, (sum, item) => sum + item.discount);

  double get cartSubtotal =>
      cart.fold(0.0, (sum, item) => sum + item.lineSubtotal - item.discount);

  double get cartTax => cart.fold(0.0, (sum, item) => sum + item.taxAmount);

  double get cartTotal => cartSubtotal + cartTax;

  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity.ceil());

  Future<Sale> checkout({
    String paymentMethod = 'cash',
    List<({String method, double amount})>? payments,
    double? chargedTotal,
    int? customerId,
  }) async {
    if (!canSell) {
      throw StateError(licenseStatus.message ?? 'License required to sell');
    }
    if (activeShift == null) {
      throw StateError('Open a shift before selling');
    }
    await assertCartHasStock();
    final sale = await _sales.checkout(
      items: List.from(cart),
      paymentMethod: paymentMethod,
      payments: payments,
      employeeId: currentEmployee?.id ?? activeShift?.employeeId ?? 1,
      customerId: customerId ?? selectedCustomer?.id,
      chargedTotal: chargedTotal,
    );
    cart.clear();
    selectedCustomer = null;
    recentSales = await _sales.recent();
    filteredSales = recentSales;
    productList = await _products.getAll();
    categories = await _products.getCategories();
    lowStockProducts = await _products.lowStockProducts();
    stats = await _sales.todayStats();
    stockHistory = await _products.stockHistory();
    if (activeShift?.id != null) {
      activeShiftSummary = await _staff.shiftSummary(activeShift!.id!);
    }
    // Single notify after checkout so MaterialApp/dialogs aren't rebuilt mid-flight.
    notifyListeners();
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

  Future<bool> login({required String username, required String pin}) async {
    final employee = await _staff.authenticate(username: username, pin: pin);
    if (employee == null) return false;
    loggedInEmployee = employee;
    currentEmployee = employee;
    isLoggedIn = true;
    requiresPinChange = pin.trim() == '1234';
    notifyListeners();
    return true;
  }

  /// Replace the signed-in user's PIN. Rejects the factory default `1234`.
  Future<void> changeOwnPin({
    required String currentPin,
    required String newPin,
  }) async {
    final employee = loggedInEmployee;
    if (employee?.id == null) throw Exception('not_logged_in');
    final normalizedNew = newPin.trim();
    final normalizedCurrent = currentPin.trim();
    if (normalizedNew.length < 4) throw Exception('pin_too_short');
    if (normalizedNew == '1234') throw Exception('pin_is_default');
    final fresh = await _staff.authenticate(
      username: employee!.username ?? '',
      pin: normalizedCurrent,
    );
    if (fresh == null || fresh.id != employee.id) {
      throw Exception('wrong_current_pin');
    }
    await _staff.update(employee, pin: normalizedNew);
    employees = await _staff.getAll();
    loggedInEmployee = employees.firstWhere(
      (e) => e.id == employee.id,
      orElse: () => employee,
    );
    currentEmployee = loggedInEmployee;
    requiresPinChange = false;
    notifyListeners();
  }

  void logout() {
    loggedInEmployee = null;
    currentEmployee = null;
    isLoggedIn = false;
    requiresPinChange = false;
    cart.clear();
    selectedCustomer = null;
    notifyListeners();
  }

  void setCurrentEmployee(Employee employee) {
    currentEmployee = employee;
    notifyListeners();
  }

  Future<void> addEmployee(Employee employee, {String? pin}) async {
    await _staff.insert(employee, pin: pin);
    employees = await _staff.getAll();
    notifyListeners();
  }

  Future<void> updateEmployee(Employee employee, {String? pin}) async {
    await _staff.update(employee, pin: pin);
    employees = await _staff.getAll();
    if (currentEmployee?.id == employee.id) {
      currentEmployee = employees.firstWhere(
        (e) => e.id == employee.id,
        orElse: () => currentEmployee!,
      );
    }
    if (loggedInEmployee?.id == employee.id) {
      loggedInEmployee = employees.firstWhere(
        (e) => e.id == employee.id,
        orElse: () => loggedInEmployee!,
      );
    }
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

  Future<ShiftSummary> closeShift({required double closingCash}) async {
    final shift = activeShift;
    if (shift?.id == null) throw StateError('No open shift');
    final shiftId = shift!.id!;
    await _staff.closeShift(shiftId: shiftId, closingCash: closingCash);
    final summary = await _staff.shiftSummary(shiftId);
    activeShift = await _staff.currentOpenShift();
    activeShiftSummary = null;
    shiftHistory = await _staff.shiftHistory();
    notifyListeners();
    return summary;
  }

  Future<ShiftSummary> getShiftSummary(int shiftId) => _staff.shiftSummary(shiftId);

  // --- Reports ---

  Future<void> loadReport({required DateTime from, required DateTime to}) async {
    reportStats = await _sales.reportStats(from: from, to: to);
    notifyListeners();
  }

  // --- Discounts ---

  Future<void> addDiscount(DiscountRule rule) async {
    await _settings.insertDiscount(rule);
    await refreshConfigSettings();
  }

  Future<void> updateDiscount(DiscountRule rule) async {
    await _settings.updateDiscount(rule);
    await refreshConfigSettings();
  }

  Future<void> deleteDiscount(int id) async {
    await _settings.deleteDiscount(id);
    await refreshConfigSettings();
  }

  // --- Payment methods ---

  Future<void> addPaymentMethod(PaymentMethodConfig method) async {
    await _settings.insertPaymentMethod(method);
    await refreshConfigSettings();
  }

  Future<void> updatePaymentMethod(PaymentMethodConfig method) async {
    await _settings.updatePaymentMethod(method);
    await refreshConfigSettings();
  }

  Future<void> deletePaymentMethod(int id) async {
    await _settings.deletePaymentMethod(id);
    await refreshConfigSettings();
  }

  // --- POS devices ---

  Future<void> addPosDevice(PosDevice device) async {
    await _settings.insertPosDevice(device);
    await refreshConfigSettings();
  }

  Future<void> updatePosDevice(PosDevice device) async {
    await _settings.updatePosDevice(device);
    await refreshConfigSettings();
  }

  Future<void> deletePosDevice(int id) async {
    await _settings.deletePosDevice(id);
    await refreshConfigSettings();
  }

  // --- Printers ---

  Future<void> addPrinter(PrinterConfig printer) async {
    await _settings.insertPrinter(printer);
    await refreshConfigSettings();
  }

  Future<void> updatePrinter(PrinterConfig printer) async {
    await _settings.updatePrinter(printer);
    await refreshConfigSettings();
  }

  Future<void> deletePrinter(int id) async {
    await _settings.deletePrinter(id);
    await refreshConfigSettings();
  }

  ReceiptStoreInfo get receiptStoreInfo => ReceiptStoreInfo(
        storeName: storeName,
        phone: phone,
        email: email,
        address: address,
        receiptHeader: receiptHeader,
        receiptFooter: receiptFooter,
        currencySymbol: currencySymbol,
        taxName: taxName,
        logoPath: storeLogoPath.isEmpty ? null : storeLogoPath,
      );

  Future<void> printSaleReceipt(
    SaleDetail detail, {
    double? amountReceived,
    double? change,
    bool forceDialog = false,
  }) {
    final t = AppStrings.of(language);
    return ReceiptPrinter.printSale(
      detail: detail,
      store: receiptStoreInfo,
      t: t,
      paymentLabel: paymentLabel,
      printers: printers,
      options: ReceiptPrintOptions(
        amountReceived: amountReceived,
        change: change,
        forceDialog: forceDialog,
        paperWidthMm: ReceiptPrinter.defaultPrinter(printers)?.paperWidth ?? 80,
      ),
    );
  }

  Future<void> printTestReceipt({PrinterConfig? printer}) {
    final t = AppStrings.of(language);
    return ReceiptPrinter.printTest(
      store: receiptStoreInfo,
      t: t,
      printer: printer ?? ReceiptPrinter.defaultPrinter(printers),
    );
  }

  Future<void> printZReport(
    ShiftSummary summary, {
    double? countedCash,
    bool forceDialog = false,
  }) {
    final t = AppStrings.of(language);
    return ReceiptPrinter.printZReport(
      summary: summary,
      store: receiptStoreInfo,
      t: t,
      paymentLabel: paymentLabel,
      printers: printers,
      countedCash: countedCash,
      forceDialog: forceDialog,
    );
  }

  // --- Network ---

  Future<void> saveNetworkSettings(NetworkSettings settings) async {
    await _settings.saveNetworkSettings(settings);
    networkSettings = settings;
    notifyListeners();
  }

  // --- Backup ---

  Future<String> exportBackup(String destinationPath) => _settings.exportDatabase(destinationPath);

  Future<void> restoreBackup(String sourcePath) async {
    await _settings.restoreDatabase(sourcePath);
    await load();
  }

  String suggestedBackupName() => _settings.suggestedBackupName();

  String get databaseDirectory => _settings.databaseDirectory;

  String get databasePath => _settings.databasePath;
}
