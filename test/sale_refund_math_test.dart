import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/models/sale.dart';

void main() {
  SaleItem item({
    double quantity = 5,
    double refunded = 0,
    double unitPrice = 10,
  }) {
    return SaleItem(
      saleId: 1,
      productId: 10,
      productName: 'Soap',
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: unitPrice * quantity,
      refundedQuantity: refunded,
    );
  }

  group('SaleItem.remainingQuantity', () {
    test('full remaining when nothing refunded', () {
      expect(item().remainingQuantity, 5);
    });

    test('partial remaining after prior refund', () {
      expect(item(refunded: 2).remainingQuantity, 3);
    });

    test('zero when fully refunded', () {
      expect(item(refunded: 5).remainingQuantity, 0);
    });

    test('never goes negative if over-refunded in data', () {
      expect(item(refunded: 9).remainingQuantity, 0);
    });
  });

  group('refund qty clamp (mirrors sale_repository)', () {
    double clamp(double want, double remaining) {
      if (want <= 0) return 0;
      return want > remaining ? remaining : want;
    }

    test('caps want to remaining', () {
      expect(clamp(4, 2), 2);
      expect(clamp(1, 3), 1);
      expect(clamp(0, 5), 0);
      expect(clamp(-1, 5), 0);
    });

    test('status after refund', () {
      String status(List<({double sold, double refunded})> lines) {
        final fully = lines.every((l) => l.refunded + 0.0001 >= l.sold);
        return fully ? 'refunded' : 'partial_refund';
      }

      expect(
        status([(sold: 5.0, refunded: 2.0), (sold: 1.0, refunded: 1.0)]),
        'partial_refund',
      );
      expect(
        status([(sold: 5.0, refunded: 5.0), (sold: 1.0, refunded: 1.0)]),
        'refunded',
      );
    });
  });
}
