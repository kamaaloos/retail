import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/models/cart_item.dart';
import 'package:retail_manager/models/product.dart';

void main() {
  Product product({
    double price = 10,
    double taxRate = 10,
  }) {
    return Product(
      id: 1,
      name: 'Test',
      sku: 'T1',
      sellingPrice: price,
      costPrice: 5,
      taxRate: taxRate,
      stockOnHand: 20,
    );
  }

  group('CartItem totals', () {
    test('subtotal is price × qty', () {
      final item = CartItem(product: product(), quantity: 3);
      expect(item.lineSubtotal, 30);
    });

    test('tax is on (subtotal − discount)', () {
      final item = CartItem(product: product(taxRate: 10), quantity: 2, discount: 5);
      // taxable = 20 - 5 = 15 → tax 1.5
      expect(item.taxAmount, 1.5);
      expect(item.lineTotal, 16.5);
    });

    test('zero tax when rate is 0', () {
      final item = CartItem(product: product(taxRate: 0), quantity: 1);
      expect(item.taxAmount, 0);
      expect(item.lineTotal, 10);
    });

    test('copy is independent', () {
      final a = CartItem(product: product(), quantity: 1, discount: 1);
      final b = a.copy();
      b.quantity = 9;
      b.discount = 0;
      expect(a.quantity, 1);
      expect(a.discount, 1);
    });
  });
}
