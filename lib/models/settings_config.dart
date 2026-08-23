class DiscountRule {
  final int? id;
  final String name;
  final String discountType; // percent | fixed
  final double value;
  final double minPurchase;
  final bool active;
  final String scope; // all | products
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> productIds;

  const DiscountRule({
    this.id,
    required this.name,
    this.discountType = 'percent',
    this.value = 0,
    this.minPurchase = 0,
    this.active = true,
    this.scope = 'all',
    this.startDate,
    this.endDate,
    this.productIds = const [],
  });

  factory DiscountRule.fromMap(Map<String, Object?> map, {List<int>? productIds}) {
    return DiscountRule(
      id: map['id'] as int?,
      name: map['name'] as String,
      discountType: map['discount_type'] as String? ?? 'percent',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      minPurchase: (map['min_purchase'] as num?)?.toDouble() ?? 0,
      active: (map['active'] as int? ?? 1) == 1,
      scope: map['scope'] as String? ?? 'all',
      startDate: _parseDate(map['start_date'] as String?),
      endDate: _parseDate(map['end_date'] as String?),
      productIds: productIds ?? const [],
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'discount_type': discountType,
        'value': value,
        'min_purchase': minPurchase,
        'active': active ? 1 : 0,
        'scope': scope,
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      };

  bool isActiveOn(DateTime when) {
    if (!active) return false;
    final day = DateTime(when.year, when.month, when.day);
    if (startDate != null) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (day.isBefore(start)) return false;
    }
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (day.isAfter(end)) return false;
    }
    return true;
  }

  bool appliesToProduct(int? productId) {
    if (scope == 'all') return true;
    if (productId == null) return false;
    return productIds.contains(productId);
  }

  double discountAmountForLine(double lineSubtotal) {
    if (lineSubtotal < minPurchase) return 0;
    if (discountType == 'fixed') {
      return value.clamp(0, lineSubtotal);
    }
    return (lineSubtotal * value / 100).clamp(0, lineSubtotal);
  }

  String summary({required String percentLabel, required String fixedLabel}) {
    if (discountType == 'fixed') {
      return fixedLabel.replaceAll('{value}', value.toStringAsFixed(2));
    }
    return percentLabel.replaceAll('{value}', value.toStringAsFixed(value % 1 == 0 ? 0 : 1));
  }

  String scopeLabel({
    required String allProducts,
    required String selectedProducts,
    required String productCount,
  }) {
    if (scope == 'all') return allProducts;
    if (productIds.isEmpty) return selectedProducts;
    return productCount.replaceAll('{count}', '${productIds.length}');
  }

  String periodLabel({
    required String always,
    required String fromTo,
    required String fromOnly,
    required String untilOnly,
    required String Function(DateTime) formatDate,
  }) {
    if (startDate == null && endDate == null) return always;
    if (startDate != null && endDate != null) {
      return fromTo
          .replaceAll('{from}', formatDate(startDate!))
          .replaceAll('{to}', formatDate(endDate!));
    }
    if (startDate != null) {
      return fromOnly.replaceAll('{from}', formatDate(startDate!));
    }
    return untilOnly.replaceAll('{to}', formatDate(endDate!));
  }
}

/// Pick the best matching discount for a cart line.
double bestLineDiscount({
  required int? productId,
  required double lineSubtotal,
  required List<DiscountRule> rules,
  DateTime? when,
}) {
  final now = when ?? DateTime.now();
  var best = 0.0;
  for (final rule in rules) {
    if (!rule.isActiveOn(now)) continue;
    if (!rule.appliesToProduct(productId)) continue;
    final amount = rule.discountAmountForLine(lineSubtotal);
    if (amount > best) best = amount;
  }
  return best;
}

class PaymentMethodConfig {
  final int? id;
  final String code;
  final String label;
  final bool enabled;
  final int sortOrder;

  const PaymentMethodConfig({
    this.id,
    required this.code,
    required this.label,
    this.enabled = true,
    this.sortOrder = 0,
  });

  factory PaymentMethodConfig.fromMap(Map<String, Object?> map) {
    return PaymentMethodConfig(
      id: map['id'] as int?,
      code: map['code'] as String,
      label: map['label'] as String,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'code': code,
        'label': label,
        'enabled': enabled ? 1 : 0,
        'sort_order': sortOrder,
      };
}

class PosDevice {
  final int? id;
  final String name;
  final String deviceType;
  final String identifier;
  final bool active;
  final String notes;

  const PosDevice({
    this.id,
    required this.name,
    this.deviceType = 'terminal',
    this.identifier = '',
    this.active = true,
    this.notes = '',
  });

  factory PosDevice.fromMap(Map<String, Object?> map) {
    return PosDevice(
      id: map['id'] as int?,
      name: map['name'] as String,
      deviceType: map['device_type'] as String? ?? 'terminal',
      identifier: map['identifier'] as String? ?? '',
      active: (map['active'] as int? ?? 1) == 1,
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'device_type': deviceType,
        'identifier': identifier,
        'active': active ? 1 : 0,
        'notes': notes,
      };
}

class PrinterConfig {
  final int? id;
  final String name;
  final String printerType;
  final String connection;
  final String address;
  final int paperWidth;
  final bool isDefault;
  final bool active;

  const PrinterConfig({
    this.id,
    required this.name,
    this.printerType = 'receipt',
    this.connection = 'usb',
    this.address = '',
    this.paperWidth = 80,
    this.isDefault = false,
    this.active = true,
  });

  factory PrinterConfig.fromMap(Map<String, Object?> map) {
    return PrinterConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      printerType: map['printer_type'] as String? ?? 'receipt',
      connection: map['connection'] as String? ?? 'usb',
      address: map['address'] as String? ?? '',
      paperWidth: map['paper_width'] as int? ?? 80,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      active: (map['active'] as int? ?? 1) == 1,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'printer_type': printerType,
        'connection': connection,
        'address': address,
        'paper_width': paperWidth,
        'is_default': isDefault ? 1 : 0,
        'active': active ? 1 : 0,
      };
}

class NetworkSettings {
  final bool enabled;
  final String serverUrl;
  final String terminalName;
  final int syncIntervalMinutes;

  const NetworkSettings({
    this.enabled = false,
    this.serverUrl = '',
    this.terminalName = '',
    this.syncIntervalMinutes = 60,
  });

  factory NetworkSettings.fromMap(Map<String, String> settings) {
    return NetworkSettings(
      enabled: settings['network_enabled'] == '1',
      serverUrl: settings['network_server_url'] ?? '',
      terminalName: settings['network_terminal_name'] ?? '',
      syncIntervalMinutes: int.tryParse(settings['network_sync_interval'] ?? '') ?? 60,
    );
  }

  Map<String, String> toSettingsMap() => {
        'network_enabled': enabled ? '1' : '0',
        'network_server_url': serverUrl,
        'network_terminal_name': terminalName,
        'network_sync_interval': syncIntervalMinutes.toString(),
      };
}
