import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/util/cash_rounding.dart';

/// Lightweight smoke — full app shell needs DB init and is covered elsewhere.
void main() {
  test('money helpers are wired for POS', () {
    expect(CashRounding.amountDue(3.27, 'cash'), 3.25);
    expect(CashRounding.amountDue(3.27, 'card'), 3.27);
  });
}
