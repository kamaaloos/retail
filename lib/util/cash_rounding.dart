/// Cash / non-card rounding helpers (nearest $0.05).
///
/// Examples: 3.27 → 3.25, 3.99 → 4.00.
class CashRounding {
  CashRounding._();

  /// True for card / credit / debit — exact cents, no cash rounding.
  static bool isCardPayment(String methodCodeOrLabel) {
    final s = methodCodeOrLabel.toLowerCase();
    return s.contains('card') ||
        s.contains('credit') ||
        s.contains('debit') ||
        s.contains('visa') ||
        s.contains('mastercard') ||
        s.contains('amex');
  }

  /// Round to nearest 5 cents (0.05).
  static double roundToNearestNickel(double amount) {
    if (amount.isNaN || amount.isInfinite) return amount;
    return (amount * 20).round() / 20.0;
  }

  /// Amount the customer owes for [method] (card = exact, else nickel-rounded).
  static double amountDue(double rawTotal, String methodCodeOrLabel) {
    final exact = double.parse(rawTotal.toStringAsFixed(2));
    if (isCardPayment(methodCodeOrLabel)) return exact;
    return double.parse(roundToNearestNickel(exact).toStringAsFixed(2));
  }

  /// Difference applied to discount so stored total matches charged amount.
  /// Positive when rounding down (customer pays less).
  static double adjustment(double rawTotal, double chargedTotal) {
    return double.parse((rawTotal - chargedTotal).toStringAsFixed(2));
  }
}
