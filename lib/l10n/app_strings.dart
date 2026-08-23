import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Offline UI strings for Settings → Language.
class AppStrings {
  AppStrings._(this.code);

  final String code;

  static AppStrings of(String languageCode) => AppStrings._(languageCode);

  /// Native display names shown in the language picker.
  static const supported = <String, String>{
    'en_US': 'English (US)',
    'en_GB': 'English (UK)',
    'fr_FR': 'Français',
    'ar_SA': 'العربية',
    'so_SO': 'Soomaali',
  };

  Locale get locale {
    final parts = code.split('_');
    if (parts.length >= 2) return Locale(parts[0], parts[1]);
    return Locale(parts.first);
  }

  /// Flutter Material widgets only ship localizations for select locales.
  /// Custom [AppStrings] still uses [code] (e.g. so_SO) for app copy.
  Locale get materialLocale {
    if (code.startsWith('so')) return const Locale('en', 'US');
    return locale;
  }

  String get intlLocale {
    if (code.startsWith('so')) return 'en'; // Somali date symbols fallback
    return code;
  }

  bool get isRtl => code.startsWith('ar');

  String get(String key) {
    final table = _tables[code] ?? _tables['en_US']!;
    return table[key] ?? _tables['en_US']![key] ?? key;
  }

  String formatDate(DateTime dt, {String pattern = 'd MMMM yyyy، HH:mm'}) {
    final usePattern = isRtl ? pattern : 'd MMM yyyy, HH:mm';
    try {
      return DateFormat(usePattern, intlLocale).format(dt);
    } catch (_) {
      try {
        return DateFormat(usePattern, isRtl ? 'ar' : 'en').format(dt);
      } catch (_) {
        return DateFormat('d MMM yyyy, HH:mm').format(dt);
      }
    }
  }

