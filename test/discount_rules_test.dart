import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/models/settings_config.dart';

void main() {
  final now = DateTime(2026, 8, 24);

  group('DiscountRule', () {
    test('percent discount on line', () {
      const rule = DiscountRule(name: '10%', discountType: 'percent', value: 10);
      expect(rule.discountAmountForLine(100), 10);
    });

    test('fixed discount clamps to line', () {
      const rule = DiscountRule(name: '\$5', discountType: 'fixed', value: 5);
      expect(rule.discountAmountForLine(3), 3);
      expect(rule.discountAmountForLine(20), 5);
    });

    test('min purchase gate', () {
      const rule = DiscountRule(
        name: 'Big',
        discountType: 'percent',
        value: 50,
        minPurchase: 50,
      );
      expect(rule.discountAmountForLine(40), 0);
      expect(rule.discountAmountForLine(50), 25);
    });

    test('date window', () {
      final rule = DiscountRule(
        name: 'Weekend',
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 25),
      );
      expect(rule.isActiveOn(now), isTrue);
      expect(rule.isActiveOn(DateTime(2026, 8, 19)), isFalse);
      expect(rule.isActiveOn(DateTime(2026, 8, 26)), isFalse);
    });

    test('product scope', () {
      const all = DiscountRule(name: 'All', scope: 'all');
      const scoped = DiscountRule(name: 'Scoped', scope: 'products', productIds: [7, 8]);
      expect(all.appliesToProduct(99), isTrue);
      expect(scoped.appliesToProduct(7), isTrue);
      expect(scoped.appliesToProduct(1), isFalse);
      expect(scoped.appliesToProduct(null), isFalse);
    });
  });

  group('bestLineDiscount', () {
    test('picks the largest matching rule', () {
      final amount = bestLineDiscount(
        productId: 1,
        lineSubtotal: 100,
        when: now,
        rules: const [
          DiscountRule(name: '5%', discountType: 'percent', value: 5),
          DiscountRule(name: '12%', discountType: 'percent', value: 12),
          DiscountRule(name: 'inactive', discountType: 'percent', value: 50, active: false),
        ],
      );
      expect(amount, 12);
    });

    test('ignores product-scoped rules that do not match', () {
      final amount = bestLineDiscount(
        productId: 1,
        lineSubtotal: 100,
        when: now,
        rules: const [
          DiscountRule(
            name: 'Other SKU',
            discountType: 'percent',
            value: 40,
            scope: 'products',
            productIds: [99],
          ),
          DiscountRule(name: 'All 5%', discountType: 'percent', value: 5),
        ],
      );
      expect(amount, 5);
    });
  });
}
