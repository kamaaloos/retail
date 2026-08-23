import 'package:flutter/material.dart';

/// Main app sections (sidebar order).
enum AppPage {
  dashboard(0, Icons.dashboard_outlined, Icons.dashboard),
  pos(1, Icons.point_of_sale_outlined, Icons.point_of_sale),
  products(2, Icons.inventory_2_outlined, Icons.inventory_2),
  categories(3, Icons.category_outlined, Icons.category),
  salesHistory(4, Icons.receipt_long_outlined, Icons.receipt_long),
  inventory(5, Icons.warehouse_outlined, Icons.warehouse),
  staff(6, Icons.groups_outlined, Icons.groups),
  shifts(7, Icons.schedule_outlined, Icons.schedule),
  reports(8, Icons.assessment_outlined, Icons.assessment),
  settings(9, Icons.settings_outlined, Icons.settings);

  const AppPage(this.navIndex, this.iconOutlined, this.iconFilled);

  final int navIndex;
  final IconData iconOutlined;
  final IconData iconFilled;

  static AppPage? fromIndex(int index) {
    for (final page in AppPage.values) {
      if (page.navIndex == index) return page;
    }
    return null;
  }
}

abstract final class RolePermissions {
  static bool canAccess(String role, AppPage page) {
    switch (role.toLowerCase()) {
      case 'cashier':
        return page == AppPage.dashboard || page == AppPage.pos;
      case 'manager':
        return page != AppPage.staff && page != AppPage.settings;
      case 'admin':
      case 'owner':
        return true;
      default:
        return page == AppPage.dashboard || page == AppPage.pos;
    }
  }

  static List<AppPage> allowedPages(String role) {
    return AppPage.values.where((page) => canAccess(role, page)).toList();
  }

  static AppPage defaultPage(String role) {
    return allowedPages(role).first;
  }
}
