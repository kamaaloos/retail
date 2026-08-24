import 'cart_item.dart';

/// A parked POS cart so another customer can be served meantime.
class HeldCart {
  final String id;
  final String label;
  final List<CartItem> items;
  final DateTime heldAt;
  final int? employeeId;

  const HeldCart({
    required this.id,
    required this.label,
    required this.items,
    required this.heldAt,
    this.employeeId,
  });

  int get lineCount => items.length;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity.ceil());

  double get total => items.fold(0.0, (sum, item) => sum + item.lineTotal);
}
