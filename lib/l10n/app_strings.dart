import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Lightweight offline strings for Settings → Language.
class AppStrings {
  AppStrings._(this.code);

  final String code;

  static AppStrings of(String languageCode) => AppStrings._(languageCode);

  static const supported = <String, String>{
    'en_US': 'English - (US)',
    'en_GB': 'English - (UK)',
    'fr_FR': 'French',
    'ar_SA': 'Arabic',
  };

  Locale get locale {
    final parts = code.split('_');
    if (parts.length >= 2) return Locale(parts[0], parts[1]);
    return Locale(parts.first);
  }

  /// Locale tag for [DateFormat] / [NumberFormat] (e.g. `ar_SA`).
  String get intlLocale => code;

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
  String get settingsSubtitle => get('settingsSubtitle');

  static const _tables = <String, Map<String, String>>{
    'en_US': {
      'appName': 'Shop X',
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
      'settingsSubtitle': 'Business, tax, currency and app preferences',
    },
    'en_GB': {
      'appName': 'Shop X',
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
      'settingsSubtitle': 'Business, tax, currency and app preferences',
    },
    'fr_FR': {
      'appName': 'Shop X',
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
      'settingsSubtitle': 'Entreprise, taxe, devise et préférences',
    },
    'ar_SA': {
      'appName': 'شوب إكس',
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
      'settingsSubtitle': 'المتجر والضريبة والعملة وتفضيلات التطبيق',
    },
  };
}
