import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/models/insufficient_stock.dart';

void main() {
  group('InsufficientStockException', () {
    test('formatQty strips trailing zeros for whole numbers', () {
      expect(InsufficientStockException.formatQty(3.0), '3');
      expect(InsufficientStockException.formatQty(0), '0');
    });

    test('formatQty keeps decimals when needed', () {
      expect(InsufficientStockException.formatQty(1.5), '1.50');
      expect(InsufficientStockException.formatQty(0.25), '0.25');
    });

    test('localized fills name / need / have', () {
      const e = InsufficientStockException(
        productName: 'Milk',
        requested: 5,
        available: 2,
      );
      expect(
        e.localized('Not enough stock for {name}. Need {need}, available {have}.'),
        'Not enough stock for Milk. Need 5, available 2.',
      );
    });

    test('toString is human-readable', () {
      const e = InsufficientStockException(
        productName: 'Bread',
        requested: 2.5,
        available: 1,
      );
      expect(e.toString(), contains('Bread'));
      expect(e.toString(), contains('2.50'));
      expect(e.toString(), contains('1'));
    });
  });
}
