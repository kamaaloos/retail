class Product {
  final int? id;
  final String sku;
  final String? barcode;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final String unit;
  final String color;
  final String? imagePath;
  final double costPrice;
  final double sellingPrice;
  final double taxRate;
  final double reorderLevel;
  final bool active;
  final double stockOnHand;
  final String? createdAt;
  final String? updatedAt;

  const Product({
    this.id,
    required this.sku,
    this.barcode,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.unit = 'pcs',
    this.color = '#3B82F6',
    this.imagePath,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.taxRate = 0,
    this.reorderLevel = 0,
    this.active = true,
    this.stockOnHand = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => stockOnHand <= reorderLevel;

  bool get isDecimalUnit => unit == 'kg' || unit == 'L' || unit == 'm';

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      sku: map['sku'] as String,
      barcode: map['barcode'] as String?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      unit: map['unit'] as String? ?? 'pcs',
      color: map['color'] as String? ?? '#3B82F6',
      imagePath: map['image_path'] as String?,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      reorderLevel: (map['reorder_level'] as num?)?.toDouble() ?? 0,
      active: (map['active'] as int? ?? 1) == 1,
      stockOnHand: (map['stock_on_hand'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'category_id': categoryId,
      'unit': unit,
      'color': color,
      'image_path': imagePath,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'tax_rate': taxRate,
      'reorder_level': reorderLevel,
      'active': active ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? sku,
    String? barcode,
    String? name,
    int? categoryId,
    String? categoryName,
    String? unit,
    String? color,
    String? imagePath,
    bool clearImage = false,
    double? costPrice,
    double? sellingPrice,
    double? taxRate,
    double? reorderLevel,
    bool? active,
    double? stockOnHand,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      color: color ?? this.color,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxRate: taxRate ?? this.taxRate,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      active: active ?? this.active,
      stockOnHand: stockOnHand ?? this.stockOnHand,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

const productUnits = ['pcs', 'kg', 'L', 'm'];

const productColorPalette = [
  '#3B82F6',
  '#22C55E',
  '#F59E0B',
  '#EF4444',
  '#A855F7',
  '#06B6D4',
  '#EC4899',
  '#84CC16',
  '#F97316',
  '#64748B',
];