  String formatDateIso(String? iso, {String pattern = 'd MMMM yyyy، HH:mm'}) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return formatDate(dt, pattern: pattern);
  }

  String saleStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return statusCompleted;
      case 'refunded':
        return statusRefunded;
      case 'partial_refund':
      case 'partially_refunded':
        return statusPartialRefund;
      case 'void':
      case 'voided':
        return statusVoided;
      default:
        return status;
    }
  }

  String shiftStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return statusOpen;
      case 'closed':
        return statusClosedShift;
      default:
        return status;
    }
  }

  String roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return roleOwner;
      case 'admin':
        return roleAdmin;
      case 'manager':
        return roleManager;
      case 'cashier':
        return roleCashier;
      default:
        return role;
    }
  }

  String paymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return payCash;
      case 'card':
        return payCard;
      case 'mobile':
        return payMobile;
      default:
        return method;
    }
  }

  String get appName => get('appName');
  String get dashboard => get('dashboard');
  String get pos => get('pos');
  String get products => get('products');
  String get categories => get('categories');
  String get salesHistory => get('salesHistory');
  String get inventory => get('inventory');
  String get staff => get('staff');
  String get shifts => get('shifts');
  String get reports => get('reports');
  String get settings => get('settings');
  String get saveSettings => get('saveSettings');
  String get appearance => get('appearance');
  String get darkMode => get('darkMode');
  String get language => get('language');
  String get settingsSaved => get('settingsSaved');
  String get businessInfo => get('businessInfo');
  String get about => get('about');
  String get settingsSubtitle => get('settingsSubtitle');

  String get dashboardSubtitle => get('dashboardSubtitle');
  String get openPos => get('openPos');
  String get todaySales => get('todaySales');
  String get transactions => get('transactions');
  String get grossProfit => get('grossProfit');
  String get lowStock => get('lowStock');
  String get recentSales => get('recentSales');
  String get noSalesYet => get('noSalesYet');
  String get lowStockAlerts => get('lowStockAlerts');
  String get stockLabel => get('stockLabel');
  String get reorderLabel => get('reorderLabel');
  String get lowBadge => get('lowBadge');
  String get staffFallback => get('staffFallback');
  String get adminFallback => get('adminFallback');

  String get statusCompleted => get('statusCompleted');
  String get statusRefunded => get('statusRefunded');
  String get statusPartialRefund => get('statusPartialRefund');
  String get statusVoided => get('statusVoided');

  String get posTitle => get('posTitle');
  String get posSubtitle => get('posSubtitle');
  String get productsSubtitle => get('productsSubtitle');
  String get newProduct => get('newProduct');
  String get noProductsYet => get('noProductsYet');
  String get categoriesSubtitle => get('categoriesSubtitle');
  String get newCategory => get('newCategory');
  String get noCategoriesYet => get('noCategoriesYet');
  String get salesHistorySubtitle => get('salesHistorySubtitle');
  String get inventorySubtitle => get('inventorySubtitle');
  String get receiveStock => get('receiveStock');
  String get staffSubtitle => get('staffSubtitle');
  String get addEmployee => get('addEmployee');
  String get shiftsSubtitle => get('shiftsSubtitle');
  String get reportsSubtitle => get('reportsSubtitle');

  // Settings form
  String get tabGeneral => get('tabGeneral');
  String get tabDiscounts => get('tabDiscounts');
  String get tabPaymentMethods => get('tabPaymentMethods');
  String get tabPosDevices => get('tabPosDevices');
  String get tabPrinters => get('tabPrinters');
  String get tabBackup => get('tabBackup');
  String get tabNetwork => get('tabNetwork');
  String get discountsSubtitle => get('discountsSubtitle');
  String get addDiscount => get('addDiscount');
  String get editDiscount => get('editDiscount');
  String get noDiscountsYet => get('noDiscountsYet');
  String get discountName => get('discountName');
  String get discountType => get('discountType');
  String get discountPercent => get('discountPercent');
  String get discountFixed => get('discountFixed');
  String get discountValue => get('discountValue');
  String get minPurchase => get('minPurchase');
  String get discountPercentSummary => get('discountPercentSummary');
  String get discountFixedSummary => get('discountFixedSummary');
  String get deleteDiscountConfirm => get('deleteDiscountConfirm');
  String get discountScope => get('discountScope');
  String get discountScopeAll => get('discountScopeAll');
  String get discountScopeProducts => get('discountScopeProducts');
  String get discountProductCount => get('discountProductCount');
  String get discountStartDate => get('discountStartDate');
  String get discountEndDate => get('discountEndDate');
  String get discountSelectProducts => get('discountSelectProducts');
  String get discountProductsRequired => get('discountProductsRequired');
  String get discountAlways => get('discountAlways');
  String get discountFromTo => get('discountFromTo');
  String get discountFromOnly => get('discountFromOnly');
  String get discountUntilOnly => get('discountUntilOnly');
  String get discountOff => get('discountOff');
  String get cartDiscount => get('cartDiscount');
  String get paymentMethodsSubtitle => get('paymentMethodsSubtitle');
  String get addPaymentMethod => get('addPaymentMethod');
  String get editPaymentMethod => get('editPaymentMethod');
  String get noPaymentMethodsYet => get('noPaymentMethodsYet');
  String get methodCode => get('methodCode');
  String get methodLabel => get('methodLabel');
  String get enabled => get('enabled');
  String get deletePaymentMethodConfirm => get('deletePaymentMethodConfirm');
  String get atLeastOnePaymentMethod => get('atLeastOnePaymentMethod');
  String get posDevicesSubtitle => get('posDevicesSubtitle');
  String get addPosDevice => get('addPosDevice');
  String get editPosDevice => get('editPosDevice');
  String get noPosDevicesYet => get('noPosDevicesYet');
  String get deviceName => get('deviceName');
  String get deviceType => get('deviceType');
  String get deviceIdentifier => get('deviceIdentifier');
  String get deviceNotes => get('deviceNotes');
  String get deviceTypeTerminal => get('deviceTypeTerminal');
  String get deviceTypeTablet => get('deviceTypeTablet');
  String get deviceTypeScanner => get('deviceTypeScanner');
  String get deletePosDeviceConfirm => get('deletePosDeviceConfirm');
  String get printersSubtitle => get('printersSubtitle');
  String get addPrinter => get('addPrinter');
  String get editPrinter => get('editPrinter');
  String get noPrintersYet => get('noPrintersYet');
  String get printerName => get('printerName');
  String get printerType => get('printerType');
  String get printerConnection => get('printerConnection');
  String get printerAddress => get('printerAddress');
  String get paperWidth => get('paperWidth');
  String get defaultPrinter => get('defaultPrinter');
  String get printerTypeReceipt => get('printerTypeReceipt');
  String get printerTypeLabel => get('printerTypeLabel');
  String get connectionUsb => get('connectionUsb');
  String get connectionNetwork => get('connectionNetwork');
  String get connectionBluetooth => get('connectionBluetooth');
  String get deletePrinterConfirm => get('deletePrinterConfirm');
  String get backupSubtitle => get('backupSubtitle');
  String get exportBackup => get('exportBackup');
  String get importBackup => get('importBackup');
  String get backupExported => get('backupExported');
  String get backupRestored => get('backupRestored');
  String get backupRestoreConfirm => get('backupRestoreConfirm');
  String get backupRestoreWarning => get('backupRestoreWarning');
  String get backupLocation => get('backupLocation');
  String get networkSubtitle => get('networkSubtitle');
  String get networkEnabled => get('networkEnabled');
  String get networkEnabledHint => get('networkEnabledHint');
  String get serverUrl => get('serverUrl');
  String get terminalName => get('terminalName');
  String get syncInterval => get('syncInterval');
  String get syncIntervalHint => get('syncIntervalHint');
  String get minutes => get('minutes');
  String get networkSaved => get('networkSaved');
  String get nameRequired => get('nameRequired');
  String get invalidUrl => get('invalidUrl');
  String get storeName => get('storeName');
  String get phone => get('phone');
  String get email => get('email');
  String get address => get('address');
  String get receiptHeader => get('receiptHeader');
  String get receiptFooter => get('receiptFooter');
  String get currencyCode => get('currencyCode');
  String get currencySymbol => get('currencySymbol');
  String get taxName => get('taxName');
  String get taxRate => get('taxRate');
  String get taxType => get('taxType');
  String get taxExclusive => get('taxExclusive');
  String get taxInclusive => get('taxInclusive');
  String get storeLogo => get('storeLogo');
  String get storeLogoHint => get('storeLogoHint');
  String get uploadLogo => get('uploadLogo');
  String get logoUploadLater => get('logoUploadLater');
  String get version => get('version');
  String get systemName => get('systemName');
  String get copyrightNotice => get('copyrightNotice');
  String get comingSoon => get('comingSoon');
  String get comingSoonBody => get('comingSoonBody');
  String get couldNotSave => get('couldNotSave');

  String get searchHint => get('searchHint');
  String get allCategories => get('allCategories');
  String get noProductsFound => get('noProductsFound');
  String get cart => get('cart');
  String get clearCart => get('clearCart');
  String get cartItemsCount => get('cartItemsCount');
  String get tapProductsToAdd => get('tapProductsToAdd');
  String get subtotal => get('subtotal');
  String get tax => get('tax');
  String get total => get('total');
  String get chargeBtn => get('chargeBtn');
  String get cartEmpty => get('cartEmpty');
  String get chargeTitle => get('chargeTitle');
  String get payCash => get('payCash');
  String get payCard => get('payCard');
  String get payMobile => get('payMobile');
  String get periodDaily => get('periodDaily');
  String get periodWeekly => get('periodWeekly');
  String get periodMonthly => get('periodMonthly');
  String get revenue => get('revenue');
  String get estProfit => get('estProfit');
  String get salesCount => get('salesCount');
  String get avgSale => get('avgSale');
  String get topProducts => get('topProducts');
  String get noSalesInPeriod => get('noSalesInPeriod');
  String get paymentBreakdown => get('paymentBreakdown');
  String get noPaymentsYet => get('noPaymentsYet');
  String get salesTrend => get('salesTrend');
  String get revenueVsProfit => get('revenueVsProfit');
  String get shiftOpen => get('shiftOpen');
  String get noActiveShift => get('noActiveShift');
  String get openShiftHint => get('openShiftHint');
  String get openShiftBtn => get('openShiftBtn');
  String get cashInBtn => get('cashInBtn');
  String get cashOutBtn => get('cashOutBtn');
  String get closeBtn => get('closeBtn');
  String get openingCash => get('openingCash');
  String get cashSales => get('cashSales');
  String get cashInOut => get('cashInOut');
  String get expectedCash => get('expectedCash');
  String get cashMovements => get('cashMovements');
  String get noMovementsYet => get('noMovementsYet');
  String get shiftHistoryTitle => get('shiftHistoryTitle');
  String get noShiftsYet => get('noShiftsYet');
  String get colEmployee => get('colEmployee');
  String get colOpened => get('colOpened');
  String get colClosed => get('colClosed');
  String get colOpening => get('colOpening');
  String get colClosing => get('colClosing');
  String get colExpected => get('colExpected');
  String get colDiff => get('colDiff');
  String get colStatus => get('colStatus');
  String get statusOpen => get('statusOpen');
  String get statusClosedShift => get('statusClosedShift');
  String get movementIn => get('movementIn');
  String get movementOut => get('movementOut');

  String get cancel => get('cancel');
  String get ok => get('ok');
  String get save => get('save');
  String get apply => get('apply');
  String get delete => get('delete');
  String get set => get('set');
  String get remove => get('remove');
  String get upload => get('upload');
  String get none => get('none');
  String get active => get('active');
  String get inactive => get('inactive');
  String get amount => get('amount');
  String get note => get('note');
  String get noteOptional => get('noteOptional');
  String get reason => get('reason');
  String get quantityTitle => get('quantityTitle');
  String get qtyLabel => get('qtyLabel');
  String get saleCompleted => get('saleCompleted');
  String get editProduct => get('editProduct');
  String get productAdded => get('productAdded');
  String get productUpdated => get('productUpdated');
  String get productDeactivated => get('productDeactivated');
  String get deactivateProduct => get('deactivateProduct');
  String get deactivateBtn => get('deactivateBtn');
  String get deactivateProductConfirm => get('deactivateProductConfirm');
  String get productImage => get('productImage');
  String get colName => get('colName');
  String get colPrice => get('colPrice');
  String get colCost => get('colCost');
  String get colStock => get('colStock');
  String get colSkuBarcode => get('colSkuBarcode');
  String get colCategory => get('colCategory');
  String get sku => get('sku');
  String get barcode => get('barcode');
  String get unitLabel => get('unitLabel');
  String get sellingPrice => get('sellingPrice');
  String get costLabel => get('costLabel');
  String get taxPercent => get('taxPercent');
  String get reorderLevel => get('reorderLevel');
  String get color => get('color');
  String get couldNotSaveImage => get('couldNotSaveImage');
  String get editCategory => get('editCategory');
  String get deleteCategory => get('deleteCategory');
  String get deleteCategoryConfirm => get('deleteCategoryConfirm');
  String get categoryProductCount => get('categoryProductCount');
  String get filterFrom => get('filterFrom');
  String get filterTo => get('filterTo');
  String get allStaff => get('allStaff');
  String get employee => get('employee');
  String get refund => get('refund');
  String get refundReason => get('refundReason');
  String get saleRefunded => get('saleRefunded');
  String get adjustStockTitle => get('adjustStockTitle');
  String get currentStock => get('currentStock');
  String get quantityDelta => get('quantityDelta');
  String get reasonRequired => get('reasonRequired');
  String get stockAdjusted => get('stockAdjusted');
  String get productLabel => get('productLabel');
  String get quantity => get('quantity');
  String get unitCost => get('unitCost');
  String get invoiceOptional => get('invoiceOptional');
  String get stockReceived => get('stockReceived');
  String get noProducts => get('noProducts');
  String get adjustBtn => get('adjustBtn');
  String get receiveBtn => get('receiveBtn');
  String get reorderLine => get('reorderLine');
  String get recentMovements => get('recentMovements');
  String get productFallback => get('productFallback');
  String get editEmployee => get('editEmployee');
  String get noEmployeesYet => get('noEmployeesYet');
  String get username => get('username');
  String get role => get('role');
  String get setCurrent => get('setCurrent');
  String get badgeCurrent => get('badgeCurrent');
  String get shiftOpened => get('shiftOpened');
  String get shiftClosed => get('shiftClosed');
  String get cashInRecorded => get('cashInRecorded');
  String get cashOutRecorded => get('cashOutRecorded');
  String get roleOwner => get('roleOwner');
  String get roleAdmin => get('roleAdmin');
  String get roleManager => get('roleManager');
  String get roleCashier => get('roleCashier');

  String get signIn => get('signIn');
  String get loginSubtitle => get('loginSubtitle');
  String get pin => get('pin');
  String get pinHint => get('pinHint');
  String get pinRequired => get('pinRequired');
  String get pinTooShort => get('pinTooShort');
  String get usernameRequired => get('usernameRequired');
  String get invalidCredentials => get('invalidCredentials');
  String get loginHint => get('loginHint');
  String get keepCurrentPin => get('keepCurrentPin');
  String get accessDenied => get('accessDenied');

  List<(IconData, String)> get settingsTabs => [
        (Icons.tune, tabGeneral),
        (Icons.percent, tabDiscounts),
        (Icons.payments_outlined, tabPaymentMethods),
        (Icons.devices, tabPosDevices),
        (Icons.print_outlined, tabPrinters),
        (Icons.backup_outlined, tabBackup),
        (Icons.wifi, tabNetwork),
      ];

  static const _baseEn = <String, String>{
    'appName': 'MayleSoft retail',
    'dashboard': 'Dashboard',
    'pos': 'POS',
    'products': 'Products',
    'categories': 'Categories',
    'salesHistory': 'Sales History',
    'inventory': 'Inventory',
    'staff': 'Staff',
    'shifts': 'Shifts',
    'reports': 'Reports',
    'settings': 'Settings',
    'saveSettings': 'Save Settings',
    'appearance': 'Appearance',
    'darkMode': 'Dark Mode',
    'language': 'Language',
    'settingsSaved': 'Settings saved',
    'businessInfo': 'Business Information',
    'about': 'About',
    'settingsSubtitle': 'Business, tax, currency and app preferences',
    'dashboardSubtitle': 'Offline POS overview · {store}',
    'openPos': 'Open POS',
    'todaySales': 'Today Sales',
    'transactions': 'Transactions',
    'grossProfit': 'Gross Profit',
    'lowStock': 'Low Stock',
    'recentSales': 'Recent sales',
    'noSalesYet': 'No sales yet. Ring one up from POS.',
    'lowStockAlerts': 'Low stock alerts',
    'stockLabel': 'Stock',
    'reorderLabel': 'reorder',
    'lowBadge': 'LOW',
    'staffFallback': 'Staff',
    'adminFallback': 'Admin',
    'statusCompleted': 'completed',
    'statusRefunded': 'refunded',
    'statusPartialRefund': 'partial refund',
    'statusVoided': 'voided',
    'posTitle': 'Point of Sale',
    'posSubtitle': 'Scan, search, or tap products',
    'productsSubtitle': '{count} active products',
    'newProduct': 'New Product',
    'noProductsYet': 'No products yet',
    'categoriesSubtitle': '{count} categories',
    'newCategory': 'New Category',
    'noCategoriesYet': 'No categories yet',
    'salesHistorySubtitle': 'Filter and review receipts',
    'inventorySubtitle': 'Stock levels, adjustments & receiving',
    'receiveStock': 'Receive Stock',
    'staffSubtitle': 'Employees & current cashier',
    'addEmployee': 'Add Employee',
    'shiftsSubtitle': 'Cash drawer & shift history',
    'reportsSubtitle': 'Revenue, products & payments',
    'tabGeneral': 'General',
    'tabDiscounts': 'Discounts',
    'tabPaymentMethods': 'Payment Methods',
    'tabPosDevices': 'POS Devices',
    'tabPrinters': 'Printers',
    'tabBackup': 'Backup & Restore',
    'tabNetwork': 'Network',
    'discountsSubtitle': 'Product or store-wide discounts with optional date ranges',
    'addDiscount': 'Add Discount',
    'editDiscount': 'Edit Discount',
    'noDiscountsYet': 'No discount rules yet',
    'discountName': 'Discount name',
    'discountType': 'Type',
    'discountPercent': 'Percentage',
    'discountFixed': 'Fixed amount',
    'discountValue': 'Value',
    'minPurchase': 'Minimum purchase',
    'discountPercentSummary': '{value}% off',
    'discountFixedSummary': '{value} off',
    'deleteDiscountConfirm': 'Delete discount «{name}»?',
    'discountScope': 'Applies to',
    'discountScopeAll': 'All products',
    'discountScopeProducts': 'Selected products',
    'discountProductCount': '{count} products',
    'discountStartDate': 'Start date',
    'discountEndDate': 'End date',
    'discountSelectProducts': 'Select products',
    'discountProductsRequired': 'Select at least one product',
    'discountAlways': 'Any time',
    'discountFromTo': '{from} – {to}',
    'discountFromOnly': 'From {from}',
    'discountUntilOnly': 'Until {to}',
    'discountOff': 'Discount',
    'cartDiscount': 'Discount',
    'paymentMethodsSubtitle': 'Choose which payment options appear at checkout',
    'addPaymentMethod': 'Add Payment Method',
    'editPaymentMethod': 'Edit Payment Method',
    'noPaymentMethodsYet': 'No payment methods configured',
    'methodCode': 'Code',
    'methodLabel': 'Display label',
    'enabled': 'Enabled',
    'deletePaymentMethodConfirm': 'Delete payment method «{name}»?',
    'atLeastOnePaymentMethod': 'At least one payment method must stay enabled',
    'posDevicesSubtitle': 'Register terminals, tablets, and scanners',
    'addPosDevice': 'Add Device',
    'editPosDevice': 'Edit Device',
    'noPosDevicesYet': 'No POS devices registered',
    'deviceName': 'Device name',
    'deviceType': 'Device type',
    'deviceIdentifier': 'Identifier / serial',
    'deviceNotes': 'Notes',
    'deviceTypeTerminal': 'Terminal',
    'deviceTypeTablet': 'Tablet',
    'deviceTypeScanner': 'Scanner',
    'deletePosDeviceConfirm': 'Remove device «{name}»?',
    'printersSubtitle': 'Receipt and label printers for this terminal',
    'addPrinter': 'Add Printer',
    'editPrinter': 'Edit Printer',
    'noPrintersYet': 'No printers configured',
    'printerName': 'Printer name',
    'printerType': 'Printer type',
    'printerConnection': 'Connection',
    'printerAddress': 'Address / port',
    'paperWidth': 'Paper width (mm)',
    'defaultPrinter': 'Default receipt printer',
    'printerTypeReceipt': 'Receipt',
    'printerTypeLabel': 'Label',
    'connectionUsb': 'USB',
    'connectionNetwork': 'Network',
    'connectionBluetooth': 'Bluetooth',
    'deletePrinterConfirm': 'Delete printer «{name}»?',
    'backupSubtitle': 'Export or restore your local database',
    'exportBackup': 'Export Backup',
    'importBackup': 'Import Backup',
    'backupExported': 'Backup saved to {path}',
    'backupRestored': 'Backup restored successfully',
    'backupRestoreConfirm': 'Restore backup?',
    'backupRestoreWarning': 'This replaces all current data with the backup file. Continue?',
    'backupLocation': 'Database folder: {path}',
    'networkSubtitle': 'Multi-terminal sync settings (server required)',
    'networkEnabled': 'Enable network sync',
    'networkEnabledHint': 'When enabled, this terminal can sync with a MayleSoft server',
    'serverUrl': 'Server URL',
    'terminalName': 'Terminal name',
    'syncInterval': 'Sync interval',
    'syncIntervalHint': 'How often to check for updates',
    'minutes': 'minutes',
    'networkSaved': 'Network settings saved',
    'nameRequired': 'Name is required',
    'invalidUrl': 'Enter a valid http or https URL',
    'storeName': 'Store Name',
    'phone': 'Phone',
    'email': 'Email',
    'address': 'Address',
    'receiptHeader': 'Receipt Header',
    'receiptFooter': 'Receipt Footer',
    'currencyCode': 'Currency Code',
    'currencySymbol': 'Currency Symbol',
    'taxName': 'Tax Name',
    'taxRate': 'Tax Rate %',
    'taxType': 'Tax Type',
    'taxExclusive': 'Exclusive',
    'taxInclusive': 'Inclusive',
    'storeLogo': 'Store Logo',
    'storeLogoHint': 'Square logo recommended (e.g. 400×400). Used for receipts and branding.',
    'uploadLogo': 'Upload Logo',
    'logoUploadLater': 'Logo upload will be available in a later update',
    'version': 'Version',
    'systemName': 'System name',
    'copyrightNotice': 'Copyright 2026 - MayleSoft retail, designed by Eng. Hasan Kamaal',
    'comingSoon': '{title} coming soon',
    'comingSoonBody': 'This section is reserved for upcoming MayleSoft retail configuration options.',
    'couldNotSave': 'Could not save: {error}',
    'searchHint': 'Search name, SKU or barcode…',
    'allCategories': 'All',
    'noProductsFound': 'No products found',
    'cart': 'Cart',
    'clearCart': 'Clear',
    'cartItemsCount': '{count} items',
    'tapProductsToAdd': 'Tap products to add',
    'subtotal': 'Subtotal',
    'tax': 'Tax',
    'total': 'Total',
    'chargeBtn': 'Charge {amount}',
    'cartEmpty': 'Cart is empty',
    'chargeTitle': 'Charge',
    'payCash': 'Cash',
    'payCard': 'Card',
    'payMobile': 'Mobile',
    'periodDaily': 'Daily',
    'periodWeekly': 'Weekly',
    'periodMonthly': 'Monthly',
    'revenue': 'Revenue',
    'estProfit': 'Est. Profit',
    'salesCount': 'Sales',
    'avgSale': 'Avg sale',
    'topProducts': 'Top products',
    'noSalesInPeriod': 'No sales in this period',
    'paymentBreakdown': 'Payment breakdown',
    'salesTrend': 'Sales trend',
    'revenueVsProfit': 'Revenue vs profit',
    'noPaymentsYet': 'No payments yet',
    'shiftOpen': 'Shift open',
    'noActiveShift': 'No active shift',
    'openShiftHint': 'Open a shift to start selling with a cash drawer',
    'openShiftBtn': 'Open shift',
    'cashInBtn': 'Cash in',
    'cashOutBtn': 'Cash out',
    'closeBtn': 'Close',
    'openingCash': 'Opening cash',
    'cashSales': 'Cash sales',
    'cashInOut': 'Cash in / out',
    'expectedCash': 'Expected cash',
    'cashMovements': 'Cash movements',
    'noMovementsYet': 'No movements yet',
    'shiftHistoryTitle': 'Shift history',
    'noShiftsYet': 'No shifts yet',
    'colEmployee': 'Employee',
    'colOpened': 'Opened',
    'colClosed': 'Closed',
    'colOpening': 'Opening',
    'colClosing': 'Closing',
    'colExpected': 'Expected',
    'colDiff': 'Diff',
    'colStatus': 'Status',
    'statusOpen': 'open',
    'statusClosedShift': 'closed',
    'movementIn': 'IN',
    'movementOut': 'OUT',
    'cancel': 'Cancel',
    'ok': 'OK',
    'save': 'Save',
    'apply': 'Apply',
    'delete': 'Delete',
    'set': 'Set',
    'remove': 'Remove',
    'upload': 'Upload',
    'none': 'None',
    'active': 'Active',
    'inactive': 'Inactive',
    'amount': 'Amount',
    'note': 'Note',
    'noteOptional': 'Note (optional)',
    'reason': 'Reason',
    'quantityTitle': 'Quantity · {unit}',
    'qtyLabel': 'Qty ({unit})',
    'saleCompleted': 'Sale {receipt} completed',
    'editProduct': 'Edit Product',
    'productAdded': 'Product added',
    'productUpdated': 'Product updated',
    'productDeactivated': 'Product deactivated',
    'deactivateProduct': 'Deactivate product',
    'deactivateBtn': 'Deactivate',
    'deactivateProductConfirm': 'Remove "{name}" from the catalogue?',
    'productImage': 'Product image',
    'colName': 'Name',
    'colPrice': 'Price',
    'colCost': 'Cost',
    'colStock': 'Stock',
    'colSkuBarcode': 'SKU / Barcode',
    'colCategory': 'Category',
    'sku': 'SKU',
    'barcode': 'Barcode',
    'unitLabel': 'Unit',
    'sellingPrice': 'Selling price',
    'costLabel': 'Cost',
    'taxPercent': 'Tax %',
    'reorderLevel': 'Reorder level',
    'color': 'Color',
    'couldNotSaveImage': 'Could not save image: {error}',
    'editCategory': 'Edit Category',
    'deleteCategory': 'Delete category',
    'deleteCategoryConfirm': 'Delete "{name}"?',
    'categoryProductCount': '{count} products',
    'filterFrom': 'From',
    'filterTo': 'To',
    'allStaff': 'All staff',
    'employee': 'Employee',
    'refund': 'Refund',
    'refundReason': 'Refund reason',
    'saleRefunded': 'Sale refunded',
    'adjustStockTitle': 'Adjust stock · {name}',
    'currentStock': 'Current: {qty} {unit}',
    'quantityDelta': 'Quantity delta (+/-)',
    'reasonRequired': 'Reason (required)',
    'stockAdjusted': 'Stock adjusted',
    'productLabel': 'Product',
    'quantity': 'Quantity',
    'unitCost': 'Unit cost',
    'invoiceOptional': 'Invoice # (optional)',
    'stockReceived': 'Stock received',
    'noProducts': 'No products',
    'adjustBtn': 'Adjust',
    'receiveBtn': 'Receive',
    'reorderLine': 'Reorder {level} · {sku}',
    'recentMovements': 'Recent movements',
    'productFallback': 'Product',
    'editEmployee': 'Edit employee',
    'noEmployeesYet': 'No employees yet',
    'username': 'Username',
    'role': 'Role',
    'setCurrent': 'Set current',
    'badgeCurrent': 'current',
    'shiftOpened': 'Shift opened',
    'shiftClosed': 'Shift closed',
    'cashInRecorded': 'Cash in recorded',
    'cashOutRecorded': 'Cash out recorded',
    'roleOwner': 'owner',
    'roleAdmin': 'admin',
    'roleManager': 'manager',
    'roleCashier': 'cashier',
    'signIn': 'Sign in',
    'loginSubtitle': 'Sign in to continue to {store}',
    'pin': 'PIN',
    'pinHint': '4–6 digit PIN',
    'pinRequired': 'Enter your PIN',
    'pinTooShort': 'PIN must be at least 4 digits',
    'usernameRequired': 'Enter your username',
    'invalidCredentials': 'Invalid username or PIN',
    'loginHint': 'Default: admin / 1234',
    'keepCurrentPin': 'Leave blank to keep current PIN',
    'accessDenied': 'You do not have access to this section',
  };

  static Map<String, String> _with(Map<String, String> overrides) => {..._baseEn, ...overrides};

  static final _tables = <String, Map<String, String>>{
    'en_US': _baseEn,
    'en_GB': _with(const {
      'dashboardSubtitle': 'Offline POS overview · {store}',
    }),
    'fr_FR': _with(const {
      'appName': 'MayleSoft retail',
      'dashboard': 'Tableau de bord',
      'pos': 'Caisse',
      'products': 'Produits',
      'categories': 'Catégories',
      'salesHistory': 'Historique des ventes',
      'inventory': 'Inventaire',
      'staff': 'Personnel',
      'shifts': 'Sessions',
      'reports': 'Rapports',
      'settings': 'Paramètres',
      'saveSettings': 'Enregistrer',
      'appearance': 'Apparence',
      'darkMode': 'Mode sombre',
      'language': 'Langue',
      'settingsSaved': 'Paramètres enregistrés',
      'businessInfo': 'Informations commerciales',
      'about': 'À propos',
      'settingsSubtitle': 'Entreprise, taxe, devise et préférences',
      'dashboardSubtitle': 'Aperçu caisse hors ligne · {store}',
      'openPos': 'Ouvrir la caisse',
      'todaySales': 'Ventes du jour',
      'transactions': 'Transactions',
      'grossProfit': 'Bénéfice brut',
      'lowStock': 'Stock bas',
      'recentSales': 'Ventes récentes',
      'noSalesYet': 'Aucune vente. Passez en caisse.',
      'lowStockAlerts': 'Alertes stock bas',
      'stockLabel': 'Stock',
      'reorderLabel': 'seuil',
      'lowBadge': 'BAS',
      'staffFallback': 'Personnel',
      'adminFallback': 'Admin',
      'statusCompleted': 'terminé',
      'statusRefunded': 'remboursé',
      'statusPartialRefund': 'remboursement partiel',
      'statusVoided': 'annulé',
      'posTitle': 'Point de vente',
      'posSubtitle': 'Scannez, recherchez ou touchez un produit',
      'productsSubtitle': '{count} produits actifs',
      'newProduct': 'Nouveau produit',
      'noProductsYet': 'Aucun produit',
      'categoriesSubtitle': '{count} catégories',
      'newCategory': 'Nouvelle catégorie',
      'noCategoriesYet': 'Aucune catégorie',
      'salesHistorySubtitle': 'Filtrer et consulter les tickets',
      'inventorySubtitle': 'Niveaux, ajustements et réception',
      'receiveStock': 'Réception stock',
      'staffSubtitle': 'Employés et caissier actuel',
      'addEmployee': 'Ajouter un employé',
      'shiftsSubtitle': 'Caisse et historique des sessions',
      'reportsSubtitle': 'Revenus, produits et paiements',
      'tabGeneral': 'Général',
      'tabDiscounts': 'Remises',
      'tabPaymentMethods': 'Modes de paiement',
      'tabPosDevices': 'Terminaux POS',
      'tabPrinters': 'Imprimantes',
      'tabBackup': 'Sauvegarde',
      'tabNetwork': 'Réseau',
      'discountsSubtitle': 'Remises prédéfinies pour la caisse et les promotions',
      'addDiscount': 'Ajouter une remise',
      'editDiscount': 'Modifier la remise',
      'noDiscountsYet': 'Aucune règle de remise',
      'discountName': 'Nom de la remise',
      'discountType': 'Type',
      'discountPercent': 'Pourcentage',
      'discountFixed': 'Montant fixe',
      'discountValue': 'Valeur',
      'minPurchase': 'Achat minimum',
      'discountPercentSummary': '{value} % de remise',
      'discountFixedSummary': '{value} de remise',
      'deleteDiscountConfirm': 'Supprimer la remise « {name} » ?',
      'discountScope': 'S\'applique à',
      'discountScopeAll': 'Tous les produits',
      'discountScopeProducts': 'Produits sélectionnés',
      'discountProductCount': '{count} produits',
      'discountStartDate': 'Date de début',
      'discountEndDate': 'Date de fin',
      'discountSelectProducts': 'Sélectionner les produits',
      'discountProductsRequired': 'Sélectionnez au moins un produit',
      'discountAlways': 'Toute période',
      'discountFromTo': '{from} – {to}',
      'discountFromOnly': 'À partir du {from}',
      'discountUntilOnly': 'Jusqu\'au {to}',
      'discountOff': 'Remise',
      'cartDiscount': 'Remise',
      'paymentMethodsSubtitle': 'Modes de paiement proposés à la caisse',
      'addPaymentMethod': 'Ajouter un mode de paiement',
      'editPaymentMethod': 'Modifier le mode de paiement',
      'noPaymentMethodsYet': 'Aucun mode de paiement configuré',
      'methodCode': 'Code',
      'methodLabel': 'Libellé affiché',
      'enabled': 'Activé',
      'deletePaymentMethodConfirm': 'Supprimer le mode « {name} » ?',
      'atLeastOnePaymentMethod': 'Au moins un mode de paiement doit rester actif',
      'posDevicesSubtitle': 'Enregistrer terminaux, tablettes et scanners',
      'addPosDevice': 'Ajouter un appareil',
      'editPosDevice': 'Modifier l\'appareil',
      'noPosDevicesYet': 'Aucun terminal POS enregistré',
      'deviceName': 'Nom de l\'appareil',
      'deviceType': 'Type d\'appareil',
      'deviceIdentifier': 'Identifiant / série',
      'deviceNotes': 'Notes',
      'deviceTypeTerminal': 'Terminal',
      'deviceTypeTablet': 'Tablette',
      'deviceTypeScanner': 'Scanner',
      'deletePosDeviceConfirm': 'Retirer l\'appareil « {name} » ?',
      'printersSubtitle': 'Imprimantes reçus et étiquettes pour ce terminal',
      'addPrinter': 'Ajouter une imprimante',
      'editPrinter': 'Modifier l\'imprimante',
      'noPrintersYet': 'Aucune imprimante configurée',
      'printerName': 'Nom de l\'imprimante',
      'printerType': 'Type d\'imprimante',
      'printerConnection': 'Connexion',
      'printerAddress': 'Adresse / port',
      'paperWidth': 'Largeur papier (mm)',
      'defaultPrinter': 'Imprimante reçu par défaut',
      'printerTypeReceipt': 'Reçu',
      'printerTypeLabel': 'Étiquette',
      'connectionUsb': 'USB',
      'connectionNetwork': 'Réseau',
      'connectionBluetooth': 'Bluetooth',
      'deletePrinterConfirm': 'Supprimer l\'imprimante « {name} » ?',
      'backupSubtitle': 'Exporter ou restaurer la base locale',
      'exportBackup': 'Exporter la sauvegarde',
      'importBackup': 'Importer la sauvegarde',
      'backupExported': 'Sauvegarde enregistrée : {path}',
      'backupRestored': 'Sauvegarde restaurée',
      'backupRestoreConfirm': 'Restaurer la sauvegarde ?',
      'backupRestoreWarning': 'Cela remplace toutes les données actuelles. Continuer ?',
      'backupLocation': 'Dossier base : {path}',
      'networkSubtitle': 'Synchronisation multi-terminal (serveur requis)',
      'networkEnabled': 'Activer la sync réseau',
      'networkEnabledHint': 'Ce terminal peut synchroniser avec un serveur MayleSoft',
      'serverUrl': 'URL du serveur',
      'terminalName': 'Nom du terminal',
      'syncInterval': 'Intervalle de sync',
      'syncIntervalHint': 'Fréquence de vérification des mises à jour',
      'minutes': 'minutes',
      'networkSaved': 'Paramètres réseau enregistrés',
      'nameRequired': 'Le nom est obligatoire',
      'invalidUrl': 'Entrez une URL http ou https valide',
      'storeName': 'Nom du magasin',
      'phone': 'Téléphone',
      'email': 'E-mail',
      'address': 'Adresse',
      'receiptHeader': 'En-tête du reçu',
      'receiptFooter': 'Pied de page du reçu',
      'currencyCode': 'Code devise',
      'currencySymbol': 'Symbole devise',
      'taxName': 'Nom de la taxe',
      'taxRate': 'Taux de taxe %',
      'taxType': 'Type de taxe',
      'taxExclusive': 'Hors taxe',
      'taxInclusive': 'TTC',
      'storeLogo': 'Logo du magasin',
      'storeLogoHint': 'Logo carré recommandé (ex. 400×400). Utilisé pour les reçus et la marque.',
      'uploadLogo': 'Téléverser le logo',
      'logoUploadLater': 'Le téléversement du logo arrivera dans une mise à jour ultérieure',
      'version': 'Version',
      'systemName': 'Nom du système',
      'copyrightNotice': 'Copyright 2026 - MayleSoft retail, designed by Eng. Hasan Kamaal',
      'comingSoon': '{title} bientôt disponible',
      'comingSoonBody': 'Cette section est réservée aux options de configuration à venir.',
      'couldNotSave': 'Enregistrement impossible : {error}',
      'searchHint': 'Rechercher nom, SKU ou code-barres…',
      'allCategories': 'Tout',
      'noProductsFound': 'Aucun produit trouvé',
      'cart': 'Panier',
      'clearCart': 'Vider',
      'cartItemsCount': '{count} articles',
      'tapProductsToAdd': 'Touchez un produit pour l\'ajouter',
      'subtotal': 'Sous-total',
      'tax': 'Taxe',
      'total': 'Total',
      'chargeBtn': 'Encaisser {amount}',
      'cartEmpty': 'Le panier est vide',
      'chargeTitle': 'Encaisser',
      'payCash': 'Espèces',
      'payCard': 'Carte',
      'payMobile': 'Mobile',
      'periodDaily': 'Journalier',
      'periodWeekly': 'Hebdomadaire',
      'periodMonthly': 'Mensuel',
      'revenue': 'Revenus',
      'estProfit': 'Profit est.',
      'salesCount': 'Ventes',
      'avgSale': 'Vente moy.',
      'topProducts': 'Meilleurs produits',
      'noSalesInPeriod': 'Aucune vente sur cette période',
      'paymentBreakdown': 'Répartition des paiements',
      'salesTrend': 'Tendance des ventes',
      'revenueVsProfit': 'Revenus vs profit',
      'noPaymentsYet': 'Aucun paiement',
      'shiftOpen': 'Session ouverte',
      'noActiveShift': 'Aucune session active',
      'openShiftHint': 'Ouvrez une session pour vendre avec un tiroir-caisse',
      'openShiftBtn': 'Ouvrir session',
      'cashInBtn': 'Entrée caisse',
      'cashOutBtn': 'Sortie caisse',
      'closeBtn': 'Fermer',
      'openingCash': 'Fond de caisse',
      'cashSales': 'Ventes espèces',
      'cashInOut': 'Entrées / sorties',
      'expectedCash': 'Espèces attendues',
      'cashMovements': 'Mouvements de caisse',
      'noMovementsYet': 'Aucun mouvement',
      'shiftHistoryTitle': 'Historique des sessions',
      'noShiftsYet': 'Aucune session',
      'colEmployee': 'Employé',
      'colOpened': 'Ouverture',
      'colClosed': 'Fermeture',
      'colOpening': 'Fond',
      'colClosing': 'Comptage',
      'colExpected': 'Attendu',
      'colDiff': 'Écart',
      'colStatus': 'Statut',
      'statusOpen': 'ouvert',
      'statusClosedShift': 'fermé',
      'movementIn': 'ENTRÉE',
      'movementOut': 'SORTIE',
      'cancel': 'Annuler',
      'ok': 'OK',
      'save': 'Enregistrer',
      'apply': 'Appliquer',
      'delete': 'Supprimer',
      'set': 'Définir',
      'remove': 'Retirer',
      'upload': 'Téléverser',
      'none': 'Aucune',
      'active': 'Actif',
      'inactive': 'Inactif',
      'amount': 'Montant',
      'note': 'Note',
      'noteOptional': 'Note (facultatif)',
      'reason': 'Motif',
      'quantityTitle': 'Quantité · {unit}',
      'qtyLabel': 'Qté ({unit})',
      'saleCompleted': 'Vente {receipt} terminée',
      'editProduct': 'Modifier le produit',
      'productAdded': 'Produit ajouté',
      'productUpdated': 'Produit mis à jour',
      'productDeactivated': 'Produit désactivé',
      'deactivateProduct': 'Désactiver le produit',
      'deactivateBtn': 'Désactiver',
      'deactivateProductConfirm': 'Retirer « {name} » du catalogue ?',
      'productImage': 'Image du produit',
      'colName': 'Nom',
      'colPrice': 'Prix',
      'colCost': 'Coût',
      'colStock': 'Stock',
      'colSkuBarcode': 'SKU / Code-barres',
      'colCategory': 'Catégorie',
      'sku': 'SKU',
      'barcode': 'Code-barres',
      'unitLabel': 'Unité',
      'sellingPrice': 'Prix de vente',
      'costLabel': 'Coût',
      'taxPercent': 'Taxe %',
      'reorderLevel': 'Seuil de réappro.',
      'color': 'Couleur',
      'couldNotSaveImage': 'Impossible d\'enregistrer l\'image : {error}',
      'editCategory': 'Modifier la catégorie',
      'deleteCategory': 'Supprimer la catégorie',
      'deleteCategoryConfirm': 'Supprimer « {name} » ?',
      'categoryProductCount': '{count} produits',
      'filterFrom': 'Du',
      'filterTo': 'Au',
      'allStaff': 'Tout le personnel',
      'employee': 'Employé',
      'refund': 'Rembourser',
      'refundReason': 'Motif du remboursement',
      'saleRefunded': 'Vente remboursée',
      'adjustStockTitle': 'Ajuster le stock · {name}',
      'currentStock': 'Actuel : {qty} {unit}',
      'quantityDelta': 'Variation (+/-)',
      'reasonRequired': 'Motif (obligatoire)',
      'stockAdjusted': 'Stock ajusté',
      'productLabel': 'Produit',
      'quantity': 'Quantité',
      'unitCost': 'Coût unitaire',
      'invoiceOptional': 'N° facture (facultatif)',
      'stockReceived': 'Stock reçu',
      'noProducts': 'Aucun produit',
      'adjustBtn': 'Ajuster',
      'receiveBtn': 'Recevoir',
      'reorderLine': 'Seuil {level} · {sku}',
      'recentMovements': 'Mouvements récents',
      'productFallback': 'Produit',
      'editEmployee': 'Modifier l\'employé',
      'noEmployeesYet': 'Aucun employé',
      'username': 'Nom d\'utilisateur',
      'role': 'Rôle',
      'setCurrent': 'Définir actuel',
      'badgeCurrent': 'actuel',
      'shiftOpened': 'Session ouverte',
      'shiftClosed': 'Session fermée',
      'cashInRecorded': 'Entrée caisse enregistrée',
      'cashOutRecorded': 'Sortie caisse enregistrée',
      'roleOwner': 'propriétaire',
      'roleAdmin': 'admin',
      'roleManager': 'manager',
      'roleCashier': 'caissier',
      'signIn': 'Connexion',
      'loginSubtitle': 'Connectez-vous pour accéder à {store}',
      'pin': 'PIN',
      'pinHint': 'PIN de 4 à 6 chiffres',
      'pinRequired': 'Saisissez votre PIN',
      'pinTooShort': 'Le PIN doit contenir au moins 4 chiffres',
      'usernameRequired': 'Saisissez votre identifiant',
      'invalidCredentials': 'Identifiant ou PIN incorrect',
      'loginHint': 'Par défaut : admin / 1234',
      'keepCurrentPin': 'Laisser vide pour conserver le PIN actuel',
      'accessDenied': 'Vous n\'avez pas accès à cette section',
    }),
    'ar_SA': _with(const {
      'appName': 'MayleSoft retail',
      'dashboard': 'لوحة التحكم',
      'pos': 'نقطة البيع',
      'products': 'المنتجات',
      'categories': 'التصنيفات',
      'salesHistory': 'سجل المبيعات',
      'inventory': 'المخزون',
      'staff': 'الموظفون',
      'shifts': 'الورديات',
      'reports': 'التقارير',
      'settings': 'الإعدادات',
      'saveSettings': 'حفظ الإعدادات',
      'appearance': 'المظهر',
      'darkMode': 'الوضع الداكن',
      'language': 'اللغة',
      'settingsSaved': 'تم حفظ الإعدادات',
      'businessInfo': 'معلومات المتجر',
      'about': 'حول',
      'settingsSubtitle': 'المتجر والضريبة والعملة وتفضيلات التطبيق',
      'dashboardSubtitle': 'نظرة عامة على نقطة البيع دون اتصال · {store}',
      'openPos': 'فتح نقطة البيع',
      'todaySales': 'مبيعات اليوم',
      'transactions': 'المعاملات',
      'grossProfit': 'إجمالي الربح',
      'lowStock': 'مخزون منخفض',
      'recentSales': 'المبيعات الأخيرة',
      'noSalesYet': 'لا توجد مبيعات بعد. ابدأ من نقطة البيع.',
      'lowStockAlerts': 'تنبيهات المخزون المنخفض',
      'stockLabel': 'المخزون',
      'reorderLabel': 'حد الطلب',
      'lowBadge': 'منخفض',
      'staffFallback': 'موظف',
      'adminFallback': 'المسؤول',
      'statusCompleted': 'مكتمل',
      'statusRefunded': 'مسترد',
      'statusPartialRefund': 'استرداد جزئي',
      'statusVoided': 'ملغى',
      'posTitle': 'نقطة البيع',
      'posSubtitle': 'امسح أو ابحث أو اضغط على المنتجات',
      'productsSubtitle': '{count} منتج نشط',
      'newProduct': 'منتج جديد',
      'noProductsYet': 'لا توجد منتجات بعد',
      'categoriesSubtitle': '{count} تصنيف',
      'newCategory': 'تصنيف جديد',
      'noCategoriesYet': 'لا توجد تصنيفات بعد',
      'salesHistorySubtitle': 'تصفية ومراجعة الإيصالات',
      'inventorySubtitle': 'مستويات المخزون والتعديلات والاستلام',
      'receiveStock': 'استلام مخزون',
      'staffSubtitle': 'الموظفون والكاشير الحالي',
      'addEmployee': 'إضافة موظف',
      'shiftsSubtitle': 'درج النقد وسجل الورديات',
      'reportsSubtitle': 'الإيرادات والمنتجات والمدفوعات',
      'tabGeneral': 'عام',
      'tabDiscounts': 'الخصومات',
      'tabPaymentMethods': 'طرق الدفع',
      'tabPosDevices': 'أجهزة نقطة البيع',
      'tabPrinters': 'الطابعات',
      'tabBackup': 'النسخ الاحتياطي',
      'tabNetwork': 'الشبكة',
      'discountsSubtitle': 'خصومات جاهزة للدفع والعروض',
      'addDiscount': 'إضافة خصم',
      'editDiscount': 'تعديل الخصم',
      'noDiscountsYet': 'لا توجد قواعد خصم',
      'discountName': 'اسم الخصم',
      'discountType': 'النوع',
      'discountPercent': 'نسبة مئوية',
      'discountFixed': 'مبلغ ثابت',
      'discountValue': 'القيمة',
      'minPurchase': 'الحد الأدنى للشراء',
      'discountPercentSummary': 'خصم {value}%',
      'discountFixedSummary': 'خصم {value}',
      'deleteDiscountConfirm': 'حذف الخصم «{name}»؟',
      'discountScope': 'ينطبق على',
      'discountScopeAll': 'جميع المنتجات',
      'discountScopeProducts': 'منتجات محددة',
      'discountProductCount': '{count} منتجات',
      'discountStartDate': 'تاريخ البداية',
      'discountEndDate': 'تاريخ النهاية',
      'discountSelectProducts': 'اختر المنتجات',
      'discountProductsRequired': 'اختر منتجًا واحدًا على الأقل',
      'discountAlways': 'أي وقت',
      'discountFromTo': '{from} – {to}',
      'discountFromOnly': 'من {from}',
      'discountUntilOnly': 'حتى {to}',
      'discountOff': 'خصم',
      'cartDiscount': 'الخصم',
      'paymentMethodsSubtitle': 'طرق الدفع المعروضة عند الدفع',
      'addPaymentMethod': 'إضافة طريقة دفع',
      'editPaymentMethod': 'تعديل طريقة الدفع',
      'noPaymentMethodsYet': 'لا توجد طرق دفع',
      'methodCode': 'الرمز',
      'methodLabel': 'الاسم المعروض',
      'enabled': 'مفعّل',
      'deletePaymentMethodConfirm': 'حذف طريقة «{name}»؟',
      'atLeastOnePaymentMethod': 'يجب تفعيل طريقة دفع واحدة على الأقل',
      'posDevicesSubtitle': 'تسجيل الأجهزة والأجهزة اللوحية والماسحات',
      'addPosDevice': 'إضافة جهاز',
      'editPosDevice': 'تعديل الجهاز',
      'noPosDevicesYet': 'لا أجهزة POS مسجلة',
      'deviceName': 'اسم الجهاز',
      'deviceType': 'نوع الجهاز',
      'deviceIdentifier': 'المعرف / الرقم التسلسلي',
      'deviceNotes': 'ملاحظات',
      'deviceTypeTerminal': 'جهاز طرفي',
      'deviceTypeTablet': 'جهاز لوحي',
      'deviceTypeScanner': 'ماسح',
      'deletePosDeviceConfirm': 'إزالة الجهاز «{name}»؟',
      'printersSubtitle': 'طابعات الإيصالات والملصقات لهذا الجهاز',
      'addPrinter': 'إضافة طابعة',
      'editPrinter': 'تعديل الطابعة',
      'noPrintersYet': 'لا طابعات مُعدّة',
      'printerName': 'اسم الطابعة',
      'printerType': 'نوع الطابعة',
      'printerConnection': 'الاتصال',
      'printerAddress': 'العنوان / المنفذ',
      'paperWidth': 'عرض الورق (مم)',
      'defaultPrinter': 'طابعة الإيصال الافتراضية',
      'printerTypeReceipt': 'إيصال',
      'printerTypeLabel': 'ملصق',
      'connectionUsb': 'USB',
      'connectionNetwork': 'شبكة',
      'connectionBluetooth': 'بلوتوث',
      'deletePrinterConfirm': 'حذف الطابعة «{name}»؟',
      'backupSubtitle': 'تصدير أو استعادة قاعدة البيانات المحلية',
      'exportBackup': 'تصدير النسخة الاحتياطية',
      'importBackup': 'استيراد النسخة الاحتياطية',
      'backupExported': 'تم حفظ النسخة في {path}',
      'backupRestored': 'تمت استعادة النسخة بنجاح',
      'backupRestoreConfirm': 'استعادة النسخة؟',
      'backupRestoreWarning': 'سيستبدل هذا جميع البيانات الحالية. متابعة؟',
      'backupLocation': 'مجلد قاعدة البيانات: {path}',
      'networkSubtitle': 'إعدادات المزامنة متعددة الأجهزة (يتطلب خادمًا)',
      'networkEnabled': 'تفعيل المزامنة الشبكية',
      'networkEnabledHint': 'يمكن لهذا الجهاز المزامنة مع خادم MayleSoft',
      'serverUrl': 'رابط الخادم',
      'terminalName': 'اسم الجهاز',
      'syncInterval': 'فترة المزامنة',
      'syncIntervalHint': 'عدد مرات التحقق من التحديثات',
      'minutes': 'دقائق',
      'networkSaved': 'تم حفظ إعدادات الشبكة',
      'nameRequired': 'الاسم مطلوب',
      'invalidUrl': 'أدخل رابط http أو https صالحًا',
      'storeName': 'اسم المتجر',
      'phone': 'الهاتف',
      'email': 'البريد الإلكتروني',
      'address': 'العنوان',
      'receiptHeader': 'رأس الإيصال',
      'receiptFooter': 'تذييل الإيصال',
      'currencyCode': 'رمز العملة',
      'currencySymbol': 'رمز العملة المعروض',
      'taxName': 'اسم الضريبة',
      'taxRate': 'نسبة الضريبة %',
      'taxType': 'نوع الضريبة',
      'taxExclusive': 'غير شاملة',
      'taxInclusive': 'شاملة',
      'storeLogo': 'شعار المتجر',
      'storeLogoHint': 'يُفضّل شعار مربع (مثل 400×400). يُستخدم للإيصالات والعلامة التجارية.',
      'uploadLogo': 'رفع الشعار',
      'logoUploadLater': 'رفع الشعار سيكون متاحًا في تحديث لاحق',
      'version': 'الإصدار',
      'systemName': 'اسم النظام',
      'copyrightNotice': 'Copyright 2026 - MayleSoft retail, designed by Eng. Hasan Kamaal',
      'comingSoon': '{title} قريبًا',
      'comingSoonBody': 'هذا القسم مخصص لخيارات إعدادات MayleSoft retail القادمة.',
      'couldNotSave': 'تعذر الحفظ: {error}',
      'searchHint': 'ابحث بالاسم أو الرمز أو الباركود…',
      'allCategories': 'الكل',
      'noProductsFound': 'لم يُعثر على منتجات',
      'cart': 'السلة',
      'clearCart': 'مسح',
      'cartItemsCount': '{count} عنصر',
      'tapProductsToAdd': 'اضغط على المنتجات للإضافة',
      'subtotal': 'المجموع الفرعي',
      'tax': 'الضريبة',
      'total': 'الإجمالي',
      'chargeBtn': 'تحصيل {amount}',
      'cartEmpty': 'السلة فارغة',
      'chargeTitle': 'تحصيل',
      'payCash': 'نقدًا',
      'payCard': 'بطاقة',
      'payMobile': 'محفظة',
      'periodDaily': 'يومي',
      'periodWeekly': 'أسبوعي',
      'periodMonthly': 'شهري',
      'revenue': 'الإيرادات',
      'estProfit': 'الربح التقديري',
      'salesCount': 'المبيعات',
      'avgSale': 'متوسط البيع',
      'topProducts': 'أفضل المنتجات',
      'noSalesInPeriod': 'لا مبيعات في هذه الفترة',
      'paymentBreakdown': 'توزيع المدفوعات',
      'salesTrend': 'اتجاه المبيعات',
      'revenueVsProfit': 'الإيرادات مقابل الربح',
      'noPaymentsYet': 'لا مدفوعات بعد',
      'shiftOpen': 'وردية مفتوحة',
      'noActiveShift': 'لا توجد وردية نشطة',
      'openShiftHint': 'افتح وردية لبدء البيع مع درج النقد',
      'openShiftBtn': 'فتح وردية',
      'cashInBtn': 'إيداع نقد',
      'cashOutBtn': 'سحب نقد',
      'closeBtn': 'إغلاق',
      'openingCash': 'رصيد الافتتاح',
      'cashSales': 'مبيعات نقدية',
      'cashInOut': 'إيداع / سحب',
      'expectedCash': 'النقد المتوقع',
      'cashMovements': 'حركات النقد',
      'noMovementsYet': 'لا حركات بعد',
      'shiftHistoryTitle': 'سجل الورديات',
      'noShiftsYet': 'لا ورديات بعد',
      'colEmployee': 'الموظف',
      'colOpened': 'الفتح',
      'colClosed': 'الإغلاق',
      'colOpening': 'الافتتاح',
      'colClosing': 'العد',
      'colExpected': 'المتوقع',
      'colDiff': 'الفرق',
      'colStatus': 'الحالة',
      'statusOpen': 'مفتوحة',
      'statusClosedShift': 'مغلقة',
      'movementIn': 'إيداع',
      'movementOut': 'سحب',
      'cancel': 'إلغاء',
      'ok': 'موافق',
      'save': 'حفظ',
      'apply': 'تطبيق',
      'delete': 'حذف',
      'set': 'تعيين',
      'remove': 'إزالة',
      'upload': 'رفع',
      'none': 'لا شيء',
      'active': 'نشط',
      'inactive': 'غير نشط',
      'amount': 'المبلغ',
      'note': 'ملاحظة',
      'noteOptional': 'ملاحظة (اختياري)',
      'reason': 'السبب',
      'quantityTitle': 'الكمية · {unit}',
      'qtyLabel': 'الكمية ({unit})',
      'saleCompleted': 'تم إتمام البيع {receipt}',
      'editProduct': 'تعديل المنتج',
      'productAdded': 'تمت إضافة المنتج',
      'productUpdated': 'تم تحديث المنتج',
      'productDeactivated': 'تم إلغاء تفعيل المنتج',
      'deactivateProduct': 'إلغاء تفعيل المنتج',
      'deactivateBtn': 'إلغاء التفعيل',
      'deactivateProductConfirm': 'إزالة «{name}» من القائمة؟',
      'productImage': 'صورة المنتج',
      'colName': 'الاسم',
      'colPrice': 'السعر',
      'colCost': 'التكلفة',
      'colStock': 'المخزون',
      'colSkuBarcode': 'SKU / الباركود',
      'colCategory': 'التصنيف',
      'sku': 'SKU',
      'barcode': 'الباركود',
      'unitLabel': 'الوحدة',
      'sellingPrice': 'سعر البيع',
      'costLabel': 'التكلفة',
      'taxPercent': 'الضريبة %',
      'reorderLevel': 'حد إعادة الطلب',
      'color': 'اللون',
      'couldNotSaveImage': 'تعذر حفظ الصورة: {error}',
      'editCategory': 'تعديل التصنيف',
      'deleteCategory': 'حذف التصنيف',
      'deleteCategoryConfirm': 'حذف «{name}»؟',
      'categoryProductCount': '{count} منتج',
      'filterFrom': 'من',
      'filterTo': 'إلى',
      'allStaff': 'كل الموظفين',
      'employee': 'الموظف',
      'refund': 'استرداد',
      'refundReason': 'سبب الاسترداد',
      'saleRefunded': 'تم استرداد البيع',
      'adjustStockTitle': 'تعديل المخزون · {name}',
      'currentStock': 'الحالي: {qty} {unit}',
      'quantityDelta': 'فرق الكمية (+/-)',
      'reasonRequired': 'السبب (مطلوب)',
      'stockAdjusted': 'تم تعديل المخزون',
      'productLabel': 'المنتج',
      'quantity': 'الكمية',
      'unitCost': 'تكلفة الوحدة',
      'invoiceOptional': 'رقم الفاتورة (اختياري)',
      'stockReceived': 'تم استلام المخزون',
      'noProducts': 'لا توجد منتجات',
      'adjustBtn': 'تعديل',
      'receiveBtn': 'استلام',
      'reorderLine': 'حد الطلب {level} · {sku}',
      'recentMovements': 'الحركات الأخيرة',
      'productFallback': 'منتج',
      'editEmployee': 'تعديل الموظف',
      'noEmployeesYet': 'لا يوجد موظفون بعد',
      'username': 'اسم المستخدم',
      'role': 'الدور',
      'setCurrent': 'تعيين الحالي',
      'badgeCurrent': 'الحالي',
      'shiftOpened': 'تم فتح الوردية',
      'shiftClosed': 'تم إغلاق الوردية',
      'cashInRecorded': 'تم تسجيل الإيداع',
      'cashOutRecorded': 'تم تسجيل السحب',
      'roleOwner': 'مالك',
      'roleAdmin': 'مسؤول',
      'roleManager': 'مدير',
      'roleCashier': 'كاشير',
      'signIn': 'تسجيل الدخول',
      'loginSubtitle': 'سجّل الدخول للمتابعة إلى {store}',
      'pin': 'رمز PIN',
      'pinHint': 'رمز من 4–6 أرقام',
      'pinRequired': 'أدخل رمز PIN',
      'pinTooShort': 'يجب أن يكون PIN 4 أرقام على الأقل',
      'usernameRequired': 'أدخل اسم المستخدم',
      'invalidCredentials': 'اسم المستخدم أو PIN غير صحيح',
      'loginHint': 'الافتراضي: admin / 1234',
      'keepCurrentPin': 'اتركه فارغًا للاحتفاظ برمز PIN الحالي',
      'accessDenied': 'ليس لديك صلاحية الوصول إلى هذا القسم',
    }),
    'so_SO': _with(const {
      'appName': 'MayleSoft retail',
      'dashboard': 'Dashboard-ka',
      'pos': 'POS',
      'products': 'Alaabta',
      'categories': 'Qaybaha',
      'salesHistory': 'Taariikhda iibka',
      'inventory': 'Kaydka',
      'staff': 'Shaqaalaha',
      'shifts': 'Shaqooyinka',
      'reports': 'Warbixinada',
      'settings': 'Dejinta',
      'saveSettings': 'Kaydi dejinta',
      'appearance': 'Muuqaalka',
      'darkMode': 'Habka madow',
      'language': 'Luqadda',
      'settingsSaved': 'Dejinta waa la kaydiyay',
      'businessInfo': 'Macluumaadka ganacsiga',
      'about': 'Ku saabsan',
      'settingsSubtitle': 'Ganacsiga, canshuurta, lacagta iyo doorbidyada app-ka',
      'dashboardSubtitle': 'Dulmar POS offline · {store}',
      'openPos': 'Fur POS',
      'todaySales': 'Iibka maanta',
      'transactions': 'Macamalada',
      'grossProfit': 'Faa\'iidada guud',
      'lowStock': 'Kayd hooseeya',
      'recentSales': 'Iibkii u dambeeyay',
      'noSalesYet': 'Weli iib ma jiro. Ka bilow POS.',
      'lowStockAlerts': 'Digniinada kaydka hooseeya',
      'stockLabel': 'Kayd',
      'reorderLabel': 'heerka dib-u-dalashada',
      'lowBadge': 'HOOSE',
      'staffFallback': 'Shaqaale',
      'adminFallback': 'Maamul',
      'statusCompleted': 'la dhammeeyay',
      'statusRefunded': 'la soo celiyay',
      'statusPartialRefund': 'soo-celin qayb ah',
      'statusVoided': 'la buriyay',
      'posTitle': 'Barta iibka',
      'posSubtitle': 'Iskaanka, raadi, ama taabo alaabta',
      'productsSubtitle': '{count} alaab firfircoon',
      'newProduct': 'Alaab cusub',
      'noProductsYet': 'Weli alaab ma jirto',
      'categoriesSubtitle': '{count} qaybood',
      'newCategory': 'Qayb cusub',
      'noCategoriesYet': 'Weli qaybo ma jiraan',
      'salesHistorySubtitle': 'Shaandhee oo dib u eeg rasiidhada',
      'inventorySubtitle': 'Heerarka kaydka, hagaajinta & soo-qaadista',
      'receiveStock': 'Soo qaado kayd',
      'staffSubtitle': 'Shaqaalaha & lacag-qaadaha hadda',
      'addEmployee': 'Kudar shaqaale',
      'shiftsSubtitle': 'Sanduuqa lacagta & taariikhda shaqada',
      'reportsSubtitle': 'Dakhliga, alaabta & lacag-bixinta',
      'tabGeneral': 'Guud',
      'tabDiscounts': 'Qiimo-dhimista',
      'tabPaymentMethods': 'Hababka lacag-bixinta',
      'tabPosDevices': 'Qalabka POS',
      'tabPrinters': 'Daabacadaha',
      'tabBackup': 'Kaydin & soo-celin',
      'tabNetwork': 'Shabakadda',
      'discountsSubtitle': 'Qiimo-dhimis diyaar ah oo loogu talagalay lacag-bixinta',
      'addDiscount': 'Ku dar qiimo-dhimis',
      'editDiscount': 'Wax ka beddel qiimo-dhimista',
      'noDiscountsYet': 'Weli xeer qiimo-dhimis ma jiro',
      'discountName': 'Magaca qiimo-dhimista',
      'discountType': 'Nooca',
      'discountPercent': 'Boqolkiiba',
      'discountFixed': 'Qadar go\'an',
      'discountValue': 'Qiimaha',
      'minPurchase': 'Iibka ugu yar',
      'discountPercentSummary': '{value}% dhimis',
      'discountFixedSummary': '{value} dhimis',
      'deleteDiscountConfirm': 'Tirtir qiimo-dhimista «{name}»?',
      'discountScope': 'Waxay khuseysaa',
      'discountScopeAll': 'Dhammaan alaabta',
      'discountScopeProducts': 'Alaab la doortay',
      'discountProductCount': '{count} alaab',
      'discountStartDate': 'Taariikhda bilowga',
      'discountEndDate': 'Taariikhda dhammaadka',
      'discountSelectProducts': 'Dooro alaabta',
      'discountProductsRequired': 'Dooro ugu yaraan hal alaab',
      'discountAlways': 'Waqti kasta',
      'discountFromTo': '{from} – {to}',
      'discountFromOnly': 'Laga bilaabo {from}',
      'discountUntilOnly': 'Ilaa {to}',
      'discountOff': 'Qiimo-dhimis',
      'cartDiscount': 'Qiimo-dhimis',
      'paymentMethodsSubtitle': 'Dooro hababka lacag-bixinta ee ka muuqda POS',
      'addPaymentMethod': 'Ku dar hab lacag-bixin',
      'editPaymentMethod': 'Wax ka beddel habka lacag-bixinta',
      'noPaymentMethodsYet': 'Weli hab lacag-bixin lama dejin',
      'methodCode': 'Koodhka',
      'methodLabel': 'Magaca muuqaalka',
      'enabled': 'Shid',
      'deletePaymentMethodConfirm': 'Tirtir habka «{name}»?',
      'atLeastOnePaymentMethod': 'Ugu yaraan hal hab lacag-bixin waa inuu shidan yahay',
      'posDevicesSubtitle': 'Diiwaangeli terminaals, tablet-yo iyo scanner-yo',
      'addPosDevice': 'Ku dar qalab',
      'editPosDevice': 'Wax ka beddel qalabka',
      'noPosDevicesYet': 'Weli qalab POS lama diiwaangelin',
      'deviceName': 'Magaca qalabka',
      'deviceType': 'Nooca qalabka',
      'deviceIdentifier': 'Aqoonsi / serial',
      'deviceNotes': 'Qoraalo',
      'deviceTypeTerminal': 'Terminal',
      'deviceTypeTablet': 'Tablet',
      'deviceTypeScanner': 'Scanner',
      'deletePosDeviceConfirm': 'Ka saar qalabka «{name}»?',
      'printersSubtitle': 'Daabacadaha rasiidhada iyo summadaha terminal-kan',
      'addPrinter': 'Ku dar daabacad',
      'editPrinter': 'Wax ka beddel daabacada',
      'noPrintersYet': 'Weli daabacad lama dejin',
      'printerName': 'Magaca daabacada',
      'printerType': 'Nooca daabacada',
      'printerConnection': 'Isku xirka',
      'printerAddress': 'Cinwaanka / dekedda',
      'paperWidth': 'Ballaca warqadda (mm)',
      'defaultPrinter': 'Daabacada rasiidhada asalka ah',
      'printerTypeReceipt': 'Rasiid',
      'printerTypeLabel': 'Summad',
      'connectionUsb': 'USB',
      'connectionNetwork': 'Shabakad',
      'connectionBluetooth': 'Bluetooth',
      'deletePrinterConfirm': 'Tirtir daabacada «{name}»?',
      'backupSubtitle': 'Dhoofso ama soo celi xogta ku kaydsan kombuyuutarka',
      'exportBackup': 'Dhoofso kaydinta',
      'importBackup': 'Soo celi kaydinta',
      'backupExported': 'Kaydinta waa la kaydiyay: {path}',
      'backupRestored': 'Kaydinta si guul leh ayaa loo soo celiyay',
      'backupRestoreConfirm': 'Soo celi kaydinta?',
      'backupRestoreWarning': 'Tani waxay beddeli doontaa dhammaan xogta hadda jirta. Sii wad?',
      'backupLocation': 'Galka xogta: {path}',
      'networkSubtitle': 'Dejinta isku-xirka terminal-yo badan (server ayaa loo baahan yahay)',
      'networkEnabled': 'Shid isku-xirka shabakadda',
      'networkEnabledHint': 'Terminal-kan wuxuu isku xiri karaa server-ka MayleSoft',
      'serverUrl': 'URL-ka server-ka',
      'terminalName': 'Magaca terminal-ka',
      'syncInterval': 'Waqtiga isku-xirka',
      'syncIntervalHint': 'Inta jeer ee la hubiyo cusboonaysiinta',
      'minutes': 'daqiiqo',
      'networkSaved': 'Dejinta shabakadda waa la kaydiyay',
      'nameRequired': 'Magaca waa waajib',
      'invalidUrl': 'Geli URL http ama https sax ah',
      'storeName': 'Magaca dukaanka',
      'phone': 'Telefoon',
      'email': 'Email',
      'address': 'Cinwaanka',
      'receiptHeader': 'Madaxa rasiidka',
      'receiptFooter': 'Cagta rasiidka',
      'currencyCode': 'Koodhka lacagta',
      'currencySymbol': 'Calaamada lacagta',
      'taxName': 'Magaca canshuurta',
      'taxRate': 'Heerka canshuurta %',
      'taxType': 'Nooca canshuurta',
      'taxExclusive': 'Ka baxsan',
      'taxInclusive': 'Ku jirta',
      'storeLogo': 'Astaanta dukaanka',
      'storeLogoHint': 'Astaan afar-gees ah ayaa la taliyaa (tusaale 400×400). Waxaa loo isticmaalaa rasiidhada iyo summada.',
      'uploadLogo': 'Soo geli astaanta',
      'logoUploadLater': 'Soo-gelinta astaanta waxay noqon doontaa update dambe',
      'version': 'Nooca',
      'systemName': 'Magaca nidaamka',
      'copyrightNotice': 'Copyright 2026 - MayleSoft retail, designed by Eng. Hasan Kamaal',
      'comingSoon': '{title} dhawaan',
      'comingSoonBody': 'Qaybtan waxaa loogu talagalay doorashooyinka dejinta ee soo socda ee MayleSoft retail.',
      'couldNotSave': 'Lama kaydin karo: {error}',
      'searchHint': 'Raadi magac, SKU ama barcode…',
      'allCategories': 'Dhammaan',
      'noProductsFound': 'Alaab lama helin',
      'cart': 'Gaadhiga',
      'clearCart': 'Nadiifi',
      'cartItemsCount': '{count} shay',
      'tapProductsToAdd': 'Taabo alaabta si aad ugu darto',
      'subtotal': 'Wadarta hoose',
      'tax': 'Canshuur',
      'total': 'Wadarta',
      'chargeBtn': 'Qaad {amount}',
      'cartEmpty': 'Gaadhigu waa madhan',
      'chargeTitle': 'Qaad lacagta',
      'payCash': 'Lacag caddaan',
      'payCard': 'Kaarka',
      'payMobile': 'Moobile',
      'periodDaily': 'Maalinle',
      'periodWeekly': 'Toddobaadle',
      'periodMonthly': 'Bille',
      'revenue': 'Dakhliga',
      'estProfit': 'Faa\'iido qiyaas ah',
      'salesCount': 'Iibyo',
      'avgSale': 'Celceliska iibka',
      'topProducts': 'Alaabta ugu iibka badan',
      'noSalesInPeriod': 'Iib ma jiro muddadan',
      'paymentBreakdown': 'Qaybinta lacag-bixinta',
      'salesTrend': 'Isbeddelka iibka',
      'revenueVsProfit': 'Dakhliga vs faa\'iidada',
      'noPaymentsYet': 'Weli lacag-bixin ma jirto',
      'shiftOpen': 'Shaqada waa furan',
      'noActiveShift': 'Shaqo firfircoon ma jirto',
      'openShiftHint': 'Fur shaqo si aad u bilowdo iibka sanduuqa lacagta',
      'openShiftBtn': 'Fur shaqo',
      'cashInBtn': 'Lacag geli',
      'cashOutBtn': 'Lacag bixi',
      'closeBtn': 'Xir',
      'openingCash': 'Lacagta furitaanka',
      'cashSales': 'Iibka lacag caddaan',
      'cashInOut': 'Lacag geli / bixi',
      'expectedCash': 'Lacagta la filayo',
      'cashMovements': 'Dhaqdhaqaaqyada lacagta',
      'noMovementsYet': 'Weli dhaqdhaqaaq ma jiro',
      'shiftHistoryTitle': 'Taariikhda shaqada',
      'noShiftsYet': 'Weli shaqo ma jirto',
      'colEmployee': 'Shaqaale',
      'colOpened': 'La furay',
      'colClosed': 'La xiray',
      'colOpening': 'Furitaanka',
      'colClosing': 'Xiritaanka',
      'colExpected': 'La filayo',
      'colDiff': 'Farqiga',
      'colStatus': 'Xaalad',
      'statusOpen': 'furan',
      'statusClosedShift': 'xiran',
      'movementIn': 'GELI',
      'movementOut': 'BIXI',
      'cancel': 'Jooji',
      'ok': 'Haa',
      'save': 'Kaydi',
      'apply': 'Codso',
      'delete': 'Tirtir',
      'set': 'Deji',
      'remove': 'Ka saar',
      'upload': 'Soo geli',
      'none': 'Midna',
      'active': 'Firfircoon',
      'inactive': 'Aan firfircoonayn',
      'amount': 'Qadarka',
      'note': 'Qoraal',
      'noteOptional': 'Qoraal (ikhtiyaari)',
      'reason': 'Sabab',
      'quantityTitle': 'Tirada · {unit}',
      'qtyLabel': 'Tirada ({unit})',
      'saleCompleted': 'Iibka {receipt} waa la dhammeeyay',
      'editProduct': 'Wax ka beddel alaabta',
      'productAdded': 'Alaabta waa la daray',
      'productUpdated': 'Alaabta waa la cusboonaysiiyay',
      'productDeactivated': 'Alaabta waa la joojiyay',
      'deactivateProduct': 'Jooji alaabta',
      'deactivateBtn': 'Jooji',
      'deactivateProductConfirm': 'Ka saar «{name}» liiska?',
      'productImage': 'Sawirka alaabta',
      'colName': 'Magac',
      'colPrice': 'Qiimo',
      'colCost': 'Kharash',
      'colStock': 'Kayd',
      'colSkuBarcode': 'SKU / Barcode',
      'colCategory': 'Qayb',
      'sku': 'SKU',
      'barcode': 'Barcode',
      'unitLabel': 'Unug',
      'sellingPrice': 'Qiimaha iibka',
      'costLabel': 'Kharash',
      'taxPercent': 'Canshuur %',
      'reorderLevel': 'Heerka dib-u-dalashada',
      'color': 'Midab',
      'couldNotSaveImage': 'Sawirka lama kaydin karo: {error}',
      'editCategory': 'Wax ka beddel qaybta',
      'deleteCategory': 'Tirtir qaybta',
      'deleteCategoryConfirm': 'Tirtir «{name}»?',
      'categoryProductCount': '{count} alaab',
      'filterFrom': 'Laga bilaabo',
      'filterTo': 'Ilaa',
      'allStaff': 'Dhammaan shaqaalaha',
      'employee': 'Shaqaale',
      'refund': 'Soo celi',
      'refundReason': 'Sababta soo-celinta',
      'saleRefunded': 'Iibka waa la soo celiyay',
      'adjustStockTitle': 'Hagaaji kaydka · {name}',
      'currentStock': 'Hadda: {qty} {unit}',
      'quantityDelta': 'Isbeddelka tirada (+/-)',
      'reasonRequired': 'Sabab (waajib)',
      'stockAdjusted': 'Kaydka waa la hagaajiyay',
      'productLabel': 'Alaab',
      'quantity': 'Tirada',
      'unitCost': 'Kharashka unugga',
      'invoiceOptional': 'Lambarka qaansheegta (ikhtiyaari)',
      'stockReceived': 'Kaydka waa la helay',
      'noProducts': 'Alaab ma jirto',
      'adjustBtn': 'Hagaaji',
      'receiveBtn': 'Soo qaado',
      'reorderLine': 'Dib-u-dalasho {level} · {sku}',
      'recentMovements': 'Dhaqdhaqaaqyadii u dambeeyay',
      'productFallback': 'Alaab',
      'editEmployee': 'Wax ka beddel shaqaalaha',
      'noEmployeesYet': 'Weli shaqaale ma jiro',
      'username': 'Magaca isticmaalaha',
      'role': 'Doorka',
      'setCurrent': 'Deji kan hadda',
      'badgeCurrent': 'hadda',
      'shiftOpened': 'Shaqada waa la furay',
      'shiftClosed': 'Shaqada waa la xiray',
      'cashInRecorded': 'Lacag gelinta waa la diiwaangeliyay',
      'cashOutRecorded': 'Lacag bixinta waa la diiwaangeliyay',
      'roleOwner': 'milkiile',
      'roleAdmin': 'maamul',
      'roleManager': 'maareeye',
      'roleCashier': 'lacag-qaade',
      'signIn': 'Gal',
      'loginSubtitle': 'Gal si aad u gasho {store}',
      'pin': 'PIN',
      'pinHint': 'PIN 4–6 lambar ah',
      'pinRequired': 'Geli PIN-kaaga',
      'pinTooShort': 'PIN-ku waa inuu ahaadaa ugu yaraan 4 lambar',
      'usernameRequired': 'Geli magaca isticmaalaha',
      'invalidCredentials': 'Magaca isticmaalaha ama PIN khaldan',
      'loginHint': 'Asal ahaan: admin / 1234',
      'keepCurrentPin': 'Ka tag madhan si aad u haysato PIN-ka hadda',
      'accessDenied': 'Ma haysatid gelitaanka qaybtan',
    }),
  };
}
