class Category {
  final int? id;
  final String name;
  final String color;
  final String? createdAt;
  final int productCount;

  const Category({
    this.id,
    required this.name,
    this.color = '#3B82F6',
    this.createdAt,
    this.productCount = 0,
  });

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String? ?? '#3B82F6',
      createdAt: map['created_at'] as String?,
      productCount: (map['product_count'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
    };
  }
}
