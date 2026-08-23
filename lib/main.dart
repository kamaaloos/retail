import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';
import 'l10n/app_strings.dart';
import 'providers/retail_store.dart';
import 'ui/pages.dart';
import 'ui/settings_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('en_GB');
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('ar');
  await initializeDateFormatting('ar_SA');
  await AppDatabase.instance.init();

  final store = RetailStore();
  await store.load();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const ShopXApp(),
    ),
  );
}

class ShopXApp extends StatelessWidget {
  const ShopXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final strings = AppStrings.of(store.language);

    return MaterialApp(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildRetailTheme(dark: store.darkMode),
      locale: strings.locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en', 'GB'),
        Locale('fr', 'FR'),
        Locale('ar', 'SA'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: strings.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  List<(IconData, IconData, String)> _destinations(AppStrings s) => [
        (Icons.dashboard_outlined, Icons.dashboard, s.dashboard),
        (Icons.point_of_sale_outlined, Icons.point_of_sale, s.pos),
        (Icons.inventory_2_outlined, Icons.inventory_2, s.products),
        (Icons.category_outlined, Icons.category, s.categories),
        (Icons.receipt_long_outlined, Icons.receipt_long, s.salesHistory),
        (Icons.warehouse_outlined, Icons.warehouse, s.inventory),
        (Icons.groups_outlined, Icons.groups, s.staff),
        (Icons.schedule_outlined, Icons.schedule, s.shifts),
        (Icons.assessment_outlined, Icons.assessment, s.reports),
        (Icons.settings_outlined, Icons.settings, s.settings),
      ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final strings = AppStrings.of(store.language);
    final destinations = _destinations(strings);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: AppColors.panel,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(strings.appName, style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: destinations.length,
                    itemBuilder: (context, i) {
                      final d = destinations[i];
                      final selected = index == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () => setState(() => index = i),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? d.$2 : d.$1,
                                  size: 20,
                                  color: selected ? AppColors.accent : AppColors.muted,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    d.$3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected ? AppColors.text : AppColors.muted,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          (store.currentEmployee?.name ?? 'A').characters.first.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.currentEmployee?.name ?? 'Admin',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                            ),
                            Text(
                              (store.currentEmployee?.role ?? 'owner').toUpperCase(),
                              style: TextStyle(color: AppColors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.logout, size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.bg,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(index),
                  child: _page(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _page(int i) {
    switch (i) {
      case 1:
        return const PosPage();
      case 2:
        return const ProductsPage();
      case 3:
        return const CategoriesPage();
      case 4:
        return const SalesHistoryPage();
      case 5:
        return const InventoryPage();
      case 6:
        return const StaffPage();
      case 7:
        return const ShiftsPage();
      case 8:
        return const ReportsPage();
      case 9:
        return const SettingsPage();
      case 0:
      default:
        return DashboardHome(onOpenPos: () => setState(() => index = 1));
    }
  }
}
