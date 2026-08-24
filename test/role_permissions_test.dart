import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/auth/role_permissions.dart';

void main() {
  group('RolePermissions', () {
    test('cashier can sell and open shifts, not settings', () {
      expect(RolePermissions.canAccess('cashier', AppPage.pos), isTrue);
      expect(RolePermissions.canAccess('cashier', AppPage.shifts), isTrue);
      expect(RolePermissions.canAccess('cashier', AppPage.settings), isFalse);
      expect(RolePermissions.canAccess('cashier', AppPage.customers), isFalse);
    });

    test('manager cannot open staff or settings', () {
      expect(RolePermissions.canAccess('manager', AppPage.reports), isTrue);
      expect(RolePermissions.canAccess('manager', AppPage.customers), isTrue);
      expect(RolePermissions.canAccess('manager', AppPage.staff), isFalse);
      expect(RolePermissions.canAccess('manager', AppPage.settings), isFalse);
    });

    test('admin/owner see everything', () {
      for (final page in AppPage.values) {
        expect(RolePermissions.canAccess('admin', page), isTrue, reason: '$page');
        expect(RolePermissions.canAccess('owner', page), isTrue, reason: '$page');
      }
    });
  });
}
