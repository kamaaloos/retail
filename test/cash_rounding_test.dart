import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/util/cash_rounding.dart';

void main() {
  group('CashRounding.roundToNearestNickel', () {
    test('rounds down mid-range cents', () {
      expect(CashRounding.roundToNearestNickel(3.27), 3.25);
      expect(CashRounding.roundToNearestNickel(1.02), 1.00);
    });

    test('rounds up toward next nickel', () {
      expect(CashRounding.roundToNearestNickel(3.99), 4.00);
      expect(CashRounding.roundToNearestNickel(1.03), 1.05);
    });

    test('leaves exact nickels unchanged', () {
      expect(CashRounding.roundToNearestNickel(2.50), 2.50);
      expect(CashRounding.roundToNearestNickel(0.05), 0.05);
    });

    test('passes through NaN / infinity', () {
      expect(CashRounding.roundToNearestNickel(double.nan).isNaN, isTrue);
      expect(CashRounding.roundToNearestNickel(double.infinity), double.infinity);
    });
  });

  group('CashRounding.isCardPayment', () {
    test('detects card-like methods', () {
      expect(CashRounding.isCardPayment('card'), isTrue);
      expect(CashRounding.isCardPayment('Credit Card'), isTrue);
      expect(CashRounding.isCardPayment('visa'), isTrue);
      expect(CashRounding.isCardPayment('DEBIT'), isTrue);
      expect(CashRounding.isCardPayment('Amex'), isTrue);
    });

    test('cash and mobile are not card', () {
      expect(CashRounding.isCardPayment('cash'), isFalse);
      expect(CashRounding.isCardPayment('mobile'), isFalse);
      expect(CashRounding.isCardPayment('other'), isFalse);
    });
  });

  group('CashRounding.amountDue', () {
    test('cash applies nickel rounding', () {
      expect(CashRounding.amountDue(3.27, 'cash'), 3.25);
      expect(CashRounding.amountDue(3.99, 'cash'), 4.00);
    });

    test('card keeps exact cents', () {
      expect(CashRounding.amountDue(3.27, 'card'), 3.27);
      expect(CashRounding.amountDue(3.99, 'visa'), 3.99);
    });
  });

  group('CashRounding.adjustment', () {
    test('positive when customer pays less after rounding down', () {
      expect(CashRounding.adjustment(3.27, 3.25), 0.02);
    });

    test('negative when rounded up', () {
      expect(CashRounding.adjustment(3.99, 4.00), -0.01);
    });

    test('zero when unchanged', () {
      expect(CashRounding.adjustment(2.50, 2.50), 0.00);
    });
  });
}
