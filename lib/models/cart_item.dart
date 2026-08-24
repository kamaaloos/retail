import 'product.dart';

class CartItem {
  final Product product;
  double quantity;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
  });

  double get unitPrice => product.sellingPrice;

  double get lineSubtotal => unitPrice * quantity;

  double get taxAmount {
    final taxable = (lineSubtotal - discount).clamp(0, double.infinity);
    return taxable * (product.taxRate / 100);
  }

  double get lineTotal => (lineSubtotal - discount) + taxAmount;

  CartItem copy() => CartItem(
        product: product,
        quantity: quantity,
        discount: discount,
      );
}
