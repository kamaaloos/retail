class InsufficientStockException implements Exception {
  final String productName;
  final double requested;
  final double available;

  const InsufficientStockException({
    required this.productName,
    required this.requested,
    required this.available,
  });

  static String formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }

  String localized(String template) => template
      .replaceAll('{name}', productName)
      .replaceAll('{need}', formatQty(requested))
      .replaceAll('{have}', formatQty(available));

  @override
  String toString() =>
      'Not enough stock for $productName (need ${formatQty(requested)}, have ${formatQty(available)})';
}
